using MacroTools, Reactive

function convert_expr(var, f, args, scene_sym, kw_sym, func, dictsym)
    tmpvar = gensym()
    args = map(args) do arg
        if arg == var
            return tmpvar
        else
            esc(var)
        end
    end
    var_sym = QuoteNode(var)
    quote
        $tmpvar = to_signal(find_default($scene_sym, $kw_sym, $(QuoteNode(func)), $var_sym))
        $(esc(var)) = map($f, $(args...))
        $dictsym[$var_sym] = $(esc(var))
    end
end

function process_body_element(elem, fargs, mainfunc, dictsym, kwarg_keys)
    docs = []; symbols = []
    if isa(elem, Expr) && elem.head == :kw
        var, call = elem.args
        @capture(call,
            f_(args__) |
            args__::f_
        ) || error("Use a call or type assert on right hand side")

        expr = convert_expr(var, f, args, fargs[1], fargs[2], mainfunc, dictsym)
        return expr, [var], []
    end
    if isa(elem, Expr) && elem.head == :block
        syms = Symbol[]
        docs = []
        result = Expr(:block)
        for arg in elem.args
            expr, _syms, _docs = process_body_element(arg, fargs, mainfunc, dictsym, kwarg_keys)
            push!(result.args, expr)
            append!(syms, _syms)
            append!(docs, _docs)
        end
        return result, syms, docs
    end
    # If is documented
    if isa(elem, Expr) && elem.head == :macrocall &&
            length(elem.args) == 3 && elem.args[1].head == :core &&
            elem.args[1].args[1] == Symbol("@doc")
        push!(docs, elem.args[2])
        # the expression that is documented
        return process_body_element(elem.args[3], fargs, mainfunc, dictsym, kwarg_keys)
    end
    # exclusive blocks
    if isa(elem, Expr) && elem.head == :call && elem.args[1] == :xor
        xor_expr = Expr(:block)
        first_expr = Expr(:block)
        current_expr = xor_expr
        for (i, arg) in enumerate(elem.args[2:end])
            expression, syms, docs = process_body_element(arg, fargs, mainfunc, dictsym, kwarg_keys)
            if i == 1
                first_expr = expression
                # since a xor block defaults to first definition, we don't actually
                # need to check for it's args and create an if - since it will land
                # in the last else block anyways
                continue
            end
            condition = :(any(x-> x in $kwarg_keys, $syms))
            else_expr = Expr(:block)
            ifelse = Expr(:if, condition, expression, else_expr)
            push!(current_expr.args, ifelse)
            current_expr = else_expr # now we need to insert into else
        end
        # defaults to first block in the last else block
        current_expr.args = first_expr.args
        return xor_expr, Symbol[], docs
    end
    found = @capture(elem,
        (var_ = f_(args__)) |
        (var_ = args__::f_)
    )
    result = if found
        push!(symbols, var)
        convert_expr(var, f, args, fargs[1], fargs[2], mainfunc, dictsym)
    else
        elem
    end
    return result, symbols, docs
end


"""
    `@default function name(args...) end`

Macro that allows for concise default creations.
From this expression:

    ```julia
        @default function sprites(scene, kw_args)
            attribute = convert_function(attribute)
            attribute2 = convert_function2(attribute, attribute2)
        end
    ```

It creates a function `sprites(scene, kw_args)::Dict{Symbol, Any}`

Which will first look in kw_args for `:attribute`, if found it will call `convert_function(kw_args[:attribute])`
and insert it in the returned attribute dictionary.
If it's not found in kw_args, it will search in scene.theme.sprites for `:attribute` and if not found there it will
search one level higher (scene.theme).
This can be manually achieved by calling: `find_default(scene, kw_args, func, :attribute)`.

The same will be done for attribute2, which also demonstrate that you can reference previously defined attributes and that you can
use as many inputs to convert_function as you want.
You can optionally define a doc string for an attribute like this:
    ```julia
        Attribute 1 is great
        attribute = convert_fun(attribute)
    ```
If you don't define any doc string, it will default to the doc string of the convert function.

For attributes that don't need a complex convert function, you can simply use a type
assert:
    ```Julia
        attribute = attribute::Float32
        # will become
        attribute = convert(Float32, find_default(scene, kw_args, sprites, :attribute))
    ```
"""
macro default(func)
    @capture(func,
        function mainfunc_(fargs__)
            body__
        end
    ) || error("Please use @default with a function declaration, e.g.
        @default function myfunc(args...)
            ...
        end
    ")

    length(fargs) == 2 || error("Function should only have to arguments, namely scene and kw_args. Found: $fargs")
    docs = []
    result = []
    dictsym = gensym(:attributes)
    kwarg_keys = gensym(:keys)
    for elem in body
        expr, syms, docs = process_body_element(elem, fargs, mainfunc, dictsym, kwarg_keys)
        push!(result, expr)
    end
    expr = quote
        function $(esc(mainfunc))($(fargs...))
            $dictsym = Dict{Symbol, Any}()
            $kwarg_keys = keys($dictsym)
            $(result...)
            return $dictsym
        end
    end
    expr
end




nice_dump(x, intent = 0) = (print("    "^intent); show(x); println())
function nice_dump(x::Expr, intent = 0)
    Base.is_linenumber(x) && return
    println("    "^intent, "head: ", x.head)
    intent += 1
    for elem in x.args
        nice_dump(elem, intent)
    end
end


"""
Billboard attribute to always have a primitive face the camera.
Can be used for rotation.
"""
immutable Billboard end
