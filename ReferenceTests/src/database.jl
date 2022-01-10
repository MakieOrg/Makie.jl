
struct Entry
    title::String
    source_location::LineNumberNode
    code::Expr
    func::Function
    used_functions::Set{Symbol}
end

function Entry(title, source_location, code, func)
    used_functions = Set{Symbol}()
    MacroTools.postwalk(code) do x
        if @capture(x, f_(xs__))
            push!(used_functions, Symbol(string(f)))
        end
        if @capture(x, f_(xs__) do; body__; end)
            push!(used_functions, Symbol(string(f)))
        end
        return x
    end
    return Entry(title, source_location, code, func, used_functions)
end

const DATABASE = Dict{String, Entry}()

function cell_expr(name, code, source)
    title = string(name)
    return quote
        closure = () -> $(esc(code))
        entry = ReferenceTests.Entry(
            $(title),
            $(QuoteNode(source)),
            $(QuoteNode(code)),
            closure
        )
        if haskey(ReferenceTests.DATABASE, $title)
            error("Titles must be unique for tests")
        end
        ReferenceTests.DATABASE[$title] = entry
    end
end

macro cell(name, code)
    return cell_expr(name, code, __source__)
end

"""
    save_result(path, object)

Helper, to more easily save all kind of results from the test database
"""
function save_result(path::String, scene::Makie.FigureLike)
    FileIO.save(path * ".png", scene)
end

function save_result(path::String, stream::VideoStream)
    FileIO.save(path * ".mp4", stream)
end

function save_result(path::String, object)
    FileIO.save(path, object)
end

function load_database()
    empty!(DATABASE)
    include(joinpath(@__DIR__, "tests/primitives.jl"))
    include(joinpath(@__DIR__, "tests/text.jl"))
    include(joinpath(@__DIR__, "tests/attributes.jl"))
    include(joinpath(@__DIR__, "tests/examples2d.jl"))
    include(joinpath(@__DIR__, "tests/examples3d.jl"))
    include(joinpath(@__DIR__, "tests/short_tests.jl"))
    include(joinpath(@__DIR__, "tests/unitful.jl"))
    include(joinpath(@__DIR__, "tests/dates.jl"))
    include(joinpath(@__DIR__, "tests/categorical.jl"))
    return DATABASE
end

function database_filtered(title_excludes = []; functions=[])
    database = ReferenceTests.load_database()
    return filter(database) do (name, entry)
        !(entry.title in title_excludes) &&
        !any(x-> x in entry.used_functions, functions)
    end
end
