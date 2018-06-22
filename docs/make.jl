using Documenter, Makie

makedocs(
    modules = [Makie],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "scene.md",
            "conversions.md",
            "functions.md",
            "documentation.md",
            "backends.md",
            "extending.md",
            "themes.md",
            "interaction.md",
            "axis.md",
            "legends.md",
            "output.md",
            "reflection.md",
            "layout.md"
        ],
        "Developper Documentation" => [
            "devdocs.md",
        ],
    ]
)

ENV["TRAVIS_BRANCH"] = "stable"
ENV["TRAVIS_PULL_REQUEST"] = "false"
ENV["TRAVIS_REPO_SLUG"] = "github.com/JuliaPlots/Makie.jl.git"
ENV["TRAVIS_TAG"] = "v0.0.1"
ENV["TRAVIS_OS_NAME"] = "linux"
ENV["TRAVIS_JULIA_VERSION"] = "0.6"

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo   = "github.com/JuliaPlots/Makie.jl.git",
    julia  = "0.6",
    target = "build",
    osname = "linux",
    make = nothing
)
