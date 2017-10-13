function hover(to_hover::Vector, to_display, window)
    hover(to_hover[], to_display, window)
end

function get_cam(x)
    if isa(x, GLAbstraction.Context)
        return get_cam(x.children)
    elseif isa(x, Vector)
        return get_cam(first(x))
    elseif isa(x, GLAbstraction.RenderObject)
        return x[:preferred_camera]
    end
end


function hover(to_hover, to_display, window)
    if isa(to_hover, GLAbstraction.Context)
        return hover(to_hover.children, to_display, window)
    end
    area = map(window.inputs[:mouseposition]) do mp
        SimpleRectangle{Int}(round(Int, mp+10)..., 100, 70)
    end
    mh = GLWindow.mouse2id(window)
    popup = GLWindow.Screen(
        window,
        hidden = map(mh-> !(mh.id == to_hover.id), mh),
        area = area,
        stroke = (2f0, RGBA(0f0, 0f0, 0f0, 0.8f0))
    )
    cam = get!(popup.cameras, :perspective) do
        GLAbstraction.PerspectiveCamera(
            popup.inputs, Vec3f0(3), Vec3f0(0),
            keep = Signal(false),
            theta = Signal(Vec3f0(0)), trans = Signal(Vec3f0(0))
        )
    end

    map(enumerate(to_display)) do id
        i,d = id
        robj = visualize(d)
        viewit = Reactive.droprepeats(map(mh->mh.id == to_hover.id && mh.index == i, mh))
        camtype = get_cam(robj)
        Reactive.preserve(map(viewit) do vi
            if vi
                empty!(popup)
                if camtype == :perspective
                    cam.projectiontype.value = GLVisualize.PERSPECTIVE
                else
                    cam.projectiontype.value = GLVisualize.ORTHOGRAPHIC
                end
                GLVisualize._view(robj, popup, camera = cam)
                bb = GLAbstraction.boundingbox(robj).value
                mini = minimum(bb)
                w = GeometryTypes.widths(bb)
                wborder = w * 0.08f0 #8 percent border
                bb = GeometryTypes.AABB{Float32}(mini - wborder, w + 2 * wborder)
                GLAbstraction.center!(cam, bb)
            end
        end)
    end
    nothing
end
