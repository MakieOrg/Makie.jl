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
include("../../ReferenceTests/src/refimage_manifest.jl")
include("manifest.jl")
include("bonito-app.jl")

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))

function __init__()
    # cleanup downloaded files when julia closes
    return atexit(wipe_cache!)
end

function print_usage()
    print(
        """
        Usage: reference_updater <pr|commit> <value>
               reference_updater manifest <pr|commit> <value>
          pr <number>               - Open the viewer for a pull request's latest CI run
          commit <sha>              - Open the viewer for a specific commit's CI run
          manifest pr <number>      - Add the PR's recorded updates to the manifest (no viewer)
          manifest commit <sha>     - Add the commit's recorded updates to the manifest

        Examples:
          reference_updater pr 123
          reference_updater manifest pr 123
        """
    )
    return
end

function source_kwargs(mode, value)
    mode == "pr" && return (; pr = parse(Int, value))
    mode == "commit" && return (; commit = value)
    return nothing
end

function (@main)(args::Vector{String})
    if length(args) < 2
        print_usage()
        return 1
    end

    if args[1] == "manifest"
        if length(args) < 3
            print_usage()
            return 1
        end
        if args[2] == "pr"
            add_pr_updates_to_manifest(parse(Int, args[3]))
        elseif args[2] == "commit"
            add_pr_updates_to_manifest(; commit = args[3])
        else
            println("`manifest` must be followed by 'pr' or 'commit'.")
            return 1
        end
        return 0
    end

    kw = source_kwargs(args[1], args[2])
    if kw === nothing
        println("First argument must be 'pr', 'commit', or 'manifest'.")
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
