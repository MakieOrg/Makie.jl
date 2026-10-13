module Changelog

    using Dates

    const ROOT = normpath(joinpath(@__DIR__, ".."))
    const ENTRY_DIR = joinpath(ROOT, "changelog")
    const CHANGELOG_PATH = joinpath(ROOT, "CHANGELOG.md")
    const PR_URL = "https://github.com/MakieOrg/Makie.jl/pull"
    const NON_ENTRY_FILES = ["README.md"]

    const SECTIONS = ["Breaking", "Added", "Changed", "Deprecated", "Removed", "Fixed"]

    struct Entry
        pr::Int
        section::Union{Nothing, String}
        lines::Vector{String}
    end

    function entry_files(dir = ENTRY_DIR)
        files = filter(∉(NON_ENTRY_FILES), readdir(dir))
        for file in files
            occursin(r"^[1-9]\d*\.md$", file) ||
                error("Invalid file `changelog/$file`, entry files must be named `<PR number>.md`.")
        end
        return sort!(joinpath.(dir, files); by = pr_number, rev = true)
    end

    pr_number(path) = parse(Int, chopsuffix(basename(path), ".md"))

    function parse_entry_file(path)
        pr = pr_number(path)
        lines = readlines(path)
        file_error(msg) = error("`changelog/$pr.md`: $msg")

        entries = Entry[]
        section = nothing
        empty_section_line = 0
        continuable = false
        for (i, line) in enumerate(lines)
            heading = match(r"^## (.*)$", line)
            if isempty(strip(line))
                continue
            elseif heading !== nothing
                empty_section_line > 0 && file_error("Section on line $empty_section_line has no entries.")
                section = String(strip(heading[1]))
                section in SECTIONS ||
                    file_error("Invalid section `## $section` on line $i, allowed are $(join(("`## $s`" for s in SECTIONS), ", ")).")
                empty_section_line = i
                continuable = false
            elseif occursin(r"^- \S", line)
                push!(entries, Entry(pr, section, [rstrip(line)]))
                empty_section_line = 0
                continuable = true
            elseif occursin(r"^\s+\S", line) && continuable
                push!(entries[end].lines, rstrip(line))
            else
                file_error(
                    "Invalid line $i: $(repr(line))\n" *
                        "Every line must be a `## <section>` heading, start a `- ` entry, be an indented continuation of the previous entry, or be blank."
                )
            end
        end
        empty_section_line > 0 && file_error("Section on line $empty_section_line has no entries.")
        isempty(entries) && file_error("No entries found, add at least one `- ` entry.")

        occursin(Regex("$(PR_URL)/$pr\\b"), join(lines, "\n")) &&
            file_error("Must not link to PR #$pr, the link is added automatically.")

        return entries
    end

    function render_entry(entry::Entry)
        first_line = "$(entry.lines[1]) [#$(entry.pr)]($PR_URL/$(entry.pr))"
        return [first_line; entry.lines[2:end]]
    end

    render_entries(entries) = mapreduce(render_entry, vcat, entries; init = String[])

    function join_blocks(blocks)
        nonempty = filter(!isempty, blocks)
        return isempty(nonempty) ? String[] : reduce((a, b) -> [a; ""; b], nonempty)
    end

    function unreleased_lines(dir = ENTRY_DIR)
        entries = mapreduce(parse_entry_file, vcat, entry_files(dir); init = Entry[])
        unsectioned = render_entries(filter(e -> e.section === nothing, entries))
        sectioned = map(SECTIONS) do section
            section_entries = filter(e -> e.section == section, entries)
            isempty(section_entries) ? String[] : ["### $section"; ""; render_entries(section_entries)]
        end
        return join_blocks([[unsectioned]; sectioned])
    end

    function insert_section(changelog_lines, section_lines)
        header_idx = findfirst(==("# Changelog"), changelog_lines)
        header_idx === nothing && error("Could not find the `# Changelog` header in CHANGELOG.md.")
        rest = changelog_lines[(header_idx + 1):end]
        first_content = something(findfirst(!isempty ∘ strip, rest), length(rest) + 1)
        return [changelog_lines[1:header_idx]; ""; section_lines; ""; rest[first_content:end]]
    end

    function release!(version::VersionNumber; changelog_path = CHANGELOG_PATH, dir = ENTRY_DIR, date = today())
        entries = unreleased_lines(dir)
        isempty(entries) && @warn "No changelog entries found in $dir."
        section = ["## [$version] - $(Dates.format(date, "yyyy-mm-dd"))"; ""; entries]
        write(changelog_path, join(insert_section(readlines(changelog_path), section), "\n") * "\n")
        rm.(entry_files(dir))
        return
    end

    function check()
        mktempdir() do tmp
            changelog_copy = joinpath(tmp, "CHANGELOG.md")
            dir_copy = joinpath(tmp, "changelog")
            cp(CHANGELOG_PATH, changelog_copy)
            cp(ENTRY_DIR, dir_copy)
            release!(v"999.0.0"; changelog_path = changelog_copy, dir = dir_copy)
            isempty(entry_files(dir_copy)) || error("Entry files were not removed after release.")
            println("Changelog entries are valid. Release section preview:\n")
            released = readlines(changelog_copy)
            next_section = findnext(startswith("## "), released, findfirst(startswith("## "), released) + 1)
            println(join(released[1:(something(next_section, length(released) + 1) - 1)], "\n"))
        end
        return
    end

    function check_pr(pr::Int, added_files)
        expected = "changelog/$pr.md"
        foreign = filter(f -> f != expected && basename(f) ∉ NON_ENTRY_FILES, added_files)
        isempty(foreign) ||
            error("This PR adds changelog files not named after its number $pr: $(join(foreign, ", ")). Rename them to `$expected`.")
        isfile(joinpath(ROOT, expected)) ||
            error("Missing `$expected`. Add it with one or more `- ` entries, or apply the `skip-changelog` label.")
        return check()
    end

    function main(args)
        if length(args) == 1 && args[1] == "check"
            check()
        elseif length(args) >= 2 && args[1] == "check-pr"
            check_pr(parse(Int, args[2]), args[3:end])
        else
            error("Usage: julia changelog.jl check | check-pr <PR number> [added changelog files...]")
        end
        return
    end

end

if abspath(PROGRAM_FILE) == @__FILE__
    Changelog.main(ARGS)
end
