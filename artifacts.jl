# Artifact generator for the assets directory.
#
# Requires:
#
#   - A github token stored in `ENV["GITHUB_TOKEN"]` with access to `repo` read/write.
#   - Extra packages: `ghr_jll` for release uploading.
#
# Usage:
#
#   - Update files in `/assets` directory.
#   - Bump the `version` variable below.
#   - Run `rebuild_artifacts()` to create new tarball and update Artifacts.toml.
#   - Commit & push the changes.
#   - Run `release_artifacts()` to create a new release and upload the new tarball.
# Note:
# https://discourse.julialang.org/t/git-tree-sha1-for-artifacts-toml/43879
# can make this process on windows a bit annoying
# TODO figure out if we can use ArtifactUtils or so...

using Pkg.Artifacts
using ghr_jll
using LibGit2

version = v"0.1.3"
user = "JuliaPlots"
repo = "Makie.jl"
host = "https://github.com/$user/$repo/releases/download"

build_path = joinpath(@__DIR__, "build")
assets_path = joinpath(@__DIR__, "assets")
artifact_toml = joinpath(@__DIR__, "Artifacts.toml")

function rebuild_artifacts()
    ispath(build_path) && rm(build_path, force=true, recursive=true)
    mkpath(build_path)

    product_hash = create_artifact() do artifact_dir
        cp(assets_path, artifact_dir; force = true)
    end

    archive_filename = "assets-$version.tar.gz"
    path = joinpath(build_path, archive_filename)
    download_hash = archive_artifact(product_hash, path)
    bind_artifact!(
        artifact_toml,
        "assets",
        product_hash,
        force = true,
        download_info = Tuple[
            (
                "$host/assets-$version/$archive_filename",
                download_hash,
            ),
        ],
    )
    return path
end

function release_artifacts(tar_path)
    name = "Release assets $(version)"
    commit = string(LibGit2.GitHash(LibGit2.GitCommit(LibGit2.GitRepo(@__DIR__), "HEAD")))
    token = ENV["GITHUB_TOKEN"]
    tag = "assets-$version"
    ghr() do bin
        run(`$bin -u $user -r $repo -n $name -c $commit -t $token $tag $tar_path`)
    end
end

tar_path = rebuild_artifacts()

release_artifacts(tar_path)
