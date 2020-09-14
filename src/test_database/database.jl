
const DATABASE = []
const UNIQUE_DATABASE_NAMES = Set(Symbol[])

function unique_name!(name, unique_names=UNIQUE_DATABASE_NAMES)
    funcname = Symbol(replace(lowercase(string(name)), r"[ #$!@#$%^&*()+]" => '_'))
    while isdefined(AbstractPlotting, funcname) || (funcname in unique_names)
        name = string(funcname)
        m = match(r"(.*)_(\d+)$", name)
        if m !== nothing
            name, num = m[1], parse(Int, m[2]) + 1
        else
            num = 1
        end
        funcname = Symbol("$(name)_$(num)")
    end
    push!(unique_names, funcname)
    funcname
end


function cell_expr(name, code)
    unique_title = unique_name!(title)
    return quote
        closure = () -> $(code)
        push!(AbstractPlotting.DATABASE, $(title) => closure)
    end
end

macro cell(name, code)
    return cell_expr(name, code)
end

macro cell(code)
    return cell_expr("no name", code)
end

function eval_examples(func)
    for (name, f) in DATABASE
        func(name, f())
    end
end
    
"""
    record_examples(folder = ""; resolution = (500, 500), resume = false)

Records all examples in the database. If error happen, you can fix them and
start record with `resume = true`, to start at the last example that errored.
"""
function record_examples(
        folder="";
        resolution=(500, 500), resume::Union{Bool,Integer}=false,
        display=false,
    )

    function output_path(entry, ending)
        joinpath(folder, "tmp", string(entry.unique_name, ending))
    end
    ispath(folder) || mkpath(folder)
    ispath(joinpath(folder, "tmp")) || mkdir(joinpath(folder, "tmp"))
    result = []
    set_theme!()
    inline!(true)
    eval_examples() do unique_name, value
        try
            subfolder = joinpath(folder, string(unique_name))
            ispath(subfolder) || mkpath(subfolder)
            save_media(example, value, subfolder)
            push!(result, subfolder)
            set_theme!()
            inline!(true)
        catch e
            @warn "Error thrown when evaluating $(unique_name)" exception = CapturedException(e, Base.catch_backtrace())
        end
    end
end
