
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


function surface(b::makie, x, y, z::AbstractMatrix{T}, attributes::Dict) where T <: AbstractFloat
    scene = get_global_scene()
    attributes[:x] = x
    attributes[:y] = y
    attributes[:z] = z
    attributes = surface_defaults(b, scene, attributes)
    gl_data, main = surface_2glvisualize(attributes)
    viz = visualize(main, Style(:surface), gl_data).children[]
    insert_scene!(scene, :surface, viz, attributes)
end


function surface(::makie, x::AbstractMatrix{T1}, y::AbstractMatrix{T2}, f::Function, attributes::Dict) where {T1, T2}
    if size(x) != size(y)
        error("x and y don't have the same size. Found: x: $(size(x)), y: $(size(y))")
    end
    z = f.(x, y)
    surface(x, y, z, attributes::Dict)
end
