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

end
