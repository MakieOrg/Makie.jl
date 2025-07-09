# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "Makie", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function download_refimages(tag = last_major_version())
    url = "https://github.com/MakieOrg/Makie.jl/releases/download/refimages-$(tag)/reference_images.tar"
    images_tar = basedir("reference_images.tar")
    images = basedir("reference_images")
    if isfile(images_tar)
        if Bool(parse(Int, get(ENV, "REUSE_IMAGES_TAR", "0")))
            @info "$images_tar already exists, skipping download as requested"
        else
            rm(images_tar)
        end
    end
    !isfile(images_tar) && download(url, images_tar)
    isdir(images) && rm(images, recursive = true, force = true)
    Tar.extract(images_tar, images)
    return images
end
