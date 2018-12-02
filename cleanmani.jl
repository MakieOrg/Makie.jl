using Pkg
using Pkg.TOML
cd(@__DIR__)
mani = TOML.parsefile("Manifest.toml")

deps = mani["CairoMakie"][1]["deps"]

function get_all_deps(name, result = Dict{String, Any}())
    pkg = mani[name][1]
    println(name)
    result[name] = [pkg]
    if haskey(pkg, "deps")
        deps = pkg["deps"]
        for dep in deps
            if !haskey(result, dep)
                get_all_deps(dep, result)
            end
        end
    end
    result
end
deps = get_all_deps("CairoMakie")
@which TOML.parsefile("")
parser = TOML.Parser(IOBuffer())
@which TOML.parse(parser)

function print_toml(path, dict)
    open(path, "w") do io
        for name in keys(dict)
            println(io, "[[$name]]")
            pkg = dict[name][1]
            for (k, v) in pkg
                println(io, k, " = ", repr(v))
            end
            println(io)
            println(io)
        end
    end
end
print_toml("Manifest.toml", deps)
