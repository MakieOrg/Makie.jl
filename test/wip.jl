######################
#                    #
#       Notes        #
#                    #
######################
# Shadercleanup:
#   -> For now I will leave the shitty push! robj + pipeline situation as it is to later implement a better way, redoing all the visualizes into also returning what pipeline


using Makie
scene = Scene()
begin
    scene = Scene()
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end

    r = linspace(-2, 2, 50)
    surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
    z = surf_func(20)
    surf = surface!(scene, r, r, z)[end]

    wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
        linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap])
    )
end
