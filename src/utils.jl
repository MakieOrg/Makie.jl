################################################################################
#                             Projection utilities                             #
################################################################################

function project_position(scene, point, model)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    @inbounds begin
    # between -1 and 1
        p = (clip ./ clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f0(p[1], -p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1f0) / 2f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

project_scale(scene::Scene, s::Number, model = Mat4f0(I)) = project_scale(scene, Vec2f0(s), model)

function project_scale(scene::Scene, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = @inbounds (scene.camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    return p .* scene.camera.resolution[]
end

function project_rect(scene, rect::Rect, model)
    mini = project_position(scene, minimum(rect), model)
    maxi = project_position(scene, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end
################################################################################
#                                Color handling                                #
################################################################################

function rgbatuple(c::Colorant)
    rgba = RGBA(c)
    red(rgba), green(rgba), blue(rgba), alpha(rgba)
end

rgbatuple(c) = rgbatuple(to_color(c))


function numbers_to_colors(numbers::AbstractArray{<:Number}, primitive)

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value

    if colorrange === AbstractPlotting.automatic
        colorrange = extrema(numbers)
    end

    AbstractPlotting.interpolated_getindex.(
        Ref(colormap),
        Float64.(numbers), # ints don't work in interpolated_getindex
        Ref(colorrange))
end

########################################
#     Image/heatmap -> ARGBSurface     #
########################################

to_uint32_color(c) = reinterpret(UInt32, convert(ARGB32, c))

function to_cairo_image(img::AbstractMatrix{<: AbstractFloat}, attributes)
    AbstractPlotting.@get_attribute attributes (colormap, colorrange)
    imui32 = to_uint32_color.(AbstractPlotting.interpolated_getindex.(Ref(colormap), img, (colorrange,)))
    to_cairo_image(imui32, attributes)
end

function to_cairo_image(img::AbstractMatrix{<: Colorant}, attributes)
    to_cairo_image(to_uint32_color.(img), attributes)
end

function to_cairo_image(img::Matrix{UInt32}, attributes)
    # In Cairo, the y-axis is expected to go from the top
    # to the bottom of the image, whereas in Makie we
    # expect it to go from the bottom to the top.
    # Therefore, we flip the y-axis here, to conform
    # to Cairo's notion of the image direction.

    # In addition, we are iterating over the y-axis first,
    # such that the "first" axis of the image is what used to
    # be the rows, instead of the columns.
    # This conforms to the row-major matrix interface which
    # Cairo expects.

    # To achieve all of this, it is sufficient to physically
    # rotate the matrix left by 90 degrees.
    return CairoARGBSurface(rotl90(img))
end
