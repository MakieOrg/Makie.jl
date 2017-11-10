
function mesh(scene::makie, x::AbstractVector, y::AbstractVector, z::AbstractVector, attributes::Dict)
    mesh(scene, Point3f0.(x, y, z), attributes)
end

function mesh(scene::makie, xyz::AbstractVector, attributes::Dict)
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    mesh(scene, xyz, faces, attributes)
end

function mesh(scene::makie, triangle_mesh, attributes::Dict)
    attributes[:mesh] = triangle_mesh
    mesh_impl(scene, attributes)
end

function mesh(scene::makie, x, y, z, indices, attributes::Dict)
    attributes[:x] = x
    attributes[:y] = y
    attributes[:z] = z
    attributes[:indices] = indices
    mesh_impl(scene, attributes)
end


function mesh(scene::makie, xyz::AbstractVector, faces::AbstractVector, attributes::Dict)
    attributes[:positions] = xyz
    attributes[:indices] = faces
    mesh_impl(scene, attributes)
end

function mesh_2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    for (k, v) in attributes

        k in (:mesh, :normals, :indices, :positions, always_skip...) && continue

        if k == :shading
            result[k] = to_value(v) # as signal not supported currently, will require shader signals
            continue
        end
        if k == :color && isa(v, AbstractVector)
            # normal colors pass through, vector of colors should be part of mesh already
            continue
        end
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = true
    result
end

function mesh_impl(scene, attributes)
    attributes = mesh_defaults(scene, attributes)
    mesh = attributes[:mesh]
    gl_data = mesh_2glvisualize(attributes)
    viz = visualize(to_signal(mesh), Style(:default), gl_data).children[]
    insert_scene!(scene, :mesh, viz, attributes)
end


function mesh(scene::makie, mesh, xyz::AbstractVector{<:Point}, attributes::Dict)
    attributes[:marker] = to_node(mesh, x-> to_mesh(scene, x))
    attributes[:positions] = xyz
    meshscatter(scene, xyz, attributes)
end
