# =============================================================================
# draw_atomic for Makie.Volume
# =============================================================================

const VOLUME_DEFAULTS = (extinction_scale=100.0f0, asymmetry_g=0.85f0, single_scatter_albedo=0.99f0)

# Extract volume rendering params from material attribute
function extract_volume_params(material_attr)
    isnothing(material_attr) && return VOLUME_DEFAULTS
    function get_param(key, default)
        if material_attr isa Makie.Attributes
            return haskey(material_attr, key) ? Float32(to_value(material_attr[key])) : default
        end
        return Float32(get(material_attr, key, default))
    end
    return (;
        extinction_scale = get_param(:extinction_scale, VOLUME_DEFAULTS.extinction_scale),
        asymmetry_g = get_param(:asymmetry_g, VOLUME_DEFAULTS.asymmetry_g),
        single_scatter_albedo = get_param(:single_scatter_albedo, VOLUME_DEFAULTS.single_scatter_albedo),
    )
end

# Apply colormap to density, writing RGBSpectrum scattering values into σ_s_grid
function volume_colormap!(σ_s_grid, density, colormap, colorrange)
    cmap = Makie.to_colormap(colormap)
    if isnothing(colorrange) || colorrange isa Makie.Automatic
        cmin, cmax = extrema(density)
    else
        cmin, cmax = Float32(colorrange[1]), Float32(colorrange[2])
    end
    crange = cmax - cmin
    crange < 1f-10 && (crange = 1f0)

    nx, ny, nz = size(density)
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
end

# Build volume medium from density and configuration
function volume_medium(density, bounds, params; colormap=nothing, colorrange=nothing)
    majorant_res = Vec{3, Int64}(16, 16, 16)
    if !isnothing(colormap)
        nx, ny, nz = size(density)
        σ_s_grid = Array{Hikari.RGBSpectrum, 3}(undef, nx, ny, nz)
        σ_a_grid = fill(Hikari.RGBSpectrum(0f0), nx, ny, nz)
        volume_colormap!(σ_s_grid, density, colormap, colorrange)
        return Hikari.RGBGridMedium(
            σ_a_grid=σ_a_grid, σ_s_grid=σ_s_grid,
            sigma_scale=params.extinction_scale, g=params.asymmetry_g,
            bounds=bounds, majorant_res=majorant_res)
    else
        scaled_density = density .* params.extinction_scale
        σ_a_factor = (1f0 - params.single_scatter_albedo) / max(params.single_scatter_albedo, 1f-6)
        return Hikari.GridMedium(scaled_density;
            σ_a=Hikari.RGBSpectrum(σ_a_factor, σ_a_factor, σ_a_factor),
            σ_s=Hikari.RGBSpectrum(1f0, 1f0, 1f0),
            g=params.asymmetry_g, bounds=bounds, majorant_res=majorant_res)
    end
end

# Update medium data arrays in-place from new density
update_medium_data!(medium::Hikari.RGBGridMedium, density, params, colormap, colorrange) =
    volume_colormap!(medium.σ_s_grid, density, colormap, colorrange)
update_medium_data!(medium::Hikari.GridMedium, density, params, colormap, colorrange) =
    medium.density .= density .* params.extinction_scale

# Rebuild majorant grid after data updates
rebuild_majorant!(m::Hikari.RGBGridMedium) =
    Hikari.build_rgb_majorant_grid!(m.majorant_grid, m.σ_a_grid, m.σ_s_grid, m.sigma_scale, size(m.σ_s_grid))
rebuild_majorant!(m::Hikari.GridMedium) =
    Hikari.build_majorant_grid!(m.majorant_grid, m.density)

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Volume)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # Ensure material attribute exists for compute graph input
    haskey(attr, :material) || (attr[:material] = Observable{Any}(nothing))

    # 1. Volume data → Float32 density
    register_computation!(attr, [:volume], [:trace_density]) do args, changed, last
        return (Float32.(args.volume),)
    end

    # 2. Spatial + colormap + material params + model → volume config
    register_computation!(attr, [:x, :y, :z, :colormap, :colorrange, :material, :model_f32c], [:trace_volume_config]) do args, changed, last
        origin = Point3f(Float32(args.x[1]), Float32(args.y[1]), Float32(args.z[1]))
        extent = Vec3f(Float32(args.x[2]) - origin[1], Float32(args.y[2]) - origin[2], Float32(args.z[2]) - origin[3])

        # Transform bounding box by model_f32c for correct world-space placement (Axis3 etc.)
        model = Mat4f(args.model_f32c)
        if model != Mat4f(I)
            p1 = model * Vec4f(origin..., 1f0)
            p2 = model * Vec4f((origin + extent)..., 1f0)
            tp1 = Point3f(p1[1] / p1[4], p1[2] / p1[4], p1[3] / p1[4])
            tp2 = Point3f(p2[1] / p2[4], p2[2] / p2[4], p2[3] / p2[4])
            origin = Point3f(min.(tp1, tp2))
            extent = Vec3f(max.(tp1, tp2) - min.(tp1, tp2))
        end

        params = extract_volume_params(args.material)
        return ((origin=origin, extent=extent, colormap=args.colormap, colorrange=args.colorrange, params=params),)
    end

    # 3. Density + config → medium (colormap conversion + construction/update)
    register_computation!(attr, [:trace_density, :trace_volume_config], [:trace_medium]) do args, changed, last
        density = args.trace_density
        config = args.trace_volume_config
        bounds = Raycore.Bounds3(config.origin, config.origin + config.extent)

        if isnothing(last) || isnothing(last.trace_medium) || changed.trace_volume_config
            return (volume_medium(density, bounds, config.params;
                        colormap=config.colormap, colorrange=config.colorrange),)
        end

        medium = last.trace_medium
        update_medium_data!(medium, density, config.params, config.colormap, config.colorrange)
        rebuild_majorant!(medium)
        return (medium,)
    end

    # 4. Medium + config → scene registration
    register_computation!(attr, [:trace_medium, :trace_volume_config], [:trace_renderobject]) do args, changed, last
        medium = args.trace_medium
        config = args.trace_volume_config

        if isnothing(last) || isnothing(last.trace_renderobject) || changed.trace_volume_config
            if !isnothing(last) && !isnothing(last.trace_renderobject)
                delete_trace_handles!(hikari_scene, last.trace_renderobject)
            end
            gb_mesh = normal_mesh(Rect3f(config.origin, config.extent))
            glass = Hikari.GlassMaterial(Kr=Hikari.RGBSpectrum(0f0), Kt=Hikari.RGBSpectrum(1f0), index=1f0)
            mat = Hikari.MediumInterface(glass; inside=medium)
            handle = push!(hikari_scene, gb_mesh, mat)
            state.needs_film_clear = true
            return (handle,)
        end

        handle = last.trace_renderobject
        Hikari.update_material!(hikari_scene, handle.interface, medium)
        state.needs_film_clear = true
        return (handle,)
    end
end
