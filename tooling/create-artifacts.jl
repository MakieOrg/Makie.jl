using Pkg.Artifacts
using Tar, CodecZlib, SHA
using ghr_jll
using LibGit2

function get_github_user_repo(path::AbstractString = pwd())
    repo = LibGit2.GitRepo(path)
    url = LibGit2.getconfig(repo, "remote.origin.url", "")
    # Match GitHub URL formats: https://github.com/user/repo.git or git@github.com:user/repo.git
    m = match(r"github\.com[:/](.+?)/(.+?)(\.git)?$", url)
    m === nothing && error("Could not extract GitHub user/repo from remote URL: $url")
    return m.captures[1], m.captures[2], url
end

function upload_release(tag, path)
    token = ENV["GITHUB_TOKEN"]
    user, repo, url = get_github_user_repo()
    ghr_jll.ghr() do ghr_path
        run(`$ghr_path -replace -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
    replace
    return "https://github.com/$(user)/$(repo)/releases/download/$(tag)/$(basename(path))"
end

function create_tar_gz(source_dir::AbstractString, output_path::AbstractString)
    return open(GzipCompressorStream, output_path, "w") do io
        Tar.create(source_dir, io)
    end
end

function sha256sum(path::AbstractString)
    return open(path, "r") do io
        bytes2hex(sha256(io))
    end
end

function upload_artifact(folder, name, tag, repo)
    artifact_hash = create_artifact() do artifact_path
        cp(folder, artifact_path; force = true)
    end
    @info "Created artifact $(name) with hash $(artifact_hash)"
    targz = abspath("$(name).tar.gz")
    create_tar_gz(folder, targz)
    sha256 = sha256sum(targz)

    @info "Created tar.gz archive for $(name)"
    return cd(repo) do
        artifact_url = upload_release(tag, targz)
        bind_artifact!(
            "Artifact.toml",
            name, artifact_hash;
            download_info = [(artifact_url, sha256)],
            force = true
        )
    end
end

artifact_dir = "./MakieAssets"
# WARNING: Need to manually set the release to not be the latest release!
upload_artifact(artifact_dir, "MakieAssets", "asssets-0.1", "./dev/Makie/")
