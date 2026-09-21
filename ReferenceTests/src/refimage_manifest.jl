import SHA

# resolved from this file's own location so it points at ReferenceTests/refimage_updates
# even when this file is `include`d into ReferenceUpdater rather than ReferenceTests.
# The manifest is a directory of per-image fragment files (one `<path>.pin` per entry,
# content = the pin) so that concurrent PRs touching different images never edit the same
# file and thus never conflict on merge.
refimage_manifest_dir() = normpath(joinpath(@__DIR__, "..", "refimage_updates"))

struct RefimageUpdate
    path::String
    pin::String
end

reference_hash(file::AbstractString) = bytes2hex(SHA.sha256(read(file)))

function pin_for(path::AbstractString, reference_folder::AbstractString)
    ref = joinpath(reference_folder, path)
    return isfile(ref) ? reference_hash(ref) : "new"
end

fragment_file(dir::AbstractString, path::AbstractString) = joinpath(dir, path * ".pin")

function read_manifest(dir::AbstractString = refimage_manifest_dir())
    entries = RefimageUpdate[]
    isdir(dir) || return entries
    for (root, _, files) in walkdir(dir)
        for f in files
            endswith(f, ".pin") || continue
            full = joinpath(root, f)
            path = replace(relpath(full, dir)[1:(end - length(".pin"))], '\\' => '/')
            push!(entries, RefimageUpdate(String(path), strip(read(full, String))))
        end
    end
    return sort!(entries, by = e -> e.path)
end

function write_entry(entry::RefimageUpdate, dir::AbstractString = refimage_manifest_dir())
    file = fragment_file(dir, entry.path)
    mkpath(dirname(file))
    write(file, entry.pin * "\n")
    return file
end

function remove_entry(path::AbstractString, dir::AbstractString = refimage_manifest_dir())
    file = fragment_file(dir, path)
    isfile(file) && rm(file)
    return
end

write_manifest(entries, dir::AbstractString = refimage_manifest_dir()) = foreach(e -> write_entry(e, dir), entries)

function classify_entries(entries, reference_folder::AbstractString)
    exempt_changed = Set{String}()
    exempt_new = Set{String}()
    to_delete = Set{String}()
    inert = RefimageUpdate[]
    for e in entries
        ref = joinpath(reference_folder, e.path)
        if e.pin == "new"
            isfile(ref) ? push!(inert, e) : push!(exempt_new, e.path)
        elseif e.pin == "delete"
            isfile(ref) ? push!(to_delete, e.path) : push!(inert, e)
        else
            (isfile(ref) && reference_hash(ref) == e.pin) ? push!(exempt_changed, e.path) : push!(inert, e)
        end
    end
    return (; exempt_changed, exempt_new, to_delete, inert)
end

# delete fragment files whose entries are no longer active (already promoted / stale)
function prune_inert!(reference_folder::AbstractString, dir::AbstractString = refimage_manifest_dir())
    for e in classify_entries(read_manifest(dir), reference_folder).inert
        remove_entry(e.path, dir)
    end
    return
end
