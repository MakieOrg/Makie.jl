using GeometryTypes, StaticArrays, Colors, GLAbstraction

"""
Hack to quickly make things more consistent inside Makie, without
changing GLVisualize too much! So we need to rewrite the attributes, the names and the
values a bit!
"""
function expand_for_glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:marker, :positions, always_skip...) && continue

        if k == :rotations
            k = :rotation
            v = Vec4f0(0, 0, 0, 1)
            result[:billboard] = true
        end
        if k == :markersize
            k = :scale
        end
        if k == :glowwidth
            k = :glow_width
        end
        if k == :glowcolor
            k = :glow_color
        end
        if k == :strokewidth
            k = :stroke_width
        end
        if k == :strokecolor
            k = :stroke_color
        end
        if k == :positions
            k = :position
        end
        if k == :colormap
            k = :color_map
        end
        if k == :colornorm
            k = :color_norm
        end
        result[k] = to_signal(v)
    end
    result[:fxaa] = false
    result
end


# function scatter()
#     marker
#     strokecolor
#     strokewidth
#     glowcolor
#     glowwidth
#     markersize
#     rotations
#     if haskey(scene, :positions)
#         positions = to_positions(positions)
#     elseif haskey(scene, :z)
#         xyz = getindex.(scene, (:x, :y, :z))
#         positions = to_positions(xyz)
#     elseif haskey(scene, :y)
#         xy = getindex.(scene, (:x, :y, :z))
#         positions = to_positions(xy)
#     end
#     begin
#         color = to_color(color)
#     end
#     begin
#         colormap = to_colormap(colormap)
#         intensity = to_intensity(intensity)
#         colornorm = to_colornorm(colornorm, intensity)
#     end
# end
#
function _scatter(scene, kw_args)
    attributes = scatter_defaults(scene, kw_args)
    gl_data = expand_for_glvisualize(attributes)
    shape = to_signal(attributes[:marker])
    main = (shape, to_signal(attributes[:positions]))
    viz = visualize(main, Style(:default), gl_data)
    insert_scene!(scene, :scatter, viz, attributes)
end

function mesh2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:marker, :positions, always_skip...) && continue
        if k == :rotations
            k = :rotation
        end
        if k == :markersize
            k = :scale
        end
        if k == :positions
            k = :position
        end
        if k == :colormap
            k = :color_map
        end
        if k == :colornorm
            k = :color_norm
        end
        result[k] = to_signal(v)
    end
    result[:fxaa] = true
    result
end

function _meshscatter(scene, kw_args)
    attributes = meshscatter_defaults(scene, kw_args)
    gl_data = mesh2glvisualize(attributes)
    shape = to_signal(attributes[:marker])
    main = (shape, to_signal(attributes[:positions]))
    viz = GLVisualize.meshparticle(main, Style(:default), gl_data)
    viz = GLVisualize.assemble_shader(viz).children[]
    insert_scene!(scene, :meshscatter, viz, attributes)
end

for arg in ((:x, :y), (:x, :y, :z), (:positions,))
    insert_expr = map(arg) do elem
        :(attributes[$(QuoteNode(elem))] = $elem)
    end
    @eval begin
        function scatter(scene::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _scatter(scene, attributes)
        end
        @eval begin
            function meshscatter(scene::makie, $(arg...), attributes::Dict)
                $(insert_expr...)
                _meshscatter(scene, attributes)
            end
        end
    end
end
