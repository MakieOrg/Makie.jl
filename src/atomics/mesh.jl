
function mesh(b::makie, x::AbstractVector, y::AbstractVector, z::AbstractVector, attributes::Dict)
    mesh(b, Point3f0.(x, y, z), attributes)
end

function mesh(b::makie, xyz::AbstractVector, attributes::Dict)
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    mesh(xyz, faces, attributes)
end

function mesh(b::makie, triangle_mesh, attributes::Dict)
    attributes[:mesh] = triangle_mesh
    mesh_impl(b, attributes)
end

function mesh(b::makie, x, y, z, indices, attributes::Dict)
    attributes[:x] = x
    attributes[:y] = y
    attributes[:z] = z
    attributes[:indices] = indices
    mesh_impl(b, attributes)
end


function mesh(b::makie, xyz::AbstractVector, faces::AbstractVector, attributes::Dict)
    attributes[:positions] = xyz
    attributes[:indices] = faces
    mesh_impl(b, attributes)
end

function mesh_2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    for (k, v) in attributes
        k in (:mesh, :positions, :x, :y, :z, :normals, :indices) && continue
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
    result[:model] = eye(Mat4f0)
    result
end

function mesh_impl(b, attributes)
    scene = get_global_scene()
    attributes = mesh_defaults(b, scene, attributes)
    mesh = attributes[:mesh]
    gl_data = mesh_2glvisualize(attributes)
    viz = visualize(to_signal(mesh), Style(:default), gl_data).children[]
    insert_scene!(scene, :surface, viz, attributes)
end


function mesh(b::makie, mesh, xyz::AbstractVector{<:Point}, attributes::Dict)
    attributes[:marker] = to_node(mesh, x-> to_mesh(b, x))
    attributes[:positions] = xyz
    meshscatter(b, xyz, attributes)
end
