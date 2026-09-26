using Pluto
notebook_path = joinpath(@__DIR__, "scenes.jl")
isfile(notebook_path)

options = Pluto.Configuration.from_flat_kwargs(; project=@__DIR__)
s = Pluto.ServerSession()
nb = Pluto.SessionActions.open(s, notebook_path; run_async=false)

open(joinpath(@__DIR__, "tutorials", "scenes.md"), "w") do io
    for (i, c) in enumerate(nb.cells)
        if startswith(c.code, "md\"\"\"")
            md = join(split(c.code, "\n")[2:end-1], "\n")
            println(io, md)
        else
            println(io, """
                       \\begin{examplefigure}{}
                        ```julia
                        """)
            println(io, c.code)
            println(io, """
                        ```
                        \\end{examplefigure}
                        """)
        end
    end
end
