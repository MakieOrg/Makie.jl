"""
    showlibrary(lib::Symbol)::Scene

Shows all color gradients in the given library.
Returns a Scene with these color gradients arranged
as horizontal colorbars.
"""
function showlibrary(lib::Symbol)::Scene
    cgrads = sort(PlotUtils.cgradients(lib))
    PlotUtils.clibrary(lib)
    return showgradients(cgrads)
end


"""
    showgradients(
        cgrads::AbstractVector{Symbol};
        h = 0.0, offset = 0.2, fontsize = 0.7,
        size = (800, length(cgrads) * 84)
    )::Scene

Plots the given colour gradients arranged as horizontal colourbars.
If you change the offsets or the font size, you may need to change the resolution.
"""
function showgradients(
        cgrads::AbstractVector{Symbol};
        size = (800, length(cgrads) * 84),
    )

    f = Figure(; size = size)
    ax = Axis(f[1, 1])

    labels = map(enumerate(cgrads)) do (i, cmap)
        c = to_colormap(cmap)
        image!(
            ax,
            0 .. 10,
            i .. (i + 1),
            reshape(c, (length(c), 1))
        )

        cmapstr = string(cmap)
        return ((i + (i + 1)) / 2, cmapstr)
    end

    ax.yticks = (first.(labels), last.(labels))
    return f
end
