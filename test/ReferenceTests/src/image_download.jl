
function upload_release(user, repo, token, tag, path)
    ghr() do ghr_path
        run(`$ghr_path -replace -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "..", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function upload_reference_images(path=basedir("recorded"), tag=last_major_version())
    mktempdir() do dir
        tarfile = joinpath(dir, "refimages.tar")
        Tar.create(path, tarfile)
        upload_release("JuliaPlots", "AbstractPlotting.jl", ENV["GITHUB_TOKEN"], tag, tarfile)
    end
end

function download_refimages(tag=last_major_version())
    url = "https://github.com/JuliaPlots/AbstractPlotting.jl/releases/download/$(tag)/refimages.tar"
    images_tar = basedir("refimages.tar")
    images = basedir("refimages")
    isfile(images_tar) && rm(images_tar)
    isdir(images) && rm(images, recursive=true, force=true)
    Base.download(url, images_tar)
    Tar.extract(images_tar, images)
    return images
end


# rm(joinpath(@__DIR__, "refimages"), force=true, recursive=true)

#
# using Pkg.TOML
