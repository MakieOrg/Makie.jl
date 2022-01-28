using Test
using CairoMakie
using Pkg
path = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))

Pkg.develop(url = "https://github.com/jkrumbiegel/GitHubActionsUtils.jl/")
using GitHubActionsUtils
@assert haskey(ENV, "GITHUB_TOKEN")

# Before changing Pkg environment, try the test in #864
@testset "Runs without error" begin
    fig = Figure()
    scatter(fig[1, 1], rand(10))
    fn = tempname()*".png"
    try
        save(fn, fig)
    finally
        rm(fn)
    end
end

using ReferenceTests
using ReferenceTests: database_filtered

CairoMakie.activate!(type = "png")

excludes = Set([
    "Colored Mesh",
    "Line GIF",
    "Streamplot animation",
    "Line changing colour",
    "Axis + Surface",
    "Streamplot 3D",
    "Meshscatter Function",
    "Hollow pie chart",
    "Record Video",
    "Image on Geometry (Earth)",
    "Comparing contours, image, surfaces and heatmaps",
    "Textured Mesh",
    "Simple pie chart",
    "Animated surface and wireframe",
    "Open pie chart",
    "image scatter",
    "surface + contour3d",
    "Orthographic Camera",
    "Legend",
    "rotation",
    "3D Contour with 2D contour slices",
    "Surface with image",
    "Test heatmap + image overlap",
    "Text Annotation",
    "step-2",
    "FEM polygon 2D.png",
    "Text rotation",
    "Image on Surface Sphere",
    "FEM mesh 2D",
    "Hbox",
    "Stars",
    "Subscenes",
    "Arrows 3D",
    "Layouting",
    # sigh this is actually super close,
    # but doesn't interpolate the values inside the
    # triangles, so looks pretty different
    "FEM polygon 2D",
    "Connected Sphere",
    # markers too big, close otherwise, needs to be assimilated with glmakie
    "Unicode Marker",
    "Depth Shift",
    "Order Independent Transparency",
    "heatmap transparent colormap"
])

functions = [:volume, :volume!, :uv_mesh]
database = database_filtered(excludes, functions=functions)

tempd = mktempdir()
recorded_dir = joinpath(tempd, "recorded")
# rm(recorded; force=true, recursive=true);
mkdir(recorded_dir)

ReferenceTests.record_tests(database, recording_dir=recorded_dir)

refimage_dir = ReferenceTests.download_refimages()
missing_files, scores = ReferenceTests.compare(
    joinpath.(recording_folder, readdir(recording_folder)),
    refimage_dir
)

# copy reference images outside of Makie folder which will get cleaned
cp(refimage_dir, joinpath(tempd, "refimages"))

score_cutoff = 0.03
bad_scores = filter(x -> x[2] > score_cutoff, scores)



if GitHubActionsUtils.is_pull_request()

    # cd out of CairoMakie test folder into main repo folder
    cd("../..")

    pr_number = GitHubActionsUtils.pull_request_number()

    image_branch_name = "pr$(pr_number)-test-images"

    GitHubActionsUtils.set_github_actions_bot_as_git_user()

    run(`git clean -f -d`)

    GitHubActionsUtils.switch_to_or_create_branch(image_branch_name; orphan = true)
    
    run(`git rm -rf .`)

    cp(refimage_dir, "refimages")
    cp(recorded_dir, "recorded")

    run(`git add -A`)
    run(`git commit -m "save testimages"`)

    GitHubActionsUtils.push_git_branch(image_branch_name)

    commit_hash = chomp(read(`git rev-parse HEAD`, String))

    function image_url(parts...)
        string(
            "https://raw.githubusercontent.com/",
            GitHubActionsUtils.repository(),
            "/",
            commit_hash,
            "/",
            joinpath(parts...)
        )
    end

    function comparison_markdown(filename, score)
        """
        <details>
        <summary>$filename Score: $score</summary>

        | Recorded | Reference |
        |--|--|
        | ![]($(image_url("recorded", filename))) | ![]($(image_url("refimages", filename))) |
        
        <details>
        """
    end

    GitHubActionsUtils.comment_on_pr(
        pr_number,
        """
        # Test images with high error scores:

        $(join([comparison_markdown(bs[1], bs[2]) for bs in bad_scores], "\n\n"))
        """
    )
end