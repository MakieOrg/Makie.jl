function upload_release(user, repo, token, tag, path)
    ghr_jll.ghr() do ghr_path
        run(`$ghr_path -replace -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function upload_reference_images(path=basedir("recorded"), tag=last_major_version(); name="refimages")
    mktempdir() do dir
        tarfile = joinpath(dir, "$(name).tar")
        Tar.create(path, tarfile)
        upload_release("MakieOrg", "Makie.jl", ENV["GITHUB_TOKEN"], tag, tarfile)
    end
end
