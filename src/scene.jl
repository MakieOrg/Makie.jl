
function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    filter!(isopen, scene.current_screens)
    isempty(scene.current_screens) || return
    screen = Screen(scene)
    insert_plots!(scene)
    bb = real_boundingbox(scene)
    w = widths(bb)
    padd = w .* 0.01
    bb = FRect3D(minimum(bb) .- padd, w .+ 2padd)
    update_cam!(scene, bb)
    force_update!()
    return
end

function Base.show(io::IO, m::MIME"text/plain", plot::AbstractPlot)
    show(io, m, parent(plot))
    display(TextDisplay(io), m, plot.attributes)
    force_update!(plot)
    nothing
end
