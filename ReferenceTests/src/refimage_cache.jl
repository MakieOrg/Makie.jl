const MAX_CACHE_AGE_SECONDS = 30 * 24 * 60 * 60

"""
    cached_download(fetch!, cache_root, key, digest; now = time())

Return a folder whose content was produced by `fetch!(folder)` for `digest`, calling
`fetch!` only when `cache_root/key` holds no complete download for that digest. A download
for another digest under the same `key` is replaced, and downloads under any key that are
older than $(MAX_CACHE_AGE_SECONDS ÷ 86400) days are removed.
"""
function cached_download(fetch!, cache_root::AbstractString, key::AbstractString, digest::AbstractString; now = time())
    prune_old_downloads!(cache_root, now)

    cache_dir = joinpath(cache_root, key)
    digest_file = joinpath(cache_dir, "digest")
    content_dir = joinpath(cache_dir, "content")
    isfile(digest_file) && read(digest_file, String) == digest && return content_dir

    rm(cache_dir; force = true, recursive = true)
    mkpath(cache_dir)
    fetch!(content_dir)
    # written last so that an interrupted fetch is never mistaken for a complete one
    write(digest_file, digest)
    return content_dir
end

function prune_old_downloads!(cache_root, now)
    isdir(cache_root) || return
    for key in readdir(cache_root)
        cache_dir = joinpath(cache_root, key)
        digest_file = joinpath(cache_dir, "digest")
        if !isfile(digest_file) || now - mtime(digest_file) > MAX_CACHE_AGE_SECONDS
            rm(cache_dir; force = true, recursive = true)
        end
    end
    return
end

const REFERENCE_TESTS_UUID = Base.UUID("d37af2e0-5618-4e00-9939-d430db56ee94")

refimages_url(tag) = "https://github.com/MakieOrg/Makie.jl/releases/download/refimages-$(tag)/reference_images.tar"

function fetch_refimages!(images_dir, tag; progress = nothing)
    images_tar = Downloads.download(refimages_url(tag); progress)
    try
        Tar.extract(images_tar, images_dir)
    finally
        rm(images_tar)
    end
    return images_dir
end

function refimages_digest(tag)
    url = "https://api.github.com/repos/MakieOrg/Makie.jl/releases/tags/refimages-$(tag)"
    headers = haskey(ENV, "GITHUB_TOKEN") ? ["Authorization" => "token $(ENV["GITHUB_TOKEN"])"] : Pair{String, String}[]
    release = JSON3.read(take!(Downloads.download(url, IOBuffer(); headers)))
    asset = only(filter(a -> a["name"] == "reference_images.tar", release["assets"]))
    return String(asset["digest"])
end

"""
    cached_refimages(tag)

The extracted reference images of the `refimages-<tag>` release, reused from a local cache
until the release's tarball changes. The returned folder is shared between calls (also
between ReferenceTests and ReferenceUpdater), so it must not be modified.
"""
function cached_refimages(tag)
    cache_root = Scratch.get_scratch!(REFERENCE_TESTS_UUID, "refimages")
    return cached_download(dir -> fetch_refimages!(dir, tag), cache_root, tag, refimages_digest(tag))
end
