"""
Returns a set of all sub-expressions in an expression that look like \$some_expression
"""
function find_node_expressions(obj::Expr)
    node_expressions = Set()
    if is_interpolated_observable(obj)
        push!(node_expressions, obj)
    else
        for a in obj.args
            node_expressions = union(node_expressions, find_node_expressions(a))
        end
    end
    node_expressions
end

# empty dict if x is not an Expr
find_node_expressions(x) = Set()

is_interpolated_observable(x) = false
function is_interpolated_observable(e::Expr)
    e.head == Symbol(:$) && length(e.args) == 1
end

"""
Replaces every subexpression that looks like a node expression with a substitute symbol stored in `exprdict`.
"""
function replace_observable_expressions!(exp::Expr, exprdict)
    if is_interpolated_observable(exp)
        error("You can't @lift an expression that only consists of a single node.")
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
Replaces an expression with lift(argtuple -> expression, args...), where args
are all expressions inside the main one that begin with \$.

# Example:

x = Observable(rand(100))
y = Observable(rand(100))

## before
z = lift((x, y) -> x .+ y, x, y)

## after
z = @lift(\$x .+ \$y)

You can also use parentheses around an expression if that expression evaluates to a node.

```julia
nt = (x = Observable(1), y = Observable(2))
@lift(\$(nt.x) + \$(nt.y))
```
"""
macro lift(exp)

    node_expr_set = find_node_expressions(exp)

    if length(node_expr_set) == 0
        error("Did not find any interpolated observables. Use '\$(observable)' to interpolate it into the macro.")
    end

    # store expressions with their substitute symbols, gensym them manually to be
    # able to escape the expression later
    node_expr_arg_dict = Dict(expr => gensym("arg$i") for (i, expr) in enumerate(node_expr_set))

    replace_observable_expressions!(exp, node_expr_arg_dict)

    # keep an array for ordering
    node_expressions_array = collect(keys(node_expr_arg_dict))
    node_substitutes_array = [node_expr_arg_dict[expr] for expr in node_expressions_array]
    node_expressions_without_dollar = [n.args[1] for n in node_expressions_array]

    # the arguments to the lifted function
    argtuple = Expr(Symbol(:tuple), node_substitutes_array...)

    # the lifted function itself
    function_expression = Expr(Symbol(:->), argtuple, exp)

    # the full expression
    lift_expression = Expr(
        Symbol(:call),
        Symbol(:lift),
        esc(function_expression),
        esc.(node_expressions_without_dollar)...
    )

    lift_expression
end
