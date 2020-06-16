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

        pos = Node(rand(Point3f0, 2))
        rot = Node(rand(Vec3f0, 2))
        color = Node(rand(RGBf0, 2))
        size = Node(0.1*rand(2))

        makenew = Node(1)
        on(makenew) do i
            pos[] = rand(Point3f0, i)
            rot[] = rand(Vec3f0, i)
            color[] = rand(RGBf0, i)
            size[] = 0.1*rand(i)
        end

        scene = meshscatter(pos,
            rotations=rot,
            color=color,
            markersize=size,
            limits=FRect3D(Point3(0), Point3(1))
        )

        record(scene, @replace_with_a_path(mp4), [10, 5, 100, 60, 177]) do i
            makenew[] = i
        end
    end


end
