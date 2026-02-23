using GLMakie
using Makie: SDF, SDFBrickmap, CSG, update_brickmap!
using KernelAbstractions, AMDGPU, LinearAlgebra
using ShaderAbstractions

include("csgplot-gpu.jl")

# Scene
tree = CSG.diff(
    CSG.intersect(
        CSG.smooth_union(
            CSG.Cylinder(0.2, 0.7; color=:lightgray),
            CSG.union(
                map(1:4) do n
                    CSG.Rect(
                        Vec3f(0.1, 0.07, 0.2);
                        color=:lightgray,
                        translation=0.8 * Vec3f(cos(n * pi / 8 - pi / 16), sin(n * pi / 8 - pi / 16), 0),
                        rotation=qrotation(Vec3f(0, 0, 1), -n * pi / 8 + pi / 16),
                    )
                end...;
                mirror=(true, true, false),
            );
            smooth=0.02,
        ),
        CSG.Cylinder(0.1, 1; color=:orange),
    ),
    CSG.Cylinder(0.2, 0.4),
)

csgplot(tree)

SDF.calculate_global_bboxes!(tree)

bricksize = 8
N_blocks = 32
bb = Rect3f(Point3f(-1), Vec3f(2))
bm_size = N_blocks * (bricksize - 1) + 1
regions = Rect3f[tree.bbox[]]

# CPU (existing path)
brickmap_cpu = SDFBrickmap(bricksize, bm_size)
update_brickmap!(brickmap_cpu, bb, tree, regions) # warmup
t_cpu = @elapsed for _ in 1:5
    brickmap_cpu = SDFBrickmap(bricksize, bm_size)
    update_brickmap!(brickmap_cpu, bb, tree, regions)
end
t_cpu /= 5

# GPU
brickmap_gpu = SDFBrickmap(bricksize, bm_size)
gpu_update_brickmap!(brickmap_gpu, bb, tree, regions, AMDGPU.ROCBackend()) # warmup
t_gpu = @elapsed for _ in 1:10
    brickmap_gpu = SDFBrickmap(bricksize, bm_size)
    gpu_update_brickmap!(brickmap_gpu, bb, tree, regions, AMDGPU.ROCBackend())
end
t_gpu /= 10

println("CPU:  $(round(t_cpu*1000, digits=1)) ms")
println("GPU :  $(round(t_gpu*1000, digits=1)) ms")
println("Speedup: $(round(t_cpu/t_gpu, digits=1))x")
