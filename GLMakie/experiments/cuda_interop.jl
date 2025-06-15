using CUDA, GLMakie, NVTX
using GLMakie.GLAbstraction
# from https://discourse.julialang.org/t/cuarray-glmakie/52461/11?u=maleadt

function cu_plot(; T = Float32, N = 1024, resolution = (800, 600))
    t = CUDA.rand(T, N)
    X = CUDA.rand(T, N)

    #      so that we can create a GLBuffer before having rendered anything.
    fig = Figure(; resolution)
    ax = Axis(fig[1, 1]; limits = (0, 1, 0, 1))
    screen = display(fig)

    # get a buffer object and register it with CUDA
    buffer = GLAbstraction.GLBuffer(Point2f, N)
    resource = let
        ref = Ref{CUDA.CUgraphicsResource}()
        CUDA.cuGraphicsGLRegisterBuffer(
            ref, buffer.id,
            CUDA.CU_GRAPHICS_MAP_RESOURCE_FLAGS_WRITE_DISCARD
        )
        ref[]
    end

    NVTX.@range "main" begin
        # process data, generate points
        NVTX.@range "CUDA" begin
            # map OpenGL buffer object for writing from CUDA
            CUDA.cuGraphicsMapResources(1, [resource], stream())

            # get a CuArray object that we can work with
            array = let
                ptr_ref = Ref{CUDA.CUdeviceptr}()
                numbytes_ref = Ref{Csize_t}()
                CUDA.cuGraphicsResourceGetMappedPointer_v2(ptr_ref, numbytes_ref, resource)

                ptr = reinterpret(CuPtr{Point2f}, ptr_ref[])
                len = Int(numbytes_ref[] ÷ sizeof(Point2f))

                unsafe_wrap(CuArray, ptr, len)
            end

            # generate points
            broadcast!(array, t, X) do x, y
                return Point2f(x, y)
            end

            # wait for the GPU to finish
            synchronize()

            CUDA.cuGraphicsUnmapResources(1, [resource], stream())
        end

        # generate and render plot
        NVTX.@range "Makie" begin
            scatter!(ax, buffer)
            # force everything to render (for benchmarking purposes)
            GLMakie.render_frame(screen; resize_buffers = false)
            GLMakie.glFinish()
        end
    end

    ## clean-up

    CUDA.cuGraphicsUnregisterResource(resource)

    return
end

cu_plot()
