convert_arguments(P, y::RealVector) = convert_arguments(0:length(y), y)
convert_arguments(P, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(P, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)
convert_arguments(P, x::AbstractVector{<: VecTypes}) = (x,)
convert_arguments(P, x::GeometryPrimitive) = (decompose(Point, x),)

function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, data)
end
function convert_arguments(P, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end

function convert_arguments(P, x::Rect)
    # TODO fix the order of decompose
    (decompose(Point, x)[[1, 2, 4, 3, 1]],)
end

convert_arguments(::Type{Mesh}, m::AbstractMesh) = (m,)
function convert_arguments(
        T::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    convert_arguments(T, Point3f0.(x, y, z), indices)
end
function convert_arguments(
        ::Type{Mesh},
        vertices::AbstractVector{<: VecTypes{3, T}},
        indices::AbstractVector
    ) where T
    vert3f0 = T != Float32 ? Point3f0.(vertices) : vertices
    vertp3f0 = reinterpret(Point3f0, vert3f0)
    m = GLNormalMesh(vertp3f0, to_indices(indices))
    (m,)
end
function convert_arguments(
        MT::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    convert_arguments(MT, Point3f0.(x, y, z))
end
function convert_arguments(
        MT::Type{Mesh},
        xyz::AbstractVector{<: VecTypes{3, T}}
    ) where T
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    convert_arguments(MT, xyz, faces)
end




plot(args...; kw_args...) = plot!(Scene(), Scatter, args...; kw_args...)
plot(scene::Scene, args...; kw_args...) = plot!(scene, Scatter, args...; kw_args...)
plot(scene::Scene, P::Type, args...; kw_args...) = plot!(scene, P, args...; kw_args...)
plot(P::Type, args...; kw_args...) = plot!(Scene(), P, args...; kw_args...)

plot!(args...; kw_args...) = plot!(current_scene(), Scatter, args...; kw_args...)
plot!(scene::Scene, args...; kw_args...) = plot!(scene, Scatter, args...; kw_args...)
plot!(P::Type, args...; kw_args...) = plot!(current_scene(), P, Attributes(kw_args), args...)
plot!(P::Type, attributes::Attributes, args...) = plot!(current_scene(), P, attributes, args...)
plot!(scene::Scene, P::Type, args...; kw_args...) = plot!(scene, P, Attributes(kw_args), args...)

function plot!(scene::Scene, P::Type, attributes::Attributes, args...)
    plot!(scene, P, attributes, convert_arguments(P, args...)...)
end


is2d(scene::Scene) = widths(scene.limits[])[3] == 0.0

function plot!(scene::Scene, p::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Theme(
            show_axis = true,
            show_legend = false,
            scale_plot = true,
            center = false,
            axis = Attributes(),
            legend = Attributes(),
            scale = Vec3f0(1),
            camera = :automatic,
            limits = :automatic,
            padding = (0.1, 0.1, 0.1),
            raw = false
        )
    end
    # if !isempty(rest) # at this point, there should be no attributes left.
    #     warn("The following attributes are unused: $(sprint(show, rest))")
    # end
    if plot_attributes[:raw][] == false
        scale = scene.transformation.scale
        limits = scene.limits
        map_once(plot_attributes[:limits], data_limits(p), plot_attributes[:padding]) do limit, _limits, padd
            if limit == :automatic
                mini, maxi = _limits
                dlimits = FRect3D(mini, maxi .- mini)
                lim_w = widths(dlimits)
                padd_abs = lim_w .* Vec3f0(padd)
                limits[] = FRect3D(minimum(dlimits) .- padd_abs, lim_w .+  2padd_abs)
            else
                limits[] = FRect3D(limit)
            end
        end
        map_once(scene.px_area, limits, plot_attributes[:scale_plot]) do rect, limits, scaleit
            if scaleit && is2d(scene)
                mini, maxi = minimum(limits), maximum(limits)
                l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
                xyzfit = fit_ratio(rect, l)
                s = to_ndim(Vec3f0, xyzfit, 1f0)
                scale[] = s
            end
            return
        end
        if plot_attributes[:show_axis][] && !(any(x-> isa(x, AbstractAxis), scene.plots))
            axis_attributes = plot_attributes[:axis][]
            axis_attributes[:scale] = scale
            if is2d(scene)
                limits2d = map(limits) do l
                    l2d = FRect2D(l)
                    Tuple.((minimum(l2d), maximum(l2d)))
                end
                axis2d(scene, axis_attributes, limits2d)
            else
                limits3d = map(limits) do l
                    mini, maxi = minimum(l), maximum(l)
                    tuple.(Tuple.((mini, maxi))...)
                end
                axis3d(scene, limits3d, axis_attributes)
            end
        end
        if plot_attributes[:show_legend][]
            legend_attributes = plot_attributes[:legend][]
            legend_attributes[:scale] = scale
            legend(scene, limits, legend_attributes)
        end
        if plot_attributes[:camera][] == :automatic
            cam = scene.camera_controls[]
            if cam == EmptyCamera()
                if is2d(scene)
                    cam2d!(scene)
                else
                    cam3d!(scene)
                end
            end
        end
    end
    push!(scene, p)
    p#Series(Scene, p, plot_attributes)
end
