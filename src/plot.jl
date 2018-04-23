convert_arguments(P, y::RealVector) = convert_arguments(0:length(y), y)
convert_arguments(P, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(P, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)
convert_arguments(P, x::AbstractVector{<: VecTypes}) = (x,)
convert_arguments(P, x::GeometryPrimitive) = (decompose(Point, x),)


function convert_arguments(P, x::AbstractVector{Pair{Point{N, T}, Point{N, T}}}) where {N, T}
    (reinterpret(Point{N, T}, x),)
end

function convert_arguments(P, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)
    (Float32.(x), Float32.(y), Float32.(z))
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
    convert_arguments(P, to_range(x), to_range(y), z)
end
function convert_arguments(P, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, data)
end

function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::ClosedInterval, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    _x, _y, _z = ntuple(Val{3}) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val{3}))
    end
    (x, y, z, f.(_x, _y, _z))
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
plot(scene::Scenelike, args...; kw_args...) = plot!(scene, Scatter, args...; kw_args...)
plot(scene::Scenelike, P::Type, args...; kw_args...) = plot!(scene, P, args...; kw_args...)
plot(P::Type, args...; kw_args...) = plot!(Scene(), P, args...; kw_args...)

plot!(args...; kw_args...) = plot!(current_scene(), Scatter, args...; kw_args...)
plot!(scene::Scenelike, args...; kw_args...) = plot!(scene, Scatter, args...; kw_args...)
plot!(P::Type, args...; kw_args...) = plot!(current_scene(), P, Attributes(kw_args), args...)
plot!(P::Type, attributes::Attributes, args...) = plot!(current_scene(), P, attributes, args...)
plot!(scene::Scenelike, P::Type, args...; kw_args...) = plot!(scene, P, Attributes(kw_args), args...)

function plot!(scene::Scenelike, P::Type, attributes::Attributes, args...)
    plot!(scene, P, attributes, convert_arguments(P, args...)...)
end


is2d(scene::Scenelike) = widths(limits(scene)[])[3] == 0.0


function plot!(scene::Scenelike, subscene::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Theme(
            show_axis = true,
            show_legend = false,
            scale_plot = true,
            center = false,
            axis = Attributes(),
            legend = Attributes(),
            camera = :automatic,
            limits = :automatic,
            padding = Vec3f0(0.1),
            raw = false
        )
    end

    push!(scene, subscene)
    if plot_attributes[:raw][] == false
        s_limits = limits(scene)
        map_once(plot_attributes[:limits], plot_attributes[:padding]) do limit, padd
            println("limits")
            if limit == :automatic
                dlimits = data_limits(scene)
                lim_w = widths(dlimits)
                padd_abs = lim_w .* Vec3f0(padd)
                s_limits[] = FRect3D(minimum(dlimits) .- padd_abs, lim_w .+  2padd_abs)
            else
                s_limits[] = FRect3D(limit)
            end
        end
        map_once(pixelarea(scene), s_limits, plot_attributes[:scale_plot]) do rect, limits, scaleit

            # not really sure how to scale 3D scenes in a reasonable way
            if scaleit && is2d(scene)
                println("scale_plot")
                mini, maxi = minimum(limits), maximum(limits)
                l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
                xyzfit = fit_ratio(rect, l)
                s = to_ndim(Vec3f0, xyzfit, 1f0)
                scale!(scene, s)
            end
            return
        end
        if plot_attributes[:show_axis][] && !(any(isaxis, plots(scene)))
            println("axis")
            axis_attributes = plot_attributes[:axis][]
            if is2d(scene)
                limits2d = map(s_limits) do l
                    l2d = FRect2D(l)
                    Tuple.((minimum(l2d), maximum(l2d)))
                end
                axis2d(scene, axis_attributes, limits2d)
            else
                limits3d = map(s_limits) do l
                    mini, maxi = minimum(l), maximum(l)
                    tuple.(Tuple.((mini, maxi))...)
                end
                axis3d(scene, limits3d, axis_attributes)
            end
        end
        # if plot_attributes[:show_legend][] && haskey(p.attributes, :colormap)
        #     legend_attributes = plot_attributes[:legend][]
        #     colorlegend(scene, p.attributes[:colormap], p.attributes[:colornorm], legend_attributes)
        # end
        if plot_attributes[:camera][] == :automatic
            cam = cameracontrols(scene)
            if cam == EmptyCamera()
                if is2d(scene)
                    cam2d!(scene)
                else
                    println("cam3d")
                    cam3d!(scene)
                end
            end
        end
    end

    subscene
end
