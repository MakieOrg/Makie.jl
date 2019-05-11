using Test, Tables, Observables
using AbstractPlotting
using WGLMakie
import GeometryTypes
using WGLMakie: WebGL, lasset, JSInstanceBuffer, JSBuffer, to_js_uniforms
using ShaderAbstractions: InstancedProgram, VertexArray
import GeometryTypes: GLNormalMesh, GLPlainMesh
using Tables: columns

Scene(resolution = (500, 500))
scene = meshscatter!(rand(Point3f0, 10), rotations = rand(Quaternionf0, 10))
plot = scene[end]
meshy = GLNormalMesh(plot.marker[])
instance = VertexArray(meshy)

uniform_dict = Dict(
    :model => plot.model,
    :projectionview => scene.camera.projectionview,
    :markersize => map(Vec3f0, plot.markersize)
)
ip = InstancedProgram(
    WebGL(), lasset("simple.vert"),
    instance,
    VertexArray(; offset = plot[1])
    ; uniform_dict...
)

using WGLMakie: JSBuffer
THREE, document, window, js_scene, renderer = WGLMakie.three_scene(scene)
# bufferGeometry = THREE.new.BoxBufferGeometry(0.1, 0.1, 0.1);
js_vbo = THREE.new.InstancedBufferGeometry()
# js_vbo.index = bufferGeometry.index;
# js_vbo.attributes.position = bufferGeometry.attributes.position;

context = js_scene

# for (name, buff) in pairs(columns(ip.program.vertexarray))
for (name, buff) in pairs(columns(instance))
    js_buff = JSBuffer(context, buff).setDynamic(true)
    js_vbo.addAttribute(name, js_buff)
end
# end
using GeometryBasics
import GeometryTypes
indices = GeometryTypes.faces(meshy)
indices = reinterpret(UInt32, indices)
js_vbo.setIndex(indices);
js_vbo.maxInstancedCount = length(ip.per_instance)

# per instance data
for (name, buff) in pairs(columns(ip.per_instance))
    js_buff = JSInstanceBuffer(context, buff).setDynamic(true)
    js_vbo.addAttribute(name, js_buff)
end
uniforms = to_js_uniforms(context, ip.program.uniforms)
write("test.vert", ip.program.source)
material = WGLMakie.create_material(
    ip.program.source,
    lasset("particles.frag"),
    to_js_uniforms(context, ip.program.uniforms)
)
mesh = THREE.new.Mesh(js_vbo, material)
js_scene.add(mesh)
camera = WGLMakie.get_camera(renderer, js_scene, scene)
renderer.render(js_scene, camera);
