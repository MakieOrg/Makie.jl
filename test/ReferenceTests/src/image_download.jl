
using ghr_jll
using Tar
using Downloads

function upload_release(user, repo, token, tag, path)
    ghr() do ghr_path
        run(`$ghr_path -delete -u $(user) -r $(repo) -t $(token) $(tag) $(path)`)
    end
end

function create_new_refimage_release(path, tag="v0.7.0")
    mktempdir() do dir
        tarfile = joinpath(dir, "refimages.tar")
        Tar.create(path, tarfile)
        upload_release("JuliaPlots", "MakieReferenceImages", ENV["GITHUB_TOKEN"], tag, tarfile)
    end
end

create_new_refimage_release(recording_dir)

url = "https://github.com/JuliaPlots/MakieReferenceImages/releases/download/v0.7.0/refimages.tar"

Downloads.download(url, joinpath(@__DIR__, "refimages.tar"))

rm(joinpath(@__DIR__, "refimages"), force=true, recursive=true)

Tar.extract(joinpath(@__DIR__, "refimages.tar"), joinpath(@__DIR__, "refimages"))
