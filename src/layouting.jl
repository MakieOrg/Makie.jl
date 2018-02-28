function data_limits(x)
    map(x.args) do points
        Tuple.(extrema(points))
    end
end
