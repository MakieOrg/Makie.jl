# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    #hideall
using GLMakie, LinearAlgebra

function myarrows!(scene, ps; kwargs...)
    ends = map(ps) do ps
        output = Int[]
        for i in eachindex(ps)
            isnan(ps[i]) && push!(output, i-1)
        end
        push!(output, length(ps))
        output
    end

    dict = Dict(kwargs)
    endpoints = map((ps, is) -> ps[is], ps, ends)
    dirs = map(
      (ps, is) -> -Makie.quaternion_to_2d_angle.(Makie.to_rotation(normalize.(ps[is] .- ps[is .- 1]))),
      ps, ends)
    cols = map(is -> dict[:color] isa Vector ? dict[:color][is] : dict[:color], ends)

    lines!(scene, ps; kwargs...)
    scatter!(
        scene, endpoints, marker = Makie.BezierUTriangle, color = cols,
        rotation = dirs
    )
end

scene = Scene(size = (1220, 200))
campixel!(scene)

# init space label data
spacing = 80
y0 = 80
ps = Observable(Point2f.(1:8, y0))
# spaces = [":data", "transformed64", "world", "eye", ":clip", "screen"]
spaces = ["plot.args", "plot.converted", "transformed64", "transformed32", "world", "eye", "clip", "screen"]

# plot space labels
p = text!(
    scene, ps, text = spaces, align = (:left, :center),
    fontsize = 20,
    color = [:black, :black, :gray, :gray, :gray, :gray, :gray, :gray]
)

# update space label data & derive arrows
centers = Observable(Point2f[])
text_centers = Observable(Point2f[])
map!(ps, p.plots[1][1]) do gcs
    edge = -spacing + 10
    xvals = Float64[]
    xcenters = Float64[]

    for gc in gcs
        bb = Makie.string_boundingbox(gc, Quaternionf(0,0,0,1))
        left = spacing + edge - minimum(bb)[1]
        push!(xvals, left)
        push!(xcenters, left + 0.5 * widths(bb)[1])
        edge = left + widths(bb)[1]
    end

    text_centers[] = Point2f.(xcenters, y0)
    centers[] = Point2f.(xvals[2:end] .- 0.5spacing, y0)

    return Point2f.(xvals, y0)
end

arrowpos = map(centers) do centers
    half = 0.5 * spacing - 5
    ps = Point2f[]
    lws = Float64[]
    for center in centers
        x, y = center
        push!(ps, Point2f(x-half, y), Point2f(x+half-5, y), Point2f(NaN))
        # push!(ps, Point2f(x-half, y), Point2f(x+half-8, y))
        # push!(ps, Point2f(x+half-10, y), Point2f(x+half, y))
        # push!(lws, 2, 2, 12, 0)
    end
    ps
end

# plot arrows
myarrows!(
    scene, arrowpos, linewidth = 2,
    color = [c for c in [:red, :red, :red, :green, :green, :green, :gray] for _ in 1:3]
)

# transformation labels
transformations = ["convert_arguments", "transform_func", "Float32Convert", "model", "view", "projection", "viewport"]
trans_offset = 25
text!(
    scene, centers, text = transformations, align = (:center, :center),
    offset = (0, trans_offset),
    color = [:black, :orange, :black, :orange, :cyan, :cyan, :gray]
)

# Transformation
bracket_offset = Point2f(0, trans_offset + 15)
trans_bracket_pos = map(centers) do cs
    [cs[2] + bracket_offset, cs[4] + bracket_offset]
end
text!(
  scene, trans_bracket_pos, text = ["Transformation" for _ in 1:2],
  color = :orange, align = (:center, :bottom))

# Camera
cam_bracket_pos = map(centers) do cs
    (cs[5] + bracket_offset, cs[6] + bracket_offset)
end
bracket!(
    scene,
    cam_bracket_pos,
    text = "Camera",
    color = :cyan, textcolor = :cyan
)

# CPU
dx = 10; dy = -20
cpu_bracket_pos = map(text_centers) do ps
    (ps[1] .+ (dx, dy), ps[4] .+ (-dx, dy))
end
bracket!(
    scene,
    cpu_bracket_pos,
    text = "CPU",
    color = :red, textcolor = :red,
    orientation = :down
)

# GPU
gpu_bracket_pos = map(text_centers) do ps
    (ps[4] .+ (dx, dy), ps[7] .+ (-dx, dy))
end
bracket!(
    scene,
    gpu_bracket_pos,
    text = "GPU",
    color = :green, textcolor = :green,
    orientation = :down
)

# Internal
internal_bracket_pos = map(text_centers) do ps
    (ps[7] .+ (dx, dy), ps[8] .+ (-dx, dy))
end
bracket!(
    scene,
    internal_bracket_pos,
    text = "GPU Internal",
    color = :gray, textcolor = :gray,
    orientation = :down
)

# Float32Convert
f32_ps = map(text_centers) do cs
    x1, y1 = cs[2]
    x5, y5 = cs[3]
    x2, y2 = 0.5 * (cs[3] .+ cs[4])
    x3, y3 = cs[6]
    x4, y4 = 0.5 * (cs[4] .+ cs[5])
    Point2f[
        (x1, y1+15), (x1, y1+65), (NaN, NaN),
        (x1+45, y1+83), (x5, y5+83), (x5, y2+25), (x5+45, y2+25), (NaN, NaN),
        (x5-50, y2+25), (x5-10, y2+25), (NaN, NaN),
        (x2+20, y2+40), (x2+20, y2+100), (x3, y3+100), (x3, y3+80), (NaN, NaN),
        (x2+60, y2+25), (x4-15, y4+25)
    ]
end
myarrows!(scene, f32_ps, color = :gray)
text!(
    scene, map(ps -> ps[2], f32_ps), text = "ax.finallimits",
    align = (:center, :bottom), offset = Vec2f(0, 10)
)

scene
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_7a0594b5_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_7a0594b5.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide