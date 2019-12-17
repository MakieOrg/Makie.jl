"""
Creates a GridLayout with all pairs contained in `content`. Each pair consists
of an iterable with row and column spans, and a content object. Each content
object is then placed in the GridLayout at the span from its pair.

Example:

grid!(
    [1, 1] => obj1,
    [1, 2] => obj2,
    [2, :] => obj3,
)
"""
function grid!(content::Vararg{Pair}; kwargs...)
    g = GridLayout(; kwargs...)
    for ((rows, cols), element) in content
        g[rows, cols] = element
    end
    g
end

"""
Creates a single-row GridLayout with all elements contained in `content` placed
from left to right.
"""
function hbox!(content::Vararg; kwargs...)
    ncols = length(content)
    g = GridLayout(1, ncols; kwargs...)
    for (i, element) in enumerate(content)
        g[1, i] = element
    end
    g
end

"""
Creates a single-column GridLayout with all elements contained in `content` placed
from top to bottom.
"""
function vbox!(content::Vararg; kwargs...)
    nrows = length(content)
    g = GridLayout(nrows, 1; kwargs...)
    for (i, element) in enumerate(content)
        g[i, 1] = element
    end
    g
end

"""
Creates a GridLayout in Outside align mode whose bounding box is tied to the pixelarea of `scene` minus
a padding of `padding` pixels.
"""
function grid!(scene::Scene, padding::Real, args...; kwargs...)
    grid!(args...; bbox = lift(x -> BBox(x), pixelarea(scene)), alignmode = Outside(padding), kwargs...)
end

"""
Creates a single-row GridLayout in Outside align mode whose bounding box is tied to the pixelarea
of `scene` minus a padding of `padding` pixels.
"""
function hbox!(scene::Scene, padding::Real, args...; kwargs...)
    hbox!(args...; bbox = lift(x -> BBox(x), pixelarea(scene)), alignmode = Outside(padding), kwargs...)
end

"""
Creates a single-column GridLayout in Outside align mode whose bounding box is tied to the pixelarea
of `scene` minus a padding of `padding` pixels.
"""
function vbox!(scene::Scene, padding::Real, args...; kwargs...)
    vbox!(args...; bbox = lift(x -> BBox(x), pixelarea(scene)), alignmode = Outside(padding), kwargs...)
end

"""
Creates a GridLayout filled with matrix-like content. The size of the grid will
be the size of the matrix.
"""
function grid!(content::AbstractMatrix; kwargs...)
    nrows, ncols = size(content)
    g = GridLayout(nrows, ncols; kwargs...)
    for i in 1:nrows, j in 1:ncols
        g[i, j] = content[i, j]
    end
    g
end
