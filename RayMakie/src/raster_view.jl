"""
    raster_view(screen, camera_scene, background; key=:editorview)

Render the screen's existing 3D raster objects through an independent camera.
Geometry, textures and materials are reused. Only draw uniforms are overridden,
under the caller's render lock, and restored before returning. This does not
seek animation, change the authored scene camera or replace its picking frame.
`background` is a persistent `(height,width)` device image for this view.
"""
function raster_view(screen::Screen, camera_scene::Scene, background; key = :editorview)
    screen.rasterize || throw(ArgumentError("an editor view needs a raster screen"))
    h, w = size(background)
    for state in screen.scene_states
        screen.state = state
        poll_all_plots(screen, state.makie_scene)
    end
    allobjects = overlay_robjs(screen)
    robjs = [
        (obj, (0.0f0, Float32(h), Float32(w), -Float32(h)))
            for (obj, _) in allobjects if
            Makie.cameracontrols(Makie.parent_scene(obj.uniforms[:pick_plot])) isa Makie.Camera3D &&
            Makie.to_value(obj.uniforms[:pick_plot].space) === :data
    ]
    view = Mat4f(camera_scene.camera.view[])
    projection = Mat4f(camera_scene.camera.projection[])
    eye = Vec3f(Makie.cameracontrols(camera_scene).eyeposition[])
    saved = [copy(obj.uniforms) for (obj, _) in robjs]
    try
        for (i, (obj, _)) in enumerate(robjs)
            uniforms = obj.uniforms
            overrides = (;
                view, projection, projectionview = projection * view,
                eyeposition = eye, resolution = Vec2f(w, h), px_per_unit = 1.0f0,
                viewport_origin = Vec2f(0),
            )
            for (name, value) in pairs(overrides)
                haskey(uniforms, name) && (uniforms[name] = value)
            end
            if haskey(uniforms, :view_normalmatrix)
                uniforms[:view_normalmatrix] = Mat3f(view[1:3, 1:3]) * uniforms[:world_normalmatrix]
            end
            uniforms[:fxaa] = reinterpret(Int32, (UInt32(i) << 1) | (reinterpret(UInt32, uniforms[:fxaa]) & UInt32(1)))
        end
        plan, out = frame_plan!(
            screen, key,
            g -> Mantle.Transient.Image(g, COMPOSITE_FORMAT, (w, h)),
            Mantle.Clear((0.0f0, 0.0f0, 0.0f0, 1.0f0)), background, robjs, w, h;
            finish = function (g, img)
                pixels = Mantle.Transient.Buffer(g, COMPOSITE_FORMAT, w * h)
                Mantle.copy!(g, "read view", pixels, img)
                return pixels
            end
        )
        Mantle.run!(plan)
        frame = merge(out, (; ppu = 1.0))
        return (;
            image = unswizzle(reshape(Array(Mantle.storage(out.result)), w, h), w, h),
            frame, projectionview = projection * view,
        )
    finally
        for ((obj, _), uniforms) in zip(robjs, saved)
            empty!(obj.uniforms)
            merge!(obj.uniforms, uniforms)
        end
    end
end

"Release an independent view's render targets without closing the film screen."
function close_raster_view!(screen::Screen; key = :editorview)
    cached = pop!(screen.frame_plans, key, nothing)
    cached === nothing && return nothing
    Mantle.free!(cached[2])
    Mantle.free!(cached[3].pixels)
    return nothing
end
