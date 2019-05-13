

function AbstractPlotting.convert_attribute(x, ::Nothing, key1, key2)
    convert_attribute(x, key1, key2)
end

function AbstractPlotting.convert_attribute(x::AbstractVector, ::Nothing, ::key"linewidth", key2)
    return x[1:2:(length(x) - 1)]
end

function create_shader(scene::Scene, plot::LineSegments)
    # Potentially per instance attributes
    positions = plot[1][]
    startr, endr = 1:2:(length(positions)-1), 2:2:length(positions)
    segment_start = positions[startr]
    segment_end = positions[endr]
    per_instance = Dict{Symbol, Any}(
        :segment_start => segment_start,
        :segment_end => segment_end,
    )
    uniforms = Dict{Symbol, Any}()
    for k in (:linewidth, :color)
        attribute = lift(x-> convert_attribute(x, Key{k}(), key"scatter"()), plot[k])
        if isscalar(attribute)
            uniforms[k] = attribute
            uniforms[Symbol("$(k)_start")] = attribute
            uniforms[Symbol("$(k)_end")] = attribute
        else
            per_instance[Symbol("$(k)_start")] = lift(x-> x[startr], attribute)
            per_instance[Symbol("$(k)_end")] = lift(x-> x[endr], attribute)
        end
    end
    uniforms[:model] = plot.model
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
function draw_js(jsscene, mscene::Scene, plot::LineSegments)
    program = create_shader(mscene, plot)
    mesh = wgl_convert(jsscene, program)

    write(joinpath(@__DIR__, "..", "debug", "linesegments.vert"), program.program.vertex_source)
    write(joinpath(@__DIR__, "..", "debug", "linesegments.frag"), program.program.fragment_source)

    mesh.name = "LineSegments"
    jsscene.add(mesh)
end
