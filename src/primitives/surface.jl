is_unitrange(x) = (false, 0:0)
is_unitrange(x::Range) = (true, x)
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

function ngrid(x::AbstractVector, y::AbstractVector)
    xgrid = [Float32(x[i]) for i = 1:length(x), j = 1:length(y)]
    ygrid = [Float32(y[j]) for i = 1:length(x), j = 1:length(y)]
    xgrid, ygrid
end

function nan_extrema(array)
    mini, maxi = (Inf, -Inf)
    for elem in array
        isnan(elem) && continue
        mini = min(mini, elem)
        maxi = max(maxi, elem)
    end
    Vec2f0(mini, maxi)
end

to_colornorm(norm, intensity) = Vec2f0(norm)
function to_colornorm(norm::Void, intensity)
    nan_extrema(intensity)
end
to_intensity(x::AbstractArray) = x

to_surface(x::Range) = x
to_surface(x) = Float32.(x)

function surface_2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    xy = []

    for (k, v) in kw_args
        k in (:z,) && continue
        if k in (:x, :y)
            push!(xy, v)
            continue
        end
        if k == :colornorm
            k = :color_norm
        end
        if k == :colormap
            k = :color_map
        end
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = true
    result[:model] = eye(Mat4f0)
    x, y = xy
    x_is_ur, xrange = is_unitrange(to_value(x))
    y_is_ur, yrange = is_unitrange(to_value(y))
    main = to_signal(kw_args[:z])
    if x_is_ur && y_is_ur
        result[:ranges] = (x, y)
    else
        if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
            main = to_signal.((x, y, main))
        elseif isa(x, AbstractVector) || isa(y, AbstractVector)
            xy = to_signal(lift_node(x, y) do x, y
                ngrid(x, y)
            end)
            main = (map(first, xy), map(last, xy), main)
        else
            error("surface: combination of types not supported: $(typeof(x)) $(typeof(y)) $(typeof(z))")
        end
    end
    result, main
end

@default function surface(scene, kw_args)
    x = to_surface(x)
    y = to_surface(y)
    z = to_surface(z)
    xor(
        begin # Colormap is first, so it will default to it
            colormap = to_colormap(colormap)
            # convert function should only have one argument right now, so we create this closure
            colornorm = ((colornorm) -> to_colornorm(colornorm, z))(colornorm)
        end,
        begin
            color = to_color(color)
        end
    )
end

function surface(x, y, z::AbstractMatrix{T}; kw_args...) where T <: AbstractFloat
    scene = get_global_scene()
    attributes = expand_kwargs(kw_args)
    attributes[:x] = x
    attributes[:y] = y
    attributes[:z] = z
    attributes = surface_defaults(scene, attributes)
    gl_data, main = surface_2glvisualize(attributes)
    viz = visualize(main, Style(:surface), gl_data).children[]
    insert_scene!(scene, :surface, viz, attributes)
end

function surface(x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function; kw_args...) where {T1, T2}
    T = Base.Core.Inference.return_type(f, (T1, T2))# TODO, i heard this is bad?!
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    surface(x, y, z; kw_args...)
end

function surface(x::AbstractMatrix{T1}, y::AbstractMatrix{T2}, f::Function; kw_args...) where {T1, T2}
    if size(x) != size(y)
        error("x and y don't have the same size. Found: x: $(size(x)), y: $(size(y))")
    end
    z = f.(x, y)
    surface(x, y, z; kw_args...)
end
