using Documenter, MakiE

makedocs(
    modules = [MakiE],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "scene.md",
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

ENV["TRAVIS_BRANCH"] = "latest"
ENV["TRAVIS_PULL_REQUEST"] = "false"
ENV["TRAVIS_REPO_SLUG"] = "github.com/SimonDanisch/MakiE.jl.git"
ENV["TRAVIS_TAG"] = "tag"
ENV["TRAVIS_OS_NAME"] = "linux"
ENV["TRAVIS_JULIA_VERSION"] = "0.6"

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo   = "github.com/SimonDanisch/MakiE.jl.git",
    julia  = "0.6",
    target = "build",
    osname = "linux",
    make = nothing
)
