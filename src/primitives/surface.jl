is_unitrange(x) = false, 0:0
is_unitrange(x::UnitRange) = true, 0:0
function is_unitrange(x::AbstractVector)
    length(x) < 2 && return false, 0:0
    diff = x[2] - x[1]
    length(x) < 3 && return true, x[1]:x[2]
    last = x[3]
    for elem in drop(x, 3)
        diff2 = elem - last
        diff2 != diff && return false, 0:0
    end
    return true, range(first(x), diff, length(x))
end


function surface(x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function, kw_args) where T1, T2
    T = Base.Core.Inference.return_type(f, (T1, T2))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    surface(x, y, z, kw_args)
end
function surface(x::AbstractMatrix{T1}, y::AbstractMatrix{T2}, f::Function, kw_args) where T1, T2
    if size(x) != size(y)
        error("x and y don't have the same size. Found: x: $(size(x)), y: $(size(y))")
    end
    T = Base.Core.Inference.return_type(f, (T1, T2))
    z = f.(x, y)
    surface(x, y, z, kw_args)
end


function surface_attributes(kw_args)


end


function _extract_surface(d::Plots.Surface)
    d.surf
end
function _extract_surface(d::AbstractArray)
    d
end

# TODO when to transpose??
function extract_surface(d)
    map(_extract_surface, (d[:x], d[:y], d[:z]))
end
function topoints{P}(::Type{P}, array)
    [P(x) for x in zip(array...)]
end
function extract_points(d)
    dim = is3d(d) ? 3 : 2
    array = (d[:x], d[:y], d[:z])[1:dim]
    topoints(Point{dim, Float32}, array)
end

function surface(x, y, z::AbstractMatrix{T}, kw_args) where T <: AbstractFloat
    x_is_ur, xrange = is_unitrange(x)
    y_is_ur, yrange = is_unitrange(x)
    if x_is_ur && y_is_ur
        kw_args[:ranges] = (xrange, yrange)
    else
        if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
            main = map(s->map(Float32, s), (x, y, z))
        elseif isa(x, AbstractVector) || isa(y, AbstractVector)
            x = Float32[x[i] for i = 1:size(z,1), j = 1:size(z,2)]
            y = Float32[y[j] for i = 1:size(z,1), j = 1:size(z,2)]
            main = (x, y, map(Float32, z))
        else
            error("surface: combination of types not supported: $(typeof(x)) $(typeof(y)) $(typeof(z))")
        end
        if get(kw_args, :wireframe, false)
            return wireframe(x, y, z, kw_args)
        end
    end
    return visualize(main, Style(:surface), kw_args)
end
