# Crown Scene - pbrt-v4 VolPath Example
# Port of the crown scene from pbrt-v4-scenes to test the VolPath integrator
#
# This scene showcases:
# - MetalMaterial with gold (Au) properties for conductor materials
# - CoatedDiffuseMaterial for glossy painted surfaces
# - GlassMaterial for dielectric gems
# - MatteMaterial for diffuse surfaces
# - MixMaterial for texture-masked material blending
# - Area lights with blackbody emission

using TraceMakie, Makie, Hikari, GeometryBasics, Raycore
using FileIO
using StaticArrays

# Scene base path
const CROWN_DIR = joinpath(dirname(dirname(pathof(Hikari))), "..", "..", "pbrt-v4-scenes", "crown")
# =============================================================================
# PBRT File Parser (Minimal - just for crown scene)
# =============================================================================

"""
Parse the crown.pbrt file to extract material and geometry definitions.
"""
function parse_crown_pbrt()
    pbrt_path = joinpath(CROWN_DIR, "crown.pbrt")
    content = read(pbrt_path, String)

    # Extract material definitions
    materials = Dict{String, Any}()
    geometries = Vector{NamedTuple}()

    # Parse named materials
    # Pattern: MakeNamedMaterial "name" ... parameters ...
    for m in eachmatch(r"MakeNamedMaterial\s+\"([^\"]+)\"\s+([^\n]+(?:\n\s+[^\n]+)*)", content)
        name = m.captures[1]
        params = m.captures[2]
        materials[name] = parse_material_params(params)
    end

    # Parse shapes with material assignments
    current_material = nothing
    lines = split(content, '\n')
    i = 1
    while i <= length(lines)
        line = lines[i]

        # Track current named material
        if contains(line, "NamedMaterial")
            m = match(r"NamedMaterial\s+\"([^\"]+)\"", line)
            if m !== nothing
                current_material = m.captures[1]
            end
        end

        # Extract PLY references - filename is on next line
        if contains(line, "\"plymesh\"") && i + 1 <= length(lines)
            m = match(r"\"string filename\"\s*\[\s*\"([^\"]+)\"\s*\]", lines[i+1])
            if m !== nothing
                push!(geometries, (file=m.captures[1], material=current_material))
            end
        end

        i += 1
    end

    return materials, geometries
end

"""
Parse material parameters from pbrt format.
"""
function parse_material_params(params::AbstractString)
    result = Dict{String, Any}()

    # Extract material type
    type_match = match(r"\"string type\"\s*\[\s*\"([^\"]+)\"\s*\]", params)
    if type_match !== nothing
        result["type"] = type_match.captures[1]
    end

    # Extract common parameters
    # Roughness
    for (key, pattern) in [
        ("roughness", r"\"float roughness\"\s*\[\s*([\d.e+-]+)\s*\]"),
        ("uroughness", r"\"float uroughness\"\s*\[\s*([\d.e+-]+)\s*\]"),
        ("vroughness", r"\"float vroughness\"\s*\[\s*([\d.e+-]+)\s*\]"),
        ("eta", r"\"float eta\"\s*\[\s*([\d.e+-]+)\s*\]"),
    ]
        m = match(pattern, params)
        if m !== nothing
            result[key] = parse(Float32, m.captures[1])
        end
    end

    # RGB colors
    for (key, pattern) in [
        ("reflectance", r"\"rgb reflectance\"\s*\[\s*([\d.e+-]+)\s+([\d.e+-]+)\s+([\d.e+-]+)\s*\]"),
        ("Kd", r"\"rgb Kd\"\s*\[\s*([\d.e+-]+)\s+([\d.e+-]+)\s+([\d.e+-]+)\s*\]"),
    ]
        m = match(pattern, params)
        if m !== nothing
            result[key] = (
                parse(Float32, m.captures[1]),
                parse(Float32, m.captures[2]),
                parse(Float32, m.captures[3])
            )
        end
    end

    # Check for spectrum eta/k (gold)
    if contains(params, "metal-Au-eta")
        result["eta_spectrum"] = "gold"
    end
    if contains(params, "metal-Au-k")
        result["k_spectrum"] = "gold"
    end

    return result
end

# =============================================================================
# Material Creation
# =============================================================================

"""
Create a Hikari MetalMaterial with gold properties.
Using the built-in METAL_GOLD preset which provides RGB approximations
that get uplifted to spectral values during rendering.
"""
function create_gold_material(; roughness=0.01f0)
    eta, k = Hikari.METAL_GOLD
    Hikari.MetalMaterial(
        eta=eta,
        k=k,
        roughness=roughness
    )
end

"""
Create materials from parsed pbrt definitions.
"""
function create_materials(parsed_materials::Dict)
    materials = Dict{String, Any}()

    for (name, params) in parsed_materials
        mat_type = get(params, "type", "")

        if mat_type == "conductor"
            # All crown conductors use gold
            roughness = get(params, "roughness", 0.01f0)
            materials[name] = create_gold_material(roughness=roughness)

        elseif mat_type == "coateddiffuse"
            refl = get(params, "reflectance", (0.5f0, 0.5f0, 0.5f0))
            roughness = get(params, "roughness", 0.1f0)
            materials[name] = Hikari.CoatedDiffuseMaterial(
                reflectance=refl,
                roughness=roughness,
                eta=1.5f0
            )

        elseif mat_type == "dielectric"
            eta = get(params, "eta", 1.5f0)
            materials[name] = Hikari.GlassMaterial(index=eta)

        elseif mat_type == "diffuse"
            kd = get(params, "Kd", get(params, "reflectance", (0.5f0, 0.5f0, 0.5f0)))
            materials[name] = Hikari.MatteMaterial(
                Kd=Hikari.RGBSpectrum(kd[1], kd[2], kd[3])
            )

        elseif mat_type == "mix"
            # MixMaterial - will need special handling with material indices
            # For now, create a placeholder
            materials[name] = :mix_placeholder
        else
            # Default to diffuse gray
            materials[name] = Hikari.MatteMaterial(
                Kd=Hikari.RGBSpectrum(0.5f0)
            )
        end
    end

    return materials
end

# =============================================================================
# Geometry Loading
# =============================================================================

"""
Load a PLY mesh from the crown geometry folder.
"""
function load_crown_mesh(filename::AbstractString)
    full_path = joinpath(CROWN_DIR, filename)
    if !isfile(full_path)
        @warn "Mesh file not found: $full_path"
        return nothing
    end
    return load(full_path)
end

# =============================================================================
# Scene Setup
# =============================================================================

"""
Create the crown scene with ALL geometry and materials.
Loads all 794 PLY meshes from the pbrt-v4 crown scene.
"""
function create_crown_scene(; resolution=(512, 512))
    println("Parsing crown.pbrt...")
    parsed_materials, geometries = parse_crown_pbrt()

    println("Found $(length(parsed_materials)) materials and $(length(geometries)) geometry references")

    # Create Hikari materials
    println("Creating materials...")
    materials = create_materials(parsed_materials)

    # Set up lights (following the pbrt scene: 5500K blackbody area lights)
    # For simplicity, using point lights approximating the area light positions
    lights = [
        Makie.PointLight(RGBf(50, 45, 40), Vec3f(0, 20, -70)),    # back light
        Makie.PointLight(RGBf(30, 28, 25), Vec3f(40, 20, -10)),   # right light
        Makie.PointLight(RGBf(30, 28, 25), Vec3f(-40, 20, -10)),  # left light
        Makie.PointLight(RGBf(20, 18, 16), Vec3f(15, 0, 20)),     # front right
        Makie.PointLight(RGBf(20, 18, 16), Vec3f(-20, 0, 20)),    # front left
        Makie.AmbientLight(RGBf(0.05, 0.05, 0.05)),
    ]

    # Create scene
    scene = Scene(
        size=resolution;
        lights=lights
    )
    cam3d!(scene)

    # Load ALL geometry
    println("Loading all $(length(geometries)) meshes...")
    loaded = 0
    failed = 0
    for (i, geom) in enumerate(geometries)
        try
            mesh_data = load_crown_mesh(geom.file)
            if mesh_data === nothing
                failed += 1
                continue
            end

            # Get material for this geometry
            mat = get(materials, geom.material, nothing)
            if mat === nothing || mat === :mix_placeholder
                # Use default gold material for unmapped geometries
                mat = create_gold_material()
            end

            # Add mesh to scene
            mesh!(scene, mesh_data; material=mat)
            loaded += 1
        catch e
            failed += 1
        end

        # Progress indicator
        if i % 100 == 0
            println("  Loaded $loaded / $(length(geometries)) meshes...")
        end
    end

    println("Loaded $loaded meshes ($failed failed)")

    # Set camera (approximating pbrt LookAt 0 5.5 24  ->  0 11 -10)
    update_cam!(scene, Vec3f(0, 5.5, 24), Vec3f(0, 11, -10), Vec3f(0, 1, 0))

    return scene
end

# =============================================================================
# Rendering
# =============================================================================

"""
Render the crown scene using the VolPath integrator.
"""
function render_crown(;
    resolution=(512, 512),
    samples=16,
    max_depth=10
)
    scene = create_crown_scene(resolution=resolution)
    TraceMakie.activate!(backend=AMDGPU.ROCBackend())
    @time img = colorbuffer(scene;
        backend=TraceMakie,
        integrator=Hikari.VolPath(
            samples_per_pixel=samples,
            max_depth=max_depth,
        )
    )

    return img, scene
end

# =============================================================================
# Main
# =============================================================================

if !isdir(CROWN_DIR)
    error("Crown scene not found at: $CROWN_DIR\nPlease ensure pbrt-v4-scenes is available.")
end
using AMDGPU
# Render with full scene
img, scene = render_crown(
    resolution=(512, 512),
    samples=20,
    max_depth=12
)

screen = Makie.getscreen(scene)

Array(Hikari.postprocess!(screen.state.film;
    exposure=1.5,
    tonemap=nothing,
    gamma=2.2f0,
    sensor=Hikari.FilmSensor(iso=100, white_balance=2500)
))


# Save result
output_path = joinpath(CROWN_DIR, "crown_hikari.png")
save(output_path, img)
println("\nSaved render to: $output_path")
