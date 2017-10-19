function heatmap(x, y, z, kw_args)
    get!(kw_args, :color_norm, Vec2f0(ignorenan_extrema(z)))
    get!(kw_args, :color_map, Plots.make_gradient(cgrad()))
    delete!(kw_args, :intensity)
    I = GLVisualize.Intensity{Float32}
    heatmap = I[z[j,i] for i=1:size(z, 2), j=1:size(z, 1)]
    tex = GLAbstraction.Texture(heatmap, minfilter=:nearest)
    kw_args[:stroke_width] = 0f0
    kw_args[:levels] = 1f0
    visualize(tex, Style(:default), kw_args)
end

"""
"xy" or "yx"
"""
function to_spatial_order(b, x)
    if !(x in ("yx", "xy"))
        error("Spatial order must be \"yx\" or \"xy\". Found: $x")
    end
    x
end

"""
:xy or :yx
"""
to_spatial_order(b, x::Symbol) = to_spatial_order(b, string(x))

"""
`Tuple{<: Number, <: Number}`
"""
function to_interval(b, x)
    if isa(x, Tuple{<: Number, <: Number})
        return x
    else
        error("Not an accepted value for interval. Please have a look at the documentation for to_interval")
    end
end

"""
Pair{<: Number, <: Number} e.g. 2 => 100
"""
to_interval(b, x::Pair{<: Number, <: Number}) = to_interval(b, (x...,))

"""
`AbstractVector` will be interpreted as an interval from minimum to maximum
"""
to_interval(b, x::AbstractVector) = to_interval(b, (minimum(x), maximum(y)))

@default function image(b, scene, kw_args)
    spatialorder = to_spatial_order(spatialorder)
    x = to_interval(x)
    y = to_interval(y)
    image = to_image(image)
end

function image2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    result[:primitive] = to_signal(lift_node(getindex.(attributes, (:x, :y, :spatialorder))...) do x, y, so
        if so != "xy"
            y, x = x, y
        end
        xmin, ymin = minimum(x), minimum(y)
        xmax, ymax = maximum(x), maximum(y)
        SimpleRectangle{Float32}(xmin, ymin, xmax - xmin, ymax - ymin)
    end)
    result[:spatialorder] = to_value(attributes[:spatialorder])
    result
end

function image(b::makie, x, y, img, attributes::Dict)
    scene = get_global_scene()
    attributes[:x] = x
    attributes[:y] = y
    attributes[:image] = img
    attributes = image_defaults(b, scene, attributes)
    gl_data = image2glvisualize(attributes)
    viz = visualize(to_signal(attributes[:image]), Style(:default), gl_data).children[]
    insert_scene!(scene, :image, viz, attributes)
end
