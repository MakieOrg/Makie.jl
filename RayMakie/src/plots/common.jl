# =============================================================================
# Common helpers for RayMakie plot conversion
# =============================================================================

# =============================================================================
# Color/Spectrum conversion
# =============================================================================

# A Makie colour is sRGB-encoded: it is what GLMakie and CairoMakie put on the
# screen as is, and what RayMakie's overlays and composite do too (see
# `COMPOSITE_FORMAT`). A reflectance is linear, and the film encodes the traced
# image for display once more at the end. Handing the encoded value to Hikari as
# the reflectance brightened every colour: `RGBf(0.3, 0.2, 0.1)` under a unit
# ambient light came back as (0.65, 0.56, 0.38), and a dark skin tone projected
# from a photo rendered pale. Alpha is coverage, not light, and is not encoded.
function to_spectrum(data::Colorant)
    rgb = RGBf(data)
    Hikari.RGBSpectrum(Hikari.srgb_gamma_to_linear(rgb.r), Hikari.srgb_gamma_to_linear(rgb.g),
                       Hikari.srgb_gamma_to_linear(rgb.b), Float32(Colors.alpha(data)))
end
to_spectrum(data::AbstractMatrix{<:Colorant}) = map(to_spectrum, data)

# 8-bit textures (every PNG and glTF image) take a 256-entry decode table and
# all threads: per pixel `srgb_gamma_to_linear` made a 4096² texture cost 0.65 s,
# which is most of a frame when a texture is animated. Same values as above.
function to_spectrum(data::AbstractMatrix{<:Union{AbstractRGB{N0f8}, TransparentRGB{<:AbstractRGB{N0f8}}}})
    lut = [Hikari.srgb_gamma_to_linear(Float32(reinterpret(N0f8, UInt8(i)))) for i in 0:255]
    decode(x::N0f8) = @inbounds lut[reinterpret(x) + 1]
    out = similar(data, Hikari.RGBSpectrum)
    Threads.@threads for i in eachindex(data, out)
        c = @inbounds data[i]
        @inbounds out[i] = Hikari.RGBSpectrum(decode(red(c)), decode(green(c)), decode(blue(c)), Float32(Colors.alpha(c)))
    end
    return out
end

# A colour that is linear already: glTF's `baseColorFactor` is, by the spec,
# where its `baseColorTexture` is sRGB.
linear_spectrum(c) = Hikari.RGBSpectrum(Float32(c[1]), Float32(c[2]), Float32(c[3]), 1f0)

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

# Material merging moved to `Hikari/src/materials/merge-color.jl`: which field
# of a material is its colour is Hikari's business, and keeping a second copy
# here went stale the moment a material gained a field — `displacement` was
# added to six of them and none were updated, which turned every coloured plot
# into a `MethodError` reported as "failed to resolve trace_renderobject".
const merge_color_with_material = Hikari.merge_color_with_material

# =============================================================================
# Material extraction
# =============================================================================

"""
    color_was_set(plot) -> Bool

Whether the user actually gave this plot a `color`.

`color` is a cycled attribute, so Makie always leaves a value in
`attributes.inputs`: `resolve_cycled!` writes the symbol `:cycled` for every
cycled attribute that was *not* assigned. Testing `!== nothing` therefore reports
every plot as coloured.
"""
function color_was_set(plot::Plot)
    haskey(plot.attributes.inputs, :color) || return false
    value = plot.attributes.inputs[:color].value
    return value !== nothing && value !== :cycled
end

"""Whether the plot's colour is only the cycler's default, which no one chose. A surface's
unset colour is `nothing` instead, and is its colormapped values."""
color_cycled(plot::Plot) = haskey(plot.attributes.inputs, :color) && plot.attributes.inputs[:color].value === :cycled

function extract_material(plot::Plot, tex::Union{Hikari.Texture, Hikari.VertexColorTexture, Nothing})
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material = has_material ? to_value(plot.material) : nothing

    if material isa Hikari.Material && !isnothing(tex)
        # MediumInterface with emission: merge the color into the base material.
        # This lets users combine colormap/color with emissive overlays, e.g.
        # surface!(...; colormap=..., material=MediumInterface(Diffuse(); emission=Emission(...)))
        # The cycler's palette colour is no colour (see below): with it the material
        # keeps its own surface. Merging it painted a textured emissive mix, an Earth
        # with city lights, in the palette's blue.
        if material isa Hikari.MediumInterface && material.emission !== nothing
            return color_cycled(plot) ? material : merge_color_with_material(tex, material)
        end
        # If material was set post-construction (not in inputs), it's a deliberate
        # user override (e.g. recipe_plot.plots[1].material = my_mat) and should
        # always take priority over any colors, including recipe-assigned ones.
        material_in_inputs = haskey(plot.attributes.inputs, :material) && plot.attributes.inputs[:material].value !== nothing
        if !material_in_inputs
            return material
        end
        # Both material and color were provided in the constructor - merge them.
        #
        # "Not set" is `:cycled`, not `nothing`: Makie's `resolve_cycled!` writes
        # that symbol into every cycled attribute the user did NOT assign, so a
        # `!== nothing` test calls an unset colour explicit and merges the palette
        # colour over the material. That made `material = Diffuse(color = green)`
        # silently render in the cycler's blue — the material was accepted,
        # converted, uploaded, and then overwritten.
        color_explicitly_set = color_was_set(plot)
        color_explicitly_set || return material
        return merge_color_with_material(tex, material)
    elseif material isa Hikari.Material
        return material
    elseif !isnothing(tex)
        return Hikari.Diffuse(color = tex, roughness = 0.0f0)
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
# glTF material conversion
# =============================================================================

"""A glTF material's image as Hikari samples it: colour textures decoded from sRGB, data textures as they are."""
gltf_image(::Nothing; srgb::Bool) = nothing
gltf_image(entry; srgb::Bool) = srgb ? Hikari.Texture(to_spectrum(entry["image"])) : Hikari.to_texture(entry["image"])
gltf_image(mat_dict, key; srgb::Bool) = gltf_image(get(mat_dict, key, nothing); srgb)

"""
    glb_material_to_hikari(mat_dict) -> (material, emission)

A glTF material dict (MeshIO's) as Hikari's `GLTF` material, which renders as Blender's glTF
importer makes it, and its emission as an `Emission`, or `nothing`. The emission is left out of the
`GLTF` and goes to the mesh as area lights instead, which light the scene directly. An emissive
colour of one is one nit, as Hikari normalizes every emitter.
"""
function glb_material_to_hikari(mat_dict::Dict{String, Any})
    diffuse = get(mat_dict, "diffuse", Vec3f(1, 1, 1))
    material = Hikari.GLTF(;
        base_color_factor = (diffuse[1], diffuse[2], diffuse[3], get(mat_dict, "alpha", 1.0f0)),
        base_color_texture = gltf_image(mat_dict, "diffuse map"; srgb = true),
        metallic_factor = get(mat_dict, "metallic", 1.0f0),
        roughness_factor = get(mat_dict, "roughness", 1.0f0),
        metallic_roughness_texture = gltf_image(mat_dict, "metallic roughness map"; srgb = false),
        normal_texture = gltf_image(mat_dict, "normal map"; srgb = false),
        alpha_mode = Symbol(lowercase(get(mat_dict, "alpha mode", "OPAQUE"))),
        alpha_cutoff = get(mat_dict, "alpha cutoff", 0.5f0)
    )
    emissive = get(mat_dict, "emissive", Vec3f(0))
    image = gltf_image(mat_dict, "emissive map"; srgb = true)
    emission = if !isnothing(image)
        Hikari.Emission(color = image, strength = max(maximum(emissive), 1.0f0), two_sided = true)
    elseif any(>(0), emissive)
        Hikari.Emission(color = Hikari.RGBSpectrum(emissive[1], emissive[2], emissive[3]), two_sided = true)
    end
    return (material = material, emission = emission)
end

# =============================================================================
# A material's images in slots the plot keeps
# =============================================================================
#
# A plot's material reaches Hikari with each image it holds (a field holding a texture, at any
# depth of the materials it nests) replaced by the handle of a slot the plot keeps for that field.
# An image is stored once, and copied into its slot again only when its field was set: setting
# `plot.material.roughness` recompiles the material and moves no image. Which fields were set the
# plot's `material_fields` versions say (`Makie.ComputePipeline.track_fields!`): the same array
# set again counts, as it may have been changed in place.

"""The slots a plot keeps for its material's images, by field path."""
const StoredFields = Dict{Tuple, Hikari.TexHandle}

"""Whether a material field holds an image a plot keeps a slot for."""
owns_slot(t::Hikari.Texture{<:Any, 2}) = true
owns_slot(::AbstractMatrix{<:Colorant}) = true
owns_slot(::Hikari.VertexColorTexture) = true
owns_slot(::Any) = false

"""Which top-level fields of a material were set since the versions `last`: `versions` says, and without them all."""
fields_set(versions::Dict{Symbol, Int}, last::Dict{Symbol, Int}) = f -> get(versions, f, 0) != get(last, f, -1)
fields_set(versions, last) = Returns(true)

"""
    stored_fields!(set, material, owned, is_set) -> material

`material` with each image in it replaced by the handle of the slot `owned` keeps for its field
path in `set`, the scene's materials: stored where there is none yet, copied into it where
`is_set` says its top-level field was set, and as it is otherwise. An emitter's images are the
lights' and stay images.
"""
stored_fields!(set, material::Hikari.Material, owned::StoredFields, is_set) = stored_fields!(set, material, owned, is_set, ())
stored_fields!(set, m::Union{Hikari.Emission, Hikari.GeneratedGeometry}, owned::StoredFields, is_set, path) = m
function stored_fields!(set, m::Hikari.Material, owned::StoredFields, is_set, path)
    for f in fieldnames(typeof(m))
        value = getfield(m, f)
        stored = stored_field!(set, value, owned, is_set, (path..., f))
        stored === value || (m = Hikari.with_field(m, f, stored))
    end
    return m
end
stored_field!(set, value::Hikari.Material, owned, is_set, path) = stored_fields!(set, value, owned, is_set, path)
function stored_field!(set, value, owned, is_set, path)
    owns_slot(value) || return value
    old = get(owned, path, nothing)
    owned[path] = old === nothing ? Hikari.device_param(set, value) :
        is_set(first(path)) ? Raycore.update_item(set, old, value) : old
    return owned[path]
end

# =============================================================================
# Per-instance material creation (for meshscatter)
# =============================================================================

# A plot colour per instance, on the material the plot was given: Hikari's own colour merge, which
# knows which field of each material is its colour.
create_material_with_color(color::Colorant, ::Nothing) = Hikari.Diffuse(color = Hikari.ConstTexture(to_spectrum(color)))
create_material_with_color(color::Colorant, template::Hikari.Material) =
    Hikari.merge_color_with_material(Hikari.ConstTexture(to_spectrum(color)), template)
# MediumInterface: return as-is (emission/medium properties don't map to colors)
create_material_with_color(::Colorant, template::Hikari.MediumInterface) = template

# =============================================================================
# Material texture extraction (for in-place color updates)
# =============================================================================

get_material_texture(mat::Hikari.Diffuse) = mat.color isa Hikari.Texture ? mat.color : nothing
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
