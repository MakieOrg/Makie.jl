"""
Returns a set of all sub-expressions in an expression that look like \$some_expression
"""
function find_observable_expressions(obj::Expr)
    observable_expressions = Set()
    if is_interpolated_observable(obj)
        push!(observable_expressions, obj)
    else
        for a in obj.args
            observable_expressions = union(observable_expressions, find_observable_expressions(a))
        end
    end
    return observable_expressions
end

# empty dict if x is not an Expr
find_observable_expressions(x) = Set()

is_interpolated_observable(x) = false
function is_interpolated_observable(e::Expr)
    return e.head == Symbol(:$) && length(e.args) == 1
end

"""
Replaces every subexpression that looks like a observable expression with a substitute symbol stored in `exprdict`.
"""
function replace_observable_expressions!(exp::Expr, exprdict)
    if is_interpolated_observable(exp)
        error("You can't @lift an expression that only consists of a single observable.")
    else
        for (i, arg) in enumerate(exp.args)
            if is_interpolated_observable(arg)
                exp.args[i] = exprdict[arg]
            else
                replace_observable_expressions!(arg, exprdict)
            end
        end
    end
    return exp
end

replace_observable_expressions!(x, exprdict) = nothing

"""
Replaces an expression with `lift(argtuple -> expression, args...)`, where `args`
are all expressions inside the main one that begin with \$.

# Example:

```julia
x = Observable(rand(100))
y = Observable(rand(100))
```

## before
```julia
z = lift((x, y) -> x .+ y, x, y)
```

## after
```julia
z = @lift(\$x .+ \$y)
```

You can also use parentheses around an expression if that expression evaluates to an observable.

```julia
nt = (x = Observable(1), y = Observable(2))
@lift(\$(nt.x) + \$(nt.y))
```
"""
macro lift(exp)

    observable_expr_set = find_observable_expressions(exp)

    if length(observable_expr_set) == 0
        error("Did not find any interpolated observables. Use '\$(observable)' to interpolate it into the macro.")
    end

    # store expressions with their substitute symbols, gensym them manually to be
    # able to escape the expression later
    observable_expr_arg_dict = Dict(expr => gensym("arg$i") for (i, expr) in enumerate(observable_expr_set))

    replace_observable_expressions!(exp, observable_expr_arg_dict)

    # keep an array for ordering
    observable_expressions_array = collect(keys(observable_expr_arg_dict))
    observable_substitutes_array = [observable_expr_arg_dict[expr] for expr in observable_expressions_array]
    observable_expressions_without_dollar = [n.args[1] for n in observable_expressions_array]

    # the arguments to the lifted function
    argtuple = Expr(Symbol(:tuple), observable_substitutes_array...)

    # the lifted function itself
    function_expression = Expr(Symbol(:->), argtuple, exp)

    # the full expression
    lift_expression = Expr(
        Symbol(:call),
        Symbol(:lift),
        esc(function_expression),
        esc.(observable_expressions_without_dollar)...
    )

    return lift_expression
end
