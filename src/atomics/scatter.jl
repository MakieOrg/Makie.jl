using GeometryTypes, StaticArrays, Colors, GLAbstraction



"""
Hack to quickly make things more consistent inside MakiE, without
changing GLVisualize too much! So we need to rewrite the attributes, the names and the
values a bit!
"""
function expand_for_glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:marker, :positions, :x, :y, :z) && continue
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
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = false
    result[:model] = eye(Mat4f0)
    result
end


function _scatter(b, kw_args)
    scene = get_global_scene()
    attributes = scatter_defaults(b, scene, kw_args)
    gl_data = expand_for_glvisualize(attributes)
    shape = to_signal(attributes[:marker])
    main = (shape, to_signal(attributes[:positions]))
    viz = GLVisualize.sprites(main, Style(:default), gl_data)
    viz = GLVisualize.assemble_shader(viz).children[]
    insert_scene!(scene, :scatter, viz, attributes)
end

function mesh2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:marker, :positions, :x, :y, :z, :rotations) && continue
        # if k == :rotations
        #     k = :rotation
        # end
        if k == :markersize
            k = :scale
        end
        if k == :positions
            k = :position
        end
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = true
    result[:model] = eye(Mat4f0)
    result
end

function _meshscatter(b, kw_args)
    scene = get_global_scene()
    attributes = meshscatter_defaults(b, scene, kw_args)
    gl_data = mesh2glvisualize(attributes)
    shape = to_signal(attributes[:marker])
    main = (shape, to_signal(attributes[:positions]))
    viz = GLVisualize.meshparticle(main, Style(:default), gl_data)
    viz = GLVisualize.assemble_shader(viz).children[]
    insert_scene!(scene, :scatter, viz, attributes)
end

for arg in ((:x, :y), (:x, :y, :z), (:positions,))
    insert_expr = map(arg) do elem
        :(attributes[$(QuoteNode(elem))] = $elem)
    end
    @eval begin
        function scatter(b::makie, $(arg...), attributes::Dict)
            $(insert_expr...)
            _scatter(b, attributes)
        end
        @eval begin
            function meshscatter(b::makie, $(arg...), attributes::Dict)
                $(insert_expr...)
                _meshscatter(b, attributes)
            end
        end
    end
end
