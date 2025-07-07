all_lines = collect(eachline(joinpath(@__DIR__, "..", "CHANGELOG.md")))
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
