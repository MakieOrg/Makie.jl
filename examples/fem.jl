using LinearElasticity

# Define problem
nels = (60,20,4)
sizes = (1.0,1.0,1.0)
E = 1.0;
ν = 0.3;
force = -1.0;
problem = PointLoadCantilever(nels, sizes, E, ν, force)

# Build element stiffness matrices and force vectors
einfo = ElementFEAInfo(problem);

# Assemble global stiffness matrix and force vector
ginfo = assemble(problem, einfo);

# Solve for node displacements
u = ginfo.K \ ginfo.f

mesh = problem.ch.dh.grid
node_dofs = problem.metadata.node_dofs

node_displacements = reshape(u[node_dofs], 3, JuAFEM.getnnodes(mesh))

using Makie
using GeometryTypes

# Overloads to get the fem nodes working!

function AbstractPlotting.to_vertices(cells::AbstractVector{<: JuAFEM.Node{N, T}}) where {N, T}
    convert_arguments(nothing, cells)[1]
end
function AbstractPlotting.to_gl_indices(cells::AbstractVector{<: JuAFEM.Cell})
    tris = GLTriangle[]
    for cell in cells
        to_triangle(tris, cell)
    end
    tris
end

function to_triangle(tris, cell::JuAFEM.Cell{3, 8, 6})
    nodes = cell.nodes
    push!(tris, GLTriangle(nodes[1], nodes[2], nodes[5]))
    push!(tris, GLTriangle(nodes[5], nodes[2], nodes[6]))

    push!(tris, GLTriangle(nodes[6], nodes[2], nodes[3]))
    push!(tris, GLTriangle(nodes[3], nodes[6], nodes[7]))

    push!(tris, GLTriangle(nodes[7], nodes[8], nodes[3]))
    push!(tris, GLTriangle(nodes[3], nodes[8], nodes[4]))

    push!(tris, GLTriangle(nodes[4], nodes[8], nodes[5]))
    push!(tris, GLTriangle(nodes[5], nodes[4], nodes[1]))

    push!(tris, GLTriangle(nodes[1], nodes[2], nodes[3]))
    push!(tris, GLTriangle(nodes[3], nodes[1], nodes[4]))
end

function AbstractPlotting.convert_arguments(P, x::AbstractVector{<: JuAFEM.Node{N, T}}) where {N, T}
    convert_arguments(P, reinterpret(Point{N, T}, x))
end
#TODO make this work without creating a Node
cnode = Node(zeros(Float32, length(mesh.nodes)))
scene = Makie.mesh(mesh.nodes, mesh.cells, color = cnode, colorrange = (0.0, 33.0), shading = false)
mplot = scene[end]
displacevec = reinterpret(Vec{3, Float64}, node_displacements, (size(node_displacements, 2),))
displace = norm.(displacevec)

new_nodes = broadcast(1:length(mesh.nodes), mesh.nodes) do i, node
    JuAFEM.Node(ntuple(Val{3}) do j
        node.x[j] + node_displacements[j, i]
    end)
end

mesh!(mesh.nodes, mesh.cells, color = (:gray, 0.4))

scatter!(Point3f0.(getfield.(new_nodes, :x)), markersize = 0.1)
# TODO make mplot[1] = new_nodes work

mplot.input_args[1][] = new_nodes
# TODO make mplot[:color] = displace work
push!(cnode, displace)

points = reinterpret(Point{3, Float64}, mesh.nodes)
arrows!(points, displacevec, linecolor = (:black, 0.3))
scene
