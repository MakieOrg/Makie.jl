using Documenter, MakiE

makedocs(
    modules = [MakiE],
    format = :html,
    sitename = "Plotting in pure Julia",
    pages = [
        "Home" => "index.md",
        "Basics" => [
            "functions.md",
            "extending.md",
            "referencing.md",
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

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-cinder"),
    repo   = "github.com/SimonDanisch/MakiE.jl.git",
    julia  = "0.6",
    target = "build",
    osname = "linux",
    make = nothing
)
