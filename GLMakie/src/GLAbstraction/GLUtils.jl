function print_with_lines(out::IO, text::AbstractString)
    io = IOBuffer()
    for (i, line) in enumerate(split(text, "\n"))
        println(io, @sprintf("%-4d: %s", i, line))
    end
    return write(out, take!(io))
end
print_with_lines(text::AbstractString) = print_with_lines(stdout, text)

"""
Needed to match the lazy gl_convert exceptions.
    `Target`: targeted OpenGL type
    `x`: the variable that gets matched
"""
matches_target(::Type{Target}, x::T) where {Target, T} = applicable(gl_convert, nothing, Target, x) || T <: Target  # it can be either converted to Target, or it's already the target
matches_target(::Type{Target}, x::Observable{T}) where {Target, T} = applicable(gl_convert, nothing, Target, x)  || T <: Target
matches_target(::Function, x) = true
matches_target(::Function, x::Nothing) = false

signal_convert(T1, y::T2) where {T2 <: Observable} = lift(convert, Observable(T1), y)


"""
Takes a dict and inserts defaults, if not already available.
The variables are made accessible in local scope, so things like this are possible:
gen_defaults! dict begin
    a = 55
    b = a * 2 # variables, like a, will get made visible in local scope
    c::JuliaType = X # `c` needs to be of type JuliaType. `c` will be made available with it's original type and then converted to JuliaType when inserted into `dict`
    d = x => GLType # OpenGL convert target. Gets only applied if `x` is convertible to GLType. Will only be converted when passed to RenderObject
    d = x => \"doc string\"
    d = x => (GLType, \"doc string and gl target\")
end
"""
macro gen_defaults!(dict, args)
    args.head === :block || error("second argument needs to be a block of form
    begin
        a = 55
        b = a * 2 # variables, like a, will get made visible in local scope
        c::JuliaType = X # c needs to be of type JuliaType. c will be made available with it's original type and then converted to JuliaType when inserted into data
        d = x => GLType # OpenGL convert target. Gets only applied if x is convertible to GLType. Will only be converted when passed to RenderObject
    end")
    tuple_list = args.args
    dictsym = gensym()
    return_expression = Expr(:block)
    push!(return_expression.args, :($dictsym = $dict)) # dict could also be an expression, so we need to assign it to a variable at the beginning
    push!(return_expression.args, :(gl_convert_targets = get!($dictsym, :gl_convert_targets, Dict{Symbol, Any}()))) # exceptions for glconvert.
    push!(return_expression.args, :(doc_strings = get!($dictsym, :doc_string, Dict{Symbol, Any}()))) # exceptions for glconvert.
    # @gen_defaults can be used multiple times, so we need to reuse gl_convert_targets if already in here
    for (i, elem) in enumerate(tuple_list)
        opengl_convert_target = :() # is optional, so first is an empty expression
        convert_target = :() # is optional, so first is an empty expression
        doc_strings = :()
        if Meta.isexpr(elem, :(=))
            key_name, value_expr = elem.args
            if isa(key_name, Expr) && key_name.head === :(::) # we need to convert to a julia type
                key_name, convert_target = key_name.args
                convert_target = :(GLAbstraction.signal_convert($convert_target, $key_name))
            else
                convert_target = :($key_name)
            end
            key_sym = Expr(:quote, key_name)
            if isa(value_expr, Expr) && value_expr.head === :call && value_expr.args[1] === :(=>)  # we might need to insert a convert target
                value_expr, target = value_expr.args[2:end]
                undecided = []
                if isa(target, Expr)
                    undecided = target.args
                else
                    push!(undecided, target)
                end
                for elem in undecided
                    isa(elem, Expr) && continue #
                    if isa(elem, AbstractString) # only docstring
                        doc_strings = :(doc_strings[$key_sym] = $elem)
                    elseif isa(elem, Symbol)
                        opengl_convert_target = quote
                            if GLAbstraction.matches_target($elem, $key_name)
                                gl_convert_targets[$key_sym] = $elem
                            end
                        end
                    end
                end
            end
            expr = quote
                $key_name = if haskey($dictsym, $key_sym)
                    $dictsym[$key_sym]
                else
                    $value_expr # in case that evaluating value_expr is expensive, we use a branch instead of get(dict, key, default)
                end
                $dictsym[$key_sym] = $convert_target
                $opengl_convert_target
                $doc_strings
            end
            push!(return_expression.args, expr)
        end
    end
    #push!(return_expression.args, :($dictsym[:gl_convert_targets] = gl_convert_targets)) #just pass the targets via the dict
    push!(return_expression.args, :($dictsym)) #return dict
    return esc(return_expression)
end
export @gen_defaults!

makesignal(@nospecialize(v)) = convert(Observable, v)

@inline const_lift(f::Union{DataType, Type, Function}, inputs...) = lift(f, map(makesignal, inputs)...)
export const_lift
