# TODO
# - add 3D bounding boxes (on pixel scene via projection...?)
# - add finalizer to clean up indicator plots

# checklist:
#=
- scatter 2D :)
- scatter 3D :)
- LScene Axis :(
- lines 2D :)
- lines 3D :)
- meshscatter 2D :/ (bad bboxes)
- meshscatter 3D :/
- linesegments 3D :)
- linesegments 2D :)
- heatmap :/ (bad bbox)
- barplot :/ (bad bbox)
=#

struct DataInspector
    parent::Scene

    attributes::Attributes
    plots::Vector{AbstractPlot}

    whitelist::Vector{AbstractPlot}
    blacklist::Vector{AbstractPlot}
end

function data_inspector(fig::Figure; blacklist = flatten_plots(fig.scene.plots), kwargs...)
    data_inspector(fig.scene; blacklist = blacklist, kwargs...)
end

# Probably needs do defined elsewhere or this file needs to be moved
# using ..MakieLayout: Axis, Axis3, LScene
# function data_inspector(ax::Union{Axis, Axis3, LScene}; whitelist = ax.scene.plots, kwargs...)
#     parent = root(ax.scene)
#     data_inspector(parent; whitelist = whitelist, kwargs...)
# end

function data_inspector(
        scene::SceneLike; 
        whitelist = AbstractPlot[], blacklist = AbstractPlot[], range = 10
    )
    @assert cameracontrols(scene) isa PixelCamera

    inspector = DataInspector(
        scene,
        Attributes(
            display_text = " ",
            position = Point2f0(0),
            visible = false,
            halign = :left,
            bbox = Rect3D(Vec3f0(0,0,0),Vec3f0(1,1,1)),
            bbox_visible = false,
            depth = 1e3
        ),
        AbstractPlot[], whitelist, blacklist
    )

    on(events(scene).mouseposition) do mp
        # This is super cheap
        is_mouseinside(scene) || return false

        picks = pick_sorted(scene, mp, range)
        should_clear = true
        for (plt, idx) in picks
            @info idx, typeof(plt)
            b1 = plt === nothing
            b2 = plt in inspector.blacklist
            b3 = (!isempty(inspector.whitelist) && !(plt in inspector.whitelist))
            b4 = b1 || b2 || b3
            @info b1 b2 b3 b4
            if (plt !== nothing) && !(plt in inspector.blacklist) && 
                (isempty(inspector.whitelist) || (plt in inspector.whitelist))
                show_data(inspector, plt, idx)
                should_clear = false
                break
            end
        end

        if should_clear
            inspector.attributes.visible[] = false
            inspector.attributes.bbox_visible[] = false
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
        if cameracontrols(p.parent) isa PixelCamera
            # This will probably end up being what we use...
            map(p._glyphlayout, p.position) do gl, pos
                FRect2D(Bbox_from_glyphlayout(gl)) + Vec2f0(pos[1], pos[2])
            end
        else 
            map(p._glyphlayout, p.position, camera(p.parent).projectionview, pixelarea(p.parent)) do gl, pos, pv, area
                px_pos = AbstractPlotting.project(pv, Vec2f0(widths(area)), to_ndim(Point3f0, pos, 0))
                px_bbox = Bbox_from_glyphlayout(gl) + to_ndim(Vec3f0, px_pos, 0)
                px_bbox = px_bbox - Vec3f0(0.5widths(area)..., 0)
                px_bbox = FRect3D(
                    2 .* origin(px_bbox) ./ Vec3f0(widths(area)..., 1),
                    2 .* widths(px_bbox) ./ Vec3f0(widths(area)..., 1)
                )
                ps = unique(coordinates(px_bbox))
                inv_pv = inv(pv)
                world_ps = map(ps) do p
                    proj = inv_pv * Vec4f0(p..., 1)
                    proj[SOneTo(3)] / proj[4]
                end
                minx, maxx = extrema(getindex.(world_ps, (1,)))
                miny, maxy = extrema(getindex.(world_ps, (2,)))
                minz, maxz = extrema(getindex.(world_ps, (3,)))
                world_bbox = FRect3D(Point3f0(minx, miny, minz), Vec3f0(maxx-minx, maxy-miny, maxz-minz))
                world_bbox
            end
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
        overdraw=!true, show_axis=false
    )

    bbox = text2worldbbox(p1)
    # pop!(inspector.parent.plots)
    tbb = wireframe!(
        inspector.parent, bbox,
        color = :lightblue, shading = false, visible = a.visible, overdraw=!true, 
        show_axis=false
    )
    bg = mesh!(
        inspector.parent, bbox, color = :orange, shading = false, 
        visible = a.visible, overdraw=!true, show_axis=false
    )

    p2 = wireframe!(
        inspector.parent, 
        map(p -> FRect2D(p .- Vec2f0(10), Vec2f0(20)), a.position), 
        color = :red, linewidth = 2, overdraw=!true,
        visible = a.visible, show_axis=false
    )
    p3 = wireframe!(
        inspector.parent, a.bbox,
        color = :red, visible = a.bbox_visible, overdraw=!true, show_axis=false
    )
    # To make sure inspector plots end up in front
    # 3D plots should be fine with depth > 1.0, but I'm not sure about 2D
    on(a.depth) do d
        # This is a translate to, not translate by!?!
        translate!(bg, Vec3f0(0,0,d))
        translate!(tbb, Vec3f0(0,0,d+0.1))
        translate!(p1, Vec3f0(0,0,d+1))
        translate!(p2, Vec3f0(0,0,d))
        translate!(p3, Vec3f0(0,0,d))
    end
    a.depth[] = a.depth[]
    push!(inspector.plots, p1, tbb, bg, p2, p3)
    append!(inspector.blacklist, flatten_plots(inspector.plots))
    nothing
end


function show_data(inspector::DataInspector, plot::Union{Scatter, MeshScatter}, idx)
    @info "Scatter, MeshScatter"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        scene = parent_scene(plot)
        pos = to_ndim(Point3f0, plot[1][][idx], 0)
        proj_pos = project(
            camera(scene).projectionview[],
            Vec2f0(widths(pixelarea(scene)[])),
            pos
        )
        a.position[] = proj_pos .+ Vec2f0(origin(pixelarea(scene)[]))
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

        scene = parent_scene(plot)

        # cast ray from cursor into screen, find closest point to line
        pos = mouseposition(scene)
        p0, p1 = plot[1][][idx-1:idx]
        origin, dir = view_ray(scene)
        p = closest_point_on_line(p0, p1, origin, dir)

        proj_pos = project(
            camera(scene).projectionview[],
            Vec2f0(widths(pixelarea(scene)[])),
            to_ndim(Point3f0, p, 0)
        )

        a.position[] = proj_pos .+ Vec2f0(minimum(pixelarea(scene)[]))
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
        
        # TODO this should create a plot in its parent scene, not in inspectors
        # parent scene
        bbox = boundingbox(plot)
        min, max = extrema(bbox)
        p = 0.5 * (max .+ min)
        a.position[] = Point2f0(p[1], p[2]) #.+ Vec2f0(origin(pixelarea(scene)[]))
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
        scene = parent_scene(plot)
        proj_pos = project(
            camera(scene).projectionview[],
            Vec2f0(widths(pixelarea(scene)[])),
            to_ndim(Point3f0, pos, 0)
        )
        a.position[] = proj_pos .+ Vec2f0(origin(pixelarea(scene)[]))
        a.display_text[] = position2string(pos)
        a.bbox[] = FRect3D(bbox)
        a.visible[] = true
        a.bbox_visible[] = true
    end
end

pos2index(x, r, N) = ceil(Int, N * (x - minimum(r) + 1e-10) / (maximum(r) - minimum(r)))
index2pos(i, r, N) = minimum(r) + (maximum(r) - minimum(r)) * (i-0.5) / (N)

function show_data(inspector::DataInspector, plot::Heatmap, idx)
    # This is a mess but it'll need to be updated once Heatmaps are centered 
    # anyway...
    # Alternatively, could this get a useful index?
    @info "Heatmap"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        # idx == 0 :(
        scene = parent_scene(plot)
        mpos = mouseposition(scene)
        i = pos2index(mpos[1], plot[1][], size(plot[3][], 1))
        j = pos2index(mpos[2], plot[2][], size(plot[3][], 2))
        x = index2pos(i, plot[1][], size(plot[3][], 1))
        y = index2pos(j, plot[2][], size(plot[3][], 2))
        z = plot[3][][i, j]

        proj_pos = project(
            camera(scene).projectionview[],
            Vec2f0(widths(pixelarea(scene)[])),
            Point3f0(x, y, 0)
        )

        # bbox = plot.plots[1][1][][idx]
        a.position[] = proj_pos .+ Vec2f0(origin(pixelarea(scene)[]))
        a.display_text[] = @sprintf("%0.3f @ (%i, %i)", z, i, j)
        # a.bbox[] = FRect3D(bbox)
        a.visible[] = true
        # a.bbox_visible[] = true
    end
end


function show_data(inspector::DataInspector, plot::Surface, idx)
    @info "Surface"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
        a.bbox_visible[] = false
    else
        @info idx
        # ps = [Point3f0(xs[i], ys[j], zs[i, j]) for j in eachindex(ys) for i in eachindex(xs)]
        # idxs = LinearIndices(size(zs))
        # faces = [
        #     QuadFace(idxs[i, j], idxs[i+1, j], idxs[i+1, j+1], idxs[i, j+1])
        #     for j in 1:size(zs, 2)-1 for i in 1:size(zs, 1)-1
        # ]
        # faces = [QuadFace(i, i+1, i+N+1, i+N) for i in ]
        
        # # The div skips faces that connect the right edge to the left
        # N = size(plot[3][], 1)
        # shifted = idx + div(idx, N)
        # face = QuadFace(shifted, shifted+1, shifted+N+1, shifted+N)

        # bbox = plot.plots[1][1][][idx]
        # a.position[] = Point3f0(x, y, 0)
        # a.display_text[] = @sprintf("%0.3f @ (%i, %i)", z, i, j)
        # a.bbox[] = FRect3D(bbox)
        # a.visible[] = true
        # a.bbox_visible[] = true
    end
end


function show_data(inspector::DataInspector, plot, idx)
    @info "else"
    inspector.attributes.visible[] = false
    inspector.attributes.bbox_visible[] = false

    nothing
end