using Documenter#, Makie
cd(Pkg.dir("Makie", "docs"))



function test()
    """
    ```Julia
    using Makie

    scene = Scene(resolution = (500, 500))
    @ref A = rand(32, 32) # if uploaded to the GPU, it will be shared on the GPU

    surface(@ref A) # refer to exactly the same a in wireframe and surface plot
    wireframe((@ref A) .+ 0.5) # offsets A on the GPU based on the same data

    for i = 1:10
        # updates A - resulting in an animation of the surface and offsetted wireframe plot
        @ref A[:, :] = rand(32, 32)
    end
    ```
    """
end



makedocs(
    #modules = [Makie],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = ["Home" => "index.md"]
)
#
# ENV["TRAVIS_BRANCH"] = "latest"
# ENV["TRAVIS_PULL_REQUEST"] = "false"
# ENV["TRAVIS_REPO_SLUG"] = "github.com/SimonDanisch/MakieDocs.git"
# ENV["TRAVIS_TAG"] = "tag"
# ENV["TRAVIS_OS_NAME"] = "linux"
# ENV["TRAVIS_JULIA_VERSION"] = "0.6"
#
# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
#     repo   = "github.com/SimonDanisch/MakieDocs.git",
#     julia  = "0.6",
#     target = "build",
#     osname = "linux",
#     make = nothing
# )
