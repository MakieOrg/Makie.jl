nodesym(exp::Expr) = exp.args[1]

"""
Returns a set of all symbols in an expression that look like \$some_symbol
"""
function findnodesyms(obj::Expr)
    nodesymbols = Set{Symbol}()
    if isnodeexpression(obj)
        push!(nodesymbols, nodesym(obj))
    else
        for a in obj.args
            nodesymbols = union(nodesymbols, findnodesyms(a))
        end
    end
    nodesymbols
end

function findnodesyms(x)
    # empty set if x is not an Expr
    Set{Symbol}()
end

isnodeexpression(x) = false
function isnodeexpression(e::Expr)
    e.head == Symbol(:$) && length(e.args) == 1
end

"""
Replaces every subexpression that looks like a node expression with just its
symbol behind the \$.
"""
function replacenodesyms!(exp::Expr)
    if isnodeexpression(exp)
        error("You can't @lift an expression that only consists of a single node.")
    else
        for (i, arg) in enumerate(exp.args)
            if isnodeexpression(arg)
                exp.args[i] = nodesym(arg)
            else
                replacenodesyms!(arg)
            end
        end
    end
    exp
end

replacenodesyms!(x) = begin end

"""
Replaces an expression with lift(argtuple -> expression, args...), where args
are all expressions inside the main one that begin with \$.

# Example:

x = Node(rand(100))
y = Node(rand(100))

## before
z = lift((x, y) -> x .+ y, x, y)

## after
z = @lift(\$x .+ \$y)
"""
macro lift(exp)

    nodesyms = findnodesyms(exp)

    if length(nodesyms) == 0
        error("Did not find any expressions that looked like nodes.")
    end

    replacenodesyms!(exp)

    # keep an array for ordering because we need this twice
    nodesyms_array = collect(nodesyms)

    # the arguments to the lifted function
    argtuple = Expr(Symbol(:tuple), nodesyms_array...)

    # the lifted function itself
    function_expression = Expr(Symbol(:->), argtuple, exp)

    # the full expression
    lift_expression = Expr(
        Symbol(:call),
        Symbol(:lift),
        esc(function_expression),
        esc.(nodesyms_array)...
    )

    lift_expression
end
