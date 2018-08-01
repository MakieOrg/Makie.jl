
@block AnthonyWang ["implicits"] begin
    @cell "Implicit equation" ["2d", contour, implicit] begin
        r = linspace(-5, 5, 400)
        (a, b) = -1, 2
        z = ((x,y) -> y.^4 - x.^4 + a .* y.^2 + b .* x.^2).(r, r')
        z2 =  z .* (abs.(z) .< 250)
        contour(r, r, z2)
    end

    @cell "Cube lattice" ["3d", contour, implicit, colormap] begin
        r = linspace(-3, 3, 100)
        me = [((1 ./ x).^2 + (1 ./ y).^2 + (1 ./ z).^2) for x=r, y=r, z=r]
        me2 = me .* (abs.(me) .> 1.5)
        contour(me2, color = :Set2)
    end

    @cell "3D cube with sphere cutout, inside" ["3d", volume, implicit] begin
        scene = Scene()
        r = linspace(-1, 1, 100)
        mat = [(x.^2 + y.^2 + z.^2) for x=r, y=r, z=r]
        mat2 = mat .* (mat .> 1.4)
        #plot the space inside
        volume(mat2, algorithm = :absorptionrgba)
    end

    @cell "3D cube with sphere cutout, outside" ["3d", volume, implicit] begin
        scene = Scene()
        r = linspace(-1, 1, 100)
        mat = [(x.^2 + y.^2 + z.^2) for x=r, y=r, z=r]
        mat2 = mat .* (mat .< 1.4)
        #plot the space outside
        volume(mat2, algorithm = :absorptionrgba)
    end

    @cell "Biohazard" ["3d", volume, implicit, algorithm, absorption] begin
        (a, b) = -1, 2
        r = linspace(-5, 5, 100)
        z = ((x,y) -> y.^4 - x.^4 + a.*y.^2 + b.*x.^2).(r, r')
        me = [cos.(2 .* pi .* sqrt.(x.^2 + y.^2)) .* (4 .* z) for x=r, y=r, z=r]
        me2 = me .* (abs.(me) .> z .* 3)
        volume(me2, algorithm = :absorptionrgba)
    end

    @cell "Twisty cube thing" ["3d", implicit, contour, colormap, colorrange] begin
        (a, b) = -1, 2
        r = linspace(-2, 2, 100)
        z = ((x,y) -> x + y).(r, r') ./ 5
        me = [z .* sin.(3 .* (atan.(y ./ x) .+ z.^2 .+ pi .* (x .> 0))) for x=r, y=r, z=r]
        me2 = me .* (me .> z .* 0.25)
        contour(me2, levels = 6, colormap = :Spectral)
    end

    @cell "Spacecraft from a galaxy far, far away" ["3d", implicit, contour, surface, inequalities, colormap, colorrange] begin
        N = 100
        r = linspace(-1, 1, N)

        # bunch of equations and inequalities
        f1(x,y,z) = x.^2 .+ y.^2 .+ z.^2 #center sphere
        f2(x,y,z) = y.^2 .+ z.^2 #command deck cylinder thing
        f3(x,y,z) = x.^2 .+ 4 .* y.^2 #controls the flattened cylinder connecting center pod to wings
        f4(x,y,z) = (y .* 0.7 .+ 0.05) #defines the diagonal spokes
        f5(x,y,z) = (y .* 0.7 .- 0.05) #defines the diagonal spokes
        f6(x,y,z) = abs.(x) + 0.3 .* abs.(y) #frame part of the wings

        e1(x,y,z) = 0.12 .* (1 .- abs.(z)) #limits of a hexagonal tube in the inside of the craft
        e2(x,y,z) = abs.(z) .* (abs.(z) .< 0.95) #outer limits of the wing plane
        e3(x,y,z) = abs.(z) .* (abs.(z) .> 0.9) #inner limits of the wing plane
        e4(x,y,z) = (abs.(x) + abs.(0.3 .*y)) .* ((abs.(x) + abs.(0.3 .* y)) .< 1) #frame of the wings
        e5(x,y,z) = abs.(z) .* (abs.(z) .< 1.05) #outside thickness of wing frames, including the spokes
        e6(x,y,z) = abs.(z) .* (abs.(z) .> 0.80) #inside thickness of wing frames, including the spokes
        e7(x,y,z) = abs.(x) .* (abs.(x) .< 0.7) #length of the straight bars part of frames
        e8(x,y,z) = abs.(y) .* (abs.(y) .> 0.9) #width of the straight bars part of frames
        e9(x,y,z) = abs.(y) .* (abs.(y) .< 0.035) #the thickness of the horizontal reinforcing bar on the wing planes

        amp = 15 #this just amplifies the "strength" of a volume, so that it shows up more clearly in the plot

        # spawn the tie fighter
        me = [(f1(x,y,z) .* f1(x,y,z).<0.2) .+ ((f2(x,y,z) .* f2(x,y,z).<0.02).*((x.<0.68).*(x.>0.50))) .+ amp .* (f3(x,y,z) .* (f3(x,y,z) .< e1(x,y,z))) .+ (e2(x,y,z).*e3(x,y,z).*e4(x,y,z)) .+ (e5(x,y,z).*e6(x,y,z)).*((e7(x,y,z)).*(e8(x,y,z)) .+ e9(x,y,z) .+ ((x.>f5(x,y,z)).*x).*((x.<f4(x,y,z)).*x) .+ ((-x.>f5(x,y,z)).*x).*((-x.<f4(x,y,z)).*x) .+ ((f6(x,y,z).*(f6(x,y,z).<1.05)).*(f6(x,y,z).*(f6(x,y,z).>0.95)))) for x=r, y=r, z=r]

        me2 = me
        for i = 1:length(r)
            me2[:,:,i] = me2[:,:,i] - min(me2[:,:,i]...)
            me2[:,:,i] = me2[:,:,i] ./ max(me2[:,:,i]...)
        end
        volume(me2, algorithm = :mip, colormap = :Purples, colorrange = (0,0.6))
    end

end
