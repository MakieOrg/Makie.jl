gpuvec(x) = GPUVector(GLBuffer(x))

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
    k
end

make_context_current(screen::Screen) = GLFW.MakeContextCurrent(to_native(screen))

function cached_robj!(robj_func, screen, scene, x::AbstractPlot)
    robj = get!(screen.cache, object_id(x)) do
        gl_attributes = map(filter((k, v)-> k != :transformation, x.attributes)) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = lift_convert(key, value, x)
            gl_key => gl_value
        end
        robj = robj_func(Dict{Symbol, Any}(gl_attributes))
        for key in (:view, :projection, :resolution, :eyeposition, :projectionview)
            robj[key] = getfield(scene.camera, key)
        end
        screen.cache2plot[robj.id] = x
        push!(screen, scene, robj)
        robj
    end
end

index1D(x::SubArray) = parentindexes(x)[1]

handle_view(array::AbstractVector, attributes) = array
handle_view(array::Signal, attributes) = array

function handle_view(array::SubArray, attributes)
    A = parent(array)
    indices = index1D(array)
    attributes[:indices] = indices
    A
end
function handle_view(array::Signal{T}, attributes) where T <: SubArray
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

function Base.insert!(screen::Screen, scene::Scene, x::Union{Scatter, MeshScatter})
    robj = cached_robj!(screen, scene, x) do gl_attributes
        marker = lift_convert(:marker, pop!(gl_attributes, :marker), x)
        if isa(x, Scatter)
            gl_attributes[:billboard] = map(rot-> isa(rot, Billboard), x.attributes[:rotations])
        end
        # TODO either stop using bb's from glvisualize
        # or don't set them randomly to nothing
        gl_attributes[:boundingbox] = nothing
        positions = handle_view(x[1], gl_attributes)
        visualize((value(marker), positions), Style(:default), Dict{Symbol, Any}(gl_attributes)).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Lines)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = value(linestyle)
        positions = handle_view(x[1], data)
        visualize(positions, Style(:lines), data).children[]
    end
end
function Base.insert!(screen::Screen, scene::Scene, x::LineSegments)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = value(linestyle)
        positions = handle_view(x[1], data)
        visualize(positions, Style(:linesegment), data).children[]
    end
end
function Base.insert!(screen::Screen, scene::Scene, x::Combined)
    for elem in x.plots
        insert!(screen, scene, elem)
    end
end

using AbstractPlotting: get_texture_atlas, glyph_bearing!, glyph_uv_width!, glyph_scale!, calc_position, calc_offset

function to_gl_text(string, startpos::AbstractVector{T}, textsize, font, align, rot, model) where T <: VecTypes
    atlas = get_texture_atlas()
    N = length(T)
    positions, uv_offset_width, scale = Point{N, Float32}[], Vec4f0[], Vec2f0[]
    toffset = calc_offset(string, textsize, font, atlas)
    str_idx = start(string)
    broadcast_foreach(1:length(string), startpos, textsize, (font,), align) do idx, pos, tsize, font, align
        char, str_idx = next(string, str_idx)
        _font = isa(font[1], NativeFont) ? font[1] : font[1][idx]
        mpos = model * Vec4f0(to_ndim(Vec3f0, pos, 0f0)..., 1f0)
        push!(positions, to_ndim(Point{N, Float32}, mpos, 0))
        push!(uv_offset_width, glyph_uv_width!(atlas, char, _font))
        if isa(tsize, Vec2f0) # this needs better unit support
            push!(scale, tsize) # Vec2f0, we assume it's already in absolute size
        else
            push!(scale, glyph_scale!(atlas, char,_font, tsize))
        end
    end
    positions, toffset, uv_offset_width, scale
end

function to_gl_text(string, startpos::VecTypes{N, T}, textsize, font, aoffsetvec, rot, model) where {N, T}
    atlas = get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point{N, Float32}, mpos, 0f0)
    rscale = Float32(textsize)
    chars = convert(Vector{Char}, string)
    positions2d = calc_position(string, Point2f0(0), rscale, font, atlas)
    # font is Vector{FreeType.NativeFont} so we need to protec
    toffset = calc_offset(chars, rscale, font, atlas)
    aoffset = AbstractPlotting.align_offset(Point2f0(0), positions2d[end], atlas, rscale, font, aoffsetvec)
    aoffsetn = to_ndim(Point{N, Float32}, aoffset, 0f0)
    uv_offset_width = glyph_uv_width!.(atlas, chars, (font,))
    scale = glyph_scale!.(atlas, chars, (font,), rscale)
    positions = map(positions2d) do p
        pn = rot * (to_ndim(Point{N, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ pos
    end
    positions, toffset, uv_offset_width, scale
end

function Base.insert!(screen::Screen, scene::Scene, x::Text)
    robj = cached_robj!(screen, scene, x) do gl_attributes

        liftkeys = (:position, :textsize, :font, :align, :rotation, :model)
        gl_text = map(to_gl_text, x[1], getindex.(gl_attributes, liftkeys)...)
        # unpack values from the one signal:
        positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
            map(getindex, gl_text, Signal(i))
        end

        atlas = get_texture_atlas()
        keys = (:color, :stroke_color, :stroke_width, :rotation)
        signals = getindex.(gl_attributes, keys)

        visualize(
            (DISTANCEFIELD, positions),
            color = signals[1],
            stroke_color = signals[2],
            stroke_width = signals[3],
            rotation = signals[4],
            scale = scale,
            offset = offset,
            uv_offset_width = uv_offset_width,
            distancefield = get_texture!(atlas)
        ).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Heatmap)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = (value.((x[1], x[2])))
        heatmap = map(x[3]) do z
            [GLVisualize.Intensity{Float32}(z[j, i]) for i = 1:size(z, 2), j = 1:size(z, 1)]
        end
        interp = value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        tex = Texture(value(heatmap), minfilter = interp)
        map_once(heatmap) do x
            update!(tex, x)
        end
        gl_attributes[:stroke_width] = pop!(gl_attributes, :thickness)
        visualize(tex, Style(:default), gl_attributes).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Image)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = to_range.(value.((x[1], x[2])))
        img = x[3]
        if isa(value(img), AbstractMatrix{<: Number})
            norm = pop!(gl_attributes, :color_norm)
            cmap = pop!(gl_attributes, :color_map)
            img = map(img, cmap, norm) do img, cmap, norm
                interpolated_getindex.((cmap,), img, (norm,))
            end
        elseif isa(value(img), AbstractMatrix{<: Colorant})
            delete!(gl_attributes, :color_norm)
            delete!(gl_attributes, :color_map)
        end
        visualize(img, Style(:default), gl_attributes).children[]
    end
end

function Base.insert!(screen::Screen, scene::Scene, x::Mesh)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:shading] = value(pop!(gl_attributes, :shading))
        color = pop!(gl_attributes, :color)
        mesh = map(x[1], color) do m, c
            if isa(c, Colorant) && (isa(m, GLPlainMesh) || isa(m, GLNormalMesh))
                get!(gl_attributes, :color, c)
                m
            elseif isa(c, AbstractMatrix{<: Colorant}) && isa(m, GLNormalUVMesh)
                get!(gl_attributes, :color, c)
                m
            else
                HomogenousMesh(GLNormalMesh(m), Dict{Symbol, Any}(:color => c))
            end
        end
        visualize(mesh, Style(:default), gl_attributes).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Surface)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        if haskey(gl_attributes, :image) && gl_attributes[:image][] != nothing
            img = pop!(gl_attributes, :image)
            norm = pop!(gl_attributes, :color_norm)
            cmap = pop!(gl_attributes, :color_map)

            if isa(value(img), AbstractMatrix{<: Number})
                img = map(img, cmap, norm) do img, cmap, norm
                    interpolated_getindex.((cmap,), img, (norm,))
                end
            end
            gl_attributes[:color] = img
        else
            # delete nothing
            delete!(gl_attributes, :image)
        end
        args = x[1:3]
        if all(v-> value(v) isa AbstractMatrix, args)
            visualize(args, Style(:surface), gl_attributes).children[]
        else
            gl_attributes[:ranges] = to_range.(value.(args[1:2]))
            visualize(args[3], Style(:surface), gl_attributes).children[]
        end
    end
end

function to_width(x)
    mini, maxi = extrema(x)
    maxi - mini
end

function makieshader(paths...)
    view = Dict{String, String}()
    if !is_apple()
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
    model2 = map(model, x, y, z) do m, xyz...
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
    modelinv = map(inv, model2)
    hull = AABB{Float32}(Vec3f0(0), Vec3f0(1))
    gl_data = Dict(
        :hull => GLUVWMesh(hull),
        :volumedata => Texture(map(x-> convert(Array{Float32}, x), vol)),
        :model => model2,
        :modelinv => modelinv,
        :colormap => Texture(map(to_colormap, volume[:colormap])),
        :colorrange => map(Vec2f0, volume[:colorrange]),
        :fxaa => true
    )
    bb = map(m-> m * hull, model)
    robj = RenderObject(gl_data, shader, volume_prerender, bb)
    robj.postrenderfunction = GLAbstraction.StandardPostrender(robj.vertexarray, GL_TRIANGLES)
    robj
end

function Base.insert!(screen::Screen, scene::Scene, x::Volume)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        if gl_attributes[:algorithm][] == 0
            surface_contours(x)
        else
            dimensions = Vec3f0(to_width.(value.(x[1:3])))
            gl_attributes[:dimensions] = dimensions
            delete!(gl_attributes, :color)
            visualize(x[4], Style(:default), gl_attributes).children[]
        end
    end
end
