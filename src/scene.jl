

function center!(scene::Scene, padding = 0.01)
    bb = AbstractPlotting.real_boundingbox(scene)
    w = widths(bb)
    padd = w .* padding
    bb = FRect3D(minimum(bb) .- padd, w .+ 2padd)
    update_cam!(scene, bb)
    force_update!()
end

# function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
#     filter!(isopen, scene.current_screens)
#     isempty(scene.current_screens) || return
#     center!(scene)
#     screen = Screen(scene)
#     AbstractPlotting.insert_plots!(scene)
#     return
# end
#
# function Base.show(io::IO, m::MIME"text/plain", plot::AbstractPlot)
#     display(TextDisplay(io), m, plot.attributes)
#     force_update!()
#     nothing
# end
