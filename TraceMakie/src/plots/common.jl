# =============================================================================
# Common helpers for TraceMakie plot conversion
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
function build_vertex_color_texture(vertex_colors::AbstractVector{<:Colorant}, mesh::Raycore.TriangleMesh)
    n_faces = div(length(mesh.indices), 3)
    face_colors = Matrix{Hikari.RGBSpectrum}(undef, 3, n_faces)
    for f in 1:n_faces
        base = 3 * (f - 1)
        for v in 1:3
            face_colors[v, f] = to_spectrum(vertex_colors[mesh.indices[base + v]])
        end
    end
    return Hikari.VertexColorTexture(face_colors, Int32(n_faces))
end

# =============================================================================
# Material merging — combine color texture with existing material
# =============================================================================

function merge_color_with_material(color_tex, material::Hikari.MatteMaterial)
    Hikari.MatteMaterial(color_tex, material.σ)
end

function merge_color_with_material(color_tex, material::Hikari.MirrorMaterial)
    Hikari.MirrorMaterial(color_tex)
end

function merge_color_with_material(color_tex, material::Hikari.GlassMaterial)
    Hikari.GlassMaterial(
        material.Kr, color_tex,
        material.u_roughness, material.v_roughness,
        material.index, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.ConductorMaterial)
    Hikari.ConductorMaterial(material.eta, material.k, material.roughness, color_tex, material.remap_roughness)
end

function merge_color_with_material(color_tex, material::Hikari.CoatedDiffuseMaterial)
    Hikari.CoatedDiffuseMaterial(
        color_tex, material.u_roughness, material.v_roughness, material.thickness,
        material.eta, material.albedo, material.g, material.max_depth, material.n_samples, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.ThinDielectricMaterial)
    material
end

function merge_color_with_material(color_tex, material::Hikari.DiffuseTransmissionMaterial)
    Hikari.DiffuseTransmissionMaterial(
        color_tex, material.transmittance, material.scale
    )
end

function merge_color_with_material(color_tex, material::Hikari.CoatedDiffuseTransmissionMaterial)
    Hikari.CoatedDiffuseTransmissionMaterial(
        color_tex, material.transmittance, material.u_roughness, material.v_roughness, material.thickness,
        material.eta, material.albedo, material.g, material.max_depth, material.n_samples, material.remap_roughness
    )
end

function merge_color_with_material(color_tex, material::Hikari.CoatedConductorMaterial)
    material
end

function merge_color_with_material(color_tex, material::Hikari.MediumInterface)
    merged_inner = merge_color_with_material(color_tex, material.material)
    Hikari.MediumInterface(merged_inner; inside=material.inside, outside=material.outside)
end

function merge_color_with_material(color_tex, material::Hikari.EmissiveMaterial)
    Hikari.EmissiveMaterial(color_tex, material.scale, material.two_sided)
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
        return Hikari.MatteMaterial(tex, Hikari.ConstTexture(0.0f0))
    else
        error("Neither color nor material are defined for plot: $plot")
    end
end

# Convert color values to Hikari textures via multiple dispatch
color_to_texture(color::AbstractMatrix{<:Number}, plot) = Hikari.Texture(to_spectrum(Makie.compute_colors(plot.attributes)))
color_to_texture(color::AbstractMatrix{<:Colorant}, ::Any) = Hikari.Texture(to_spectrum(color))
color_to_texture(color::AbstractVector{<:Colorant}, ::Any) = color  # handled in mesh.jl via build_vertex_color_texture
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

"""
Extract the diffuse color texture from a GLB material dictionary.
Returns a Hikari texture (Texture or ConstTexture) or nothing if no diffuse info is present.
"""
function extract_glb_texture(mat_dict::Dict{String, Any})
    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            return Hikari.Texture(to_spectrum(diffuse_map["image"]))
        end
    end
    if haskey(mat_dict, "diffuse")
        diffuse = mat_dict["diffuse"]
        return Hikari.ConstTexture(to_spectrum(RGBf(diffuse[1], diffuse[2], diffuse[3])))
    end
    return nothing
end

function _has_nonzero_emissive(mat_dict::Dict{String, Any})
    if haskey(mat_dict, "emissive")
        e = mat_dict["emissive"]
        return any(x -> x > 0, e)
    end
    return false
end

function glb_material_to_hikari(mat_dict::Dict{String, Any})
    # Check for emissive properties first
    has_emissive_map = haskey(mat_dict, "emissive map")
    has_emissive = _has_nonzero_emissive(mat_dict) || has_emissive_map

    if has_emissive
        # Build emissive Le texture
        if has_emissive_map
            emissive_map = mat_dict["emissive map"]
            if haskey(emissive_map, "image")
                Le_tex = Hikari.Texture(to_spectrum(emissive_map["image"]))
                # Apply emissive factor as scale if present
                emissive_factor = get(mat_dict, "emissive", [1.0, 1.0, 1.0])
                scale = max(emissive_factor[1], emissive_factor[2], emissive_factor[3])
                return Hikari.EmissiveMaterial(Le_tex, Float32(max(scale, 1f0)), true)
            end
        end
        # Emissive color only (no map)
        if haskey(mat_dict, "emissive")
            e = mat_dict["emissive"]
            Le_tex = Hikari.ConstTexture(Hikari.RGBSpectrum(Float32(e[1]), Float32(e[2]), Float32(e[3])))
            return Hikari.EmissiveMaterial(Le_tex, 1f0, true)
        end
    end

    # Non-emissive: diffuse material
    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            img = diffuse_map["image"]
            tex = Hikari.Texture(to_spectrum(img))
            roughness = get(mat_dict, "roughness", 0.5f0)
            return Hikari.MatteMaterial(tex, Hikari.ConstTexture(Float32(roughness) * 90f0))
        end
    end

    if haskey(mat_dict, "diffuse")
        diffuse = mat_dict["diffuse"]
        color = RGBf(diffuse[1], diffuse[2], diffuse[3])
        tex = Hikari.ConstTexture(to_spectrum(color))
        roughness = get(mat_dict, "roughness", 0.5f0)
        return Hikari.MatteMaterial(tex, Hikari.ConstTexture(Float32(roughness) * 90f0))
    end

    return Hikari.MatteMaterial(
        Hikari.ConstTexture(Hikari.RGBSpectrum(0.8f0, 0.8f0, 0.8f0)),
        Hikari.ConstTexture(0.0f0)
    )
end

# =============================================================================
# Per-instance material creation (for meshscatter)
# =============================================================================

function create_material_with_color(color::Colorant, template::Nothing)
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

function create_material_with_color(color::Colorant, template::Hikari.MatteMaterial)
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), template.σ)
end

function create_material_with_color(color::Colorant, template::Hikari.ConductorMaterial)
    Hikari.ConductorMaterial(
        template.eta, template.k, template.roughness,
        Hikari.ConstTexture(to_spectrum(color)),
        template.remap_roughness
    )
end

function create_material_with_color(color::Colorant, template::Hikari.Material)
    @warn "Unsupported material type $(typeof(template)) for per-instance colors, using MatteMaterial"
    Hikari.MatteMaterial(Hikari.ConstTexture(to_spectrum(color)), Hikari.ConstTexture(0.0f0))
end

# =============================================================================
# Material texture extraction (for in-place color updates)
# =============================================================================

_get_material_texture(mat::Hikari.MatteMaterial) = mat.Kd isa Hikari.Texture ? mat.Kd : nothing
_get_material_texture(mat::Hikari.ConductorMaterial) = mat.reflectance isa Hikari.Texture ? mat.reflectance : nothing
_get_material_texture(mat::Hikari.Material) = nothing

# In-place texture data update via dispatch
_update_texture!(tex::Hikari.Texture, color::AbstractMatrix{<:Colorant}) = (tex.data = to_spectrum(color))
_update_texture!(tex::Hikari.Texture, color::AbstractVector{<:Colorant}) = (tex.data = to_spectrum.(color))
_update_texture!(tex::Hikari.Texture, color::Colorant) = fill!(tex.data, to_spectrum(to_color(color)))

# =============================================================================
# Transform helpers
# =============================================================================

function get_plot_transform(plot::Makie.AbstractPlot)
    return Mat4f(Makie.transformationmatrix(plot)[])
end
