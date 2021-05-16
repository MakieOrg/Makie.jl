# Artifact generator for the assets directory.

using Pkg.Artifacts
using URIs

version = v"0.1.0"
host = "https://github.com/JuliaPlots/AbstractPlotting.jl/releases/download"

build_path = joinpath(@__DIR__, "build")

ispath(build_path) && rm(build_path, force=true, recursive=true)
mkpath(build_path)

product_hash = create_artifact() do artifact_dir
    cp(joinpath(@__DIR__, "assets"), artifact_dir; force = true)
end

archive_filename = "assets-$version.tar.gz"
artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
download_hash = archive_artifact(product_hash, joinpath(build_path, archive_filename))

bind_artifact!(
    artifact_toml,
    "assets",
    product_hash,
    force = true,
    download_info = Tuple[
        (
            "$host/assets-$(escapeuri(string(version)))/$archive_filename",
            download_hash,
        ),
    ],
)
