include(joinpath(@__DIR__, "..", "tooling", "changelog.jl"))

unreleased_lines = Changelog.unreleased_lines()
changelog_lines = readlines(Changelog.CHANGELOG_PATH)
all_lines = if isempty(unreleased_lines)
    changelog_lines
else
    Changelog.insert_section(changelog_lines, ["## Unreleased"; ""; unreleased_lines])
end
links = Dict{String, String}()
kept_lines = filter(all_lines) do line
    islink = match(r"\[(Unreleased|\d+\.\d+\.\d+)\]: http.*", line) !== nothing
    if islink
        placeholder, url = split(line, ": ", limit = 2)
        links[placeholder] = url
    end
    return !islink
end
open(joinpath(@__DIR__, "src", "changelog.md"), "w") do io
    for line in kept_lines
        println(
            io, replace(
                line, r"## \[(Unreleased|\d+\.\d+\.\d+)\]" => function (str)
                    url = links[str[4:end]]
                    return "$str($url)"
                end
            )
        )
    end
end
