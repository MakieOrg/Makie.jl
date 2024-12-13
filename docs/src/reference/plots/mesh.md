# mesh

```@shortdocs; canonical=false
mesh
```


## Examples

```@figure backend=GLMakie
vertices = [
    0.0 0.0;
    1.0 0.0;
    1.0 1.0;
    0.0 1.0;
]

faces = [
    1 2 3;
    3 4 1;
]

colors = [:red, :green, :blue, :orange]

mesh(vertices, faces, color = colors, shading = NoShading)
```

```@figure backend=GLMakie
using FileIO

brain = load(assetpath("brain.stl"))

mesh(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:Spectral)
)
```

## Face colors and normals

```@figure backend=GLMakie
using GeometryBasics

# Reduce quality of sphere 
s = Tessellation(Sphere(Point3f(0), 1f0), 12)
ps = coordinates(s)
fs = faces(s)

# Use a FaceView to with a new set of faces which refer to one color per face.
# Each face must have the same length as the respective face in fs.
# (Using the same face type guarantees this)
FT = eltype(fs); N = length(fs)
cs = FaceView(rand(RGBf, N), [FT(i) for i in 1:N])

# generate normals per face (this creates a FaceView as well)
ns = face_normals(ps, fs)

# Create mesh
m = GeometryBasics.mesh(ps, fs, normal = ns, color = cs)

mesh(m)
```

## Using GeometryBasics.Mesh and Buffer/Sampler type

We can also create a mesh to specify normals, uv coordinates:

```@example sampler
using GeometryBasics, LinearAlgebra, GLMakie, FileIO
GLMakie.activate!() # hide


# Create vertices for a Sphere
r = 0.5f0
n = 30
θ = LinRange(0, pi, n)
φ2 = LinRange(0, 2pi, 2 * n)
x2 = [r * cos(φv) * sin(θv) for θv in θ, φv in φ2]
y2 = [r * sin(φv) * sin(θv) for θv in θ, φv in φ2]
z2 = [r * cos(θv) for θv in θ, φv in 2φ2]
points = vec([Point3f(xv, yv, zv) for (xv, yv, zv) in zip(x2, y2, z2)])

# The coordinates form a matrix, so to connect neighboring vertices with a face
# we can just use the faces of a rectangle with the same dimension as the matrix:
_faces = decompose(QuadFace{GLIndex}, Tessellation(Rect(0, 0, 1, 1), size(z2)))
# Normals of a centered sphere are easy, they're just the vertices normalized.
_normals = normalize.(points)

# Now we generate UV coordinates, which map the image (texture) to the vertices.
# (0, 0) means lower left edge of the image, while (1, 1) means upper right corner.
function gen_uv(shift)
    return vec(map(CartesianIndices(size(z2))) do ci
        tup = ((ci[1], ci[2]) .- 1) ./ ((size(z2) .* shift) .- 1)
        return Vec2f(reverse(tup))
    end)
end

# We add some shift to demonstrate how UVs work:
uv = gen_uv(0.0)
# We can use a Buffer to update single elements in an array directly on the GPU
# with GLMakie. They work just like normal arrays, but forward any updates written to them directly to the GPU
uv_buff = Buffer(uv)
gb_mesh = GeometryBasics.Mesh(points, _faces; uv = uv_buff, normal = _normals)

f, ax, pl = mesh(gb_mesh,  color = rand(100, 100), colormap=:blues)
wireframe!(ax, gb_mesh, color=(:black, 0.2), linewidth=2, transparency=true)
record(f, "uv_mesh.mp4", LinRange(0, 1, 100)) do shift
    uv_buff[1:end] = gen_uv(shift)
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./uv_mesh.mp4" />
```

The uv coordinates that go out of bounds will get repeated per default.
One can use a `Sampler` object to change that behaviour:

```@example sampler
#=
Possible values:
:clamp_to_edge (default)
:mirrored_repeat
:repeat
=#
data = load(Makie.assetpath("earth.png"))
color = Sampler(rotl90(data'), x_repeat=:mirrored_repeat,y_repeat=:repeat)
f, ax, pl = mesh(gb_mesh,  color = color)
wireframe!(ax, gb_mesh, color=(:black, 0.2), linewidth=2, transparency=true)

record(f, "uv_mesh_mirror.mp4", LinRange(0, 1, 100)) do shift
    uv_buff[1:end] = gen_uv(shift)
end
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./uv_mesh_mirror.mp4" />
```

## Complex Meshes (Experimental)

```@figure backend=GLMakie
using FileIO

# Load a mesh with material information. This will produce a GeometryBasics.MetaMesh
sponza = load(assetpath("sponza/sponza.obj"))

# The MetaMesh contains a standard GeometryBasics.Mesh in `sponza.mesh` with
# `mesh.views` defining the different sub-meshes, and material metadata in the
# `sponza.meta` Dict. The metadata includes:
# - meta[:material_names] which maps each view in `mesh.views` to a material name
# - meta[:materials] which maps a material name to a nested Dict of the loaded properties
# When a MetaMesh is given to Makie.mesh(), it will look for these entries and
# try to build a plot accordingly.
f, a, p = mesh(sponza)

# Set up camera
update_cam!(a.scene, Vec3f(-15, 7, 1), Vec3f(3, 5, 0), Vec3f(0,1,0))
cameracontrols(a).settings.center[] = false # don't recenter on display
cameracontrols(a).settings.fixed_axis[] = false # rotate freely

f
```

## Attributes

```@attrdocs
Mesh
```
