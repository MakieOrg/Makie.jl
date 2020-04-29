################################################################################
#                             Projection utilities                             #
################################################################################

function project_position(scene, point, model)
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    @inbounds begin
    # between -1 and 1
        p = (clip ./ clip[4])[Vec(1, 2)]
        # flip y to match cairo
        p_yflip = Vec2f0(p[1], -p[2])
        # normalize to between 0 and 1
        p_0_to_1 = (p_yflip .+ 1f0) / 2f0
    end
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

project_scale(scene::Scene, s::Number, model = Mat4f0(I)) = project_scale(scene, Vec2f0(s), model)

function project_scale(scene::Scene, s, model = Mat4f0(I))
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = @inbounds (scene.camera.projectionview[] * model * p4d)[Vec(1, 2)] ./ 2f0
    return p .* scene.camera.resolution[]
end

function project_rect(scene, rect::Rect, model)
    mini = project_position(scene, minimum(rect), model)
    maxi = project_position(scene, maximum(rect), model)
    return Rect(mini, maxi .- mini)
end
