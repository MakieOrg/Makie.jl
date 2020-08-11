function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(P::PlotFunc, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

function searchrange(x, xlims)
    min, max = xlims
    i1 = searchsortedfirst(x, min)
    i2 = searchsortedlast(x, max)
    return i1:i2
end

function trim_density(k::KernelDensity.UnivariateKDE, xlims)
    range = searchrange(k.x, xlims)
    UnivariateKDE(k.x[range], k.density[range])
end

function density(x; trim = false)
    k = KernelDensity.kde(x)
    return trim ? trim_density(k, extrema_nan(x)) : k
end