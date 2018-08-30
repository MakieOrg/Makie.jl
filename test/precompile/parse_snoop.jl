path = joinpath(@__DIR__, "precompile.csv")


result = String[]
open(path) do io
    for line in eachline(io)
        push!(result, split(line, '\t')[2][2:end-1])
    end
end


expressions = parse.(result)

using MacroTools
findmod2(v::Vector, mods = Set()) = (foreach(x-> findmod2(x, mods), v); mods)
function findmod2(expr, mods = Set())
    if @capture(expr, Type_{args__})
        findmod2(args, mods)
        findmod2(Type, mods)
    elseif @capture(expr, call_(args__) | (args__,) | Tuple{args__})
        findmod2(args, mods)
    elseif @capture(expr, getfield(Mod_, sym_))
        if isa(Mod, Symbol)
            push!(mods, Mod)
        else
            findmod2(Mod, mods)
        end
    elseif @capture(expr, Mod_.field_)
        if isa(Mod, Symbol)
            push!(mods, Mod)
        else
            findmod2(Mod, mods)
        end
    end
    mods
end


modules = findmod2(expressions)

:Pkg in names(Base)


open(joinpath(dirname(path), "precompie.jl"), "w") do io
    inbuilds = (:Logging, :Base, :Core, :Pkg, :Main, :Test)
    add_mods = filter(x-> !(x in inbuilds), modules)
    println(io, "Pkg.pkg\"add $(join(add_mods, " "))\"") # make sure packages are added
    println(io, "using $(join(modules, ", "))")
    for elem in expressions
        if @capture(elem, Tuple{f_, args__})
            println(io, "try")
            if isempty(args)
                println(io, "precompile($f, ())")
            else
                println(io, "precompile($f, ($(join(args, ", ")),))")
            end
            println(io, "catch; end")
        end
    end
end
