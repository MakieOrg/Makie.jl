
using MacroTools, Reactive


"""
Extract a default for `func` + `attribute`.
If the attribute is in kw_args that will be selected.]
Else will search in scene.Theme.func for `attribute` and if not found there it will
search one level higher (scene.Theme).
"""
function find_default(scene, kw_args, func, attribute)
    if haskey(kw_args, attribute)
        return kw_args[attribute]
    end
    if haskey(scene, :Theme)
        if haskey(scene, :Theme, Symbol(func), attribute)
            return scene[:Theme, Symbol(func), attribute]
        elseif haskey(scene, :Theme, attribute)
            return scene[:Theme, attribute]
        else
            error("Theme doesn't contain a default for $attribute. Please provide $attribute for $func")
        end
    else
        error("Scene doesn't contain a theme and therefore doesn't provide any defaults.
            Please provide attribute $attribute for $func")
    end
end

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
        $tmpvar = Signal(find_default($scene_sym, $kw_sym, $(QuoteNode(func)), $var_sym))
        $(esc(var)) = map(convert_f, $(args...))
        $dictsym[$var_sym] = $(esc(var))
    end
end

function process_body_element(elem, var, f, args, fargs, mainfunc, dictsym, result = [])

    expr = if isa(elem, Expr) && elem.head == :macrocall &&
            length(elem.args) == 3 && elem.args[1].head == :core &&
            elem.args[1].args[1] == Symbol("@doc")
        push!(docs, elem.args[2])
        elem.args[3]
    else
        elem
    end

    # xor blocks
    if isa(expr, Expr) && expr.head == :call && expr.args[1] == :xor
        args = args[2:end]
        quote
            kw_keys = keys(kw_args)
            if kw_keys in Akeys
            elseif kw_keys in Bkeys
            else
                # Use first defined
                $A
            end
        end
    end
    found = @capture(expr,
        (var_ = f_(args__)) |
        (var_ = args__::f_)
    )
    if found
        push!(result, convert_expr(var, f, args, fargs[1], fargs[2], mainfunc, dictsym))
    else
        push!(result, expr)
    end

end

"""
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
If it's not found in kw_args, it will search in scene.Theme.sprites for `:attribute` and if not found there it will
search one level higher (scene.Theme).
This can be manually achieved by calling: `find_default(scene, kw_args, func, :attribute)`.

The same will be done for attribute2, which also demonstrate that you can reference previously defined attributes and that you can
use as many inputs to convert_function as you want.
You can optionally define a doc string for an attribute like this:
    ```julia
        """
        Attribute 1 is great
        """
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
    for elem in body

    end
    expr = quote
        function $mainfunc($(fargs...))
            $dictsym = Dict{Symbol, Any}()
            $(result...)
            return $dictsym
        end
    end
    println(expr)
    expr
end


@default function sprites(scene, kw_args)


end

macro test(x)
    nice_dump(x)
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


@test(
    xor(
        color = to_color(color),
        begin
            colormap = to_colormap(colormap)
            colornorm = to_colornorm(colornorm, positions)
            intensity = to_intensity(intensity)
        end, begin
            println("test")
        end
    )
)
