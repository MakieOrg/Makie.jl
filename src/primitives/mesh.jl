function to_mesh(x, y, z)
    verts = vec(Point3f0.(x, y, z))
    faces = reinterpret(GLTriangle, UInt32[0:(length(verts)-1);])
    GLPlainMesh(vertices = verts, faces = faces)
end

function to_faces(x::Vector{NTuple{N, TI}}) where {N, TI <: Integer}
    to_faces(reinterpret(Face{N, TI}, x))
end

function to_faces(faces::Vector{<: Face})
    decompose(GLTriangle, faces)
end


function to_faces(x::Vector{Int})
    if length(x) % 3 != 0
        error("Int indices need to represent triangles, therefore need to be a multiple of three. Found: $(length(x))")
    end
    reinterpret(GLTriangle, UInt32.(x .- 1))
end

function to_mesh(verts, faces, colors, attribute_id::Void)
    lift_node(verts, faces) do v, f
        GLPlainMesh(v, f)
    end
end
function to_mesh(verts, faces, colors::Node{<:Colorant}, attribute_id::Void)
    lift_node(verts, faces, c) do v, f, c
        GLNormalColorMesh(vertices = v, faces = f, color = c)
    end
end
function to_mesh(verts, faces, colors::AbstractVector, attribute_id::Void)
    lift_node(verts, faces, colors) do v, f, c
        if length(c) != length(v)
            error("You need one color per vertex. Found: $(length(v)) vertices, and $(length(c)) colors")
        end
        GLNormalVertexcolorMesh(vertices = v, faces = f, color = c)
    end
end

function to_mesh(verts, faces, colors::AbstractVector, attribute_id::AbstractVector)
    lift_node(verts, faces, colors, attribute_id) do v, f, c, id
        if length(id) != length(v)
            error("You need one attribute per vertex. Found: $(length(v)) vertices, and $(length(id)) attributes")
        end
        GLNormalAttributeMesh(
            vertices = v, faces = f,
            attributes = c, attribute_id = id
        )
    end
end

@default function mesh(scene, kw_args)
    color = to_color(color)
    shading = shading::Bool
    positions = to_positions(positions)
    faces = to_faces(faces)
    attribute_id = to_attribut_id(attribute_id)
    vertexmesh = to_mesh(positions, faces, color, attribute_id)
end


function mesh(xyz::AbstractVector, faces::AbstractVector; kw_args...)
    attributes = expand_kwargs(kw_args)
    scene = get_global_scene()
    attributes[:positions] = xyz
    attributes[:faces] = faces
    attributes = mesh_defaults(scene, attributes)
    pos
end

function mesh(x::AbstractVector, y::AbstractVector, z::AbstractVector; kw_args...)
    mesh(Point3f0.(x, y, z); kw_args...)
end

function mesh(xyz; kw_args...)
    faces = reinterpret(GLTriangle, UInt32[0:(length(x)-1);])
    mesh(xyz, faces; kw_args...)
end

function mesh(m::AbstractMesh; kw_args...)

end


function mesh(x, y, z, faces; kw_args...)
    mesh(Point3f0.(x, y, z), faces; kw_args...)
end
