# volume

{{doc volume}}

### Examples

\begin{showhtml}{}
```julia:ex-volume
using JSServe
Page(exportable=true, offline=true)
```
\end{showhtml}

\begin{showhtml}{}
```julia:ex-volume
using WGLMakie, FileIO, NIfTI, ImageTransformations
WGLMakie.activate!()

brain = restrict(niread(Makie.assetpath("brain.nii.gz")).raw)
mini, maxi = extrema(brain)
cube_with_holes = Float32.((brain .- mini) ./ (maxi - mini))

function labeled_slider(r, name, start=first(r))
    s = JSServe.Slider(r)
    s.value[] = start
    return DOM.div(name, s, map(x-> string(round(x, digits=2)), s.value)), s
end

App() do session
    levelsd, levels = labeled_slider(2:10, "levels")
    absorptiond, absorption = labeled_slider(range(0, stop=5, step=0.5), "absorption", 3.0)
    isovalued, isovalue = labeled_slider(range(0, stop=1, step=0.1), "isovalue", 0.5)
    alphad, alpha = labeled_slider(range(0, stop=1, step=0.1), "alpha", 0.5)

    fig = Figure(resolution=(800, 800))
    # Make a colormap, with the first value being transparent
    colormap = RGBAf.(to_colormap(:plasma), 1.0)
    colormap[1] = RGBAf(0,0,0,0)

    volume!(LScene(fig[1, 1], show_axis=false), cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = isovalue)
    volume!(LScene(fig[1, 2], show_axis=false), cube_with_holes, algorithm = :absorption, absorption=absorption, colormap=colormap)
    volume!(LScene(fig[2, 1], show_axis=false), cube_with_holes, algorithm = :mip, colormap=colormap)
    contour!(LScene(fig[2, 2], show_axis=false), cube_with_holes, levels=levels, alpha=alpha, isorange = 0.07)

    colgap!(fig.layout, 0)
    rowgap!(fig.layout, 0)

    return JSServe.record_states(session, DOM.div(absorptiond, isovalued, levelsd, alphad, fig))
end
```
\end{showhtml}
