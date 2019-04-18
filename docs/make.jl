using Documenter, WGLMakie

makedocs(;
    modules=[WGLMakie],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/SimonDanisch/WGLMakie.jl/blob/{commit}{path}#L{line}",
    sitename="WGLMakie.jl",
    authors="Simon Danisch",
    assets=[],
)

deploydocs(;
    repo="github.com/SimonDanisch/WGLMakie.jl",
)
