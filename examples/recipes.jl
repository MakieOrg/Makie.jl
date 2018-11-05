@block SimonDanisch [recipe] begin

    @cell "Type recipe for molecule simulation" [meshscatter, linesegments, molecules] begin
        import AbstractPlotting: Plot, default_theme, plot!, to_value

        struct Simulation
            grid::Vector{Point3f0}
        end
        # Probably worth having a macro for this!
        function default_theme(scene::SceneLike, ::Type{<: Plot(Simulation)})
            Theme(
                advance = 0,
                molecule_sizes = [0.08, 0.04, 0.04],
                molecule_colors = [:maroon, :deepskyblue2, :deepskyblue2]
            )
        end

        # The recipe! - will get called for plot(!)(x::SimulationResult)
        function AbstractPlotting.plot!(p::Plot(Simulation))
            sim = to_value(p[1]) # first argument is the SimulationResult
            # when advance changes, get new positions from the simulation
            mpos = lift(p[:advance]) do i
                sim.grid .+ rand(Point3f0, length(sim.grid)) .* 0.01f0
            end
            # size shouldn't change, so we might as well get the value instead of signal
            pos = to_value(mpos)
            N = length(pos)
            sizes = lift(p[:molecule_sizes]) do s
                repeat(s, outer = N ÷ 3)
            end
            sizes = lift(p[:molecule_sizes]) do s
                repeat(s, outer = N ÷ 3)
            end
            colors = lift(p[:molecule_colors]) do c
                repeat(c, outer = N ÷ 3)
            end
            scene = meshscatter!(p, mpos, markersize = sizes, color = colors)
            indices = Int[]
            for i in 1:3:N
                push!(indices, i, i + 1, i, i + 2)
            end
            meshplot = p.plots[end] # meshplot is the last plot we added to p
            # meshplot[1] -> the positions (first argument) converted to points, so
            # we don't do the conversion 2 times for linesegments!
            linesegments!(p, lift(x-> view(x, indices), meshplot[1]))
        end

        # To write out a video of the whole simulation
        using Makie
        n = 5
        r = range(-1, stop = 1, length = n)
        grid = Point3f0.(r, reshape(r, (1, n, 1)), reshape(r, (1, 1, n)))
        molecules = map(1:(n^3) * 3) do i
            i3 = ((i - 1) ÷ 3) + 1
            xy = 0.1; z = 0.08
            i % 3 == 1 && return grid[i3]
            i % 3 == 2 && return grid[i3] + Point3f0(xy, xy, z)
            i % 3 == 0 && return grid[i3] + Point3f0(-xy, xy, z)
        end
        result = Simulation(molecules)
        scene = plot(result)
        N = 100
        record(scene, @replace_with_a_path(mp4), 1:N) do i
            scene[end][:advance] = i
        end
    end
end

#
#
# # or a slider example
# scene = Scene()
# # the whole layouting is still horrible - which is next on the todo list!
# ui_scene = Scene(scene, lift(x-> IRect(0, 0, widths(x)[1], 50), pixelarea(scene)))
# campixel!(ui_scene)
# plot_scene = Scene(scene, lift(x-> IRect(0, 50, widths(x) .- Vec(0, 50)), pixelarea(scene)))
# sim = plot!(plot_scene, result)[end]
# sim_index = slider!(ui_scene, 1:length(result.solution.t), raw = true)[end]
# foreach(sim_index[:value]) do idx
#     sim[:simulation_index] = idx
# end
# scene
#
# #the above should soon become:
# sim = plot(result)
# slider = slider(1:N)
# foreach(slider) do idx
#     sim[end][:simulation_index] = idx
# end
# hbox(sim, slider)
