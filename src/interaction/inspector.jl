struct DataInspector
    parent::Scene
    attributes::Attributes
    plots::Vector{ScenePlot}

    whitelist::Vector{ScenePlot}
    blacklist::Vector{ScenePlot}
end


function data_inspector(
        scene; 
        whitelist = ScenePlot[], blacklist = ScenePlot[], range = 10
    )

    inspector = DataInspector(
        scene,
        Attributes(
            display_text = " ",
            position = Point3f0(0),
            visible = false,
            halign = :left,
            bbox = Rect3D(Vec3f0(0,0,0),Vec3f0(1,1,1)),
            bbox_visible = false,
        ),
        ScenePlot[], whitelist, blacklist
    )

    on(events(scene).mouseposition) do mp
        # This is super cheap
        is_mouseinside(scene) || return false

        plt, idx = pick(scene, mp, range)
        @info idx, typeof(plt)
        if plt === nothing
            inspector.attributes.visible[] = false
            inspector.attributes.bbox_visible[] = false
        else
            show_data(inspector, plt, idx)
        end
    end

    draw_data_inspector!(inspector)

    inspector
end


position2string(p::Point2f0) = @sprintf("x: %0.6f\ny: %0.6f", p[1], p[2])
position2string(p::Point3f0) = @sprintf("x: %0.6f\ny: %0.6f\nz: %0.6f", p[1], p[2], p[3])

function Bbox_from_glyphlayout(gl)
    bbox = FRect3D(
        gl.origins[1] .+ Vec3f0(origin(gl.bboxes[1])..., 0), 
        Vec3f0(widths(gl.bboxes[1])..., 0)
    )
    for (o, bb) in zip(gl.origins[2:end], gl.bboxes[2:end])
        bbox2 = FRect3D(o .+ Vec3f0(origin(bb)..., 0), Vec3f0(widths(bb)..., 0))
        bbox = union(bbox, bbox2)
    end
    bbox
end
function text2worldbbox(p::Text)
    if p._glyphlayout[] isa Vector
        @info "TODO"
    else
        map(p._glyphlayout, p.position, camera(p.parent).projectionview, pixelarea(p.parent)) do gl, pos, pv, area
            px_pos = AbstractPlotting.project(pv, Vec2f0(widths(area)), to_ndim(Point3f0, pos, 0))
            px_bbox = Bbox_from_glyphlayout(gl) + to_ndim(Vec3f0, px_pos, 0)
            # @info px_bbox
            px_bbox = px_bbox - Vec3f0(0.5widths(area)..., 0)
            # @info px_bbox
            px_bbox = FRect3D(
                2 .* origin(px_bbox) ./ Vec3f0(widths(area)..., 1),
                2 .* widths(px_bbox) ./ Vec3f0(widths(area)..., 1)
            )
            # @info px_bbox
            # p00 = 2 .* (origin(px_bbox) .- Vec3f0(0.5widths(area)..., 0)) ./ Vec3f0(widths(area)..., 1)
            # p11 = p0 .+ 2 * widths(px_bbox) ./ Vec3f0(widths(area)..., 1)
            ps = unique(coordinates(px_bbox))
            inv_pv = inv(pv)
            # world_p0 = inv_pv * Vec4f0(p0..., 1); world_p0 = world_p0 / world_p0[4]
            # world_p1 = inv_pv * Vec4f0(p1..., 1); world_p1 = world_p1 / world_p1[4]
            # world_bbox = FRect3D(world_p0[SOneTo(3)], world_p1[SOneTo(3)] .- world_p0[SOneTo(3)])
            world_ps = map(ps) do p
                proj = inv_pv * Vec4f0(p..., 1)
                proj[SOneTo(3)] / proj[4]
            end
            minx, maxx = extrema(getindex.(world_ps, (1,)))
            miny, maxy = extrema(getindex.(world_ps, (2,)))
            minz, maxz = extrema(getindex.(world_ps, (3,)))
            world_bbox = FRect3D(Point3f0(minx, miny, minz), Vec3f0(maxx-minx, maxy-miny, maxz-minz))
            # world_bbox = inv(pv) * px_bbox
            # @info world_bbox
            world_bbox
        end
    end
end
function text2pixelbbox(p::Text)
    if p._glyphlayout[] isa Vector
        @info "TODO"
    else
        map(Bbox_from_glyphlayout, p._glyphlayout)
    end
end


function draw_data_inspector!(inspector)
    a = inspector.attributes
    p1 = text!(
        inspector.parent, a.display_text, 
        position = a.position, visible = a.visible, halign = a.halign,
        overdraw=true
    )
    map(p1.position, camera(inspector.parent).projectionview, pixelarea(inspector.parent)) do pos, pv, area
        projected = AbstractPlotting.project(pv, Vec2f0(widths(area)), to_ndim(Point3f0, pos, 0))
        # @info "Before: $pos"
        # @info "After: $projected"
        nothing
    end
    tbb = wireframe!(
        inspector.parent, text2worldbbox(p1),
        color = :lightblue, shading = false, visible = a.visible, overdraw=true
    )
    bg = mesh!(
        inspector.parent, 
        map(
                p1.position, 
                camera(inspector.parent).projectionview, 
                pixelarea(inspector.parent),
                text2pixelbbox(p1)
            ) do pos, pv, area, bbox
            projected = AbstractPlotting.project(pv, Vec2f0(widths(area)), to_ndim(Point3f0, pos, 0))
            bbox + to_ndim(Point3f0, projected, 0) + Point3f0(0, 0, 1e-3) # -4, 1, 
        end, 
        color = :orange, shading = false, visible = a.visible, overdraw=true,
        model = map(
                p1.position,
                camera(inspector.parent).projectionview, 
                inspector.parent.px_area
            ) do pos, pv, rect
            projected = AbstractPlotting.project(pv, Vec2f0(widths(rect)), to_ndim(Point3f0, pos, 0))
            inv(pv) * 
            scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
            translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
        end
    )
    p2 = scatter!(
        inspector.parent, map(x -> [x], a.position), 
        color = (:yellow, 0.5), strokecolor = :red, overdraw=true,
        visible = a.visible
    )
    p3 = wireframe!(
        inspector.parent, a.bbox,
        color = :red, visible = a.bbox_visible, overdraw=true
    )
    push!(inspector.plots, p1, p2, p3, bg, tbb)
    nothing
end


function show_data(inspector::DataInspector, plot::Union{Scatter, MeshScatter}, idx)
    @info "Scatter, MeshScatter"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        pos = to_ndim(Point3f0, plot[1][][idx], 0)
        a.position[] = pos
        a.display_text[] = position2string(pos)
        a.visible[] = true
    end
end



function closest_point_on_line(p0::Point2f0, p1::Point2f0, r::Point2f0)
    # This only works in 2D
    AP = P .- A; AB = B .- A
    A .+ AB * dot(AP, AB) / dot(AB, AB)
end

function view_ray(scene)
    inv_projview = inv(camera(scene).projectionview[])
    view_ray(inv_projview, events(scene).mouseposition[], pixelarea(scene)[])
end
function view_ray(inv_view_proj, mpos, area::Rect2D)
    # This figures out the camera view direction from the projectionview matrix (?)
    # and computes a ray from a near and a far point.
    # Based on ComputeCameraRay from ImGuizmo
    mp = 2f0 .* (mpos .- minimum(area)) ./ widths(area) .- 1f0
    v = inv_view_proj * Vec4f0(0, 0, -10, 1)
    reversed = v[3] < v[4]
    near = reversed ? 1f0 - 1e-6 : 0f0
    far = reversed ? 0f0 : 1f0 - 1e-6

    origin = inv_view_proj * Vec4f0(mp[1], mp[2], near, 1f0)
    origin = origin[SOneTo(3)] ./ origin[4]

    p = inv_view_proj * Vec4f0(mp[1], mp[2], far, 1f0)
    p = p[SOneTo(3)] ./ p[4]

    dir = normalize(p - origin)
    return origin, dir
end


# These work in 2D and 3D
function closest_point_on_line(A, B, origin, dir)
    closest_point_on_line(
        to_ndim(Point3f0, A, 0),
        to_ndim(Point3f0, B, 0),
        to_ndim(Point3f0, origin, 0),
        to_ndim(Vec3f0, dir, 0)
    )
end
function closest_point_on_line(A::Point3f0, B::Point3f0, origin::Point3f0, dir::Vec3f0)
    # See:
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection
    u_AB = normalize(B .- A)
    u_dir = normalize(dir)
    u_perp = normalize(cross(u_dir, u_AB))
    # e_RD, e_perp defines a plane with normal n
    n = normalize(cross(u_dir, u_perp))
    t = dot(origin .- A, n) / dot(u_AB, n)
    A .+ t * u_AB
end

function show_data(inspector::DataInspector, plot::Union{Lines, LineSegments}, idx)
    @info "Lines, LineSegments"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        if plot.parent.parent isa BarPlot
            return show_data(inspector, plot.parent.parent, div(idx-1, 6)+1)
        end

        pos = mouseposition(inspector.parent)
        p0, p1 = plot[1][][idx-1:idx]
        origin, dir = view_ray(inspector.parent)
        p = closest_point_on_line(p0, p1, origin, dir)
        a.position[] = p
        a.display_text[] = position2string(p)
        a.visible[] = true
    end
end

function bbox2string(bbox::Rect3D)
    p = origin(bbox)
    w = widths(bbox)
    @sprintf(
        "Bounding Box:\nx: (%0.3f, %0.3f)\ny: (%0.3f, %0.3f)\nz: (%0.3f, %0.3f)",
        p[1], w[1], p[2], w[2], p[3], w[3]
    )
end

function show_data(inspector::DataInspector, plot::Mesh, idx)
    @info "Mesh"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        if plot.parent.parent.parent isa BarPlot
            return show_data(inspector, plot.parent.parent.parent, div(idx-1, 4)+1)
        end

        bbox = boundingbox(plot)
        min, max = extrema(bbox)
        p = 0.5 * (max .+ min)
        a.position[] = p
        a.display_text[] = bbox2string(bbox)
        a.bbox[] = bbox
        a.visible[] = true
        a.bbox_visible[] = true
    end
end

function show_data(inspector::DataInspector, plot::BarPlot, idx)
    @info "BarPlot"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        pos = plot[1][][idx]
        bbox = plot.plots[1][1][][idx]
        a.position[] = to_ndim(Point3f0, pos, 0)
        a.display_text[] = position2string(pos)
        a.bbox[] = FRect3D(bbox)
        a.visible[] = true
        a.bbox_visible[] = true
    end
end

pos2index(x, r, N) = ceil(Int, N * (x - minimum(r)) / (maximum(r) - minimum(r) + 1e-10))
index2pos(i, r, N) = minimum(r) + (maximum(r) - minimum(r)) * (i-1) / (N-1)

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    # This is a mess but it'll need to be updated once Heatmaps are centered 
    # anyway...
    @info "Heatmap"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        # idx == 0 :(
        mpos = mouseposition(inspector.parent)
        i = pos2index(mpos[1], plot[1][], size(plot[3][], 1))
        j = pos2index(mpos[2], plot[2][], size(plot[3][], 2))
        x = index2pos(i, plot[1][], size(plot[3][], 1))
        y = index2pos(j, plot[2][], size(plot[3][], 2))
        z = plot[3][][i, j]

        # bbox = plot.plots[1][1][][idx]
        a.position[] = Point3f0(x, y, 0)
        a.display_text[] = @sprintf("%0.3f @ (%i, %i)", z, i, j)
        # a.bbox[] = FRect3D(bbox)
        a.visible[] = true
        # a.bbox_visible[] = true
    end
end


function show_data(inspector::DataInspector, plot, idx)
    @info "else"
    inspector.attributes.visible[] = false
    inspector.attributes.bbox_visible[] = false

    nothing
end

# barplot 
# 

# wireframe!(ax.scene, 
#     bboxes[1], #map(first, bboxes), 
#     color = :red, 
#     model = map(
#             camera(ax.scene).projectionview, 
#             ax.scene.px_area
#         ) do pv, rect
#         inv(pv) * 
#         scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
#         translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
#     end
# )
# wireframe!(ax.scene, 
#     bboxes[2], #map(first, bboxes), 
#     color = :red, 
#     model = map(
#             camera(ax.scene).projectionview, 
#             ax.scene.px_area
#         ) do pv, rect
#         inv(pv) * 
#         scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
#         translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
#     end
# )

# wireframe!(ax.scene, 
#     bbox, 
#     color = :red, 
#     model = map(
#             camera(ax.scene).projectionview, 
#             ax.scene.px_area
#         ) do pv, rect
#         inv(pv) * 
#         scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
#         translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
#     end
# )

# using AbstractPlotting: origin
# fig, ax, p = text("He\nllo")
# bbox = AbstractPlotting.screenspace_boundingbox(p)
# adjusted = map(bbox, pixelarea(fig.scene), pixelarea(ax.scene)) do bb, trg, src
#     bb + to_ndim(Vec3f0, origin(src), 0) - to_ndim(Vec3f0, origin(trg), 0)
# end
# wireframe!(fig.scene, adjusted, color=:red)
# fig

# using AbstractPlotting: origin, scalematrix, translationmatrix
# fig, ax, p = text(["Hello", "hi"], position=[Point3f0(0), Point3f0(1,1,2)])
# bboxes = AbstractPlotting.screenspace_boundingbox(p)
# wireframe!(ax.scene, 
#     bboxes[1], #map(first, bboxes), 
#     color = :red, 
#     model = map(
#             camera(ax.scene).projectionview, 
#             ax.scene.px_area
#         ) do pv, rect
#         inv(pv) * 
#         scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
#         translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
#     end
# )
# wireframe!(ax.scene, 
#     bboxes[2], #map(first, bboxes), 
#     color = :red, 
#     model = map(
#             camera(ax.scene).projectionview, 
#             ax.scene.px_area
#         ) do pv, rect
#         inv(pv) * 
#         scalematrix(Vec3f0((2.0 ./ widths(rect))..., 1)) *
#         translationmatrix(Vec3f0(-0.5widths(rect)..., 0))
#     end
# )
# fig

# # This does not work...?
# adjusted = map(bboxes) do bbox
#     map(bbox, pixelarea(fig.scene), pixelarea(ax.scene)) do bb, trg, src
#         bb + to_ndim(Vec3f0, origin(src), 0) - to_ndim(Vec3f0, origin(trg), 0)
#     end
# end
# wireframe!(fig.scene, adjusted[1], color=:red)
# wireframe!(fig.scene, adjusted[2], color=:blue)
# fig