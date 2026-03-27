# draw_atomic for scatter — delegates to setup_scatter!

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.scatter})
    setup_scatter!(screen, scene, plot, plot.attributes, screen.config.device)
end
