

function mesh(::makie, xyz::AbstractVector, faces::AbstractVector, kw_args::Dict)
    attributes = expand_kwargs(kw_args)
    scene = get_global_scene()
    attributes[:positions] = xyz
    attributes[:faces] = faces
    attributes = mesh_defaults(scene, attributes)
    pos
end

function mesh(::makie, x::AbstractVector, y::AbstractVector, z::AbstractVector, attributes::Dict)
    mesh(Point3f0.(x, y, z), attributes)
end

function mesh(::makie, xyz, attributes::Dict)
    faces = reinterpret(GLTriangle, UInt32[0:(length(x)-1);])
    mesh(xyz, faces, attributes)
end

function mesh(::makie, m::AbstractMesh, attributes::Dict)

end

function mesh(::makie, x, y, z, faces, attributes::Dict)
    mesh(Point3f0.(x, y, z), faces; kw_args...)
end
