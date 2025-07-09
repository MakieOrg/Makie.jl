# overloadable for other types that might want to offer similar interactions
function interactions end

interactions(ax::Axis) = ax.interactions
interactions(ax3::Axis3) = ax3.interactions

"""
    register_interaction!(parent, name::Symbol, interaction)

Register `interaction` with `parent` under the name `name`.
The parent will call `process_interaction(interaction, event, parent)`
whenever suitable events happen.

The interaction can be removed with `deregister_interaction!` or temporarily
toggled with `activate_interaction!` / `deactivate_interaction!`.
"""
function register_interaction!(parent, name::Symbol, interaction)
    haskey(interactions(parent), name) && error("Interaction $name already exists.")
    registration_setup!(parent, interaction)
    push!(interactions(parent), name => (true, interaction))
    return interaction
end

"""
    register_interaction!(interaction::Function, parent, name::Symbol)

Register `interaction` with `parent` under the name `name`.
The parent will call `process_interaction(interaction, event, parent)`
whenever suitable events happen.
This form with the first `Function` argument is especially intended for `do` syntax.

The interaction can be removed with `deregister_interaction!` or temporarily
toggled with `activate_interaction!` / `deactivate_interaction!`.
"""
function register_interaction!(interaction::Function, parent, name::Symbol)
    haskey(interactions(parent), name) && error("Interaction $name already exists.")
    registration_setup!(parent, interaction)
    push!(interactions(parent), name => (true, interaction))
    return interaction
end

"""
    deregister_interaction!(parent, name::Symbol)

Deregister the interaction named `name` registered in `parent`.
"""
function deregister_interaction!(parent, name::Symbol)
    !haskey(interactions(parent), name) && error("Interaction $name does not exist.")
    _, interaction = interactions(parent)[name]

    deregistration_cleanup!(parent, interaction)
    pop!(interactions(parent), name)
    return interaction
end

function registration_setup!(parent, interaction)
    # do nothing in the default case
end

function deregistration_cleanup!(parent, interaction)
    # do nothing in the default case
end

"""
    activate_interaction!(parent, name::Symbol)

Activate the interaction named `name` registered in `parent`.
"""
function activate_interaction!(parent, name::Symbol)
    !haskey(interactions(parent), name) && error("Interaction $name does not exist.")
    interactions(parent)[name] = (true, interactions(parent)[name][2])
    return nothing
end

"""
    deactivate_interaction!(parent, name::Symbol)

Deactivate the interaction named `name` registered in `parent`.
It can be reactivated with `activate_interaction!`.
"""
function deactivate_interaction!(parent, name::Symbol)
    !haskey(interactions(parent), name) && error("Interaction $name does not exist.")
    interactions(parent)[name] = (false, interactions(parent)[name][2])
    return nothing
end


function process_interaction(@nospecialize args...)
    # do nothing in the default case
    return Consume(false)
end

# a generic fallback for functions to have one really simple path to getting interactivity
# without needing to define a special type first
function process_interaction(f::Function, event, parent)
    # in case f is only defined for a specific type of event
    if applicable(f, event, parent)
        # TODO this is deprecation code, make this just `return f(event, parent)` eventually
        return f(event, parent)
    end
    return Consume(false)
end


############################################################################
#                            Axis interactions                            #
############################################################################

function _chosen_limits(rz, ax)
    r = positivize(Rect2(rz.from, rz.to .- rz.from))
    lims = ax.finallimits[]
    # restrict to y change
    if rz.restrict_x || !ax.xrectzoom[]
        r = Rect2(lims.origin[1], r.origin[2], widths(lims)[1], widths(r)[2])
    end
    # restrict to x change
    if rz.restrict_y || !ax.yrectzoom[]
        r = Rect2(r.origin[1], lims.origin[2], widths(r)[1], widths(lims)[2])
    end
    return r
end

function _selection_vertices(ax_scene, outer, inner)
    _clamp(p, plow, phigh) = Point2(clamp(p[1], plow[1], phigh[1]), clamp(p[2], plow[2], phigh[2]))
    proj(point) = project(ax_scene, point)
    transf = Makie.transform_func(ax_scene)
    outer = positivize(Makie.apply_transform(transf, outer))
    inner = positivize(Makie.apply_transform(transf, inner))

    obl = bottomleft(outer)
    obr = bottomright(outer)
    otl = topleft(outer)
    otr = topright(outer)

    ibl = _clamp(bottomleft(inner), obl, otr)
    ibr = _clamp(bottomright(inner), obl, otr)
    itl = _clamp(topleft(inner), obl, otr)
    itr = _clamp(topright(inner), obl, otr)
    # We plot the selection vertices in blockscene, which is pixelspace, so we need to manually
    # project the points to the space of `ax.scene`
    return [proj(obl), proj(obr), proj(otr), proj(otl), proj(ibl), proj(ibr), proj(itr), proj(itl)]
end

function process_interaction(r::RectangleZoom, event::MouseEvent, ax::Axis)
    # only rectangle zoom if modifier is pressed (defaults to true)
    ispressed(ax.scene, r.modifier) || return Consume(false)
    # TODO: actually, the data from the mouse event should be transformed already
    # but the problem is that these mouse events are generated all the time
    # and outside of log axes, you would quickly run into domain errors
    transf = Makie.transform_func(ax)
    inv_transf = Makie.inverse_transform(transf)

    if isnothing(inv_transf)
        @warn "Can't rectangle zoom without inverse transform" maxlog = 1
        # TODO, what can we do without inverse?
        return Consume(false)
    end

    if event.type === MouseEventTypes.leftdragstart
        data = Makie.apply_transform(inv_transf, event.data)
        prev_data = Makie.apply_transform(inv_transf, event.prev_data)

        r.from = prev_data
        r.to = data
        r.rectnode[] = _chosen_limits(r, ax)
        r.active[] = true
        return Consume(true)

    elseif event.type === MouseEventTypes.leftdrag
        # clamp mouse data to shown limits
        rect = Makie.apply_transform(transf, ax.finallimits[])
        data = Makie.apply_transform(inv_transf, rectclamp(event.data, rect))

        r.to = data
        r.rectnode[] = _chosen_limits(r, ax)
        return Consume(true)

    elseif event.type === MouseEventTypes.leftdragstop
        try
            r.callback(r.rectnode[])
        catch e
            @warn "error in rectangle zoom" exception = (e, Base.catch_backtrace())
        end
        r.active[] = false
        return Consume(true)
    end

    return Consume(false)
end

function rectclamp(p::Point{N, T}, r::Rect) where {N, T}
    mi, ma = extrema(r)
    p = clamp.(p, mi, ma)
    return Point{N, T}(p)
end

function process_interaction(r::RectangleZoom, event::KeysEvent, ax::Axis)
    r.restrict_y = Keyboard.x in event.keys
    r.restrict_x = Keyboard.y in event.keys
    r.active[] || return Consume(false)

    r.rectnode[] = _chosen_limits(r, ax)
    return Consume(true)
end

function positivize(r::Rect2)
    negwidths = r.widths .< 0
    newori = ifelse.(negwidths, r.origin .+ r.widths, r.origin)
    newwidths = ifelse.(negwidths, -r.widths, r.widths)
    return Rect2(Point2(newori), Vec2(newwidths))
end

function process_interaction(::LimitReset, event::MouseEvent, ax::Axis)

    if event.type === MouseEventTypes.leftclick
        if ispressed(ax.scene, Keyboard.left_control)
            if ispressed(ax.scene, Keyboard.left_shift)
                autolimits!(ax)
            else
                reset_limits!(ax)
            end
            return Consume(true)
        end
    end

    return Consume(false)
end


function process_interaction(s::ScrollZoom, event::ScrollEvent, ax::Axis)
    # use vertical zoom
    zoom = event.y

    tlimits = ax.targetlimits
    xzoomlock = ax.xzoomlock
    yzoomlock = ax.yzoomlock
    xzoomkey = ax.xzoomkey
    yzoomkey = ax.yzoomkey


    scene = ax.scene
    e = events(scene)
    cam = camera(scene)

    ispressed(scene, ax.zoombutton[]) || return Consume(false)

    if zoom != 0
        pa = viewport(scene)[]

        z = (1.0 - s.speed)^zoom

        mp_axscene = Vec4d((e.mouseposition[] .- pa.origin)..., 0, 1)

        # first to normal -1..1 space
        mp_axfraction = (cam.pixel_space[] * mp_axscene)[Vec(1, 2)] .*
            # now to 1..-1 if an axis is reversed to correct zoom point
            (-2 .* ((ax.xreversed[], ax.yreversed[])) .+ 1) .*
            # now to 0..1
            0.5 .+ 0.5

        xscale = ax.xscale[]
        yscale = ax.yscale[]

        transf = (xscale, yscale)
        tlimits_trans = Makie.apply_transform(transf, tlimits[])

        xorigin = tlimits_trans.origin[1]
        yorigin = tlimits_trans.origin[2]

        xwidth = tlimits_trans.widths[1]
        ywidth = tlimits_trans.widths[2]

        newxwidth = xzoomlock[] ? xwidth : xwidth * z
        newywidth = yzoomlock[] ? ywidth : ywidth * z

        newxorigin = xzoomlock[] ? xorigin : xorigin + mp_axfraction[1] * (xwidth - newxwidth)
        newyorigin = yzoomlock[] ? yorigin : yorigin + mp_axfraction[2] * (ywidth - newywidth)

        timed_ticklabelspace_reset(ax, s.reset_timer, s.prev_xticklabelspace, s.prev_yticklabelspace, s.reset_delay)

        newrect_trans = if ispressed(scene, xzoomkey[])
            Rectd(newxorigin, yorigin, newxwidth, ywidth)
        elseif ispressed(scene, yzoomkey[])
            Rectd(xorigin, newyorigin, xwidth, newywidth)
        else
            Rectd(newxorigin, newyorigin, newxwidth, newywidth)
        end
        inv_transf = Makie.inverse_transform(transf)
        tlimits[] = Makie.apply_transform(inv_transf, newrect_trans)
    end

    # NOTE this might be problematic if if we add scrolling to something like Menu
    return Consume(true)
end

function process_interaction(dp::DragPan, event::MouseEvent, ax)

    if event.type !== to_drag_event(ax.panbutton[])
        return Consume(false)
    end

    tlimits = ax.targetlimits
    xpanlock = ax.xpanlock
    ypanlock = ax.ypanlock
    xpankey = ax.xpankey
    ypankey = ax.ypankey

    scene = ax.scene
    cam = camera(scene)
    pa = viewport(scene)[]

    mp_axscene = Vec4f((event.px .- pa.origin)..., 0, 1)
    mp_axscene_prev = Vec4f((event.prev_px .- pa.origin)..., 0, 1)

    mp_axfraction, mp_axfraction_prev = map((mp_axscene, mp_axscene_prev)) do mp
        # first to normal -1..1 space
        (cam.pixel_space[] * mp)[Vec(1, 2)] .*
            # now to 1..-1 if an axis is reversed to correct zoom point
            (-2 .* ((ax.xreversed[], ax.yreversed[])) .+ 1) .*
            # now to 0..1
            0.5 .+ 0.5
    end

    xscale = ax.xscale[]
    yscale = ax.yscale[]

    transf = (xscale, yscale)
    tlimits_trans = Makie.apply_transform(transf, tlimits[])

    movement_frac = mp_axfraction .- mp_axfraction_prev

    xscale = ax.xscale[]
    yscale = ax.yscale[]

    transf = (xscale, yscale)
    tlimits_trans = Makie.apply_transform(transf, tlimits[])

    xori, yori = tlimits_trans.origin .- movement_frac .* widths(tlimits_trans)

    if xpanlock[] || ispressed(scene, ypankey[])
        xori = tlimits_trans.origin[1]
    end

    if ypanlock[] || ispressed(scene, xpankey[])
        yori = tlimits_trans.origin[2]
    end

    timed_ticklabelspace_reset(ax, dp.reset_timer, dp.prev_xticklabelspace, dp.prev_yticklabelspace, dp.reset_delay)

    inv_transf = Makie.inverse_transform(transf)
    newrect_trans = Rectd(Vec2(xori, yori), widths(tlimits_trans))
    tlimits[] = Makie.apply_transform(inv_transf, newrect_trans)

    return Consume(true)
end


function process_interaction(dr::DragRotate, event::MouseEvent, ax3d::Axis3)
    if event.type !== MouseEventTypes.leftdrag
        return Consume(false)
    end

    dpx = event.px - event.prev_px

    ax3d.azimuth[] += -dpx[1] * 0.01
    ax3d.elevation[] = clamp(ax3d.elevation[] - dpx[2] * 0.01, -pi / 2 + 0.001, pi / 2 - 0.001)

    return Consume(true)
end


function process_interaction(interaction::DragPan, event::MouseEvent, ax::Axis3)
    if event.type !== MouseEventTypes.rightdrag || (event.px == event.prev_px)
        return Consume(false)
    end

    tlimits = ax.targetlimits
    mini = minimum(tlimits[])
    ws = widths(tlimits[])

    # restrict to direction
    x_translate = !(ax.xtranslationlock[]) && ispressed(ax, ax.xtranslationkey[])
    y_translate = !(ax.ytranslationlock[]) && ispressed(ax, ax.ytranslationkey[])
    z_translate = !(ax.ztranslationlock[]) && ispressed(ax, ax.ztranslationkey[])

    if !(x_translate || y_translate || z_translate) # none restricted -> all active
        xyz_translate = (true, true, true)
    else
        xyz_translate = (x_translate, y_translate, z_translate)
    end

    # Perform translation
    if (ax.viewmode[] == :free) && ispressed(ax, ax.axis_translation_mod[])

        ws = widths(ax.layoutobservables.computedbbox[])[2]
        ax.axis_offset[] -= Vec2d(2 .* (event.px - event.prev_px) ./ ws)

    else

        #=
        # Faster but less accurate (dependent on aspect ratio)
        scene_area = viewport(ax.scene)[]
        relative_delta = (event.px - event.prev_px) ./ widths(scene_area)

        # Get u_x (screen right direction) and u_y (screen up direction)
        u_z = ax.scene.camera.view_direction[]
        u_y = ax.scene.camera.upvector[]
        u_x = cross(u_z, u_y)

        translation = - 2.0 * (relative_delta[1] * u_x + relative_delta[2] * u_y) .* ws
        =#

        # Slower but more accurate
        model = ax.scene.transformation.model[]
        world_center = to_ndim(Point3f, model * to_ndim(Point4d, mini .+ 0.5 * ws, 1), NaN)
        # make plane_normal perpendicular to the allowed translation directions
        # allow_normal = xyz_translate == (true, true, true) ? (1, 1, 1) : (1 .- xyz_translate)
        # plane = Plane3f(world_center, allow_normal .* ax.scene.camera.view_direction[])
        plane = Plane3f(world_center, ax.scene.camera.view_direction[])
        p0 = ray_plane_intersection(plane, ray_from_projectionview(ax.scene, event.prev_px))
        p1 = ray_plane_intersection(plane, ray_from_projectionview(ax.scene, event.px))
        delta = p1 - p0
        translation = isfinite(delta) ? - inv(model[Vec(1, 2, 3), Vec(1, 2, 3)]) * delta : Point3d(0)

        tlimits[] = Rect3f(mini + xyz_translate .* translation, ws)
    end

    return Consume(true)
end


function process_interaction(interaction::ScrollZoom, event::ScrollEvent, ax::Axis3)
    # use vertical zoom
    zoom = event.y

    if zoom == 0
        return Consume(false)
    end

    tlimits = ax.targetlimits
    mini = minimum(tlimits[])
    maxi = maximum(tlimits[])
    center = 0.5 .* (mini .+ maxi)

    # restrict to direction
    x_zoom = !(ax.xzoomlock[]) && ispressed(ax, ax.xzoomkey[])
    y_zoom = !(ax.yzoomlock[]) && ispressed(ax, ax.yzoomkey[])
    z_zoom = !(ax.zzoomlock[]) && ispressed(ax, ax.zzoomkey[])

    if !(x_zoom || y_zoom || z_zoom) # none restricted -> all active
        xyz_zoom = (true, true, true)
    else
        xyz_zoom = (x_zoom, y_zoom, z_zoom)
    end

    zoom_mult = (1.0f0 - interaction.speed)^zoom

    if ax.viewmode[] == :free

        ax.zoom_mult[] = ax.zoom_mult[] * zoom_mult

    else
        # Compute target
        mode = ax.zoommode[]
        target = Point3f(NaN)
        model = ax.scene.transformation.model[]

        if mode == :cursor
            # try to find position of plot object under cursor
            mp = mouseposition_px(ax)
            ray = ray_from_projectionview(ax.scene, mp) # world space
            pos = Point3f(NaN)
            plot, idx = pick(ax.scene)
            if plot !== nothing
                n = findfirst(==(plot), ax.scene.plots)
                if !isnothing(n) && (n > 9) # user plot
                    pos = position_on_plot(plot, idx, ray, apply_transform = true)
                    # ^ applying transform also applies model transform so we stay in world space for this
                end
            end

            if !isfinite(pos)
                # fall back on using intersection between view ray and center view plane
                # (meaning plane parallel to screen, going through center of Axis3 limits)
                world_center = to_ndim(Point3f, model * to_ndim(Point4d, center, 1), NaN)
                plane = Plane3f(world_center, -ax.scene.camera.view_direction[])
                pos = ray_plane_intersection(plane, ray) # world space
            end
            # axis space, i.e. pre ax.scene.transformation.model applies, same as targetlimits space
            target = to_ndim(Point3f, inv(model) * to_ndim(Point4f, pos, 1), NaN)
        elseif mode == :center
            target = center # axis space
        else
            error("$(ax.zoommode[]) is not a valid mode for zooming. Should be :center or :cursor.")
        end

        mini = ifelse.(xyz_zoom, target .+ zoom_mult .* (mini .- target), mini)
        maxi = ifelse.(xyz_zoom, target .+ zoom_mult .* (maxi .- target), maxi)
        tlimits[] = Rect3f(mini, maxi - mini)
    end

    # NOTE this might be problematic if we add scrolling to something like Menu
    return Consume(true)
end

function process_interaction(::LimitReset, event::MouseEvent, ax::Axis3)
    consumed = false
    if event.type === MouseEventTypes.leftclick
        if ispressed(ax.scene, Keyboard.left_control)
            ax.zoom_mult[] = 1.0
            if ispressed(ax.scene, Keyboard.left_shift)
                autolimits!(ax)
            else
                reset_limits!(ax)
            end
            consumed = true
        end
        if ispressed(ax.scene, Keyboard.left_shift)
            ax.axis_offset[] = Vec2d(0)
            ax.elevation[] = pi / 8
            ax.azimuth[] = 1.275 * pi
            consumed = true
        end
    end

    return Consume(consumed)
end

function process_interaction(focus::FocusOnCursor, ::Union{MouseEvent, KeyEvent}, ax::Axis3)
    if ispressed(ax, ax.cursorfocuskey[]) && is_mouseinside(ax.scene) && (time() > focus.last_time + focus.timeout)
        xy = events(ax.scene).mouseposition[]
        plot, idx = pick(ax.scene, xy)
        if isnothing(plot) || (parent_scene(plot) !== ax.scene) || is_data_space(plot) ||
                (findfirst(p -> p === plot, ax.scene.plots) <= focus.skip) # is axis decoration
            return Consume(false)
        end

        ray = Ray(ax.scene, xy .- minimum(viewport(ax.scene)[]))
        p3d = position_on_plot(plot, idx, ray, apply_transform = false)
        if !isnan(p3d)
            tlimits = ax.targetlimits
            ws = widths(tlimits[])
            tlimits[] = Rect3f(p3d - 0.5 * ws, ws)
            focus.last_time = time() # to avoid double triggers
            return Consume(true)
        end
    end

    return Consume(false)
end
