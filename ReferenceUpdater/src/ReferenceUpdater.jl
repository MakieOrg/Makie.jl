module ReferenceUpdater

import ghr_jll
import Tar
import Downloads
import HTTP
import JSON3
import ZipFile
import REPL
import TOML
using Dates

function github_token()
    return get(ENV, "GITHUB_TOKEN") do
        try
            readchomp(`gh auth token`)
        catch
            error("""Could not find github authorization token, ENV["GITHUB_TOKEN"] is not defined and `gh auth token` failed as a fallback.""")
        end
    end
end

include("image_download.jl")
include("artifact-download.jl")
include("bonito-app.jl")

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))

function __init__()
    # cleanup downloaded files when julia closes
    return atexit(wipe_cache!)
end

function (@main)(args::Vector{String})
    if length(args) < 2
        println("Usage: reference_updater <pr|commit> <value>")
        println("  pr <number>      - Update references using pull request's latest CI run")
        println("  commit <sha>     - Update references using a specific commit's CI run")
        println()
        println("Examples:")
        println("  reference_updater pr 123")
        println("  reference_updater commit abc123")
        return 1
    end

    mode = args[1]
    value = args[2]

    if mode == "pr"
        kw = (; pr = parse(Int, value))
    elseif mode == "commit"
        kw = (; commit = value)
    else
        println("First argument must be 'pr' or 'commit'")
        println("Run without arguments to see usage.")
        return 1
    end

    app = serve_update_page(; kw...)
    display(app)
    Bonito.wait_for_ready(app)
    println("Bonito app started successfully. Close the browser tab to quit.")
    Bonito.wait_for(() -> Bonito.isclosed(app.session[]); timeout = 10000)
    println("Bonito app was closed.")

    return 0
end

end
