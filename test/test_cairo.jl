using Colors, Cairo
using Makie
using GeometryTypes
# d = heatmap!(scene, rand(10, 10))
# f = meshscatter!(scene, rand(10), rand(10), rand(10))
function draw_all(screen, scene::Scene)
    for elem in scene.plots
        Makie.CairoBackend.cairo_draw(screen, elem)
    end
    foreach(x->draw_all(screen, x), scene.children)
    Makie.CairoBackend.cairo_finish(screen)
end

srand(1)
scene = Scene()
s = scatter!(scene, 1:10, rand(10))
s2 = lines!(scene, -1:8, rand(10) .+ 1, color = :black)
update_cam!(scene, FRect(-4, -2, 17, 4))
nothing
scene
screen = Makie.CairoBackend.CairoScreen(scene, joinpath(homedir(), "Desktop", "test.svg"))
draw_all(screen, scene)


dev = device(A)
blocksize = 80
threads = 256
out = similar(A, OT, (blocksize,))
fill!(out, v0)
function reduce_kernel(state, f, op, v0::T, A, result) where T
    ui0 = UInt32(0); ui1 = UInt32(1); ui2 = UInt32(2)
    tmp_local = @LocalMemory(state, T, 256)
    global_index = linear_index(state)
    acc = v0
    # # Loop sequentially over chunks of input vector
    while global_index <= length(A)
        element = f(A[global_index], $(fargs...))
        acc = op(acc, element)
        global_index += global_size(state)
    end
    # Perform parallel reduction
    local_index = threadidx_x(state) - ui1
    tmp_local[local_index + ui1] = acc
    synchronize_threads(state)

    offset = blockdim_x(state) ÷ ui2
    while offset > ui0
        if (local_index < offset)
            other = tmp_local[local_index + offset + ui1]
            mine = tmp_local[local_index + ui1]
            tmp_local[local_index + ui1] = op(mine, other)
        end
        synchronize_threads(state)
        offset = offset ÷ ui2
    end
    if local_index == ui0
        result[blockidx_x(state)] = tmp_local[ui1]
    end
    return
end
end
args = (f, op, v0, A, Val{threads}(), out, rest...)
gpu_call(reduce_kernel, A, args, ((blocksize,), (threads,)))

@which print(STDERR, "println(STDERR, message...)")
@which string("asd", "b")
