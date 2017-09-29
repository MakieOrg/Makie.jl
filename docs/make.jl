using Documenter, MakiE

makedocs(
    modules = [MakiE],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "referencing.md",
            "axis.md",
            "labels.md",
            "output.md",
            "reflection.md",
            "layout.md"
        ],
    ]
)

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo   = "github.com/SimonDanisch/MakiE.jl.git",
    julia  = "0.6",
    target = "build",
    osname = "linux",
    make = nothing
)
