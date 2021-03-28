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
            halign = :left
        ),
        ScenePlot[], whitelist, blacklist
    )

    on(events(scene).mouseposition) do mp
        # This is super cheap
        is_mouseinside(scene) || return false

        # range requires GLMakie#173
        plt, idx = pick(scene, mp) # , range)
        @info idx, typeof(plt)
        if plt === nothing
            inspector.attributes.visible[] = false
        else
            show_data(inspector, plt, idx)
        end
    end

    draw_data_inspector!(inspector)

    inspector
end


function draw_data_inspector!(inspector)
    a = inspector.attributes
    p1 = text!(
        inspector.parent, a.display_text, 
        position = a.position, visible = a.visible, halign = a.halign,
        overdraw=true
    )
    p2 = scatter!(
        inspector.parent, map(x -> [x], a.position), 
        color = (:yellow, 0.5), strokecolor = :red, overdraw=true,
        visible = a.visible
    )
    push!(inspector.plots, p1, p2)
    nothing
end


function show_data(inspector::DataInspector, plot::Union{Scatter, MeshScatter}, idx)
    @info "Scatter, MeshScatter"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
    else
        pos = to_ndim(Point3f0, plot[1][][idx], 0)
        a.position[] = pos
        a.display_text[] = string(pos)
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
    @info "Lines"
    a = inspector.attributes
    if idx === nothing
        a.visible[] = false
    else
        pos = mouseposition(inspector.parent)
        p0, p1 = plot[1][][idx-1:idx]
        origin, dir = view_ray(inspector.parent)
        p = closest_point_on_line(p0, p1, origin, dir)
        a.position[] = p
        a.display_text[] = string(p)
        a.visible[] = true
    end
end


function show_data(inspector::DataInspector, plot, idx)
    @info "else"
    inspector.attributes.visible[] = false
    nothing
end