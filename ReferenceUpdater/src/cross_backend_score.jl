# Avoid loading all of ReferenceTests with its heavy dependencies
using Colors, FileIO, Statistics
import FFMPEG_jll

const RGBf = RGB{Float32}
const RGBAf = RGBA{Float32}

include("../../ReferenceTests/src/compare_media.jl")
include("../../ReferenceTests/src/cross_backend_scores.jl")

function compare_selection(root_path, files)
    file2score = Dict{String, Float64}()
    for filename in files
        to_check = joinpath(root_path, "recorded", normpath(filename))
        ref_file = replace(filename, r"(GLMakie|CairoMakie|WGLMakie)/" => "GLMakie/")
        reference = joinpath(root_path, "recorded", normpath(ref_file))
        if isfile(to_check) && isfile(reference)
            file2score[filename] = compare_media(to_check, reference)
        else
            file2score[filename] = -1.0
        end
    end
    return file2score
end
