
function create_shader(scene::Scene, plot::MeshScatter)
    # Potentially per instance attributes
    per_instance_keys = (:rotations, :markersize, :color, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    per_instance[:offset] = plot[1]

    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, plot))
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol, Any}()
    for (k,v) in uniforms
        k in (:shading, :overdraw, :fxaa, :visible, :transformation, :alpha, :linewidth, :transparency, :marker) && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end
    color = to_value(get(uniform_dict, :color, nothing))
    if color isa Colorant || color isa AbstractVector{<: Colorant} || color === nothing
        delete!(uniform_dict, :colormap)
    end

    instance = VertexArray(map(GLNormalMesh, plot.marker))
    if !GeometryBasics.hascolumn(instance, :texturecoordinate)
        uniform_dict[:texturecoordinate] = Vec2f0(0)
    end
    for key in (:view, :projection, :resolution, :eyeposition, :projectionview)
        uniform_dict[key] = getfield(scene.camera, key)
    end

    p = InstancedProgram(
        WebGL(),
        lasset("particles.vert"),
        lasset("particles.frag"),
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end


@enum Shape CIRCLE RECTANGLE ROUNDED_RECTANGLE DISTANCEFIELD TRIANGLE
primitive_shape(::Char) = Cint(DISTANCEFIELD)
primitive_shape(x::X) where X = Cint(primitive_shape(X))
primitive_shape(::Type{<: Circle}) = Cint(CIRCLE)
primitive_shape(::Type{<: SimpleRectangle}) = Cint(RECTANGLE)
primitive_shape(::Type{<: HyperRectangle{2}}) = Cint(RECTANGLE)
primitive_shape(x::Shape) = Cint(x)

function scatter_shader(scene::Scene, attributes)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity, :uv_offset_width)
    per_instance = filter(attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    for (k, v) in per_instance
        per_instance[k] = Buffer(lift_convert(k, v, nothing))
    end
    uniforms = filter(attributes) do (k, v)
        (!haskey(per_instance, k)) && isscalar(v[])
    end
    uniform_dict = Dict{Symbol, Any}()
    ignore_keys = (
        :shading, :overdraw, :rotation, :distancefield, :fxaa,
        :visible, :transformation, :alpha, :linewidth, :transparency, :marker
    )
    for (k,v) in uniforms
        k in ignore_keys && continue
        uniform_dict[k] = lift_convert(k, v, nothing)
    end
    get!(uniform_dict, :shape_type) do
        lift(primitive_shape, attributes[:marker])
    end
    if uniform_dict[:shape_type][] == 3
        atlas = AbstractPlotting.get_texture_atlas()
        uniform_dict[:distancefield] = Sampler(
            atlas.data,
            minfilter = :linear,
            magfilter = :linear,
            anisotropic = 16f0,
        )
    else
        uniform_dict[:distancefield] = Observable(false)
    end
    if !haskey(per_instance, :uv_offset_width)
        get!(uniform_dict, :uv_offset_width) do
            if haskey(attributes, :marker) && attributes[:marker][] isa Char
                lift(AbstractPlotting.glyph_uv_width!, attributes[:marker])
            else
                Vec4f0(0)
            end
        end
    end
    color = to_value(get(uniform_dict, :color, nothing))
    if color isa Colorant || color isa AbstractVector{<: Colorant} || color === nothing
        delete!(uniform_dict, :colormap)
    end
    instance = VertexArray(GLUVMesh2D(GeometryTypes.SimpleRectangle(-0.5f0, -0.5f0, 1f0, 1f0)))
    for key in (:resolution,)#(:view, :projection, :resolution, :eyeposition, :projectionview)
        uniform_dict[key] = getfield(scene.camera, key)
    end
    p = InstancedProgram(
        WebGL(),
        lasset("simple.vert"),
        lasset("sprites.frag"),
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end

function create_shader(scene::Scene, plot::Scatter)
    # Potentially per instance attributes
    per_instance_keys = (:offset, :rotations, :markersize, :color, :intensity, :marker_offset)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    attributes = copy(plot.attributes.attributes)
    attributes[:offset] = plot[1]
    attributes[:billboard] = Observable(true)

    delete!(attributes, :uv_offset_width)
    return scatter_shader(scene, attributes)
end

using AbstractPlotting: get_texture_atlas, glyph_bearing!, glyph_uv_width!, NativeFont, glyph_scale!, calc_position, calc_offset

function to_gl_text(string, startpos::AbstractVector{T}, textsize, font, align, rot, model) where T <: VecTypes
    atlas = get_texture_atlas()
    N = length(T)
    positions, uv_offset_width, scale = Point{N, Float32}[], Vec4f0[], Vec2f0[]
    # toffset = calc_offset(string, textsize, font, atlas)
    char_str_idx = iterate(string)
    broadcast_foreach(1:length(string), startpos, textsize, (font,), align) do idx, pos, tsize, font, align
        char, str_idx = char_str_idx
        _font = isa(font[1], NativeFont) ? font[1] : font[1][idx]
        mpos = model * Vec4f0(to_ndim(Vec3f0, pos, 0f0)..., 1f0)
        push!(positions, to_ndim(Point{N, Float32}, mpos, 0))
        push!(uv_offset_width, glyph_uv_width!(atlas, char, _font))
        if isa(tsize, Vec2f0) # this needs better unit support
            push!(scale, tsize) # Vec2f0, we assume it's already in absolute size
        else
            push!(scale, glyph_scale!(atlas, char,_font, tsize))
        end
        char_str_idx = iterate(string, str_idx)
    end
    positions, Vec2f0(0), uv_offset_width, scale
end

function to_gl_text(string, startpos::VecTypes{N, T}, textsize, _font, aoffsetvec, rot, model) where {N, T}
    font = to_font(_font)
    atlas = get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point{N, Float32}, mpos, 0f0)
    rscale = Float32(textsize)
    chars = Vector{Char}(string)
    scale = glyph_scale!.(Ref(atlas), chars, (font,), rscale)
    positions2d = calc_position(string, Point2f0(0), rscale, font, atlas)
    # font is Vector{FreeType.NativeFont} so we need to protec
    aoffset = AbstractPlotting.align_offset(
        Point2f0(0), positions2d[end], atlas, rscale, font, to_align(aoffsetvec)
    )
    aoffsetn = to_ndim(Point{N, Float32}, aoffset, 0f0)
    uv_offset_width = glyph_uv_width!.(Ref(atlas), chars, (font,))
    positions = map(positions2d) do p
        pn = rot * (to_ndim(Point{N, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ pos
    end
    positions, Vec2f0(0), uv_offset_width, scale
end

function create_shader(scene::Scene, plot::AbstractPlotting.Text)
    liftkeys = (:position, :textsize, :font, :align, :rotation, :model)
    gl_text = lift(to_gl_text, plot[1], getindex.(plot.attributes, liftkeys)...)
    # unpack values from the one signal:
    positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
        lift(getindex, gl_text, i)
    end
    keys = (:color, :rotation)
    signals = getindex.(plot.attributes, keys)
    return scatter_shader(scene, Dict(
        :shape_type => Observable(Cint(3)),
        :color => signals[1],
        :rotations => signals[2],
        :markersize => scale,
        :marker_offset => offset,
        :offset => positions,
        :uv_offset_width => uv_offset_width,
        :transform_marker => Observable(true),
        :billboard => Observable(false)
    ))
end


function draw_js(jsctx, jsscene, scene::Scene, plot::MeshScatter)
    program = create_shader(scene, plot)
    mesh = wgl_convert(scene, jsctx, program)
    jsscene.add(mesh)
end
function draw_js(jsctx, jsscene, scene::Scene, plot::AbstractPlotting.Text)
    program = create_shader(scene, plot)
    write(joinpath(@__DIR__, "..", "debug", "text.vert"), program.program.vertex_source)
    write(joinpath(@__DIR__, "..", "debug", "text.frag"), program.program.fragment_source)
    mesh = wgl_convert(scene, jsctx, program)
    mesh.name = "Text"
    update_model!(mesh, plot)
    jsscene.add(mesh)
end
function draw_js(jsctx, jsscene, scene::Scene, plot::Scatter)
    program = create_shader(scene, plot)
    mesh = wgl_convert(scene, jsctx, program)

    write(joinpath(@__DIR__, "..", "debug", "scatter.vert"), program.program.vertex_source)
    write(joinpath(@__DIR__, "..", "debug", "scatter.frag"), program.program.fragment_source)

    mesh.name = "Scatter"
    update_model!(mesh, plot)
    jsscene.add(mesh)
end
