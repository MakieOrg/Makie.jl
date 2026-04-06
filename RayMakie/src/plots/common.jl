# =============================================================================
# Common helpers for RayMakie plot conversion
# =============================================================================

# =============================================================================
# Color/Spectrum conversion
# =============================================================================

function to_spectrum(data::TransparentColor)
    rgb = RGBf(data)
    Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b, Float32(Colors.alpha(data)))
end
function to_spectrum(data::Color)
    rgb = RGBf(data)
    Hikari.RGBSpectrum(rgb.r, rgb.g, rgb.b, 1f0)
end
to_spectrum(data::AbstractMatrix{<:Colorant}) = map(to_spectrum, data)

# =============================================================================
# Per-vertex color → VertexColorTexture
# =============================================================================

"""
Build a VertexColorTexture from per-vertex colors and a triangle mesh.
Creates a (3, n_faces) matrix where each column stores the 3 vertex colors for that face,
enabling proper barycentric interpolation during rendering.
"""
function build_vertex_color_texture(vertex_colors::AbstractVector{<:Colorant}, mesh::GeometryBasics.Mesh)
    gb_faces = GeometryBasics.faces(mesh)
    n_faces = length(gb_faces)
    face_colors = Matrix{Hikari.RGBSpectrum}(undef, 3, n_faces)
    for (f, face) in enumerate(gb_faces)
        for v in 1:3
            face_colors[v, f] = to_spectrum(vertex_colors[face[v]])
        end
    end
    return Hikari.VertexColorTexture(face_colors, Int32(n_faces))
end

# =============================================================================
# Material merging — combine color texture with existing material
# =============================================================================

function merge_color_with_material(color_tex, material::Hikari.Diffuse)
    Hikari.Diffuse(color_tex, material.σ)
end

function merge_color_with_material(color_tex, material::Hikari.Mirror)
    Hikari.Mirror(color_tex)
end

function merge_color_with_material(color_tex, material::Hikari.Dielectric)
    Hikari.Dielectric(
        material.Kr, color_tex,
        material.u_roughness, material.v_roughness,
        material.index, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.Conductor)
    Hikari.Conductor(material.eta, material.k, material.roughness, color_tex, material.remap_roughness)
end

function merge_color_with_material(color_tex, material::Hikari.CoatedDiffuse)
    Hikari.CoatedDiffuse(
        color_tex, material.u_roughness, material.v_roughness, material.thickness,
        material.eta, material.albedo, material.g, material.max_depth, material.n_samples, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.ThinDielectric)
    material
end

function merge_color_with_material(color_tex, material::Hikari.DiffuseTransmission)
    Hikari.DiffuseTransmission(
        color_tex, material.transmittance, material.scale
    )
end

function merge_color_with_material(color_tex, material::Hikari.CoatedDiffuseTransmission)
    Hikari.CoatedDiffuseTransmission(
        color_tex, material.transmittance, material.u_roughness, material.v_roughness, material.thickness,
        material.eta, material.albedo, material.g, material.max_depth, material.n_samples, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.CoatedConductor)
    material
end

function merge_color_with_material(color_tex, material::Hikari.MediumInterface)
    merged_inner = merge_color_with_material(color_tex, material.material)
    Hikari.MediumInterface(merged_inner; inside=material.inside, outside=material.outside, emission=material.emission)
end

# Fallback for unknown material types
function merge_color_with_material(color_tex, material::Hikari.Material)
    @warn "Unknown material type $(typeof(material)), ignoring color"
    material
end

# =============================================================================
# Material extraction
# =============================================================================

function extract_material(plot::Plot, tex::Union{Hikari.Texture, Hikari.VertexColorTexture, Nothing})
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material = has_material ? to_value(plot.material) : nothing

    if material isa Hikari.Material && !isnothing(tex)
        # MediumInterface with emission: always merge the color into the base material.
        # This lets users combine colormap/color with emissive overlays, e.g.
        # surface!(...; colormap=..., material=MediumInterface(Diffuse(); emission=Emissive(...)))
        if material isa Hikari.MediumInterface && material.emission !== nothing
            return merge_color_with_material(tex, material)
        end
        # If material was set post-construction (not in inputs), it's a deliberate
        # user override (e.g. recipe_plot.plots[1].material = my_mat) and should
        # always take priority over any colors, including recipe-assigned ones.
        material_in_inputs = haskey(plot.attributes.inputs, :material) && plot.attributes.inputs[:material].value !== nothing
        if !material_in_inputs
            return material
        end
        # Both material and color were provided in the constructor - merge them.
        color_explicitly_set = haskey(plot.attributes.inputs, :color) && plot.attributes.inputs[:color].value !== nothing
        color_explicitly_set || return material
        return merge_color_with_material(tex, material)
    elseif material isa Hikari.Material
        return material
    elseif !isnothing(tex)
        return Hikari.Diffuse(tex, Hikari.ConstTexture(0.0f0))
    else
        error("Neither color nor material are defined for plot: $plot")
    end
end

# Convert color values to Hikari textures via multiple dispatch
color_to_texture(color::AbstractMatrix{<:Number}, plot) = Hikari.Texture(to_spectrum(Makie.compute_colors(plot.attributes)))
color_to_texture(color::AbstractMatrix{<:Colorant}, ::Any) = color isa Makie.LinePattern ? Hikari.ConstTexture(to_spectrum(RGBf(1,1,1))) : Hikari.Texture(to_spectrum(color))
color_to_texture(color::AbstractVector{<:Colorant}, ::Any) = color  # handled in mesh.jl via build_vertex_color_texture
function color_to_texture(color::AbstractVector{<:Number}, plot)
    # Map scalar per-vertex values through the colormap to produce per-vertex Colorant colors.
    # Cannot rely on compute_colors here as it may produce a 2D texture matrix
    # which requires UV coordinates the mesh doesn't have.
    cmap_raw = to_value(get(plot, :colormap, :viridis))
    cmap = Makie.to_colormap(cmap_raw isa Makie.Automatic ? :viridis : cmap_raw)
    crange = to_value(get(plot, :colorrange, nothing))
    lo, hi = if crange isa Makie.Automatic || isnothing(crange)
        extrema(color)
    else
        Float32(crange[1]), Float32(crange[2])
    end
    n = length(cmap)
    scale = hi == lo ? 0f0 : 1f0 / (hi - lo)
    return map(color) do val
        t = clamp((val - lo) * scale, 0f0, 1f0)
        idx = clamp(round(Int, t * (n - 1)) + 1, 1, n)
        cmap[idx]
    end
end
color_to_texture(color::Colorant, ::Any) = Hikari.ConstTexture(to_spectrum(to_color(color)))
color_to_texture(color::Union{String,Symbol}, ::Any) = Hikari.ConstTexture(to_spectrum(to_color(color)))
function color_to_texture(::Nothing, plot)
    # color=nothing means use colormapping pipeline (e.g. surface z-values)
    computed = Makie.compute_colors(plot.attributes)
    isnothing(computed) && return nothing
    return Hikari.Texture(to_spectrum(computed))
end

function extract_material(plot::Plot, color_obs::Union{Makie.Computed, Observable})
    color = to_value(color_obs)

    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material = has_material ? to_value(plot.material) : nothing

    # If material was set post-construction (not in inputs), it's a deliberate
    # user override and should always take priority over any colors.
    if material isa Hikari.Material
        material_in_inputs = haskey(plot.attributes.inputs, :material) && plot.attributes.inputs[:material].value !== nothing
        if !material_in_inputs
            return material
        end
        # Both were in constructor - only merge if color was also explicitly set
        color_explicitly_set = haskey(plot.attributes.inputs, :color) && plot.attributes.inputs[:color].value !== nothing
        if !color_explicitly_set
            return material
        end
    end

    tex = color_to_texture(color, plot)
    return extract_material(plot, tex)
end

# =============================================================================
# GLB material conversion
# =============================================================================

function has_nonzero_emissive(mat_dict::Dict{String, Any})
    if haskey(mat_dict, "emissive")
        e = mat_dict["emissive"]
        return any(x -> x > 0, e)
    end
    return false
end

"""
    build_emission_info(mat_dict) -> NamedTuple or nothing

Extract emission info (Le texture, scale, two_sided) from a GLTF material dict.
Used later for DiffuseAreaLight registration during mesh push.
"""
function build_emission_info(mat_dict::Dict{String, Any})
    has_emissive_map = haskey(mat_dict, "emissive map")
    if has_emissive_map
        emissive_map = mat_dict["emissive map"]
        if haskey(emissive_map, "image")
            Le_tex = Hikari.Texture(to_spectrum(emissive_map["image"]))
            emissive_factor = get(mat_dict, "emissive", [1.0, 1.0, 1.0])
            scale = max(emissive_factor[1], emissive_factor[2], emissive_factor[3])
            return (Le=Le_tex, scale=Float32(max(scale, 1f0)), two_sided=true)
        end
    end
    if haskey(mat_dict, "emissive")
        e = mat_dict["emissive"]
        Le = Hikari.RGBSpectrum(Float32(e[1]), Float32(e[2]), Float32(e[3]))
        return (Le=Le, scale=1f0, two_sided=true)
    end
    return nothing
end

function build_diffuse_material(mat_dict::Dict{String, Any})
    roughness = Float32(get(mat_dict, "roughness", 0.5f0))

    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            img = diffuse_map["image"]
            tex = Hikari.Texture(to_spectrum(img))
            # Textured materials use Diffuse (supports stochastic alpha pass-through)
            return Hikari.Diffuse(tex, Hikari.ConstTexture(roughness * 90f0))
        end
    end

    # Constant color: use explicit diffuse or GLTF default white (1,1,1)
    diffuse = get(mat_dict, "diffuse", Vec3f(1, 1, 1))
    color = RGBf(diffuse[1], diffuse[2], diffuse[3])
    tex = Hikari.ConstTexture(to_spectrum(color))

    # CoatedDiffuse gives proper GLTF PBR appearance (Fresnel specular + diffuse)
    return Hikari.CoatedDiffuse(reflectance=tex, roughness=roughness)
end

"""
    glb_material_to_hikari(mat_dict) -> (material, emission_info)

Convert a GLTF material dict to a Hikari BSDF material and optional emission info.
Returns a tuple: (material::Material, emission::NamedTuple or nothing).
Emission info is used later during mesh push to create DiffuseAreaLights.
"""
function glb_material_to_hikari(mat_dict::Dict{String, Any})
    diffuse_mat = build_diffuse_material(mat_dict)
    has_emissive = has_nonzero_emissive(mat_dict) || haskey(mat_dict, "emissive map")
    emission_info = has_emissive ? build_emission_info(mat_dict) : nothing
    return (material=diffuse_mat, emission=emission_info)
end

# =============================================================================
# Per-instance material creation (for meshscatter)
# =============================================================================

function create_material_with_color(color::Colorant, template::Nothing)
    Hikari.Diffuse(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

function create_material_with_color(color::Colorant, template::Hikari.Diffuse)
    Hikari.Diffuse(Hikari.ConstTexture(to_spectrum(color)), template.σ)
end

function create_material_with_color(color::Colorant, template::Hikari.Conductor)
    Hikari.Conductor(
        template.eta, template.k, template.roughness,
        Hikari.ConstTexture(to_spectrum(color)),
        template.remap_roughness
    )
end

function create_material_with_color(color::Colorant, template::Hikari.Material)
    @warn "Unsupported material type $(typeof(template)) for per-instance colors, using Diffuse"
    Hikari.Diffuse(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

# =============================================================================
# Material texture extraction (for in-place color updates)
# =============================================================================

get_material_texture(mat::Hikari.Diffuse) = mat.Kd isa Hikari.Texture ? mat.Kd : nothing
get_material_texture(mat::Hikari.Conductor) = mat.reflectance isa Hikari.Texture ? mat.reflectance : nothing
get_material_texture(mat::Hikari.Material) = nothing

# In-place texture data update via dispatch
update_texture!(tex::Hikari.Texture, color::AbstractMatrix{<:Colorant}) = (tex.data = to_spectrum(color))
update_texture!(tex::Hikari.Texture, color::AbstractVector{<:Colorant}) = (tex.data = to_spectrum.(color))
update_texture!(tex::Hikari.Texture, color::Colorant) = fill!(tex.data, to_spectrum(to_color(color)))

# =============================================================================
# Transform helpers
# =============================================================================

function get_plot_transform(plot::Makie.AbstractPlot)
    return Mat4f(Makie.transformationmatrix(plot)[])
end
