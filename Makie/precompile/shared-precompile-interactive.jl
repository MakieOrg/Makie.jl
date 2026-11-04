# Widgets that only do something with an interactive backend. Included by the interactive
# backends' precompile workloads, after `shared-precompile.jl`.
@compile begin
    f = Figure()
    Makie.Toggle(f)
    Makie.Slider(f)
    Makie.IntervalSlider(f)
    Makie.Textbox(f)
    Makie.Button(f)
    Makie.Menu(f, options = ["one"])
    Makie.SliderGrid(f, (label = "Label", range = 0:1:2, startvalue = 1))
    f
end
