using Documenter, WGLMakie, JSServe

makedocs(; modules=[WGLMakie], format=Documenter.HTML(), pages=["Home" => "index.md"],
         repo="https://github.com/JuliaPlots/WGLMakie.jl/blob/{commit}{path}#L{line}",
         sitename="WGLMakie.jl", authors="Simon Danisch")

deploydocs(; repo="github.com/JuliaPlots/WGLMakie.jl", push_preview=true)
