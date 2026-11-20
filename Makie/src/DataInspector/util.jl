# These are also used by the old DataInspector

"""
    point_in_quad_parameter(A, B, C, D, P[; iterations = 20, epsilon = 1e-6])

Given a quad

```
   A --- B
  /       \\
 /    __-- C
D -'''
```

this computes parameter `f` such that the line from `A + f * (B - A)` to
`D + f * (C - D)` crosses through the given point `P`. This assumes that `P` is
inside the quad and that none of the edges cross.
"""
function point_in_quad_parameter(
        A::VecTypes{2}, B::VecTypes{2}, C::VecTypes{2}, D::VecTypes{2}, P::VecTypes{2};
        iterations = 50, epsilon = 1.0e-6
    )

    # Our initial guess is that P is in the center of the quad (in terms of AB and DC)
    f = 0.5
    AB = B - A
    DC = C - D
    for _ in 0:iterations
        # vector between top and bottom point of the current line
        dir = (D + f * (C - D)) - (A + f * (B - A))
        # solves P + _ * dir = A + f1 * (B - A) (intersection point of ray & line)
        f1, _ = inv(Mat2f(AB..., dir...)) * (P - A)
        f2, _ = inv(Mat2f(DC..., dir...)) * (P - D)

        # next fraction estimate should be between f1 and f2
        # adding 2f to this helps avoid jumping between low and high values
        old_f = f
        f = 0.25 * (2f + f1 + f2)
        if abs(old_f - f) < epsilon
            return f
        end
    end

    return f
end


function _pixelated_image_bbox(xs, ys, img, i::Integer, j::Integer, edge_based)
    x0, x1 = extrema(xs)
    y0, y1 = extrema(ys)
    nw, nh = ((x1 - x0), (y1 - y0)) ./ size(img)
    return Rect2d(x0 + nw * (i - 1), y0 + nh * (j - 1), nw, nh)
end

function _pixelated_image_bbox(xs::Vector, ys::Vector, img, i::Integer, j::Integer, edge_based)
    return if edge_based
        Rect2d(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
    else
        _pixelated_image_bbox(
            minimum(xs) .. maximum(xs), minimum(ys) .. maximum(ys),
            img, i, j, edge_based
        )
    end
end
