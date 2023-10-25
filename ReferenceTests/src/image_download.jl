# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v$(version.major).$(version.minor)"
end

function download_refimages(
    tag=last_major_version();
    dir=normpath(joinpath(@__DIR__, "..", "refimages")),
    subdir="refimages"
)
    url = "https://github.com/MakieOrg/MakieReferenceImages/tarball/$(tag)"
    name = "refimages_$tag"
    images_tar = normpath(joinpath(@__DIR__, "..", "$(name).tar.gz"))
    if isfile(images_tar)
        if Bool(parse(Int, get(ENV, "REUSE_IMAGES_TAR", "0")))
            @info "$images_tar already exists, skipping download as requested"
        else
            rm(images_tar)
        end
    end
    !isfile(images_tar) && download(url, images_tar)
    isdir(dir) && rm(dir, recursive=true, force=true)
    mktempdir() do path
        Tar.extract(`gzcat $images_tar`, path)
        dirs = filter(x -> x ∉ [".", ".."] && isdir(x), readdir(path, join = true))
        if length(dirs) != 1
            error("Expected exactly one directory in extracted reference image tarball from github, got $dirs")
        end
        mv(only(dirs), dir)
    end
    return joinpath(dir, subdir)
end
