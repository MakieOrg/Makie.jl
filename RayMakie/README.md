# RayMakie

[![Build Status](https://github.com/SimonDanisch/RayMakie.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SimonDanisch/RayMakie.jl/actions/workflows/CI.yml?query=branch%3Amain)

Materials use Hikari's Blender-style descriptions. Their fields are editable
through the plot's ComputeGraph, including fields inside mixed materials:

```julia
using Makie, RayMakie, Hikari
using GeometryBasics: Sphere, Point3f

scene = Scene()
cam3d!(scene)
plot = mesh!(scene, Sphere(Point3f(0), 1f0);
    material = Hikari.Mix(
        Hikari.Principled(base_color = (0.2, 0.4, 0.8)),
        Hikari.Glass(); factor = 0.3))

plot.material.a.roughness = 0.2
plot.material.b.color = (0.8, 0.9, 1.0)
plot.material.factor = 0.5
roughness = plot.material.a.roughness[]
```

Scalar edits reuse material slots and GPU kernels when the shader's node and
BSDF types stay the same. They leave geometry and unrelated image buffers in
place. After changing an image array in place, assign it to its field again
(for example, `plot.material.a.base_color[] = image`) to upload that image.
Replacing a nested material also updates the images beneath that field.

The RPRMakie Lego example run with FastWavefront (~14s render time on GPU):

https://github.com/user-attachments/assets/63e9205e-d5dd-4d5e-8c6e-330b99b6faf0

Rendered cloud data from [Breeze.jl](https://github.com/NumericalEarth/Breeze.jl/issues/315) with a volume Material:

<img width="1024" height="1024" alt="bomex_cloud" src="https://github.com/user-attachments/assets/3d209ad0-9653-4481-8606-e65af6eac262" />

A complex model with many textures and polygons: 

<img width="2400" height="1800" alt="Image" src="https://github.com/user-attachments/assets/0f17105e-4101-4b75-9ffb-e4e97579d5b0" />
