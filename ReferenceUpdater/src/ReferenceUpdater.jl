module ReferenceUpdater

import ghr_jll
import Tar
import Downloads
import HTTP
import JSON3
import ZipFile
import REPL
import TOML

function github_token()
    get(ENV, "GITHUB_TOKEN") do
        try
            readchomp(`gh auth token`)
        catch
            error("""Could not find github authorization token, ENV["GITHUB_TOKEN"] is not defined and `gh auth token` failed as a fallback.""")
        end
    end
end

include("local_server.jl")
include("image_download.jl")

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))

end