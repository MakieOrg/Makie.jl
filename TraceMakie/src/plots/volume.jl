# =============================================================================
# draw_atomic for Makie.Volume
# =============================================================================

const _VOLUME_DEFAULTS = (extinction_scale=100.0f0, asymmetry_g=0.85f0, single_scatter_albedo=0.99f0)

_volume_param(params::NamedTuple, key::Symbol, default) = Float32(get(params, key, default))
_volume_param(params::Makie.Attributes, key::Symbol, default) = haskey(params, key) ? Float32(to_value(params[key])) : default
_volume_param(::Nothing, ::Symbol, default) = default

function _extract_volume_params(plot)
    mat_params = haskey(plot, :material) ? to_value(plot.material) : nothing
    return (;
        extinction_scale = _volume_param(mat_params, :extinction_scale, _VOLUME_DEFAULTS.extinction_scale),
        asymmetry_g = _volume_param(mat_params, :asymmetry_g, _VOLUME_DEFAULTS.asymmetry_g),
        single_scatter_albedo = _volume_param(mat_params, :single_scatter_albedo, _VOLUME_DEFAULTS.single_scatter_albedo),
    )
end

function _build_volume_whitted(density, origin, extent, params, colormap_attr, colorrange_attr)
    cloud_box_geo = Rect3f(origin, extent)
    cloud_box_mesh = Raycore.TriangleMesh(normal_mesh(cloud_box_geo))

    cloud = Hikari.CloudVolume(
        density;
        origin=origin,
        extent=extent,
        extinction_scale=params.extinction_scale,
        asymmetry_g=params.asymmetry_g,
        single_scatter_albedo=params.single_scatter_albedo
    )
    return cloud_box_mesh, cloud
end

function _build_volume_volpath(density, origin, extent, params, colormap_attr, colorrange_attr)
    cloud_box_geo = Rect3f(origin, extent)
    cloud_box_mesh = Raycore.TriangleMesh(normal_mesh(cloud_box_geo))

    bounds = Raycore.Bounds3(origin, origin + extent)
    majorant_res = Vec{3, Int64}(16, 16, 16)

    use_colormap = !isnothing(colormap_attr)

    if use_colormap
        cmap = Makie.to_colormap(colormap_attr)

        if isnothing(colorrange_attr) || colorrange_attr isa Makie.Automatic
            cmin, cmax = extrema(density)
        else
            cmin, cmax = Float32(colorrange_attr[1]), Float32(colorrange_attr[2])
        end
        crange = cmax - cmin
        if crange < 1f-10
            crange = 1f0
        end

        nx, ny, nz = size(density)
        σ_s_grid = Array{Hikari.RGBSpectrum, 3}(undef, nx, ny, nz)
        σ_a_grid = fill(Hikari.RGBSpectrum(0f0), nx, ny, nz)

        for iz in 1:nz, iy in 1:ny, ix in 1:nx
            d = density[ix, iy, iz]
            t = clamp((d - cmin) / crange, 0f0, 1f0)
            color = Makie.interpolated_getindex(cmap, t)
            r, g, b = Float32(color.r), Float32(color.g), Float32(color.b)
            color_max = max(r, g, b)
            if color_max < 1f-6
                r, g, b = 1f0, 1f0, 1f0
            else
                r, g, b = r / color_max, g / color_max, b / color_max
            end
            scale = d * Float32(color.alpha)
            σ_s_grid[ix, iy, iz] = Hikari.RGBSpectrum(r * scale, g * scale, b * scale)
        end

        grid_medium = Hikari.RGBGridMedium(
            σ_a_grid = σ_a_grid,
            σ_s_grid = σ_s_grid,
            sigma_scale = params.extinction_scale,
            g = params.asymmetry_g,
            bounds = bounds,
            majorant_res = majorant_res
        )
    else
        scaled_density = density .* params.extinction_scale

        σ_a_factor = (1f0 - params.single_scatter_albedo) / max(params.single_scatter_albedo, 1f-6)
        σ_a = Hikari.RGBSpectrum(σ_a_factor, σ_a_factor, σ_a_factor)
        σ_s = Hikari.RGBSpectrum(1f0, 1f0, 1f0)

        grid_medium = Hikari.GridMedium(
            scaled_density;
            σ_a = σ_a,
            σ_s = σ_s,
            g = params.asymmetry_g,
            bounds = bounds,
            majorant_res = majorant_res
        )
    end

    transparent = Hikari.GlassMaterial(
        Kr = Hikari.RGBSpectrum(0f0),
        Kt = Hikari.RGBSpectrum(1f0),
        index = 1.0f0
    )
    material = Hikari.MediumInterface(transparent; inside=grid_medium, outside=nothing)

    return cloud_box_mesh, material
end

# Dispatch on integrator type for volume construction
_build_volume(::Hikari.VolPath, args...) = _build_volume_volpath(args...)
_build_volume(::Any, args...) = _build_volume_whitted(args...)

# Dispatch on material type for in-place density updates
function _update_volume_density!(mat::Hikari.CloudVolume, density, params)
    size(density) == size(mat.density) || (@warn "Volume size mismatch"; return)
    mat.density .= density
end
function _update_volume_density!(mat::Hikari.MediumInterface, density, params)
    _update_volume_density!(mat.inside, density, params)
end
function _update_volume_density!(medium::Hikari.GridMedium, density, params)
    size(density) == size(medium.density) || (@warn "Volume size mismatch"; return)
    medium.density .= density .* params.extinction_scale
end
_update_volume_density!(::Any, density, params) = nothing

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Volume)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state
    integrator = screen.config.integrator

    # 1. Volume data → Float32 density (independent of spatial config)
    register_computation!(attr, [:volume], [:trace_density]) do args, changed, last
        return (Float32.(args.volume),)
    end

    # 2. Spatial extent + colormap → volume config (independent of density values)
    register_computation!(attr, [:x, :y, :z, :colormap, :colorrange], [:trace_volume_config]) do args, changed, last
        x_min, x_max = Float32(args.x[1]), Float32(args.x[2])
        y_min, y_max = Float32(args.y[1]), Float32(args.y[2])
        z_min, z_max = Float32(args.z[1]), Float32(args.z[2])
        origin = Point3f(x_min, y_min, z_min)
        extent = Vec3f(x_max - x_min, y_max - y_min, z_max - z_min)
        return ((origin=origin, extent=extent, colormap=args.colormap, colorrange=args.colorrange),)
    end

    # 3. TLAS management: combine density + volume config
    register_computation!(attr, [:trace_density, :trace_volume_config], [:trace_renderobject]) do args, changed, last
        density = args.trace_density
        config = args.trace_volume_config
        params = _extract_volume_params(plot)

        if isnothing(last) || isnothing(last.trace_renderobject)
            # First run: build volume and push to scene
            cloud_box_mesh, material = _build_volume(integrator, density, config.origin, config.extent, params, config.colormap, config.colorrange)
            mat_idx = push!(hikari_scene, material)
            handle = push!(hikari_scene.accel, cloud_box_mesh, mat_idx, Mat4f(I))
            state.needs_film_clear = true
            return ((handle=handle, mat_idx=mat_idx, material=material, instance_idx=length(hikari_scene.accel.instances)),)
        end

        robj = last.trace_renderobject

        if changed.trace_volume_config
            # Spatial extent or colormap changed — full rebuild
            delete!(hikari_scene.accel, robj.handle)
            cloud_box_mesh, material = _build_volume(integrator, density, config.origin, config.extent, params, config.colormap, config.colorrange)
            mat_idx = push!(hikari_scene, material)
            handle = push!(hikari_scene.accel, cloud_box_mesh, mat_idx, Mat4f(I))
            state.needs_film_clear = true
            return ((handle=handle, mat_idx=mat_idx, material=material, instance_idx=length(hikari_scene.accel.instances)),)
        end

        if changed.trace_density
            # Volume data changed — update density in-place
            _update_volume_density!(robj.material, density, params)
            state.needs_film_clear = true
        end

        return (robj,)
    end
end
