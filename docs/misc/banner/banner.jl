using GLMakie
GLMakie.activate!()

##

function copy_scene_settings(s)
    cc = cameracontrols(s)
    return (
        viewport = s.viewport[],
        eyeposition = cc.eyeposition[],
        lookat = cc.lookat[],
        upvector = cc.upvector[],
        zoom_mult = cc.zoom_mult[],
        fov = cc.fov[],
        near = cc.near[],
        far = cc.far[],
        pulser = cc.pulser[],
    )
end

function apply_camera_settings!(s, settings)
    cc = cameracontrols(s)
    cc.eyeposition[] = settings.eyeposition
    cc.lookat[] = settings.lookat
    cc.upvector[] = settings.upvector
    cc.zoom_mult[] = settings.zoom_mult
    cc.fov[] = settings.fov
    cc.near[] = settings.near
    cc.far[] = settings.far
    cc.pulser[] = settings.pulser
    Makie.update!(s)
    Makie.update!(s)
    resize!(s, settings.viewport)
    return
end

##
s = Scene(camera = cam3d!, show_axis = false, center = false)
r = range(-2, 15, length = 60)
wireframe!(
    s, r, r, ((x, y) -> sin(x) * cos(y) * max((x - 2) / 7, 0)).(r, (r)'),
    transparency = true
)

apply_camera_settings!(s, settings)

s

##


settings = copy_scene_settings(s)


##

settingsfile = joinpath(@__DIR__, "camerasettings.txt")

if !isfile(settingsfile)
    open(settingsfile, "w") do file
        print(file, repr(settings))
    end
else
    @warn "settingsfile exists already"
end


##

using CairoMakie
CairoMakie.activate!()

save(joinpath(@__DIR__, "bannermesh.png"), s, px_per_unit = 2)
