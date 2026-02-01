# Killeroo Gold Scene - PBRT-v4 Port
# Port of pbrt-v4-scenes/killeroos/killeroo-gold.pbrt to TraceMakie
#
# This scene showcases:
# - Loop subdivision surface parsing and tessellation
# - Gold conductor material with physically-based optical properties
# - Area lighting approximation

using TraceMakie, Makie, Hikari, GeometryBasics
using LinearAlgebra

const KILLEROO_DIR = joinpath(dirname(dirname(pathof(Hikari))), "..", "..", "pbrt-v4-scenes", "killeroos")

# =============================================================================
# PBRT LoopSubdiv Parser
# =============================================================================

function parse_loopsubdiv_pbrt(filepath::String)
    content = read(filepath, String)

    # Extract subdivision levels
    levels_match = match(r"\"integer levels\"\s*\[\s*(\d+)\s*\]", content)
    levels = levels_match !== nothing ? parse(Int, levels_match.captures[1]) : 3

    # Extract points
    p_match = match(r"\"point3 P\"\s*\[([\s\S]*?)\](?=\s*\"integer)", content)
    p_match === nothing && error("Could not find point3 P in file")
    p_str = p_match.captures[1]
    p_nums = [parse(Float32, m.match) for m in eachmatch(r"-?[\d.]+(?:e[+-]?\d+)?", p_str)]
    points = [Point3f(p_nums[i], p_nums[i+1], p_nums[i+2]) for i in 1:3:length(p_nums)]

    # Extract face indices
    idx_match = match(r"\"integer indices\"\s*\[([\s\S]*?)\]", content)
    idx_match === nothing && error("Could not find integer indices in file")
    idx_str = idx_match.captures[1]
    indices = [parse(Int, m.match) for m in eachmatch(r"\d+", idx_str)]
    faces = [(indices[i]+1, indices[i+1]+1, indices[i+2]+1) for i in 1:3:length(indices)]

    return points, faces, levels
end

# =============================================================================
# Loop Subdivision Algorithm
# =============================================================================

function loop_beta(valence::Int)
    valence == 3 ? 3f0 / 16f0 : 3f0 / (8f0 * valence)
end

function build_adjacency(vertices::Vector{Point3f}, faces::Vector{NTuple{3,Int}})
    n = length(vertices)
    neighbors = [Set{Int}() for _ in 1:n]
    for (v1, v2, v3) in faces
        push!(neighbors[v1], v2, v3)
        push!(neighbors[v2], v1, v3)
        push!(neighbors[v3], v1, v2)
    end
    return neighbors
end

function find_boundary_vertices(vertices::Vector{Point3f}, faces::Vector{NTuple{3,Int}})
    edge_count = Dict{Tuple{Int,Int}, Int}()
    for (v1, v2, v3) in faces
        for (a, b) in [(v1,v2), (v2,v3), (v3,v1)]
            edge = minmax(a, b)
            edge_count[edge] = get(edge_count, edge, 0) + 1
        end
    end
    boundary = falses(length(vertices))
    for ((a, b), count) in edge_count
        if count == 1
            boundary[a] = true
            boundary[b] = true
        end
    end
    return boundary
end

function subdivide_once(vertices::Vector{Point3f}, faces::Vector{NTuple{3,Int}})
    neighbors = build_adjacency(vertices, faces)
    boundary = find_boundary_vertices(vertices, faces)

    new_vertices = Vector{Point3f}()

    # Reposition original (even) vertices
    for (i, v) in enumerate(vertices)
        neighs = collect(neighbors[i])
        valence = length(neighs)

        if boundary[i]
            boundary_neighs = filter(n -> boundary[n], neighs)
            if length(boundary_neighs) >= 2
                bn = boundary_neighs[1:2]
                new_p = 0.75f0 * v + 0.125f0 * vertices[bn[1]] + 0.125f0 * vertices[bn[2]]
            else
                new_p = v
            end
        else
            β = loop_beta(valence)
            ring_sum = sum(vertices[n] for n in neighs)
            new_p = (1f0 - valence * β) * v + β * ring_sum
        end
        push!(new_vertices, new_p)
    end

    # Create edge vertices (odd vertices)
    edge_vertex_map = Dict{Tuple{Int,Int}, Int}()
    edge_faces = Dict{Tuple{Int,Int}, Vector{Int}}()

    for (fi, (v1, v2, v3)) in enumerate(faces)
        for (a, b) in [(v1,v2), (v2,v3), (v3,v1)]
            edge = minmax(a, b)
            if !haskey(edge_faces, edge)
                edge_faces[edge] = Int[]
            end
            push!(edge_faces[edge], fi)
        end
    end

    for (edge, adj_faces) in edge_faces
        a, b = edge
        if length(adj_faces) == 1
            new_p = 0.5f0 * (vertices[a] + vertices[b])
        else
            f1, f2 = adj_faces[1], adj_faces[2]
            opp1 = setdiff(faces[f1], (a, b))[1]
            opp2 = setdiff(faces[f2], (a, b))[1]
            new_p = 0.375f0 * (vertices[a] + vertices[b]) + 0.125f0 * (vertices[opp1] + vertices[opp2])
        end
        push!(new_vertices, new_p)
        edge_vertex_map[edge] = length(new_vertices)
    end

    # Create 4 new faces per original face
    new_faces = Vector{NTuple{3,Int}}()
    for (v1, v2, v3) in faces
        e12 = edge_vertex_map[minmax(v1, v2)]
        e23 = edge_vertex_map[minmax(v2, v3)]
        e31 = edge_vertex_map[minmax(v3, v1)]

        push!(new_faces, (v1, e12, e31))
        push!(new_faces, (v2, e23, e12))
        push!(new_faces, (v3, e31, e23))
        push!(new_faces, (e12, e23, e31))
    end

    return new_vertices, new_faces
end

function loop_subdivide(vertices::Vector{Point3f}, faces::Vector{NTuple{3,Int}}, levels::Int)
    v, f = vertices, faces
    for i in 1:levels
        v, f = subdivide_once(v, f)
    end
    return v, f
end

function to_mesh(vertices::Vector{Point3f}, faces::Vector{NTuple{3,Int}})
    face_indices = [TriangleFace{Int}(f[1], f[2], f[3]) for f in faces]
    mesh = GeometryBasics.Mesh(vertices, face_indices)
    return GeometryBasics.normal_mesh(mesh)
end

# =============================================================================
# Scene Creation
# =============================================================================

function load_killeroo_mesh(; levels=3)
    filepath = joinpath(KILLEROO_DIR, "geometry", "killeroo3.pbrt")
    points, faces, default_levels = parse_loopsubdiv_pbrt(filepath)
    subdiv_verts, subdiv_faces = loop_subdivide(points, faces, levels)
    return to_mesh(subdiv_verts, subdiv_faces)
end

"""
    create_killeroo_gold_scene(; resolution=(1368, 1026), subdivision_levels=3)

Create the killeroo gold scene matching pbrt-v4-scenes/killeroos/killeroo-gold.pbrt.

# PBRT Scene Reference:
- Camera: perspective at (200, 250, 70), looking at (0, 33, -50), FOV 38°
- Film: 1368x1026
- Material: Gold conductor (Au eta/k spectra, roughness 0.002)
- Lights: Area disk light (radius 150 at z=800), distant light from camera
"""
function create_killeroo_gold_scene(; resolution=(1368, 1026), subdivision_levels=3)
    println("Loading killeroo mesh ($(subdivision_levels) subdivision levels)...")
    killeroo_mesh = load_killeroo_mesh(; levels=subdivision_levels)
    println("  $(length(coordinates(killeroo_mesh))) vertices")

    # Create scene
    scene = Scene(size=resolution; lights=Makie.AbstractLight[], ambient=RGBf(0.02, 0.02, 0.02))
    cam3d!(scene)

    # Camera: LookAt 200 250 70   0 33 -50   0 0 1
    update_cam!(scene, Vec3f(200, 250, 70), Vec3f(0, 33, -50), Vec3f(0, 0, 1))
    scene.camera_controls.fov[] = 38.0

    # Gold conductor material (pbrt: roughness 0.002)
    gold_material = Hikari.Gold(roughness=0.002f0)
    mesh!(scene, killeroo_mesh; material=gold_material)

    # Ground planes (pbrt: diffuse reflectance 0.5, translated z=-140)
    ground_material = Hikari.Diffuse(Kd=(0.5f0, 0.5f0, 0.5f0))
    ground_z = -140f0
    ground_size = 400f0

    # Floor
    mesh!(scene, Rect3f(Vec3f(-ground_size, -ground_size, ground_z - 0.1f0),
                        Vec3f(2*ground_size, 2*ground_size, 0.2f0)); material=ground_material)

    # Back wall
    mesh!(scene, Rect3f(Vec3f(-ground_size, -ground_size, ground_z),
                        Vec3f(2*ground_size, 0.2f0, 1000f0)); material=ground_material)

    # Left wall
    mesh!(scene, Rect3f(Vec3f(-ground_size, -ground_size, ground_z),
                        Vec3f(0.2f0, 2*ground_size, 1000f0)); material=ground_material)

    # Lights
    # Area light: disk at z=800, radius 150, L=[50,50,50] (approximated as point light)
    push_light!(scene, Makie.PointLight(RGBf(5000, 5000, 5000), Vec3f(0, 0, 800)))

    # Distant light from camera direction
    push_light!(scene, Makie.DirectionalLight(RGBf(0.2, 0.2, 0.2), Vec3f(-200, -250, -70)))

    return scene
end

function render_killeroo_gold(;
    resolution=(1368, 1026),
    samples=64,
    max_depth=8,
    subdivision_levels=3,
    backend=Array
)
    scene = create_killeroo_gold_scene(; resolution, subdivision_levels)

    TraceMakie.activate!(
        backend=backend,
        exposure=1f0,
        tonemap=:aces,
        gamma=2.2f0,
        sensor=Hikari.FilmSensor(iso=100, white_balance=5500)
    )

    integrator = Hikari.VolPath(samples=samples, max_depth=max_depth)
    img = colorbuffer(scene; backend=TraceMakie, integrator=integrator)

    return img, scene
end

# Example usage:
using AMDGPU
img, scene = render_killeroo_gold(; samples=64, backend=ROCArray)
# save("killeroo-gold.png", img)
scene = create_killeroo_gold_scene()
