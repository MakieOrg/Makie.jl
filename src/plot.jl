# TODO what should a child inherit?
child(scene::Scene) = translated(scene)
plot(args...; kw_args...) = plot!(Scene(), Scatter, args...; kw_args...)
plot(P::Type, args...; kw_args...) = plot!(Scene(), P, args...; kw_args...)
plot(scene::SceneLike, args...; kw_args...) = plot!(child(scene), Scatter, args...; kw_args...)
plot(scene::SceneLike, P::Type, args...; kw_args...) = plot!(child(scene), P, args...; kw_args...)

plot!(args...; kw_args...) = plot!(current_scene(), Scatter, args...; kw_args...)
plot!(scene::SceneLike, args...; kw_args...) = plot!(scene, Scatter, args...; kw_args...)
plot!(P::Type, args...; kw_args...) = plot!(current_scene(), P, Attributes(kw_args), args...)
plot!(P::Type, attributes::Attributes, args...) = plot!(current_scene(), P, attributes, args...)
plot!(scene::SceneLike, P::Type, args...; kw_args...) = plot!(scene, P, Attributes(kw_args), args...)

function plot!(scene::SceneLike, P::Type, attributes::Attributes, args...)
    plot!(scene, P, attributes, convert_arguments(P, args...)...)
end

is2d(scene::SceneLike) = widths(limits(scene)[])[3] == 0.0

function plot!(scene::SceneLike, subscene::AbstractPlot, attributes::Attributes)
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

    isa(subscene, Combined) || push!(scene, subscene)
    if plot_attributes[:raw][] == false
        s_limits = limits(scene)
        map_once(plot_attributes[:limits], plot_attributes[:padding]) do limit, padd
            if limit == :automatic
                @info("calculating limits")
                @log_performance "calculating limits" begin
                    dlimits = data_limits(scene)
                    lim_w = widths(dlimits)
                    padd_abs = lim_w .* Vec3f0(padd)
                    s_limits[] = FRect3D(minimum(dlimits) .- padd_abs, lim_w .+  2padd_abs)
                end
            else
                s_limits[] = FRect3D(limit)
            end
        end
        area_widths = RefValue(widths(pixelarea(scene)[]))
        map_once(pixelarea(scene), s_limits, plot_attributes[:scale_plot]) do area, limits, scaleit
            # not really sure how to scale 3D scenes in a reasonable way
            if scaleit && is2d(scene) # && area_widths[] != widths(area)
                area_widths[] = widths(area)
                mini, maxi = minimum(limits), maximum(limits)
                l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
                xyzfit = fit_ratio(area, l)
                s = to_ndim(Vec3f0, xyzfit, 1f0)
                @info("calculated scaling: ", Tuple(s))
                scale!(scene, s)
            end
            return
        end
        if plot_attributes[:show_axis][] && !(any(isaxis, plots(scene)))
            axis_attributes = plot_attributes[:axis][]
            if is2d(scene)
                limits2d = map(s_limits) do l
                    l2d = FRect2D(l)
                    Tuple.((minimum(l2d), maximum(l2d)))
                end
                @info("Creating axis 2D")
                axis2d(scene, axis_attributes, limits2d)
            else
                limits3d = map(s_limits) do l
                    mini, maxi = minimum(l), maximum(l)
                    tuple.(Tuple.((mini, maxi))...)
                end
                @info("Creating axis 3D")
                axis3d(scene, limits3d, axis_attributes)
            end
        end
        # if plot_attributes[:show_legend][] && haskey(p.attributes, :colormap)
        #     legend_attributes = plot_attributes[:legend][]
        #     colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
        # end
        if plot_attributes[:camera][] == :automatic
            cam = cameracontrols(scene)
            if cam == EmptyCamera()
                if is2d(scene)
                    @info("setting camera to 2D")
                    cam2d!(scene)
                else
                    @info("setting camera to 3D")
                    cam3d!(scene)
                end
            end
        end
    end
    subscene
end
