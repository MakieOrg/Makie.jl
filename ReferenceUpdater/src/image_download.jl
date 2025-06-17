function upload_release(user, repo, token, tag, path)
    return ghr_jll.ghr() do ghr_path
        run(`$ghr_path -replace -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("../Makie", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function upload_reference_images(path = basedir("recorded"), tag = last_major_version())
    return mktempdir() do dir
        tarfile = joinpath(dir, "reference_images.tar")
        Tar.create(path, tarfile)
        upload_release("MakieOrg", "Makie.jl", github_token(), string("refimages-", tag), tarfile)
    end
end

function download_progress_callback(total::Int, now::Int)
    mb = x -> round(x / 1024^2; digits = 1)
    if total > 0
        pct = round(1000 * now / total) / 10  # one decimal
        msg = "Downloading: $(pct)% ($(mb(now)) / $(mb(total)) MB)"
    else
        msg = "Downloading: $(mb(now)) MB"
    end
    return print("\r$msg\e[K")
end

function download_refimages(tag = last_major_version())
    url = "https://github.com/MakieOrg/Makie.jl/releases/download/refimages-$(tag)/reference_images.tar"

    images_tar = Downloads.download(url; progress = download_progress_callback)
    images = tempname()
    isdir(images) && rm(images, recursive = true, force = true)
    Tar.extract(images_tar, images)
    rm(images_tar)
    return images
end
