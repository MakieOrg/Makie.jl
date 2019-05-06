using Test, Tables, Observables
using AbstractPlotting
using WGLMakie

scene = meshscatter(rand(Point3f0, 10), rotations = rand(Quaternionf0, 10))

write("test.vert", WGLMakie.create_shader(scene, scene[end]).program.source)
