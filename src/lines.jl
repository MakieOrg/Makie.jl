

function AbstractPlotting.convert_attribute(x, ::Nothing, key1, key2)
    convert_attribute(x, key1, key2)
end

function AbstractPlotting.convert_attribute(x::AbstractVector, ::Nothing, ::key"linewidth", key2)
    return x[1:2:(length(x) - 1)]
end

topoint(x::AbstractVector{Point{N, Float32}}) where N = x

# GRRR STUPID SubArray, with eltype different from getindex(x, 1)
topoint(x::SubArray) = topoint([el for el in x])

function topoint(x::AbstractArray{<: Point{N, T}}) where {T, N}
    topoint(Point{N, Float32}.(x))
end
function topoint(x::AbstractArray{<: Tuple{P, P}}) where P <: Point
    topoint(reinterpret(P, x))
end

function create_shader(scene::Scene, plot::LineSegments)
    # Potentially per instance attributes
    positions = lift(topoint, plot[1])
    startr = lift(p-> 1:2:(length(p)-1), positions)
    endr = lift(p-> 2:2:length(p), positions)
    p_start_end = lift(positions) do positions
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
    debug_shader("linesegments", program.program)
    mesh.name = string(objectid(plot))
    jsscene.add(mesh)
end

function draw_js(jsctx, jsscene, mscene::Scene, plot::Lines)
    @extract plot (color, linewidth, model, transformation)
    positions = plot[1]
    colors_converted = lift(x-> to_color(x), color)
    mesh = jslines!(jsctx, jsscene, plot, positions, colors_converted, linewidth, model)
    return mesh
end

br_view(scalar, idx) = scalar
br_view(array::AbstractVector, idx) = view(array, idx)

"""
    non_nan_segments_0(vector::AbstractVector)

Returns 0 based indices for all line segments that aren't NaN
"""
non_nan_segments_0(vector::AbstractVector) = non_nan_segments_0(vector, UInt32[])
function non_nan_segments_0!(vector::AbstractVector, indices_0::Vector{UInt32})
    empty!(indices_0)
    @inbounds for i in 1:(length(vector) - 1)
        if !(isnan(vector[i]) || isnan(vector[i + 1]))
            push!(indices_0, UInt32(i - 1), UInt32(i))
        end
    end
    return indices_0
end

function jslines!(THREE, scene, plot, positions_nan, colors, linewidth, model, typ = :lines)
    geometry = THREE.new.BufferGeometry()
    opaque_color = "#000"; opacity = 1
    color_buffer = nothing
    positions_buff = Float32[]
    positions_flat = map(positions_nan) do positions
        f32 = reinterpret(Float32, positions)
        resize!(positions_buff, length(f32))
        positions_buff[:] .= f32
        return positions_buff
    end
    index_buffer = UInt32[]
    segments_ui32_0 = map(positions_nan) do positions
        non_nan_segments_0!(positions, index_buffer)
    end

    if colors[] isa Colorant
        opaque_color = "#"*hex(color(colors[]))
        opacity = alpha(colors[])
    else
        flat = flatten_buffer(colors[])
        color_buffer = THREE.new.Float32BufferAttribute(flat, 4)
        geometry.setAttribute("color", color_buffer)
    end
    material = THREE.new.LineBasicMaterial(;color=opaque_color, opacity=opacity,
                                           transparent=true)

    nd = length(eltype(positions_nan[]))
    position_buffer = THREE.new.Float32BufferAttribute(positions_flat[], nd)
    geometry.setAttribute("position", position_buffer)
    geometry.setIndex(segments_ui32_0[])

    onjs(THREE, positions_flat, js"""function (flat_positions){
        var flat = deserialize_js(flat_positions);
        var position_buffer = $(position_buffer);
        position_buffer.set(flat, 0);
        position_buffer.needsUpdate = true;
    }""")

    onjs(THREE, segments_ui32_0, js"""function (segments){
        var indices = deserialize_js(segments);
        var geometry = $(geometry);
        geometry.setIndex(indices);
        // position_buffer.needsUpdate = true;
    }""")

    geometry.computeBoundingSphere()
    mesh = THREE.new.LineSegments(geometry, material)
    mesh.matrixAutoUpdate = false;
    mesh.matrix.set(model[]...)
    scene.add(mesh)
    update_model!(mesh, plot)
    return mesh
end
