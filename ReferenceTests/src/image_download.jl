# Well, to be more precise, last non patch
function last_major_version()
    path = basedir("..", "Makie", "Project.toml")
    version = VersionNumber(TOML.parse(String(read(path)))["version"])
    return "v" * string(VersionNumber(version.major, version.minor))
end

function download_refimages(tag = last_major_version())
    # CI starts from an empty depot, so caching would only add an unauthenticated API request
    get(ENV, "CI", "false") == "true" || return cached_refimages(tag)
    images = basedir("reference_images")
    rm(images; force = true, recursive = true)
    return fetch_refimages!(images, tag)
end
