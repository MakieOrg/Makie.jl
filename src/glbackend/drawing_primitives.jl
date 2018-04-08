import GLVisualize: calc_offset, glyph_uv_width!, glyph_uv_width!, get_texture_atlas, glyph_scale!, calc_position

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
    k == :colornorm && return :color_norm
    k
end

make_context_current(screen::Screen) = GLFW.MakeContextCurrent(to_native(screen))
function cached_robj!(robj_func, screen, scene, x::AbstractPlot)
    robj = get!(screen.cache, object_id(x)) do
        gl_attributes = map(filter((k, v)-> k != :transformation, x.attributes)) do key_value
            key, value = key_value
            gl_key = to_glvisualize_key(key)
            gl_value = map(val-> attribute_convert(val, Key{key}(), plot_key(x)), value)
            gl_key => gl_value
        end
        robj = robj_func(Dict{Symbol, Any}(gl_attributes))
        for key in (:view, :projection, :resolution, :eyeposition, :projectionview)
            robj[key] = getfield(scene.camera, key)
        end
        push!(screen, scene, robj)
        robj
    end
end

function Base.insert!(screen::Screen, scene::Scene, x::Union{Scatter, Meshscatter})
    robj = cached_robj!(screen, scene, x) do gl_attributes
        marker = pop!(gl_attributes, :marker)
        if isa(x, Scatter)
            gl_attributes[:billboard] = map(rot-> isa(rot, Billboard), x.attributes[:rotations])
        end
        visualize((value(marker), x.args[1]), Style(:default), Dict{Symbol, Any}(gl_attributes)).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Lines)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = value(linestyle)
        visualize(x.args[1], Style(:lines), data).children[]
    end
end
function Base.insert!(screen::Screen, scene::Scene, x::Linesegments)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        linestyle = pop!(gl_attributes, :linestyle)
        data = Dict{Symbol, Any}(gl_attributes)
        data[:pattern] = value(linestyle)
        visualize(x.args[1], Style(:linesegment), data).children[]
    end
end
function Base.insert!(screen::Screen, scene::Scene, x::Combined)
    for elem in x.plots
        insert!(screen, scene, elem)
    end
end

function to_ndim(T::Type{<: VecTypes{N, ET}}, vec::VecTypes{N2}, fillval) where {N, ET, N2}
    T(ntuple(Val{N}) do i
        i > N2 && return ET(fillval)
        @inbounds return vec[i]
    end)
end

function to_gl_text(string, startpos::AbstractVector{T}, textsize, font, align, rot, model) where T <: VecTypes
    atlas = GLVisualize.get_texture_atlas()
    N = length(T)
    positions, uv_offset_width, scale = Point{N, Float32}[], Vec4f0[], Vec2f0[]
    toffset = calc_offset(string, textsize, font, atlas)
    broadcast_foreach(1:length(string), string, startpos, textsize, (font,), align) do idx, char, pos, tsize, font, align
        _font = isa(font[1], Font) ? font[1] : font[1][idx]
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
    # font is Vector{FreeType.Font} so we need to protec
    toffset = calc_offset(chars, rscale, font, atlas)
    aoffset = align_offset(Point2f0(0), positions2d[end], atlas, rscale, font, aoffsetvec)
    aoffsetn = to_ndim(Point{N, Float32}, aoffset, 0f0)
    uv_offset_width = glyph_uv_width!.(atlas, chars, (font,))
    scale = glyph_scale!.(atlas, chars, (font,), rscale)
    positions = map(positions2d) do p
        pn = qmul(rot, to_ndim(Point{N, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ pos
    end
    positions, toffset, uv_offset_width, scale
end
function Base.insert!(screen::Screen, scene::Scene, x::Text)
    robj = cached_robj!(screen, scene, x) do gl_attributes

        liftkeys = (:position, :textsize, :font, :align, :rotation, :model)
        gl_text = map(to_gl_text, x.args[1], getindex.(gl_attributes, liftkeys)...)
        # unpack values from the one signal:
        positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
            map(getindex, gl_text, Signal(i))
        end

        atlas = GLVisualize.get_texture_atlas()
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
            distancefield = GLVisualize.get_texture!(atlas)
        ).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Heatmap)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = (value.(x.args[1:2]))
        heatmap = map(to_node(x.args[3])) do z
            [GLVisualize.Intensity{Float32}(z[j, i]) for i = 1:size(z, 2), j = 1:size(z, 1)]
        end
        interp = value(pop!(gl_attributes, :interpolate))
        interp = interp ? :linear : :nearest
        tex = GLAbstraction.Texture(value(heatmap), minfilter = interp)
        map_once(heatmap) do x
            update!(tex, x)
        end
        gl_attributes[:stroke_width] = pop!(gl_attributes, :thickness)
        visualize(tex, Style(:default), gl_attributes).children[]
    end
end
function Base.insert!(screen::Screen, scene::Scene, x::Image)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        gl_attributes[:ranges] = (value.(x.args[1:2]))
        visualize(x.args[3], Style(:default), gl_attributes).children[]
    end
end

function Base.insert!(screen::Screen, scene::Scene, x::Mesh)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:shading] = value(pop!(gl_attributes, :shading))
        visualize(x.args[1], Style(:default), gl_attributes).children[]
    end
end


function Base.insert!(screen::Screen, scene::Scene, x::Surface)
    robj = cached_robj!(screen, scene, x) do gl_attributes
        # signals not supported for shading yet
        gl_attributes[:ranges] = value.(x.args[1:2])
        visualize(x.args[3], Style(:surface), gl_attributes).children[]
    end
end
