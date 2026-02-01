module TraceMakie

using Makie, Hikari, Colors, LinearAlgebra, GeometryBasics, Raycore, KernelAbstractions
using Makie: Observable, on, colorbuffer, to_value
using Makie: Quaternionf
using GeometryBasics: VecTypes
using Colors: N0f8
using ImageCore: RGBA, RGB, clamp01nan
import Makie.Observables
using Adapt

# Include Overlay rasterization module
include("overlay/Overlay.jl")
using .Overlay

# Debug: capture overlay buffer for inspection
const DEBUG_OVERLAY = Ref{Any}(nothing)

# =============================================================================
# TraceMakieState: Tracks the mapping between Makie plots and Hikari instances
# =============================================================================

"""
    PlotInfo

Stores information about a single Makie plot in the ray tracing scene.
For MeshScatter plots, `instance_count` tracks the number of instances sharing one BLAS.
"""
mutable struct PlotInfo
    plot::Makie.AbstractPlot
    handle::Raycore.TLASHandle
    transform_obs::Union{Observable, Nothing}
    obs_funcs::Vector{Observables.ObserverFunction}
    instance_count::Int  # Number of instances (>1 for MeshScatter)
    per_instance_materials::Bool  # True if each instance has separate material (no batched transforms)
    first_instance_idx::Int  # Starting index in TLAS.instances for per-instance materials
    PlotInfo(plot, handle, transform_obs, obs_funcs, count=1, per_inst=false, first_idx=0) = new(plot, handle, transform_obs, obs_funcs, count, per_inst, first_idx)
end


"""
    PlotUpdateInfo

Tracks a plot and its computed key for polling updates via the compute graph.
The update function is registered in the plot's attributes and updates
the corresponding Hikari material/geometry in-place when polled.
"""
struct PlotUpdateInfo
    plot::Makie.AbstractPlot
    computed_key::Symbol
end

"""
    OverlayPlotInfo

Information about a plot that should be rendered as an overlay (lines, scatter, text).
"""
struct OverlayPlotInfo
    plot::Makie.AbstractPlot
    plot_type::Symbol  # :lines, :linesegments, :scatter, :text
end

"""
    TraceMakieState

Holds the state needed to synchronize a Makie scene with a Hikari ray tracing scene.
Supports dynamic updates to transformations via TLAS refit, and material/geometry
updates via the compute graph polling mechanism.
"""
mutable struct TraceMakieState
    plot_infos::Vector{PlotInfo}
    film::Hikari.Film  # Can be CPU (Array) or GPU (ROCArray/CuArray) - types differentiate
    camera::Observable
    needs_refit::Bool  # Flag to track if TLAS needs refit
    hikari_scene::Hikari.AbstractScene  # Contains the TLAS via hikari_scene.accel (Scene for CPU, ImmutableScene for GPU)
    update_infos::Vector{PlotUpdateInfo}  # Track plots for compute graph polling
    needs_film_clear::Bool  # Flag to indicate data changed and film should be cleared
    # Overlay system for lines, scatter, text
    overlay_buffer::Matrix{RGBA{Float32}}
    overlay_plots::Vector{OverlayPlotInfo}
end

# Helper to get TLAS from state (it's inside hikari_scene.accel)
get_tlas(state::TraceMakieState) = state.hikari_scene.accel

"""
    register_plot_updates!(state::TraceMakieState, info::PlotInfo, material, material_idx)

Register a plot for in-place material/geometry updates using the compute graph.
This is called during scene conversion for each plot to set up reactive updates.

When polled before rendering, the compute graph evaluates any dirty attributes
and updates the corresponding Hikari structures in-place.
"""
function register_plot_updates!(state::TraceMakieState, info::PlotInfo, material, material_idx)
    # Dispatch to plot-specific registration
    _register_plot_updates!(state, info, material, material_idx)
end

# Default: no updates for unsupported plot types
function _register_plot_updates!(state::TraceMakieState, info::PlotInfo, material, material_idx)
    # No-op for plots without special update handling
end

# Volume plots: update density array in-place (CloudVolume for Whitted integrator)
function _register_plot_updates!(state::TraceMakieState, info::PlotInfo, cloud::Hikari.CloudVolume, material_idx)
    plot = info.plot
    plot isa Makie.Plot{Makie.volume} || return
    attr = plot.attributes
    computed_key = :tracemakie_volume_update

    # Skip if already registered (e.g., from previous colorbuffer call)
    if haskey(attr, computed_key)
        push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
        return
    end

    # Register computation that watches the volume data
    # Must return a tuple with one element per output
    Makie.register_computation!(attr, [:volume], [computed_key]) do (vol_data,), changed, cached
        if changed.volume
            # Volume data changed - update CloudVolume density in-place
            if size(vol_data) == size(cloud.density)
                cloud.density .= Float32.(vol_data)
            else
                @warn "Volume size mismatch: $(size(vol_data)) vs $(size(cloud.density))"
            end
            state.needs_film_clear = true
            return (true,)
        end
        return isnothing(cached) ? (false,) : cached
    end

    push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
end

# Volume plots: update density array in-place (MediumInterface with GridMedium for VolPath integrator)
function _register_plot_updates!(state::TraceMakieState, info::PlotInfo, mi::Hikari.MediumInterface, material_idx)
    plot = info.plot
    plot isa Makie.Plot{Makie.volume} || return

    # Extract GridMedium from MediumInterface
    medium = mi.inside
    medium isa Hikari.GridMedium || return

    attr = plot.attributes
    computed_key = :tracemakie_volume_update

    # Skip if already registered
    if haskey(attr, computed_key)
        push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
        return
    end

    # Get extinction_scale from material attribute to apply during updates
    mat_params = haskey(plot, :material) ? to_value(plot.material) : nothing
    extinction_scale = 100.0f0
    if mat_params isa NamedTuple
        extinction_scale = Float32(get(mat_params, :extinction_scale, extinction_scale))
    elseif mat_params isa Makie.Attributes && haskey(mat_params, :extinction_scale)
        extinction_scale = Float32(to_value(mat_params[:extinction_scale]))
    end

    # Register computation that watches the volume data
    Makie.register_computation!(attr, [:volume], [computed_key]) do (vol_data,), changed, cached
        if changed.volume
            # Volume data changed - update GridMedium density in-place (with scaling)
            if size(vol_data) == size(medium.density)
                medium.density .= Float32.(vol_data) .* extinction_scale
            else
                @warn "Volume size mismatch: $(size(vol_data)) vs $(size(medium.density))"
            end
            state.needs_film_clear = true
            return (true,)
        end
        return isnothing(cached) ? (false,) : cached
    end

    push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
end

# Generic material handler - dispatches based on plot type
function _register_plot_updates!(state::TraceMakieState, info::PlotInfo, mat::Hikari.Material, material_idx)
    plot = info.plot

    # MeshScatter: update positions, markersize, rotation -> refit TLAS
    if plot isa Makie.Plot{Makie.meshscatter} && info.instance_count > 1
        attr = plot.attributes
        computed_key = :tracemakie_meshscatter_update

        # Skip if already registered (e.g., from previous colorbuffer call)
        if haskey(attr, computed_key)
            push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
            return
        end

        # Watch positions, markersize, and rotation
        # Must return a tuple with one element per output
        Makie.register_computation!(attr, [:positions, :markersize, :rotation], [computed_key]) do (positions, markersize, rotation), changed, cached
            if changed.positions || changed.markersize || changed.rotation
                state.needs_refit = true
                state.needs_film_clear = true
                return (true,)
            end
            return isnothing(cached) ? (false,) : cached
        end

        push!(state.update_infos, PlotUpdateInfo(plot, computed_key))

    # Mesh: update color in-place (for materials with mutable Texture)
    elseif plot isa Makie.Plot{Makie.mesh}
        # Try to get the texture from the material for in-place updates
        tex = _get_material_texture(mat)
        if !isnothing(tex) && tex isa Hikari.Texture
            attr = plot.attributes
            computed_key = :tracemakie_mesh_color_update

            # Skip if already registered
            if haskey(attr, computed_key)
                push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
                return
            end

            # Must return a tuple with one element per output
            Makie.register_computation!(attr, [:color], [computed_key]) do (color,), changed, cached
                if changed.color
                    if color isa Colorant
                        # Fill entire texture with single color
                        fill!(tex.data, to_spectrum(to_color(color)))
                    elseif color isa AbstractVector{<:Colorant}
                        tex.data = to_spectrum.(color)
                    elseif color isa AbstractMatrix{<:Colorant}
                        tex.data = to_spectrum.(color)
                    end
                    state.needs_film_clear = true
                    return (true,)
                end
                return isnothing(cached) ? (false,) : cached
            end

            push!(state.update_infos, PlotUpdateInfo(plot, computed_key))
        end
    end
end

# Helper to extract mutable texture from material (for in-place color updates)
_get_material_texture(mat::Hikari.MatteMaterial) = mat.Kd isa Hikari.Texture ? mat.Kd : nothing
_get_material_texture(mat::Hikari.MetalMaterial) = mat.reflectance isa Hikari.Texture ? mat.reflectance : nothing
_get_material_texture(mat::Hikari.Material) = nothing

"""
    poll_updates!(state::TraceMakieState)

Poll all registered plots for updates. This triggers the compute graph
to evaluate any dirty attributes and update Hikari structures in-place.
Should be called before each render frame.

Returns true if any updates occurred (film should be cleared).
"""
function poll_updates!(state::TraceMakieState)
    had_updates = false
    for info in state.update_infos
        # Access the computed node to trigger resolution
        if haskey(info.plot.attributes, info.computed_key)
            computed = info.plot.attributes[info.computed_key]
            result = computed[]
            # Result is a tuple like (true,) or (false,)
            if result isa Tuple && length(result) >= 1 && result[1] === true
                had_updates = true
            end
        end
    end
    if state.needs_film_clear
        state.needs_film_clear = false
        return true
    end
    return had_updates
end

# =============================================================================
# Transform and Sync functions
# =============================================================================

"""
    get_plot_transform(plot) -> Mat4f

Extract the full transformation matrix from a Makie plot.
"""
function get_plot_transform(plot::Makie.AbstractPlot)
    return Mat4f(Makie.transformationmatrix(plot)[])
end

# Include overlay rendering functions
include("overlay_rendering.jl")

# Include screen-related code (must come after overlay_rendering.jl since screen.jl uses render_overlays!)
include("screen.jl")

# =============================================================================
# Transform and Sync functions
# =============================================================================

"""
    update_plot_transform!(state::TraceMakieState, info::PlotInfo)

Update a single plot's transform in the TLAS.
Uses GPU-friendly batch update for both CPU and GPU backends via KernelAbstractions.
"""
function update_plot_transform!(state::TraceMakieState, info::PlotInfo)
    transform = get_plot_transform(info.plot)

    # Get backend from film to ensure CPU/GPU compatibility
    backend = KernelAbstractions.get_backend(state.film.framebuffer)

    # Allocate transform array on same backend as TLAS and fill it (no scalar indexing)
    transforms = KernelAbstractions.allocate(backend, Mat4f, 1)
    fill!(transforms, transform)

    # Use batch update with offset (works for both CPU and GPU via KA)
    first_idx = info.first_instance_idx == 0 ? 1 : info.first_instance_idx
    Raycore.update_instance_transforms!(get_tlas(state), transforms, 1, first_idx)

    state.needs_refit = true
end

"""
    refit_if_needed!(state::TraceMakieState)

Refit the TLAS if any transforms have changed.
"""
function refit_if_needed!(state::TraceMakieState)
    if state.needs_refit
        Raycore.refit_tlas!(get_tlas(state))
        state.needs_refit = false
    end
end

# =============================================================================
# Color/Spectrum conversion
# =============================================================================

function to_spectrum(data::Colorant)
    rgb = RGBf(data)
    alpha = data isa TransparentColor ? Float32(Colors.alpha(data)) : 1f0
    return Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b, alpha)
end

function to_spectrum(data::AbstractMatrix{<:Colorant})
    return map(data) do c
        rgb = RGBf(c)
        alpha = c isa TransparentColor ? Float32(Colors.alpha(c)) : 1f0
        Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b, alpha)
    end
end

"""
    merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.Material)

Create a new material of the same type but with the color texture merged in.
The color modulates the material's primary color channel (Kd, Kr, etc.).
"""
function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.MatteMaterial)
    Hikari.MatteMaterial(color_tex, material.σ)
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.MirrorMaterial)
    Hikari.MirrorMaterial(color_tex)
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.GlassMaterial)
    # Use color for transmittance (Kt) - this tints the glass
    Hikari.GlassMaterial(
        material.Kr, color_tex,
        material.u_roughness, material.v_roughness,
        material.index, material.remap_roughness
    )
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.MetalMaterial)
    # For metal, color is used as a reflectance tint that multiplies the Fresnel result
    # This preserves the physical eta/k values while allowing color variation
    Hikari.MetalMaterial(material.eta, material.k, material.roughness, color_tex, material.remap_roughness)
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.CoatedDiffuseMaterial)
    # For coated diffuse, color replaces the diffuse reflectance
    Hikari.CoatedDiffuseMaterial(
        color_tex, material.u_roughness, material.v_roughness, material.thickness,
        material.eta, material.albedo, material.g, material.max_depth, material.n_samples, material.remap_roughness
    )
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.ThinDielectricMaterial)
    # ThinDielectric is colorless (just IOR), return as-is
    material
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.DiffuseTransmissionMaterial)
    # For diffuse transmission, color replaces the reflectance
    Hikari.DiffuseTransmissionMaterial(
        color_tex, material.transmittance, material.scale
    )
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.CoatedConductorMaterial)
    # CoatedConductor is physically based - merging color doesn't make sense
    # Return as-is (similar to ThinDielectric)
    material
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.MediumInterface)
    # Forward to inner material and rewrap with same medium info
    merged_inner = merge_color_with_material(color_tex, material.material)
    Hikari.MediumInterface(merged_inner; inside=material.inside, outside=material.outside)
end

function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.EmissiveMaterial)
    # Use color as the emission - scale it by the existing scale factor
    Hikari.EmissiveMaterial(color_tex, material.scale, material.two_sided)
end

# Fallback for unknown material types - just return the material as-is
function merge_color_with_material(color_tex::Hikari.Texture, material::Hikari.Material)
    @warn "Unknown material type $(typeof(material)), ignoring color"
    material
end

function extract_material(plot::Plot, tex::Union{Hikari.Texture, Nothing})
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material = has_material ? to_value(plot.material) : nothing

    if material isa Hikari.Material && tex isa Hikari.Texture
        # Both color and material provided - merge them
        return merge_color_with_material(tex, material)
    elseif material isa Hikari.Material
        # Only material provided - use as-is
        return material
    elseif tex isa Hikari.Texture
        # Only color provided - create MatteMaterial
        return Hikari.MatteMaterial(tex, Hikari.ConstTexture(0.0f0))
    else
        error("Neither color nor material are defined for plot: $plot")
    end
end

function extract_material(plot::Plot, color_obs::Union{Makie.Computed, Observable})
    color = to_value(color_obs)

    # Check if material is explicitly provided
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material = has_material ? to_value(plot.material) : nothing

    # If material is provided and color was NOT explicitly set by the user,
    # use the material as-is without merging auto-assigned palette colors
    color_explicitly_set = plot.attributes.inputs[:color].value !== nothing
    if material isa Hikari.Material && !color_explicitly_set
        return material
    end

    # Create texture from color - updates are handled by compute graph registration
    tex = nothing
    if color isa AbstractMatrix{<:Number}
        # Use Makie's compute_colors to apply colormap
        computed = Makie.compute_colors(plot.attributes)
        tex = Hikari.Texture(to_spectrum(computed))
    elseif color isa AbstractMatrix{<:Colorant}
        tex = Hikari.Texture(to_spectrum(color))
    elseif color isa AbstractVector{<:Colorant}
        # Per-instance colors (e.g., for meshscatter)
        tex = Hikari.Texture(to_spectrum.(color))
    elseif color isa Colorant || color isa Union{String,Symbol}
        tex = Hikari.ConstTexture(to_spectrum(to_color(color)))
    elseif color isa Nothing
        # ignore!
        nothing
    else
        error("Unsupported color type for TraceMakie backend: $(typeof(color))")
    end

    return extract_material(plot, tex)
end

"""
Convert a Makie material dict (from GLB) to a Hikari material.
"""
function glb_material_to_hikari(mat_dict::Dict{String, Any})
    # Check for diffuse map (texture)
    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            img = diffuse_map["image"]
            tex = Hikari.Texture(to_spectrum(img))
            roughness = get(mat_dict, "roughness", 0.5f0)
            return Hikari.MatteMaterial(tex, Hikari.ConstTexture(Float32(roughness) * 90f0))
        end
    end

    # Check for diffuse color
    if haskey(mat_dict, "diffuse")
        diffuse = mat_dict["diffuse"]
        color = RGBf(diffuse[1], diffuse[2], diffuse[3])
        tex = Hikari.ConstTexture(to_spectrum(color))
        roughness = get(mat_dict, "roughness", 0.5f0)
        return Hikari.MatteMaterial(tex, Hikari.ConstTexture(Float32(roughness) * 90f0))
    end

    # Default: white matte
    return Hikari.MatteMaterial(
        Hikari.ConstTexture(Hikari.RGBSpectrum(0.8f0, 0.8f0, 0.8f0)),
        Hikari.ConstTexture(0.0f0)
    )
end

function to_trace_primitive(plot::Makie.Mesh)
    mesh = plot.mesh[]

    # Handle MetaMesh with materials
    if mesh isa GeometryBasics.MetaMesh
        primitives = Tuple[]

        # Check if we have material info
        if haskey(mesh, :material_names) && haskey(mesh, :materials)
            submeshes = GeometryBasics.split_mesh(mesh.mesh)
            material_names = mesh[:material_names]
            materials_dict = mesh[:materials]

            # Cache converted materials to avoid creating duplicate textures
            hikari_materials = Dict{String, Any}()
            default_mat = nothing

            for (name, submesh) in zip(material_names, submeshes)
                tmesh = Raycore.TriangleMesh(submesh)

                # Get or create cached material
                mat = get!(hikari_materials, name) do
                    if haskey(materials_dict, name)
                        glb_material_to_hikari(materials_dict[name])
                    else
                        if isnothing(default_mat)
                            default_mat = extract_material(plot, plot.color)
                        end
                        default_mat
                    end
                end

                push!(primitives, (tmesh, mat))
            end
        else
            # MetaMesh without material info - treat as single mesh
            tmesh = Raycore.TriangleMesh(mesh.mesh)
            mat = extract_material(plot, plot.color)
            push!(primitives, (tmesh, mat))
        end

        return primitives
    end

    # Regular mesh
    tmesh = Raycore.TriangleMesh(mesh)
    material = extract_material(plot, plot.color)
    return (tmesh, material)
end

function to_trace_primitive(plot::Makie.Surface)
    !plot.visible[] && return nothing
    x = plot[1]
    y = plot[2]
    z = plot[3]

    function grid(x, y, z, trans)
        space = to_value(get(plot, :space, :data))
        g = map(CartesianIndices(z)) do i
            p = Point3f(Makie.get_dim(x, i, 1, size(z)), Makie.get_dim(y, i, 2, size(z)), z[i])
            return Makie.apply_transform(trans, p, space)
        end
        return vec(g)
    end

    positions = lift(grid, x, y, z, Makie.transform_func_obs(plot))
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(z[]))
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    mesh = normal_mesh(GeometryBasics.Mesh(vec(positions[]), faces, uv=uv))

    # Convert to TriangleMesh using Raycore
    tmesh = Raycore.TriangleMesh(mesh)

    # Extract material - Surface uses z values for colormapping by default
    # Use Makie's compute_colors to get the colormapped texture
    material = extract_surface_material(plot)
    return Hikari.GeometricPrimitive(tmesh, material)
end

"""
Extract material for Surface plots, using Makie's color computation system.
"""
function extract_surface_material(plot::Makie.Surface)
    # Check if material is explicitly provided
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material_template = has_material ? to_value(plot.material) : nothing

    # Get the color - Surface can have explicit color or use z values
    color = to_value(plot.color)

    if color isa AbstractMatrix{<:Colorant}
        # Explicit color matrix provided
        tex = Hikari.Texture(to_spectrum(color))
    elseif color isa Colorant || color isa Union{String, Symbol}
        # Single color for entire surface
        tex = Hikari.ConstTexture(to_spectrum(to_color(color)))
    else
        # Use Makie's compute_colors to get colormapped texture from z values
        computed = Makie.compute_colors(plot.attributes)
        tex = Hikari.Texture(to_spectrum(computed))
    end

    if material_template isa Hikari.Material
        return merge_color_with_material(tex, material_template)
    else
        return Hikari.MatteMaterial(tex, Hikari.ConstTexture(0.0f0))
    end
end

function to_trace_primitive(plot::Makie.Plot)
    return nothing
end

"""
Convert a Makie Volume plot to a volume material with bounding box mesh.

The conversion depends on the integrator type:
- For VolPath: Creates GridMedium + MediumInterface for proper volumetric path tracing
- For other integrators (Whitted, etc.): Creates CloudVolume for ray marching

Volume parameters are passed via the `material` attribute as a NamedTuple:
```julia
volume(x, y, z, data; material=(;
    extinction_scale=100f0,      # Controls optical density
    asymmetry_g=0.85f0,          # HG phase function asymmetry (0.85 for clouds)
    single_scatter_albedo=0.99f0 # Scattering vs absorption ratio (CloudVolume only)
))
```
"""
function to_trace_primitive(plot::Makie.Volume, integrator::Hikari.Integrator=Whitted())
    !plot.visible[] && return nothing

    # Get volume data from the .volume attribute
    vol_data = to_value(plot.volume)

    # Convert to Float32 density field
    density = Float32.(vol_data)

    # Get spatial extent from x, y, z attributes (EndPoints)
    x = to_value(plot.x)
    y = to_value(plot.y)
    z = to_value(plot.z)

    # EndPoints have .start and .stop, or can be indexed [1] and [2]
    x_min, x_max = Float32(x[1]), Float32(x[2])
    y_min, y_max = Float32(y[1]), Float32(y[2])
    z_min, z_max = Float32(z[1]), Float32(z[2])

    origin = Point3f(x_min, y_min, z_min)
    extent = Vec3f(x_max - x_min, y_max - y_min, z_max - z_min)

    # Get volume parameters from material attribute (NamedTuple or Attributes)
    mat_params = haskey(plot, :material) ? to_value(plot.material) : nothing

    extinction_scale = 100.0f0
    asymmetry_g = 0.85f0
    single_scatter_albedo = 0.99f0

    if mat_params isa NamedTuple
        extinction_scale = Float32(get(mat_params, :extinction_scale, extinction_scale))
        asymmetry_g = Float32(get(mat_params, :asymmetry_g, asymmetry_g))
        single_scatter_albedo = Float32(get(mat_params, :single_scatter_albedo, single_scatter_albedo))
    elseif mat_params isa Makie.Attributes
        # Makie converts NamedTuple to Attributes - extract values
        if haskey(mat_params, :extinction_scale)
            extinction_scale = Float32(to_value(mat_params[:extinction_scale]))
        end
        if haskey(mat_params, :asymmetry_g)
            asymmetry_g = Float32(to_value(mat_params[:asymmetry_g]))
        end
        if haskey(mat_params, :single_scatter_albedo)
            single_scatter_albedo = Float32(to_value(mat_params[:single_scatter_albedo]))
        end
    end

    # Get colormap and colorrange from plot attributes
    colormap_attr = to_value(plot.colormap)
    colorrange_attr = to_value(plot.colorrange)

    # Create bounding box mesh for the volume
    cloud_box_geo = Rect3f(origin, extent)
    cloud_box_mesh = Raycore.TriangleMesh(normal_mesh(cloud_box_geo))

    # Create appropriate material based on integrator type
    if integrator isa Hikari.VolPath
        bounds = Raycore.Bounds3(origin, origin + extent)
        majorant_res = Vec{3, Int64}(16, 16, 16)

        # Check if we should use colormap (RGBGridMedium) or grayscale (GridMedium)
        # Use RGBGridMedium when colormap is explicitly set to something other than default
        use_colormap = !isnothing(colormap_attr)

        if use_colormap
            # Convert colormap to array of colors
            cmap = Makie.to_colormap(colormap_attr)

            # Determine colorrange (normalize density to [0,1] for colormap lookup)
            if isnothing(colorrange_attr) || colorrange_attr isa Makie.Automatic
                cmin, cmax = extrema(density)
            else
                cmin, cmax = Float32(colorrange_attr[1]), Float32(colorrange_attr[2])
            end
            crange = cmax - cmin
            if crange < 1f-10
                crange = 1f0
            end

            # Build per-voxel σ_s grid from colormap
            # Density controls scattering magnitude, colormap controls color
            # Alpha from colormap further modulates visibility (transparent = less scattering)
            nx, ny, nz = size(density)
            σ_s_grid = Array{Hikari.RGBSpectrum, 3}(undef, nx, ny, nz)
            # Zero absorption grid (pure scattering medium)
            σ_a_grid = fill(Hikari.RGBSpectrum(0f0), nx, ny, nz)

            for iz in 1:nz, iy in 1:ny, ix in 1:nx
                d = density[ix, iy, iz]
                # Normalize density to [0,1] for colormap lookup
                t = clamp((d - cmin) / crange, 0f0, 1f0)
                # Sample colormap (RGBA)
                color = Makie.interpolated_getindex(cmap, t)
                # Density provides scattering magnitude, color provides wavelength dependence
                # Alpha modulates overall visibility (transparent regions scatter less)
                # If colormap is black, use white (grayscale) scattering at that density
                r, g, b = Float32(color.r), Float32(color.g), Float32(color.b)
                color_max = max(r, g, b)
                if color_max < 1f-6
                    # Black in colormap = use neutral gray scattering at this density
                    r, g, b = 1f0, 1f0, 1f0
                else
                    # Normalize color to preserve hue but let density control magnitude
                    r, g, b = r / color_max, g / color_max, b / color_max
                end
                # Scale by density and alpha
                scale = d * Float32(color.alpha)
                σ_s_grid[ix, iy, iz] = Hikari.RGBSpectrum(r * scale, g * scale, b * scale)
            end

            # Create RGBGridMedium with per-voxel colors
            # Provide explicit zero σ_a grid (pbrt-v4 defaults absent grids to 1.0)
            grid_medium = Hikari.RGBGridMedium(
                σ_a_grid = σ_a_grid,
                σ_s_grid = σ_s_grid,
                sigma_scale = extinction_scale,
                g = asymmetry_g,
                bounds = bounds,
                majorant_res = majorant_res
            )
        else
            # No colormap: use original GridMedium with uniform white scattering
            scaled_density = density .* extinction_scale

            # Compute σ_a and σ_s from single_scatter_albedo
            σ_a_factor = (1f0 - single_scatter_albedo) / max(single_scatter_albedo, 1f-6)
            σ_a = Hikari.RGBSpectrum(σ_a_factor, σ_a_factor, σ_a_factor)
            σ_s = Hikari.RGBSpectrum(1f0, 1f0, 1f0)

            grid_medium = Hikari.GridMedium(
                scaled_density;
                σ_a = σ_a,
                σ_s = σ_s,
                g = asymmetry_g,
                bounds = bounds,
                majorant_res = majorant_res
            )
        end

        # Wrap in MediumInterface with transparent boundary
        transparent = Hikari.GlassMaterial(
            Kr = Hikari.RGBSpectrum(0f0),
            Kt = Hikari.RGBSpectrum(1f0),
            index = 1.0f0
        )
        material = Hikari.MediumInterface(transparent; inside=grid_medium, outside=nothing)

        return (cloud_box_mesh, material)
    else
        # For other integrators (Whitted, etc.): use CloudVolume
        cloud = Hikari.CloudVolume(
            density;
            origin=origin,
            extent=extent,
            extinction_scale=extinction_scale,
            asymmetry_g=asymmetry_g,
            single_scatter_albedo=single_scatter_albedo
        )
        return (cloud_box_mesh, cloud)
    end
end

function to_trace_primitive_with_transform(plot::Makie.Volume, integrator::Hikari.Integrator=Whitted())
    prim = to_trace_primitive(plot, integrator)
    if isnothing(prim)
        return nothing
    end
    mesh, material = prim
    # Volume coordinates are already in world space, use identity transform
    return (mesh, material, Mat4f(LinearAlgebra.I))
end

function to_trace_light(light::Makie.AmbientLight)
    color = light.color isa Observable ? light.color[] : light.color
    return Hikari.AmbientLight(
        to_spectrum(color),
    )
end

function to_trace_light(light::Makie.PointLight)
    # Convert color to RGB values
    rgb = RGBf(light.color)

    # Separate intensity from color:
    # - intensity = max(r, g, b) - this is the radiance scale
    # - color = rgb / intensity - normalized color (0-1 range)
    intensity = max(rgb.r, rgb.g, rgb.b)

    if intensity > 0
        # Normalize color to 0-1 range
        norm_r = Float32(rgb.r / intensity)
        norm_g = Float32(rgb.g / intensity)
        norm_b = Float32(rgb.b / intensity)
    else
        norm_r = 1f0
        norm_g = 1f0
        norm_b = 1f0
        intensity = 0f0
    end

    # Create RGBIlluminantSpectrum from normalized color
    table = Hikari.get_srgb_table()
    spectrum = Hikari.rgb_illuminant_spectrum(table, norm_r, norm_g, norm_b)

    # Scale calculation following pbrt-v4:
    # Li = scale * spectrum.Sample(lambda) / dist²
    # spectrum.Sample(lambda) = spectrum.scale * poly(λ) * D65(λ)
    #   For normalized RGB, poly ≈ 0.5 and scale = 2, so Sample ≈ D65(λ)
    #
    # In pbrt-v4, PointLight::Create does:
    #   light_scale = 1 / SpectrumToPhotometric(illuminant)
    # where SpectrumToPhotometric extracts just the D65 illuminant from RGBIlluminantSpectrum
    # and computes InnerProduct(D65, Y) = D65_PHOTOMETRIC
    #
    # So: scale = intensity / D65_PHOTOMETRIC
    scale = Float32(intensity) / Hikari.D65_PHOTOMETRIC

    return Hikari.PointLight(Vec3f(light.position), spectrum, scale)
end

function to_trace_light(light::Makie.SunSkyLight)
    # Convert Makie's SunSkyLight to Hikari's SunSkyLight
    # Hikari expects sun_intensity as an RGBSpectrum, scaled by the intensity multiplier
    sun_intensity = Hikari.RGBSpectrum(light.intensity)
    ground_albedo = Hikari.RGBSpectrum(light.ground_albedo.r, light.ground_albedo.g, light.ground_albedo.b)
    return Hikari.SunSkyLight(
        Vec3f(light.direction),
        sun_intensity;
        turbidity=light.turbidity,
        ground_albedo=ground_albedo,
        ground_enabled=light.ground_enabled,
    )
end

function to_trace_light(light::Makie.DirectionalLight)
    # Convert Makie's DirectionalLight to Hikari's DirectionalLight
    # Makie direction points TO light, Hikari direction is direction light TRAVELS
    # So we need to negate
    transform = Hikari.Transformation(Mat4f(I))
    return Hikari.DirectionalLight(
        transform,
        to_spectrum(light.color),
        -Vec3f(light.direction),  # Negate: Makie points TO light, Hikari is travel direction
    )
end

function to_trace_light(light::Makie.EnvironmentLight)
    # Convert Makie's EnvironmentLight to Hikari's EnvironmentLight
    # Makie stores RGBf matrix, Hikari needs RGBSpectrum matrix
    data = map(c -> Hikari.RGBSpectrum(c.r, c.g, c.b), light.image)
    # Build rotation matrix from axis-angle
    rotation = Hikari.rotation_matrix(light.rotation_angle, light.rotation_axis)
    env_map = Hikari.EnvironmentMap(data, rotation)
    # Apply photometric normalization to match pbrt-v4:
    # pbrt-v4 divides scale by SpectrumToPhotometric(&colorSpace->illuminant)
    # which normalizes radiance to be equivalent to 1 nit
    photometric_scale = light.intensity / Hikari.D65_PHOTOMETRIC
    return Hikari.EnvironmentLight(env_map, Hikari.RGBSpectrum(photometric_scale))
end

function to_trace_light(light)
    return nothing
end

function to_trace_camera(scene::Makie.Scene, film)
    cc = scene.camera_controls
    # Calculate aspect ratio from film resolution
    aspect = film.resolution[1] / film.resolution[2]
    screen_window = Hikari.Bounds2(Point2f(-aspect, -1.0f0), Point2f(aspect, 1.0f0))

    return lift(scene, cc.eyeposition, cc.lookat, cc.upvector, cc.fov) do eyeposition, lookat, upvector, fov
        view = Hikari.look_at(
            Point3f(eyeposition), Point3f(lookat), Vec3f(upvector),
        )
        return Hikari.PerspectiveCamera(
            view, screen_window,
            0.0f0, 1.0f0, 0.0f0, 1.0f6, Float32(fov),
            film
        )
    end
    return
end

"""
    build_materials_tuple(materials_list::Vector{<:Hikari.Material}) -> Tuple

Group materials by type into a tuple of vectors for MaterialScene.
"""
function build_materials_tuple(materials_list::Vector)
    if isempty(materials_list)
        return (Hikari.MatteMaterial[],)
    end

    # Group by type
    type_to_materials = Dict{DataType, Vector}()
    type_order = DataType[]

    for mat in materials_list
        T = typeof(mat)
        if !haskey(type_to_materials, T)
            type_to_materials[T] = T[]
            push!(type_order, T)
        end
        push!(type_to_materials[T], mat)
    end

    # Build tuple in order
    return Tuple([type_to_materials[T] for T in type_order])
end

"""
    collect_all_plots!(plots::Vector{Makie.AbstractPlot}, scene::Makie.Scene)

Recursively collect all plots from a scene tree, including plots in child scenes.
This handles LScene and other nested scene structures.
"""
function collect_all_plots!(plots::Vector{Makie.AbstractPlot}, scene::Makie.Scene)
    append!(plots, scene.plots)
    for child in scene.children
        collect_all_plots!(plots, child)
    end
    return plots
end

"""
    find_3d_scene(scene::Makie.Scene) -> Union{Makie.Scene, Nothing}

Find the first scene in the tree that has a 3D camera (Camera3D).
This is needed when using LScene, where the actual 3D scene with camera
is nested inside the figure's root scene.
"""
function find_3d_scene(scene::Makie.Scene)
    cc = scene.camera_controls
    if hasproperty(cc, :eyeposition)
        return scene
    end
    for child in scene.children
        result = find_3d_scene(child)
        if !isnothing(result)
            return result
        end
    end
    return nothing
end

"""
    convert_scene_with_state(scene::Makie.Scene, backend::Type=Array, integrator=Whitted()) -> TraceMakieState

Convert a Makie scene to a TraceMakieState that supports dynamic transform updates.
Automatically watches plot transformations and syncs to TLAS.

The `backend` parameter specifies the array type:
- `Array` (default): CPU rendering
- `ROCArray`: AMD GPU rendering
- `CuArray`: NVIDIA GPU rendering

The `integrator` parameter affects how Volume plots are converted:
- For VolPath: Creates GridMedium + MediumInterface for proper volumetric path tracing
- For other integrators: Creates CloudVolume for ray marching
"""
function convert_scene_with_state(mscene::Makie.Scene, backend::Type=Array, integrator::Hikari.Integrator=Whitted())
    resolution = Point2f(size(mscene))
    film = Hikari.Film(
        resolution;
        filter=Hikari.LanczosSincFilter(Point2f(1.0f0), 3.0f0),
        crop_bounds=Hikari.Bounds2(Point2f(0.0f0), Point2f(1.0f0)),
        diagonal=1.0f0, scale=1.0f0,
    )

    # Create empty Hikari scene with incremental API
    # Uses MultiTypeSet for materials/media which handles MediumInterface conversion
    # Determine KA backend from array type
    ka_backend = if backend === Array
        Raycore.KA.CPU()
    else
        # Create temp array to infer KA backend from array type
        tmp = backend{Float32}(undef, 1)
        Raycore.KA.get_backend(tmp)
    end
    hikari_scene = Hikari.Scene(backend=ka_backend)

    # Collect plot results and build scene
    plot_infos = PlotInfo[]
    # Material index is UInt32 (index into scene.media_interfaces)
    plot_to_material = Dict{Makie.AbstractPlot, Tuple{Hikari.Material, UInt32}}()
    handle_idx = 0

    for plot in Makie.collect_atomic_plots(mscene)
        result = if plot isa Makie.Volume
            to_trace_primitive_with_transform(plot, integrator)
        else
            to_trace_primitive_with_transform(plot)
        end

        if isnothing(result)
            continue
        end

        if result isa MeshScatterResult
            n_instances = length(result.transforms)
            has_per_instance_mats = result.materials isa Vector

            if has_per_instance_mats
                # Each instance has its own material
                first_handle = nothing
                first_descriptor_idx = length(hikari_scene.accel.instances) + 1
                for (transform, mat) in zip(result.transforms, result.materials)
                    mat_idx = push!(hikari_scene, mat)
                    handle = push!(hikari_scene.accel, result.mesh, mat_idx, transform)
                    if isnothing(first_handle)
                        first_handle = handle
                    end
                end
                handle_idx += n_instances
                info = PlotInfo(plot, first_handle, Makie.transformationmatrix(plot),
                               Observables.ObserverFunction[], n_instances, true, first_descriptor_idx)
                push!(plot_infos, info)
                plot_to_material[plot] = (first(result.materials), push!(hikari_scene, first(result.materials)))
            else
                # All instances share one material - use batched instancing
                mat_idx = push!(hikari_scene, result.materials)
                first_descriptor_idx = length(hikari_scene.accel.instances) + 1
                # Push mesh with multiple transforms
                handle = push!(hikari_scene.accel, Raycore.Instance(result.mesh, result.transforms,
                              [mat_idx for _ in 1:n_instances]))
                handle_idx += 1
                info = PlotInfo(plot, handle, Makie.transformationmatrix(plot),
                               Observables.ObserverFunction[], n_instances, false, first_descriptor_idx)
                push!(plot_infos, info)
                plot_to_material[plot] = (result.materials, mat_idx)
            end

        elseif result isa Vector
            # Multiple meshes from one plot
            first_handle = nothing
            first_mat = nothing
            first_mat_idx = nothing
            first_descriptor_idx = length(hikari_scene.accel.instances) + 1
            for (mesh, mat, transform) in result
                mat_idx = push!(hikari_scene, mat)
                handle = push!(hikari_scene.accel, mesh, mat_idx, transform)
                if isnothing(first_handle)
                    first_handle = handle
                    first_mat = mat
                    first_mat_idx = mat_idx
                end
            end
            handle_idx += length(result)
            info = PlotInfo(plot, first_handle, Makie.transformationmatrix(plot),
                           Observables.ObserverFunction[], length(result), false, first_descriptor_idx)
            push!(plot_infos, info)
            if !isnothing(first_mat)
                plot_to_material[plot] = (first_mat, first_mat_idx)
            end

        else
            # Single mesh
            mesh, mat, transform = result
            first_descriptor_idx = length(hikari_scene.accel.instances) + 1
            mat_idx = push!(hikari_scene, mat)
            handle = push!(hikari_scene.accel, mesh, mat_idx, transform)
            handle_idx += 1
            info = PlotInfo(plot, handle, Makie.transformationmatrix(plot),
                           Observables.ObserverFunction[], 1, false, first_descriptor_idx)
            push!(plot_infos, info)
            plot_to_material[plot] = (mat, mat_idx)
        end
    end

    # Build TLAS BVH structure
    Raycore.sync!(hikari_scene.accel)

    # Find the 3D scene for camera and lights (handles LScene nested structure)
    scene_3d = find_3d_scene(mscene)
    if isnothing(scene_3d)
        error("No 3D scene found in scene tree. TraceMakie requires a scene with a 3D camera (e.g., LScene or Scene with Camera3D).")
    end

    camera = to_trace_camera(scene_3d, film)

    # Extract lights and push to scene
    makie_lights = Makie.get_lights(scene_3d)
    for light in makie_lights
        l = to_trace_light(light)
        if !isnothing(l)
            push!(hikari_scene.lights, l)
        end
    end

    # Add ambient light if present, but skip if we already have SunSkyLight
    has_sunsky = Hikari.SunSkyLight in hikari_scene.lights.data_order
    if !has_sunsky && haskey(scene_3d.compute, :ambient_color)
        ambient_color = scene_3d.compute[:ambient_color][]
        if ambient_color != RGBf(0, 0, 0)
            push!(hikari_scene.lights, Hikari.AmbientLight(to_spectrum(ambient_color)))
        end
    end

    if isempty(hikari_scene.lights)
        error("Must have at least one light")
    end

    # Convert film to GPU if backend is not Array
    # (scene is already created with correct backend above)
    film = Raycore.Adapt.adapt(ka_backend, film)

    # Create overlay buffer matching film size
    film_size = size(film.framebuffer)
    overlay_buffer = fill(RGBA{Float32}(0f0, 0f0, 0f0, 0f0), film_size)

    # Collect overlay plots (lines, scatter, text that weren't converted to ray-traced geometry)
    overlay_plots = collect_overlay_plots(mscene)

    state = TraceMakieState(plot_infos, film, camera, false, hikari_scene, PlotUpdateInfo[], false, overlay_buffer, overlay_plots)

    # Register transform observers
    for info in plot_infos
        obs_func = on(info.transform_obs) do _
            update_plot_transform!(state, info)
        end
        push!(info.obs_funcs, obs_func)
    end

    # Register compute graph updates for each plot
    plot_to_info = Dict{Makie.AbstractPlot, PlotInfo}(info.plot => info for info in plot_infos)
    for (plot, (mat, mat_idx)) in plot_to_material
        if haskey(plot_to_info, plot)
            register_plot_updates!(state, plot_to_info[plot], mat, mat_idx)
        end
    end

    return state
end

"""
    to_trace_primitive_with_transform(plot) -> (mesh, material, transform) or Vector or nothing

Like to_trace_primitive but also extracts the plot's transformation matrix.
"""
function to_trace_primitive_with_transform(plot::Makie.Mesh)
    mesh = plot.mesh[]
    transform = get_plot_transform(plot)

    # Handle MetaMesh with materials
    if mesh isa GeometryBasics.MetaMesh
        results = []

        if haskey(mesh, :material_names) && haskey(mesh, :materials)
            submeshes = GeometryBasics.split_mesh(mesh.mesh)
            material_names = mesh[:material_names]
            materials_dict = mesh[:materials]

            hikari_materials = Dict{String, Any}()
            default_mat = nothing

            for (name, submesh) in zip(material_names, submeshes)
                tmesh = Raycore.TriangleMesh(submesh)

                mat = get!(hikari_materials, name) do
                    if haskey(materials_dict, name)
                        glb_material_to_hikari(materials_dict[name])
                    else
                        if isnothing(default_mat)
                            default_mat = extract_material(plot, plot.color)
                        end
                        default_mat
                    end
                end

                push!(results, (tmesh, mat, transform))
            end
        else
            tmesh = Raycore.TriangleMesh(mesh.mesh)
            mat = extract_material(plot, plot.color)
            push!(results, (tmesh, mat, transform))
        end

        return results
    end

    # Regular mesh
    tmesh = Raycore.TriangleMesh(mesh)
    material = extract_material(plot, plot.color)
    return (tmesh, material, transform)
end

function to_trace_primitive_with_transform(plot::Makie.Surface)
    # Surface doesn't support transforms well, fall back to identity
    prim = to_trace_primitive(plot)
    if isnothing(prim)
        return nothing
    end
    # Extract mesh and material from GeometricPrimitive
    return (prim.shape, prim.material, Mat4f(I))
end

function to_trace_primitive_with_transform(plot::Makie.Plot)
    return nothing
end

# =============================================================================
# MeshScatter support - efficient instancing with TLAS
# =============================================================================

"""
    meshscatter_marker_mesh(marker)

Convert a MeshScatter marker to a mesh. Handles geometry primitives and meshes.
"""
function meshscatter_marker_mesh(marker)
    if marker isa GeometryBasics.Mesh
        return marker
    elseif marker isa GeometryBasics.GeometryPrimitive
        return GeometryBasics.normal_mesh(marker)
    elseif marker == :Sphere || marker === Makie.automatic
        return GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1.0f0))
    elseif marker isa Symbol
        # Try to get a builtin marker
        return GeometryBasics.normal_mesh(Makie.default_marker_map()[marker])
    else
        error("Unsupported MeshScatter marker type: $(typeof(marker))")
    end
end

"""
    meshscatter_transforms(positions, markersize, rotation, plot_transform)

Build per-instance transform matrices for MeshScatter.
Each instance gets: plot_transform * translate(position) * scale(markersize) * rotate(rotation)
"""
function meshscatter_transforms(positions, markersize, rotation, plot_transform::Mat4f)
    n = length(positions)

    # Normalize markersize to per-instance Vec3f
    scales = if markersize isa Number
        fill(Vec3f(markersize), n)
    elseif markersize isa VecTypes{3}
        fill(Vec3f(markersize), n)
    elseif markersize isa AbstractVector
        if eltype(markersize) <: Number
            [Vec3f(s) for s in markersize]
        else
            [Vec3f(s) for s in markersize]
        end
    else
        fill(Vec3f(0.1f0), n)  # Default markersize
    end

    # Normalize rotation to per-instance Quaternion
    rotations = if rotation isa Quaternionf
        fill(rotation, n)
    elseif rotation isa Number
        # Rotation around z-axis
        q = Makie.qrotation(Vec3f(0, 0, 1), Float32(rotation))
        fill(q, n)
    elseif rotation isa VecTypes{3}
        # Vec3f interpreted as axis to align z-axis with
        q = Makie.rotation_between(Vec3f(0, 0, 1), Vec3f(rotation))
        fill(q, n)
    elseif rotation isa AbstractVector
        [rotation_to_quaternion(r) for r in rotation]
    else
        fill(Quaternionf(0, 0, 0, 1), n)
    end

    # Build transform matrices
    transforms = Mat4f[]
    for i in 1:n
        pos = positions[i]
        s = scales[min(i, length(scales))]
        r = rotations[min(i, length(rotations))]

        # Build local transform: T * S * R
        # Translation matrix
        T = Mat4f(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            pos[1], pos[2], pos[3], 1
        )
        # Scale matrix
        S = Mat4f(
            s[1], 0, 0, 0,
            0, s[2], 0, 0,
            0, 0, s[3], 0,
            0, 0, 0, 1
        )
        # Rotation matrix from quaternion
        R = Mat4f(Makie.rotationmatrix4(r))

        # Combine: plot_transform * T * R * S
        local_transform = T * R * S
        push!(transforms, plot_transform * local_transform)
    end

    return transforms
end

"""Helper to convert various rotation types to Quaternion."""
function rotation_to_quaternion(r)
    if r isa Quaternionf
        return r
    elseif r isa Number
        return Makie.qrotation(Vec3f(0, 0, 1), Float32(r))
    elseif r isa VecTypes{3}
        return Makie.rotation_between(Vec3f(0, 0, 1), Vec3f(r))
    else
        return Quaternionf(0, 0, 0, 1)
    end
end

"""
    to_trace_primitive_with_transform(plot::Makie.MeshScatter) -> MeshScatterResult

Returns a special result type for MeshScatter with:
- mesh: The marker mesh (single BLAS)
- materials: Either a single material (for all instances) or Vector of per-instance materials
- transforms: Vector of per-instance transforms
"""
struct MeshScatterResult
    mesh::Any
    materials::Union{Hikari.Material, Vector{<:Hikari.Material}}
    transforms::Vector{Mat4f}
end

function to_trace_primitive_with_transform(plot::Makie.MeshScatter)
    # Get positions
    positions = to_value(plot.positions)
    if isempty(positions)
        return nothing
    end

    # Get marker mesh
    marker = to_value(plot.marker)
    mesh = meshscatter_marker_mesh(marker)
    tmesh = Raycore.TriangleMesh(mesh)

    # Get transform parameters
    markersize = to_value(plot.markersize)
    rotation = to_value(plot.rotation)
    plot_transform = get_plot_transform(plot)

    # Build per-instance transforms
    transforms = meshscatter_transforms(positions, markersize, rotation, plot_transform)

    # Get material(s)
    materials = extract_meshscatter_materials(plot, length(positions))

    return MeshScatterResult(tmesh, materials, transforms)
end

"""
Extract materials for meshscatter - returns either single material or per-instance materials.
"""
function extract_meshscatter_materials(plot::Makie.MeshScatter, n_instances::Int)
    color = to_value(plot.color)
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material_template = has_material ? to_value(plot.material) : nothing

    # Check if we have per-instance colors
    if color isa AbstractVector{<:Colorant} && length(color) == n_instances
        # Per-instance colors - create one material per instance
        return [create_material_with_color(to_color(c), material_template) for c in color]
    elseif color isa AbstractVector && length(color) == n_instances
        # Per-instance numeric values - use colormap
        calc_colors = to_value(plot.calculated_colors)
        if calc_colors isa AbstractVector{<:Colorant}
            return [create_material_with_color(to_color(c), material_template) for c in calc_colors]
        end
    end

    # Single material for all instances
    return extract_material(plot, plot.color)
end

"""
Create a material with the given color, optionally based on a template material.
"""
function create_material_with_color(color::Colorant, template::Nothing)
    # Default to MatteMaterial with the color
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

function create_material_with_color(color::Colorant, template::Hikari.MatteMaterial)
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), template.σ)
end

function create_material_with_color(color::Colorant, template::Hikari.MetalMaterial)
    # For metals, color is used as reflectance tint (multiplies Fresnel result)
    # This preserves the physical eta/k values while allowing color variation
    Hikari.MetalMaterial(
        template.eta, template.k, template.roughness,
        Hikari.ConstTexture(to_spectrum(color)),
        template.remap_roughness
    )
end

function create_material_with_color(color::Colorant, template::Hikari.Material)
    # Fallback: use MatteMaterial with the color
    @warn "Unsupported material type $(typeof(template)) for per-instance colors, using MatteMaterial"
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

# Keep the old convert_scene for backwards compatibility
function convert_scene(mscene::Makie.Scene)
    state = convert_scene_with_state(mscene)
    return state.hikari_scene, state.camera, state.film
end

"""
    sync_transforms!(state::TraceMakieState)

Sync all plot transforms to the TLAS and refit.
Call this before rendering if transforms may have changed.

Uses GPU-compatible index-based updates that work on both CPU and GPU TLAS.
"""
function sync_transforms!(state::TraceMakieState)
    tlas = get_tlas(state)
    # Get backend from film's framebuffer (works for both CPU and GPU)
    backend = KernelAbstractions.get_backend(state.film.framebuffer)

    for info in state.plot_infos
        if info.instance_count > 1 && info.plot isa Makie.MeshScatter
            # MeshScatter: update all instance transforms using batch kernel
            sync_meshscatter_transforms!(state, info, backend)
        else
            # Regular plot: single transform update using batch kernel with count=1
            transform = get_plot_transform(info.plot)
            transforms = Adapt.adapt(backend, [transform])
            Raycore.update_instance_transforms!(tlas, transforms, 1, info.first_instance_idx)
        end
    end
    Raycore.refit_tlas!(tlas)
    state.needs_refit = false
end

"""
    sync_meshscatter_transforms!(state::TraceMakieState, info::PlotInfo, backend)

Update all instance transforms for a MeshScatter plot.
Uses GPU-compatible batch kernel with offset support.
"""
function sync_meshscatter_transforms!(state::TraceMakieState, info::PlotInfo, backend)
    plot = info.plot
    positions = to_value(plot.positions)
    markersize = to_value(plot.markersize)
    rotation = to_value(plot.rotation)
    plot_transform = get_plot_transform(plot)

    # Compute transforms on CPU
    transforms_cpu = meshscatter_transforms(positions, markersize, rotation, plot_transform)

    # Convert to appropriate backend array type
    transforms = KernelAbstractions.allocate(backend, Mat4f, length(transforms_cpu))
    copyto!(transforms, transforms_cpu)

    # Use batch kernel with offset (works on CPU and GPU)
    tlas = get_tlas(state)
    Raycore.update_instance_transforms!(tlas, transforms, info.instance_count, info.first_instance_idx)
end

"""
    render_frame!(state::TraceMakieState; samples=1, max_depth=5) -> Matrix

Render a single frame using the current state. Syncs transforms and refits TLAS if needed.
"""
function render_frame!(state::TraceMakieState; samples=1, max_depth=5)
    refit_if_needed!(state)
    Hikari.clear!(state.film)
    integrator = Hikari.Whitted(samples=samples, max_depth=max_depth)
    integrator(state.hikari_scene, state.film, state.camera[])
    return state.film.framebuffer
end

# Export TraceMakie-specific types
export Screen, ScreenConfig, Whitted, activate!, colorbuffer

# Re-export DenoiseConfig from Hikari for convenience
const DenoiseConfig = Hikari.DenoiseConfig
export DenoiseConfig

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

end
