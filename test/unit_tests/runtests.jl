@testset "Unit tests" begin
    @testset "#659 Volume errors if data is not a cube" begin
        fig, ax, vplot = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
        lims = AbstractPlotting.data_limits(vplot)
        lo, hi = extrema(lims)
        @test all(lo .<= 1)
        @test all(hi .>= (8,8,10))
    end
    # Minimal sanity checks for MakieLayout
    @testset "Layoutables constructors" begin
        scene, layout = layoutscene()
        ax = layout[1, 1] = Axis(scene)
        cb = layout[1, 2] = Colorbar(scene)
        gl2 = layout[2, :] = MakieLayout.GridLayout()
        bu = gl2[1, 1] = Button(scene)
        sl = gl2[1, 2] = Slider(scene)

        scat = scatter!(ax, rand(10))
        le = gl2[1, 3] = Legend(scene, [scat], ["scatter"])

        to = gl2[1, 4] = Toggle(scene)
        te = layout[0, :] = Label(scene, "A super title")
        me = layout[end + 1, :] = Menu(scene, options=["one", "two", "three"])
        tb = layout[end + 1, :] = Textbox(scene)
        @test true
    end

    include("conversions.jl")
    include("quaternions.jl")
    include("projection_math.jl")
    include("liftmacro.jl")
end
