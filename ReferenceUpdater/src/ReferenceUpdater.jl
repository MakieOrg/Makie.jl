module ReferenceUpdater

import ghr_jll
import Tar
import Downloads
import HTTP
import JSON3
import ZipFile
import REPL
import TOML

include("local_server.jl")
include("image_download.jl")

basedir(files...) = normpath(joinpath(@__DIR__, "..", files...))

end