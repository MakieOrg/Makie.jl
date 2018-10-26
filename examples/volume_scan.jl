using Makie, GeometryTypes, Colors
using AbstractPlotting: slider!, playbutton
using Observables

cd(@__DIR__)
using Pkg
Pkg.pkg"add NRRD"
using FileIO
data = load(joinpath(homedir(), "desktop", "brain.nrrd"))
psps = [rand(50, 50, 50) for i in 1:50]


mini, maxi = mapreduce(extrema, (a, b)-> (min(a[1], b[1]), max(a[2], b[2])), psps)
psps_n = map(psps) do vol
    Float32.((vol .- mini) ./ (maxi - mini))
end

volume100 = last(psps_n)
scene = Scene()
g_area = map(scene.px_area) do a
    IRect(0, 0, widths(a)[1], 50)
end
legend_w = 110
vol_area = map(scene.px_area) do a
    w, h = widths(a)
    w = w - legend_w
    IRect(0, 50, w / 2, h - 50)
end
heat_area = map(scene.px_area) do a
    w, h = widths(a)
    w = w - legend_w
    IRect(w / 2, 50, w / 2, h - 50)
end
gui = Scene(scene, g_area)
campixel!(gui)
theme(gui)[:plot] = NT(raw = true)


scene3d = Scene(scene, vol_area)
hscene = Scene(scene, heat_area)
cam3d!(scene3d)
r = range(-1, stop = 1, length = size(volume100, 1))
c = contour!(
    scene3d, r, r, r, volume100,
    alpha = 0.4, levels = 8, colorrange = (0.0, 1.0)
)[end]

rotate!(hscene, Vec3f0(0, 1, 0), -0.5pi)

volume = c[4]
planes = (:xy, :xz, :yz)
sliders = ntuple(3) do i
    s = slider!(gui, 1:size(volume[], i))[end]
    move!(s, size(volume[], i) ÷ 2)
    idx = s[:value]; plane = planes[i]
    indices = ntuple(3) do j
        planes[j] == plane ? 1 : (:)
    end
    hmap = contour!(
        hscene, r, r, volume[][indices...],
        raw = true, colorrange = (0.0, 1.0), fillrange = true,
        interpolate = true, linewidth = 0.1
    )[end]
    foreach(idx, volume) do _idx, vol
        idx = (i in (1, 2)) ? (size(vol, i) - _idx) + 1 : _idx
        transform!(hmap, (plane, r[_idx]))
        indices = ntuple(3) do j
            planes[j] == plane ? idx : (:)
        end
        if checkbounds(Bool, vol, indices...)
            hmap[3][] = view(vol, indices...)
        end
    end
    s
end
t = nothing
b = playbutton(gui, 1:length(psps_n)) do idx
    println(idx)
    move!(t, idx)
end
t = slider!(gui, 1:length(psps_n))[end];
foreach(t[:value]) do idx
    if checkbounds(Bool, psps_n, idx)
        c[4][] = psps_n[idx]
    end
end

b2 = button(gui, "3d/2d"; dimensions = (60, 40)) do clicks
    if iseven(clicks)
        cam3d!(hscene)
    else
        cam2d!(hscene)
        update_cam!(hscene, FRect(-1.25, -1.25, 2.5, 2.5))
    end
end

AbstractPlotting.vbox(gui.plots)

l = lines!(hscene, FRect(-1.01, -1.01, 2.02, 2.02), color = :black, linewidth = 2, raw = true)
transform!(l, (:yz, -1.0))
pixelarea(scene)[] = IRect(0,0,1500, 1000)
scene
