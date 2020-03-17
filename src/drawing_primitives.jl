using AbstractPlotting: get_texture_atlas, glyph_bearing!, glyph_uv_width!, glyph_scale!, calc_position, calc_offset

gpuvec(x) = GPUVector(GLBuffer(x))

to_range(x, y) = to_range.((x, y))
to_range(x::ClosedInterval) = (minimum(x), maximum(x))
to_range(x::VecTypes{2}) = x
to_range(x::AbstractRange) = (minimum(x), maximum(x))
to_range(x::AbstractVector) = (minimum(x), maximum(x))

function to_range(x::AbstractArray)
    if length(x) in size(x) # assert that just one dim != 1
        to_range(vec(x))
    else
        error("Can't convert to a range. Please supply a range/vector/interval or a tuple (min, max)")
    end
end

function to_glvisualize_key(k)
    k == :rotations && return :rotation
    k == :markersize && return :scale
    k == :glowwidth && return :glow_width
    k == :glowcolor && return :glow_color
    k == :strokewidth && return :stroke_width
    k == :strokecolor && return :stroke_color
    k == :positions && return :position
    k == :linewidth && return :thickness
    k == :marker_offset && return :offset
    k == :colormap && return :color_map
    k == :colorrange && return :color_norm
    k == :transform_marker && return :scale_primitive
    k
end

make_context_current(screen::Screen) = GLFW.MakeContextCurrent(to_native(screen))

function cached_robj!(robj_func, screen, scene, x::AbstractPlot)
    # poll inside functions to make wait on compile less prominent
    GLFW.PollEvents()
    robj = get!(screen.cache, objectid(x)) do
        filtered = filter(x.attributes) do (k, v)
            !(k in (:transformation, :tickranges, :ticklabels, :raw))
        end
        gl_attributes = Dict{Symbol, Any}(map(filtered) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = lift_convert(key, value, x)
            gl_key => gl_value
        end)
        if haskey(gl_attributes, :scale)
            gl_attributes[:use_pixel_marker] = lift(x-> x isa Vec{2, <:AbstractPlotting.Pixel}, gl_attributes[:scale])
            gl_attributes[:scale] = lift(x-> AbstractPlotting.number.(x), gl_attributes[:scale])
            if haskey(gl_attributes, :offset)
                gl_attributes[:offset] = lift(x-> AbstractPlotting.number.(x), gl_attributes[:offset])
            end
        end
        if haskey(gl_attributes, :lightposition)
            gl_attributes[:lightposition] = lift(gl_attributes[:lightposition]) do pos
                ifelse(pos == :eyeposition, getfield(scene.camera, :eyeposition), pos)
            end
        end
        robj = robj_func(gl_attributes)
        for key in (:pixel_space, :view, :projection, :resolution, :eyeposition, :projectionview)
            robj[key] = getfield(scene.camera, key)
        end
        screen.cache2plot[robj.id] = x
        robj
    end
    push!(screen, scene, robj)
    robj
end

function remove_automatic!(attributes)
    filter!(attributes) do (k, v)
        to_value(v) != automatic
    end
end

index1D(x::SubArray) = parentindices(x)[1]

handle_view(array::AbstractVector, attributes) = array
handle_view(array::Node, attributes) = array

function handle_view(array::SubArray, attributes)
    A = parent(array)
    indices = index1D(array)
    attributes[:indices] = indices
    A
end

function handle_view(array::Node{T}, attributes) where T <: SubArray
    A = lift(parent, array)
    indices = lift(index1D, array)
    attributes[:indices] = indices
    A
end

function lift_convert(key, value, plot)
    lift(value) do value
         convert_attribute(value, Key{key}(), Key{AbstractPlotting.plotkey(plot)}())
     end
end

pixel2world(scene, msize::Number) = pixel2world(scene, Point2f0(msize))[1]

function pixel2world(scene, msize::StaticVector{2})
    # TODO figure out why Vec(x, y) doesn't work correctly
    p0 = AbstractPlotting.to_world(scene, Point2f0(0.0))
    p1 = AbstractPlotting.to_world(scene, Point2f0(msize))
    diff = p1 - p0
    diff
end

pixel2world(scene, msize::AbstractVector) = pixel2world.(scene, msize)

function handle_intensities!(attributes)
    if haskey(attributes, :color) && attributes[:color][] isa AbstractVector{<: Number}
        c = pop!(attributes, :color)
        attributes[:intensity] = lift(x-> convert(Vector{Float32}, x), c)
    else
        delete!(attributes, :intensity)
        delete!(attributes, :color_map)
        delete!(attributes, :color_norm)
    end
end

function Base.insert!(screen::GLScreen, scene::Scene, x::Combined)
    # poll inside functions to make wait on compile less prominent
    GLFW.PollEvents()
    if isempty(x.plots) # if no plots inserted, this truely is an atomic
        draw_atomic(screen, scene, x)
    else
        foreach(x.plots) do x
            # poll inside functions to make wait on compile less prominent
            GLFW.PollEvents()
            insert!(screen, scene, x)
        end
    end
end

struct FastPixel end
AbstractPlotting.to_spritemarker(x::FastPixel) = x

function draw_atomic(screen::GLScreen, scene::Scene, x::Union{Scatter, MeshScatter})
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:shading] = to_value(get(gl_attributes, :shading, true))
        marker = lift_convert(:marker, pop!(gl_attributes, :marker), x)
        if isa(x, Scatter)
            gl_attributes[:billboard] = map(rot-> isa(rot, Billboard), x.attributes[:rotations])
            gl_attributes[:distancefield][] == nothing && delete!(gl_attributes, :distancefield)
            gl_attributes[:uv_offset_width][] == Vec4f0(0) && delete!(gl_attributes, :uv_offset_width)
        end
        positions = handle_view(x[1], gl_attributes)
        if marker[] isa FastPixel
            filter!(gl_attributes) do (k, v,)
                k in (:color_map, :color, :color_norm, :scale, :fxaa, :model)
            end
            if !(gl_attributes[:color][] isa AbstractVector{<: Number})
                delete!(gl_attributes, :color_norm)
                delete!(gl_attributes, :color_map)
            end
            visualize(positions, Style(:speed), Dict{Symbol, Any}(gl_attributes)).children[]
        else
            handle_intensities!(gl_attributes)
            visualize((marker, positions), Style(:default), Dict{Symbol, Any}(gl_attributes)).children[]
        end
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Lines)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = to_value(linestyle)
        positions = handle_view(x[1], data)
        handle_intensities!(data)
        visualize(positions, Style(:lines), data).children[]
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::LineSegments)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = to_value(linestyle)
        positions = handle_view(x.converted[1], data)
        if haskey(data, :color) && data[:color][] isa AbstractVector{<: Number}
            c = pop!(data, :color)
            data[:color] = lift(AbstractPlotting.el32convert, c)
        else
            delete!(data, :color_map)
            delete!(data, :color_norm)
        end
        visualize(positions, Style(:linesegment), data).children[]
    end
end

function to_gl_text(string, startpos::AbstractVector{T}, textsize, font, align, rot, model) where T <: VecTypes
    atlas = get_texture_atlas()
    N = length(T)
    positions, uv_offset_width, scale = Point{3, Float32}[], Vec4f0[], Vec2f0[]
    # toffset = calc_offset(string, textsize, font, atlas)
    char_str_idx = iterate(string)
    broadcast_foreach(1:length(string), startpos, textsize, (font,), align) do idx, pos, tsize, font, align
        char, str_idx = char_str_idx
        _font = isa(font[1], NativeFont) ? font[1] : font[1][idx]
        mpos = model * Vec4f0(to_ndim(Vec3f0, pos, 0f0)..., 1f0)
        push!(positions, to_ndim(Point{3, Float32}, mpos, 0))
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

function to_gl_text(string, startpos::VecTypes{N, T}, textsize, font, aoffsetvec, rot, model) where {N, T}
    atlas = get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point{3, Float32}, mpos, 0f0)
    rscale = Float32(textsize)
    chars = Vector{Char}(string)
    scale = glyph_scale!.(Ref(atlas), chars, (font,), rscale)
    positions2d = calc_position(string, Point2f0(0), rscale, font, atlas)
    # font is Vector{FreeType.NativeFont} so we need to protec
    aoffset = AbstractPlotting.align_offset(Point2f0(0), positions2d[end], atlas, rscale, font, aoffsetvec)
    aoffsetn = to_ndim(Point{3, Float32}, aoffset, 0f0)
    uv_offset_width = glyph_uv_width!.(Ref(atlas), chars, (font,))
    positions = map(positions2d) do p
        pn = rot * (to_ndim(Point{3, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ pos
    end
    positions, Vec2f0(0), uv_offset_width, scale
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Text)
    robj = cached_robj!(screen, scene, x) do gl_attributes

        liftkeys = (:position, :textsize, :font, :align, :rotation, :model)

        gl_text = lift(to_gl_text, x[1], getindex.(Ref(gl_attributes), liftkeys)...)
        # unpack values from the one signal:
        positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
            lift(getindex, gl_text, i)
        end

        atlas = get_texture_atlas()
        keys = (:color, :stroke_color, :stroke_width, :rotation)
        signals = getindex.(Ref(gl_attributes), keys)
        visualize(
            (DISTANCEFIELD, positions),
            color = signals[1],
            stroke_color = signals[2],
            stroke_width = signals[3],
            rotation = signals[4],
            scale = scale,
            offset = offset,
            uv_offset_width = uv_offset_width,
            distancefield = get_texture!(atlas),
            visible = gl_attributes[:visible]
        ).children[]
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Heatmap)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = lift(to_range, x[1], x[2])
        interp = to_value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        tex = Texture(x[3], minfilter = interp)
        pop!(gl_attributes, :color)
        if haskey(gl_attributes, :nan_color)
            gl_attributes[:nan_color] = lift(to_color, gl_attributes[:nan_color])
        end
        gl_attributes[:stroke_width] = pop!(gl_attributes, :thickness)
        GLVisualize.assemble_shader(GLVisualize.gl_heatmap(tex, gl_attributes)).children[]
    end
end

function vec2color(colors, cmap, crange)
    AbstractPlotting.interpolated_getindex.((to_colormap(cmap),), colors, (crange,))
end

function get_image(plot)
    if isa(plot[:color][], AbstractMatrix{<: Number})
        lift(vec2color, pop!.(Ref(plot), (:color, :color_map, :color_norm))...)
    else
        delete!(plot, :color_norm)
        delete!(plot, :color_map)
        return pop!(plot, :color)
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Image)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = lift(to_range, x[1], x[2])
        img = get_image(gl_attributes)
        # remove_automatic!(gl_attributes)
        visualize(img, Style(:default), gl_attributes).children[]
    end
end

convert_mesh_color(c::AbstractArray{<: Number}, cmap, crange) = vec2color(c, cmap, crange)
convert_mesh_color(c, cmap, crange) = c

function draw_atomic(screen::GLScreen, scene::Scene, x::Mesh)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:shading] = to_value(pop!(gl_attributes, :shading))
        color = pop!(gl_attributes, :color)
        cmap = get(gl_attributes, :color_map, Node(nothing)); delete!(gl_attributes, :color_map)
        crange = get(gl_attributes, :color_norm, Node(nothing)); delete!(gl_attributes, :color_norm)
        mesh = lift(x[1], color, cmap, crange) do m, c, cmap, crange
            c = convert_mesh_color(c, cmap, crange)
            if isa(m, GLNormalColorMesh) || isa(m, GLNormalAttributeMesh) || isa(m, GLNormalVertexcolorMesh)
                return m
            elseif c isa Colorant
                get!(gl_attributes, :color, Node(c))[] = c
                if !(isa(m, GLPlainMesh) || isa(m, GLNormalMesh))
                    return GLNormalMesh(m)
                else
                    return m
                end
            elseif c isa AbstractMatrix{<: Colorant}
                get!(gl_attributes, :color, Node(c))[] = c
                return m
            elseif c isa AbstractVector{<: Colorant}
                if length(c) != length(vertices(m))
                    error("Please use the same amount of colors as vertices. Found: $(length(vertices(m))) vertices, and $(length(c)) colors")
                end
                glm = GLNormalMesh(m)
                return HomogenousMesh(glm, Dict{Symbol, Any}(:color => convert(Vector{RGBAf0}, c)))
            else
                error("Unsupported color type: $(typeof(c))")
            end
        end
        visualize(mesh, Style(:default), gl_attributes).children[]
    end
end

function draw_atomic(screen::GLScreen, scene::Scene, x::Surface)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        color = pop!(gl_attributes, :color)
        img = nothing
        # signals not supported for shading yet
        # We automatically insert x[3] into the color channel, so if it's equal we don't need to do anything
        if isa(to_value(color), AbstractMatrix{<: Number}) && to_value(color) !== to_value(x[3])
            crange = pop!(gl_attributes, :color_norm)
            cmap = pop!(gl_attributes, :color_map)
            img = lift(color, cmap, crange) do img, cmap, norm
                AbstractPlotting.interpolated_getindex.((cmap,), img, (norm,))
            end
        elseif isa(to_value(color), AbstractMatrix{<: Colorant})
            img = color
            gl_attributes[:color_map] = nothing
            gl_attributes[:color] = nothing
            gl_attributes[:color_norm] = nothing
        end
        gl_attributes[:color] = img
        args = x[1:3]
        gl_attributes[:shading] = to_value(get(gl_attributes, :shading, true))
        if all(v-> to_value(v) isa AbstractMatrix, args)
            visualize(args, Style(:surface), gl_attributes).children[]
        else
            gl_attributes[:ranges] = to_range.(to_value.(args[1:2]))
            visualize(args[3], Style(:surface), gl_attributes).children[]
        end
    end
    return robj
end

function to_width(x)
    mini, maxi = extrema(x)
    maxi - mini
end

function makieshader(paths...)
    view = Dict{String, String}()
    if !Sys.isapple()
        view["GLSL_EXTENSIONS"] = "#extension GL_ARB_conservative_depth: enable"
        view["SUPPORTED_EXTENSIONS"] = "#define DETPH_LAYOUT"
    end
    LazyShader(
        paths...,
        view = view,
        fragdatalocation = [(0, "fragment_color"), (1, "fragment_groupid")]
    )
end

function volume_prerender()
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glDepthFunc(GL_LEQUAL)
    enabletransparency()
    glEnable(GL_CULL_FACE)
    glCullFace(GL_FRONT)
end

function surface_contours(volume::Volume)
    frag = joinpath(@__DIR__, "surface_contours.frag")
    paths = assetpath.("shader", ("fragment_output.frag", "util.vert", "volume.vert"))
    shader = makieshader(paths..., frag)
    model = volume[:model]
    x, y, z, vol = volume[1], volume[2], volume[3], volume[4]
    model2 = lift(x, y, z) do xyz...
        mi = minimum.(xyz)
        maxi = maximum.(xyz)
        w = maxi .- mi
        return Mat4f0(
            w[1], 0, 0, 0,
            0, w[2], 0, 0,
            0, 0, w[3], 0,
            mi[1], mi[2], mi[3], 1
        )
    end

    modelinv = lift((a,b)-> inv(b) * inv(a), model, model2)
    model2 = lift(*, model, model2)
    hull = FRect3D(Vec3f0(0), Vec3f0(1))
    gl_data = Dict(
        :hull => GLUVWMesh(hull),
        :volumedata => Texture(lift(x-> convert(Array{Float32}, x), vol)),
        :model => model2,
        :modelinv => modelinv,
        :colormap => Texture(lift(to_colormap, volume[:colormap])),
        :colorrange => lift(Vec2f0, volume[:colorrange]),
        :fxaa => true
    )
    bb = lift(m-> m * hull, model)
    vp = GLVisualize.VolumePrerender(
        lift(identity, volume[:transparency]),
        lift(identity, volume[:overdraw])
    )
    robj = RenderObject(gl_data, shader, vp, bb)
    robj.postrenderfunction = GLAbstraction.StandardPostrender(robj.vertexarray, GL_TRIANGLES)
    return robj
end

function draw_atomic(screen::GLScreen, scene::Scene, vol::Volume)
    robj = cached_robj!(screen, scene, vol) do gl_attributes
        if gl_attributes[:algorithm][] == 7
            return surface_contours(vol)
        else
            model = vol[:model]
            x, y, z = vol[1], vol[2], vol[3]
            gl_attributes[:model] = lift(model, x, y, z) do m, xyz...
                mi = minimum.(xyz)
                maxi = maximum.(xyz)
                w = maxi .- mi
                m2 = Mat4f0(
                    w[1], 0, 0, 0,
                    0, w[2], 0, 0,
                    0, 0, w[3], 0,
                    mi[1], mi[2], mi[3], 1
                )
                convert(Mat4f0, m) * m2
            end
            return visualize(vol[4], Style(:default), gl_attributes).children[]
        end
    end
end
