using Test

include(joinpath(@__DIR__, "..", "..", "ReferenceTests", "src", "refimage_manifest.jl"))
include(joinpath(@__DIR__, "..", "..", "ReferenceTests", "src", "runtests.jl"))
include(joinpath(@__DIR__, "..", "src", "manifest.jl"))

function make_reference_tree(dir, files)
    for (path, bytes) in files
        full = joinpath(dir, path)
        mkpath(dirname(full))
        write(full, bytes)
    end
    return dir
end

@testset "fragment read/write/classify/prune" begin
    mktempdir() do dir
        refdir = make_reference_tree(
            joinpath(dir, "ref"), [
                "CairoMakie/tooltip.png" => "old-cairo",
                "GLMakie/tooltip.png" => "old-gl",
            ]
        )
        h = reference_hash(joinpath(refdir, "CairoMakie/tooltip.png"))

        mdir = joinpath(dir, "refimage_updates")
        write_manifest(
            [
                RefimageUpdate("CairoMakie/tooltip.png", h),
                RefimageUpdate("GLMakie/tooltip.png", "deadbeef"),
                RefimageUpdate("CairoMakie/brandnew.png", "new"),
                RefimageUpdate("WGLMakie/gone.png", "delete"),
            ], mdir
        )

        # one fragment file per image, at its mirrored path -> no shared file between images
        @test isfile(joinpath(mdir, "CairoMakie", "tooltip.png.pin"))
        @test isfile(joinpath(mdir, "GLMakie", "tooltip.png.pin"))
        @test read(joinpath(mdir, "CairoMakie", "tooltip.png.pin"), String) |> strip == h

        entries = read_manifest(mdir)
        @test length(entries) == 4

        c = classify_entries(entries, refdir)
        @test c.exempt_changed == Set(["CairoMakie/tooltip.png"])
        @test c.exempt_new == Set(["CairoMakie/brandnew.png"])
        @test isempty(c.to_delete)
        @test Set(e.path for e in c.inert) == Set(["GLMakie/tooltip.png", "WGLMakie/gone.png"])

        prune_inert!(refdir, mdir)
        @test Set(e.path for e in read_manifest(mdir)) ==
            Set(["CairoMakie/tooltip.png", "CairoMakie/brandnew.png"])
        @test !isfile(joinpath(mdir, "GLMakie", "tooltip.png.pin"))   # inert file deleted
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
        mdir = joinpath(dir, "refimage_updates")

        write_manifest([RefimageUpdate("GLMakie/stale.png", "wronghash")], mdir)
        add_manifest_selection(["CairoMakie/a.png"], ["GLMakie/dropme.png"], refdir; manifest_dir = mdir)

        by_path = Dict(e.path => e.pin for e in read_manifest(mdir))
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

@testset "recording_title" begin
    @test recording_title(joinpath("GLMakie", "Standard deviation band.png")) == "Standard deviation band"
    @test recording_title(joinpath("WGLMakie", "Menu search", "step-1.png")) == "Menu search"
    @test recording_title(joinpath("CairoMakie", "Record Video.mp4")) == "Record Video"
end

@testset "split_missing_recordings" begin
    attempted = ["errored", "recorded", "stepper"]
    recorded = [joinpath("GLMakie", "recorded.png"), joinpath("GLMakie", "stepper", "step-1.png")]
    reference = [
        joinpath("GLMakie", "recorded.png"), joinpath("GLMakie", "stepper", "step-1.png"),
        joinpath("GLMakie", "errored.png"), joinpath("GLMakie", "deleted.png"),
        joinpath("GLMakie", "excluded.png"),
    ]
    skipped = [joinpath("GLMakie", "excluded.png")]

    result = split_missing_recordings(attempted, recorded, reference, skipped)
    @test result.failed == ["errored"]
    @test result.missing_recordings == [joinpath("GLMakie", "deleted.png")]
end

@testset "review_pin_state" begin
    pinned = Set(["CairoMakie/pinned.png"])
    @test review_pin_state("CairoMakie/pinned.png", 0.9, pinned; threshold = 0.05) == :pinned
    @test review_pin_state("CairoMakie/pinned.png", 0.0, pinned; threshold = 0.05) == :pinned
    @test review_pin_state("GLMakie/changed.png", 0.9, pinned; threshold = 0.05) == :unpinned
    @test review_pin_state("GLMakie/same.png", 0.0, pinned; threshold = 0.05) == :unchanged
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
            ], joinpath(dir, "refimage_updates")
        )

        cov = approval_coverage(dir; threshold = 0.05, reference_folder = refdir)
        @test cov.n_changed == 3                 # changed + unapproved + new
        @test cov.n_approved == 2                 # changed + new, not unapproved
    end
end
