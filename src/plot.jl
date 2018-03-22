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

function plot!(scene::Scene, p::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Theme(
            show_axis = false,
            show_legend = false,
            scale_plot = false,
            center = false,
            axis = Attributes(),
            legend = Attributes(),
            scale = Vec3f0(1),
            camera = :automatic,
            limits = :automatic,
            padding = (0.1, 0.1),
            raw = false
        )
    end
    # if !isempty(rest) # at this point, there should be no attributes left.
    #     warn("The following attributes are unused: $(sprint(show, rest))")
    # end
    if plot_attributes[:raw][] == false
        scale = scene.transformation.scale
        limits = map(plot_attributes[:limits], data_limits(p), plot_attributes[:padding]) do limit, dlimits, padd
            if limit == :automatic
                lim_w = dlimits[2] .- dlimits[1]
                padd_abs = lim_w .* padd
                (dlimits[1] .- padd_abs, dlimits[2] .+  padd_abs)
            else
                limit
            end
        end
        map_once(scene.px_area, limits, plot_attributes[:scale_plot]) do rect, limits, scaleit
            if scaleit
                l = ((limits[1][1], limits[2][1]), (limits[1][2], limits[2][2]))
                xyzfit = fit_ratio(rect, l)
                s = to_ndim(Vec3f0, xyzfit, 1f0)
                scale[] = s
            else
                scale[] = Vec3f0(1)
            end
            nothing
        end
        if plot_attributes[:show_axis][]
            axis_attributes = plot_attributes[:axis][]
            axis_attributes[:scale] = scale
            axis2d(scene, axis_attributes, limits)
        end
        if plot_attributes[:show_legend][]
            legend_attributes = plot_attributes[:legend][]
            legend_attributes[:scale] = scale
            legend(scene, limits, legend_attributes)
        end
        if plot_attributes[:camera][] == :automatic
            cam = scene.camera_controls[]
            if cam == EmptyCamera()
                if length(limits[][1]) == 2
                    cam2d!(scene)
                elseif length(limits[][1]) == 3
                    cam3d!(scene)
                else
                    @assert false "Scene limits should be 2d or 3d. Found limits: $limits"
                end
            end
        end
    end
    push!(scene, p)
    p#Series(Scene, p, plot_attributes)
end
