using Pkg
pkg"activate --temp"
pkg"add HTTP JSON3"

using HTTP
using JSON3
using Dates

repo = ENV["GITHUB_REPOSITORY"]
retention_days = 14

pr_previews = map(filter(startswith("PR"), readdir("previews"))) do dir
    parse(Int, match(r"PR(\d*)", dir)[1])
end

prs = JSON3.read(HTTP.get("https://api.github.com/repos/$repo/pulls").body)
open_within_threshold = map(x -> x.number, filter(prs) do pr
    time = DateTime(pr.updated_at[1:19], ISODateTimeFormat)
    return pr.state == "open" && Dates.days(now() - time) <= retention_days
end)

stale_previews = setdiff(pr_previews, open)

if isempty(stale_previews)
    @info "No stale previews"
    exit(1)
end

for pr in stale_previews
    path = joinpath("previews", "PR$pr")
    @info "Removing $path"
    rm(path, recursive = true)
end