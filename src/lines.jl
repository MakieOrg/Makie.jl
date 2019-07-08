

function AbstractPlotting.convert_attribute(x, ::Nothing, key1, key2)
    convert_attribute(x, key1, key2)
end

function AbstractPlotting.convert_attribute(x::AbstractVector, ::Nothing, ::key"linewidth", key2)
    return x[1:2:(length(x) - 1)]
end

function create_shader(scene::Scene, plot::LineSegments)
    # Potentially per instance attributes
    positions = plot[1]
    startr = lift(p-> 1:2:(length(p)-1), positions)
    endr = lift(p-> 2:2:length(p), positions)
    p_start_end = lift(plot[1]) do positions
        return (positions[startr[]], positions[endr[]])
    end

    per_instance = Dict{Symbol, Any}(
        :segment_start => Buffer(lift(first, p_start_end)),
        :segment_end => Buffer(lift(last, p_start_end)),
    )
    uniforms = Dict{Symbol, Any}()
    for k in (:linewidth, :color)
        attribute = lift(x-> convert_attribute(x, Key{k}(), key"scatter"()), plot[k])
        if isscalar(attribute)
            uniforms[k] = attribute
            uniforms[Symbol("$(k)_start")] = attribute
            uniforms[Symbol("$(k)_end")] = attribute
        else
            per_instance[Symbol("$(k)_start")] = Buffer(lift(x-> x[startr[]], attribute))
            per_instance[Symbol("$(k)_end")] = Buffer(lift(x-> x[endr[]], attribute))
        end
    end
    uniforms[:resolution] = scene.camera.resolution
    prim = GLUVMesh2D(
        vertices = Vec2f0[(0, -1), (0, 1), (1, -1), (1, 1)],
        texturecoordinates = UV{Float32}[(0,0), (0,0), (0,0), (0,0)],
        faces = GLTriangle[(1, 2, 3), (2, 4, 3)]
    )
    instance = VertexArray(prim)
    return InstancedProgram(
        WebGL(),
        lasset("line_segments.vert"),
        lasset("line_segments.frag"),
        instance,
        VertexArray(; per_instance...)
        ; uniforms...
    )
end

function draw_js(jsctx, jsscene, mscene::Scene, plot::LineSegments)
    program = create_shader(mscene, plot)
    mesh = wgl_convert(mscene, jsctx, program)
    update_model!(mesh, plot)
    write(joinpath(@__DIR__, "..", "debug", "linesegments.vert"), program.program.vertex_source)
    write(joinpath(@__DIR__, "..", "debug", "linesegments.frag"), program.program.fragment_source)
    mesh.name = "LineSegments"
    jsscene.add(mesh)
end

function draw_js(jsctx, jsscene, mscene::Scene, plot::Lines)
    @get_attribute plot (color, linewidth, model, transformation)
    positions = plot[1][]
    mesh = jslines!(jsctx, jsscene, plot, positions, color, linewidth, model)
    return mesh
end


function set_positions!(jsctx, geometry, positions::AbstractVector{<: Point{N, T}}) where {N, T}
    flat = reinterpret(T, positions)
    geometry.addAttribute(
        "position", jsctx.THREE.new.Float32BufferAttribute(flat, N)
    )
end

function set_colors!(jsctx, geometry, colors::AbstractVector{T}) where T <: Colorant
    flat = reinterpret(eltype(T), colors)
    geometry.addAttribute(
        "color", jsctx.THREE.new.Float32BufferAttribute(flat, length(T))
    )
end



function material!(jsctx, geometry, colors::AbstractVector)
    material = jsctx.THREE.new.LineBasicMaterial(
        vertexColors = jsctx.THREE.VertexColors, transparent = true
    )
    set_colors!(jsctx, geometry, colors)
    return material
end

function material!(jsctx, geometry, color::Colorant)
    material = jsctx.THREE.new.LineBasicMaterial(
        color = "#"*hex(RGB(color)),
        opacity = alpha(color),
        transparent = true
    )
    return material
end

br_view(scalar, idx) = scalar
br_view(array::AbstractVector, idx) = view(array, idx)

function split_at_nan(f, vector::AbstractVector{T}, colors) where T
    nan_idx = 1
    while true
        last_idx = findnext(x-> !isnan(x), vector, nan_idx)
        last_idx === nothing && break
        nan_idx = findnext(x-> isnan(x), vector, last_idx)
        nan_idx === nothing && (nan_idx = length(vector) + 1)
        range = last_idx:(nan_idx - 1)
        f(view(vector, range), br_view(colors, range))
    end
end

function jslines!(jsctx, scene, plot, positions_nan, colors, linewidth, model, typ = :lines)
    mesh = nothing
    split_at_nan(positions_nan, colors) do positions, colors
        geometry = jsctx.THREE.new.BufferGeometry()
        material = material!(jsctx, geometry, colors)
        material.linewidth = linewidth
        set_positions!(jsctx, geometry, positions)
        Typ = typ === :lines ? jsctx.THREE.new.Line : jsctx.THREE.new.LineSegments
        mesh = Typ(geometry, material)
        mesh.matrixAutoUpdate = false;
        mesh.matrix.set(model...)
        scene.add(mesh)
        update_model!(mesh, plot)
    end
    return mesh
end
