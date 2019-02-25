# A test case for wide lines and mitering at joints

@block Contributors ["GLMakie backend tests"] begin
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
end
