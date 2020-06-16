@block Contributors ["GLMakie backend tests"] begin

    # A test case for wide lines and mitering at joints
    @cell "Miter Joints for line rendering" [lines] begin
        scene = Scene()

        r = 4
        sep = 4*r
        scatter!(scene, (sep+2*r)*[-1,-1,1,1], (sep+2*r)*[-1,1,-1,1])

        for i=-1:1
            for j=-1:1
                angle = pi/2 + pi/4*i
                x = r*[-cos(angle/2),0,-cos(angle/2)]
                y = r*[-sin(angle/2),0,sin(angle/2)]

                linewidth = 40 * 2.0^j
                lines!(scene, x .+ sep*i, y .+ sep*j, color=RGBAf0(0,0,0,0.5), linewidth=linewidth)
                lines!(scene, x .+ sep*i, y .+ sep*j, color=:red)
            end
        end
        scene
    end

    # Test for resizing of TextureBuffer
    @cell "Dynamically adjusting number of particles in a meshscatter" [meshscatter] begin

        posb = Node(rand(Point3f0, 2))
        rotb = Node(rand(Vec3f0, 2))
        colorb = Node(rand(RGBf0, 2))
        sizeb = Node(1/2*rand(2))

        makenew = Node(1)
        on(makenew) do i
            posb[] = rand(Point3f0, i)
            rotb[] = rand(Vec3f0, i)
            colorb[] = rand(RGBf0, i)
            sizeb[] = 1/2*rand(i)
        end

        scene = meshscatter(posb,
            rotations=rotb,
            color=colorb,
            markersize=sizeb,
            limits=FRect3D(Point3(0), Point3(1))
        )

        record(scene, @replace_with_a_path(mp4), [10, 5, 100, 60, 177]) do i
            makenew[] = makenew[] + 1
        end
    end


end
