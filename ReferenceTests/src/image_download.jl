
function upload_release(user, repo, token, tag, path)
    ghr() do ghr_path
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
        upload_release("JuliaPlots", "Makie.jl", ENV["GITHUB_TOKEN"], tag, tarfile)
    end
end

function download_refimages(tag=last_major_version(); name="refimages")
    url = "https://github.com/JuliaPlots/Makie.jl/releases/download/$(tag)/$(name).tar"
    images_tar = basedir("$(name).tar")
    images = basedir(name)
    if isfile(images_tar)
        if Bool(parse(Int, get(ENV, "REUSE_IMAGES_TAR", "0")))
            @info "$images_tar already exists, skipping download as requested"
        else
            rm(images_tar)
        end
    end
    !isfile(images_tar) && download(url, images_tar)
    isdir(images) && rm(images, recursive=true, force=true)
    Tar.extract(images_tar, images)
    return images
end
