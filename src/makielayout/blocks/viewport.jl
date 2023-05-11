# Mesh generation
function Rhombicuboctahedron(; center = Point3f(0), radius = 1f0)
    o = 1 / (1 + sqrt(2))
    ps = radius .* Point3f[
        (-o, -o, -1), (-o, o, -1), (o, o, -1), (o, -o, -1),
        (-1, o, -o), (-o, 1, -o), (o, 1, -o), (1, o, -o), 
            (1, -o, -o), (o, -1, -o), (-o, -1, -o), (-1, -o, -o),
        (-1, o, o), (-o, 1, o), (o, 1, o), (1, o, o), 
            (1, -o, o), (o, -1, o), (-o, -1, o), (-1, -o, o),
        (-o, -o, 1), (-o, o, 1), (o, o, 1), (o, -o, 1),
    ] .+ (center,)
    QF = QuadFace
    TF = TriangleFace
    faces = [
        # bottom quad
        QF(1, 2, 3, 4), 
    
        # bottom triangles
        TF(2, 5, 6), TF(3, 7, 8), TF(4, 9, 10), TF(1, 11, 12),
    
        # bottom diag quads
        QF(3, 2, 6, 7), QF(4, 3, 8, 9), QF(1, 4, 10, 11), QF(2, 1, 12, 5), 
            
        # quad ring
        QF(13, 14, 6, 5), QF(14, 15, 7, 6), QF(15, 16, 8, 7), QF(16, 17, 9, 8),
        QF(17, 18, 10, 9), QF(18, 19, 11, 10), QF(19, 20, 12, 11), QF(20, 13, 5, 12),
    
        # top diag quads
        QF(22, 23, 15, 14), QF(21, 22, 13, 20), QF(24, 21, 19, 18), QF(23, 24, 17, 16), 
    
        # top triangles
        TF(21, 20, 19), TF(24, 18, 17), TF(23, 16, 15), TF(22, 14, 13),
    
        # top
        QF(21, 24, 23, 22)
    ]
    
    remapped_ps = Point3f[]
    remapped_fs = AbstractFace[]
    remapped_cs = RGBf[]
    remapped_index = Int[]
    for (idx, f) in enumerate(faces)
        i = length(remapped_ps)
        append!(remapped_ps, ps[f])
        push!(remapped_fs, length(f) == 3 ? TF(i+1, i+2, i+3) : QF(i+1, i+2, i+3, i+4))
        c = RGBf(abs.(mean(ps[f]))...)
        append!(remapped_cs, (c for _ in f))
        append!(remapped_index, [idx for _ in f])
    end
    
    _faces = decompose(GLTriangleFace, remapped_fs)
    return GeometryBasics.Mesh(
        meta(
            remapped_ps; 
            normals = normals(remapped_ps, _faces), 
            color = remapped_cs,
            index = remapped_index
        ), 
        _faces
    )
end


################################################################################
### Camera setup
################################################################################


# Simplified/Modified from Camera3D to make sure updates work correctly
struct ViewportControllerCamera <: AbstractCamera
    # eyeposition::Observable{Vec3f}
    # lookat::Observable{Vec3f}
    # upvector::Observable{Vec3f}
    phi::Observable{Float32}
    theta::Observable{Float32}
    attributes::Attributes
end

function ViewportControllerCamera(scene::Scene, axis)
    attr = Attributes(
        fov = 45.0,
        projectiontype = Makie.Perspective,
        rotationspeed = 1.0,
        click_timeout = 0.3,
        selected = false,
    )

    if axis isa Axis3
        cam = ViewportControllerCamera(
            Observable{Float32}(axis.azimuth[]), 
            Observable{Float32}(axis.elevation[]),
            attr
        )
    else
        cam = ViewportControllerCamera(
            Observable{Float32}(pi/4), 
            Observable{Float32}(0.61547977f0),
            attr
        )
    end

    disconnect!(camera(scene))

    # de/select plot on click outside/inside
    # also deselect other cameras
    deselect_all_cameras!(root(scene))
    on(camera(scene), events(scene).mousebutton, priority = 100) do event
        if event.action == Mouse.press
            attr.selected[] = is_mouseinside(scene)
        end
        return Consume(false)
    end

    # Mouse controls
    add_rotation!(scene, cam, axis)

    # add camera controls to scene
    cameracontrols!(scene, cam)

    # Trigger updates on scene resize and settings change
    # scene.px_area, 
    on(camera(scene), scene.px_area, attr[:fov], attr[:projectiontype]) do _, _, _
        update_cam!(scene, cam)
    end

    notify(attr.fov)

    connect_camera!(axis, scene)

    cam
end
deselect_camera!(cam::ViewportControllerCamera) = cam.attributes.selected[] = false

function add_rotation!(scene, cam::ViewportControllerCamera, axis)
    rotationspeed = cam.attributes[:rotationspeed]
    timeout = cam.attributes[:click_timeout]
    drag_state = RefValue((false, Vec2f(0), time()))
    e = events(scene)

    # drag start/stop
    on(camera(scene), e.mousebutton) do event
        if event.button == Mouse.left
            active, last_mousepos, last_time = drag_state[]
            if event.action == Mouse.press && is_mouseinside(scene) # && !active
                drag_state[] = (true, mouseposition_px(scene), time())
                return Consume(true)
            elseif event.action == Mouse.release && active
                dt = time() - last_time
                if dt < timeout[]
                    # do click stuff
                    p, idx = Makie.pick(scene)
                    if p isa Text
                        phi, theta = [
                            (pi, 0), (pi, 0), (0, 0), 
                            (-pi/2, 0), (-pi/2, 0), (pi/2, 0), 
                            (cam.phi[], -pi/2), (cam.phi[], -pi/2), (cam.phi[], pi/2)
                        ][idx]
                        update_cam!(scene, cam, phi, theta)
                        update_camera!(axis, cam.phi[], cam.theta[])
                    elseif p isa Mesh
                        face_idx = p[1][].index[idx]
                        phi, theta = [
                            (cam.phi[], -pi/2),
                            (3pi/4, -pi/4), (1pi/4, -pi/4), (7pi/4, -pi/4), (5pi/4, -pi/4),
                            (pi/2, -pi/4), (0, -pi/4), (-pi/2, -pi/4), (-pi, -pi/4),
                            (3pi/4, 0), (2pi/4, 0), (pi/4, 0), (0, 0), 
                            (7pi/4, 0), (6pi/4, 0), (5pi/4, 0), (pi, 0),
                            (pi/2, pi/4), (pi, pi/4), (3pi/2, pi/4), (0, pi/4),
                            (5pi/4, pi/4), (7pi/4, pi/4), (pi/4, pi/4), (3pi/4, pi/4),
                            (cam.phi[], pi/2)
                        ][face_idx]
                        @info "From Click: $phi, $theta"
                        update_cam!(scene, cam, phi, theta)
                        update_camera!(axis, cam.phi[], cam.theta[])
                    end
                else
                    # do drag stuff
                    mousepos = mouseposition_px(scene)
                    rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
                    mp = (last_mousepos .- mousepos) .* 0.01f0 .* rot_scaling
                    rotate_cam!(scene, cam, mp[1], mp[2], axis)
                end
                drag_state[] = (false, Vec2f(0), time())
                println()

                return Consume(true)
            end
        end

        return Consume(false)
    end

    # in drag
    on(camera(scene), e.mouseposition) do mp
        active, last_mousepos, last_time = drag_state[]
        if active && ispressed(scene, Mouse.left)
            mousepos = screen_relative(scene, mp)
            rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos .- mousepos) * 0.01f0 * rot_scaling
            rotate_cam!(scene, cam, mp[1], mp[2], axis)
            drag_state[] = (active, mousepos, last_time)
            println()
            return Consume(true)
        end

        return Consume(false)
    end
end

# function rotate_cam!(scene, cam::ViewportControllerCamera, angles::VecTypes, axis)
function rotate_cam!(scene, cam::ViewportControllerCamera, dphi::Real, dtheta::Real, axis)
    @info dphi, dtheta
    cam.theta[] = mod(cam.theta[] + dtheta, 2pi)
    reverse = ifelse(pi/2 <= cam.theta[] <= 3pi/2, -1, 1)
    cam.phi[] = mod(cam.phi[] + reverse * dphi, 2pi)

    update_cam!(scene, cam)    
    update_camera!(axis, cam.phi[], cam.theta[])

    return
end

# Update camera matrices
function update_cam!(scene::Scene, cam::ViewportControllerCamera, phi::Real, theta::Real)
    dphi = mod(2pi + cam.phi[] - phi, 2pi)
    print(dphi, " -> ")
    dphi = ifelse(dphi > pi, dphi - 2pi, dphi)
    println(dphi)
    if !(-pi/2 <= dphi <= pi/2)
        cam.phi[]   = mod(phi + pi, 2pi)
        cam.theta[] = mod(pi - theta, 2pi)
    else
        cam.phi[] = phi
        cam.theta[] = theta
    end
    return update_cam!(scene, cam)
end

function update_cam!(scene::Scene, cam::ViewportControllerCamera)
    # @extractvalue cam (lookat, eyeposition, upvector)
    fov = cam.attributes.fov[]

    phi = cam.phi[]; theta = cam.theta[]
    @info "update mat: $phi, $theta"
    eyeposition = 3f0 * Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
    lookat = Vec3f(0)
    theta += pi/2
    upvector = Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))

    view = Makie.lookat(eyeposition, lookat, upvector)

    aspect = Float32((/)(widths(scene.px_area[])...))
    if cam.attributes.projectiontype[] == Makie.Perspective
        view_norm = norm(eyeposition - lookat)
        proj = Makie.perspectiveprojection(Float32(fov), aspect, view_norm * 0.1f0, view_norm * 2f0)
    else
        h = norm(eyeposition - lookat); w = h * aspect
        proj = Makie.orthographicprojection(-w, w, -h, h, h * 0.1f0, h * 2f0)
    end

    Makie.set_proj_view!(camera(scene), proj, view)
    scene.camera.eyeposition[] = eyeposition

    return
end

# update controller based on axis
function connect_camera!(ax::Axis3, scene::Scene)
    cam = cameracontrols(scene)
    onany(ax.elevation, ax.azimuth) do theta, phi
        update_cam!(scene, cam, phi, theta)
        return
    end
    notify(ax.elevation)
    return
end

function connect_camera!(lscene::LScene, scene::Scene)
    cam = cameracontrols(lscene.scene)
    onany(camera(lscene.scene).view) do _
        @extractvalue cam (lookat, eyeposition, upvector)

        dir = normalize(eyeposition - lookat)
        theta = asin(dir[3]) 
        theta = mod(2pi + ifelse(upvector[3] > 0, theta, pi - theta), 2pi)
        if abs(dir[3]) > 0.9
            right = cross(upvector, dir)
            p = right[Vec(1,2)]
            p = p / norm(p)
            phi = mod(3pi/2 + atan(p[2], p[1]), 2pi)
        else
            p = dir[Vec(1,2)]
            p = p / norm(p)
            phi = mod(2pi + atan(p[2], p[1]) + ifelse(pi/2 <= theta <= 3pi/2, pi, 0), 2pi)
        end
        @info "from other: $phi, $theta"
        update_cam!(scene, scene.camera_controls, phi, theta)
        return
    end
    notify(camera(lscene.scene).view)
    return
end

# Update axis based on controller 
function update_camera!(ax::Axis3, phi, theta)
    ax.azimuth[] = phi
    ax.elevation[] = theta
    return
end

function update_camera!(lscene::LScene, phi, theta)
    cam = cameracontrols(lscene.scene)
    dir = Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
    viewdir = cam.eyeposition[] - cam.lookat[]
    theta += pi/2
    upvector = Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
    eyepos = cam.lookat[] + norm(viewdir) * dir
    update_cam!(lscene.scene, cam, eyepos, cam.lookat[], upvector)
    return
end


################################################################################
### Create Block
################################################################################


# Create Controller
Viewport3DController(x, axis::Union{LScene, Axis3}; kwargs...) = Viewport3DController(x; axis = axis, kwargs...)

function initialize_block!(controller::Viewport3DController; axis)
    blockscene = controller.blockscene

    scene = Scene(
        blockscene, 
        px_area = lift(round_to_IRect2D, blockscene, controller.layoutobservables.computedbbox), 
        # backgroundcolor = controller.backgroundcolor,
        clear = true
    )

    m = Rhombicuboctahedron()
    mesh!(scene, m, transparency = false)
    text!(scene,
        1.05 .* Point3f[(-1, 0, 0), (1, 0, 0), (0, -1, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)],
        text = ["-X", "X", "-Y", "Y", "-Z", "Z"],
        align = (:center, :center),
        rotation = [
            Makie.qrotation(Vec3f(1, 0, 0), pi/2) * Makie.qrotation(Vec3f(0, 1, 0), -pi/2),
            Makie.qrotation(Vec3f(1, 0, 0), -pi/2) * Makie.qrotation(Vec3f(0, 1, 0), pi/2),
            Makie.qrotation(Vec3f(0, 1, 0), 0) * Makie.qrotation(Vec3f(1, 0, 0), -3pi/2),
            Makie.qrotation(Vec3f(1, 0, 0), pi/2),
            Makie.qrotation(Vec3f(1, 0, 0), pi),
            Makie.qrotation(Vec3f(1, 0, 0), 0),
        ],
        markerspace = :data, fontsize = 0.4, color = :white,
        strokewidth = 0.1, strokecolor = :black, transparency = false
    )

    ViewportControllerCamera(scene, axis)

    return
end
