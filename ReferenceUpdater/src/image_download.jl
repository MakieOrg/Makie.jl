function upload_release(user, repo, token, tag, path)
    return ghr_jll.ghr() do ghr_path
        run(`$ghr_path -replace -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function upload_reference_images(path = basedir("recorded"), tag = last_major_version())
    return mktempdir() do dir
        tarfile = joinpath(dir, "reference_images.tar")
        Tar.create(path, tarfile)
        upload_release("MakieOrg", "Makie.jl", github_token(), tag, tarfile)
    end
end

function download_refimages(tag = last_major_version())
    url = "https://github.com/MakieOrg/Makie.jl/releases/download/$(tag)/reference_images.tar"
    images_tar = Downloads.download(url)
    images = tempname()
    isdir(images) && rm(images, recursive = true, force = true)
    Tar.extract(images_tar, images)
    rm(images_tar)
    return images
end
