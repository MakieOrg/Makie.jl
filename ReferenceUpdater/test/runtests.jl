using Test

include(joinpath(@__DIR__, "..", "..", "ReferenceTests", "src", "refimage_manifest.jl"))
include(joinpath(@__DIR__, "..", "src", "manifest.jl"))

function make_reference_tree(dir, files)
    for (path, bytes) in files
        full = joinpath(dir, path)
        mkpath(dirname(full))
        write(full, bytes)
    end
    return dir
end

@testset "manifest read/write/classify" begin
    mktempdir() do dir
        refdir = make_reference_tree(
            joinpath(dir, "ref"), [
                "CairoMakie/tooltip.png" => "old-cairo",
                "GLMakie/tooltip.png" => "old-gl",
            ]
        )
        h = reference_hash(joinpath(refdir, "CairoMakie/tooltip.png"))

        mpath = joinpath(dir, "manifest.txt")
        write_manifest(
            [
                RefimageUpdate("CairoMakie/tooltip.png", h),
                RefimageUpdate("GLMakie/tooltip.png", "deadbeef"),
                RefimageUpdate("CairoMakie/brandnew.png", "new"),
                RefimageUpdate("WGLMakie/gone.png", "delete"),
            ], mpath
        )

        entries = read_manifest(mpath)
        @test length(entries) == 4

        c = classify_entries(entries, refdir)
        @test c.exempt_changed == Set(["CairoMakie/tooltip.png"])
        @test c.exempt_new == Set(["CairoMakie/brandnew.png"])
        @test isempty(c.to_delete)
        @test Set(e.path for e in c.inert) == Set(["GLMakie/tooltip.png", "WGLMakie/gone.png"])

        @test Set(e.path for e in prune_inert(entries, refdir)) ==
            Set(["CairoMakie/tooltip.png", "CairoMakie/brandnew.png"])
    end
end

@testset "add_manifest_selection" begin
    mktempdir() do dir
        refdir = make_reference_tree(
            joinpath(dir, "ref"), [
                "CairoMakie/a.png" => "a-bytes",
                "GLMakie/stale.png" => "stale-bytes",
            ]
        )
        mpath = joinpath(dir, "manifest.txt")

        write_manifest([RefimageUpdate("GLMakie/stale.png", "wronghash")], mpath)
        add_manifest_selection(["CairoMakie/a.png"], ["GLMakie/dropme.png"], refdir; manifest_path = mpath)

        entries = read_manifest(mpath)
        by_path = Dict(e.path => e.pin for e in entries)
        @test !haskey(by_path, "GLMakie/stale.png")               # inert entry pruned
        @test by_path["CairoMakie/a.png"] == reference_hash(joinpath(refdir, "CairoMakie/a.png"))
        @test by_path["GLMakie/dropme.png"] == "delete"
    end
end

@testset "manifest_candidates" begin
    mktempdir() do dir
        write(joinpath(dir, "scores.tsv"), "0.9\tCairoMakie/big.png\n0.001\tGLMakie/tiny.png\n")
        write(joinpath(dir, "new_files.txt"), "WGLMakie/fresh.png\n")

        auto = manifest_candidates(dir, :auto; threshold = 0.05, backends = ("GLMakie", "CairoMakie", "WGLMakie"))
        @test auto == ["CairoMakie/big.png", "WGLMakie/fresh.png"]

        only_gl = manifest_candidates(dir, :auto; threshold = 0.0005, backends = ("GLMakie",))
        @test only_gl == ["GLMakie/tiny.png"]

        explicit = manifest_candidates(dir, ["CairoMakie/x.png"]; threshold = 0.05, backends = ("CairoMakie",))
        @test explicit == ["CairoMakie/x.png"]
    end
end

@testset "approval_coverage" begin
    mktempdir() do dir
        refdir = make_reference_tree(
            joinpath(dir, "reference"), [
                "CairoMakie/changed.png" => "ref-changed",
                "GLMakie/unapproved.png" => "ref-unapproved",
            ]
        )
        write(joinpath(dir, "scores.tsv"), "0.9\tCairoMakie/changed.png\n0.8\tGLMakie/unapproved.png\n")
        write(joinpath(dir, "new_files.txt"), "WGLMakie/newthing.png\n")

        h = reference_hash(joinpath(refdir, "CairoMakie/changed.png"))
        write_manifest(
            [
                RefimageUpdate("CairoMakie/changed.png", h),
                RefimageUpdate("WGLMakie/newthing.png", "new"),
            ], joinpath(dir, "refimage_updates.txt")
        )

        cov = approval_coverage(dir; threshold = 0.05, reference_folder = refdir)
        @test cov.n_changed == 3                 # changed + unapproved + new
        @test cov.n_approved == 2                 # changed + new, not unapproved
    end
end
