function sphere_streamline(linebuffer, ∇ˢf, pt, h, n)
    push!(linebuffer, pt)
    df = normalize(∇ˢf(pt[1], pt[2], pt[3]))
    push!(linebuffer, normalize(pt .+ h*df))
    for k=2:n
        cur_pt = last(linebuffer)
        push!(linebuffer, cur_pt)
        df = normalize(∇ˢf(cur_pt...))
        push!(linebuffer, normalize(cur_pt .+ h*df))
    end
    return
end

"""
    StreamLines

TODO add function signatures
TODO add descripton

## Attributes
$(ATTRIBUTES)
"""
@recipe(StreamLines, points, directions) do scene
    Attributes(
        h = 0.01f0,
        n = 5,
        color = :black,
        linewidth = 1
    )
end
