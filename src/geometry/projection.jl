function project_position(scene, point, model)
    # use transform func
    res = widths(scene.camera)
    p4d = to_ndim(Vec4f, to_ndim(Vec3f, point, 0.0f0), 1.0f0)
    clip = scene.camera.projectionview[] * model * p4d
    @inbounds begin
        # between -1 and 1
        p = (clip./clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f(p[1], -p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1.0f0) ./ 2.0f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

project_scale(scene, s::Number, model = Mat4f(I)) = project_scale(scene, Vec2f(s), model)

function project_scale(scene, s, model = Mat4f(I))
    p4d = to_ndim(Vec4f, s, 0.0f0)
    p = @inbounds (scene.camera.projectionview[]*model*p4d)[Vec(1, 2)] ./ 2.0f0
    return p .* widths(scene.camera)
end
