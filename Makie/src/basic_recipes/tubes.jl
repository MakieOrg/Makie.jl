# Tubes recipe: 3D tube mesh from polyline data
#
# Like lines, but renders as a mesh of cylindrical tubes. Supports:
# - Per-vertex or uniform color (same options as lines)
# - Per-vertex or uniform radius
# - Optional Catmull-Rom spline interpolation for smooth paths
# - NaN separators for multiple disconnected tube segments

"""
    tubes(positions; radius=0.1, ...)
    tubes(x, y, z; radius=0.1, ...)

Render 3D polylines as tube meshes with circular cross-sections.

Input is the same as `lines`: a vector of `Point3f` (with optional `NaN`
separators for multiple segments), or separate `x, y, z` vectors.

The tube geometry is a triangle mesh, so it is fully ray-traceable and
benefits from lighting, shadows, and reflections in RayMakie.

## Attributes

- `radius`: Tube radius. Scalar or per-vertex `Vector{Float32}`.
- `n_sides`: Number of sides for the circular cross-section (default 8).
- `spline`: If `true`, fit a Catmull-Rom spline through the points before
  generating the tube mesh. Produces smooth curves from sparse control points.
- `spline_resolution`: Number of interpolated points per input segment (default 10).
  Only used when `spline=true`.

All `lines` coloring attributes are supported: `color` can be a single color,
a `Vector{<:Colorant}` for per-vertex colors, or a `Vector{<:Number}` with
a colormap.
"""
@recipe Tubes (positions,) begin
    "Tube radius. Scalar or per-vertex Vector{Float32}."
    radius = 0.1f0
    "Number of sides for the circular cross-section."
    n_sides = 8
    "Fit Catmull-Rom spline through points for smooth curves."
    spline = false
    "Interpolated points per segment when spline=true."
    spline_resolution = 10
    "Tube color. Same options as lines: single color, per-vertex colors, or numeric + colormap."
    color = @inherit linecolor
    "Material for ray tracing (e.g. Hikari.Gold, Hikari.Diffuse). Forwarded to mesh!."
    material = nothing
    cycle = [:color]
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

# convert_arguments: same as lines (accept x,y,z or positions)
function convert_arguments(::Type{<:Tubes}, x::AbstractVector, y::AbstractVector, z::AbstractVector)
    return (Point3f.(x, y, z),)
end

# ============================================================================
# Catmull-Rom spline interpolation
# ============================================================================

"""
    catmull_rom(p0, p1, p2, p3, t; alpha=0.5f0)

Evaluate a centripetal Catmull-Rom spline at parameter `t` in [0,1].
`alpha=0.5` gives centripetal parameterization (no cusps, no self-intersections).
"""
function catmull_rom(p0::Point3f, p1::Point3f, p2::Point3f, p3::Point3f, t::Float32; alpha::Float32=0.5f0)
    # Knot parameterization
    d01 = sqrt(sum((p1 .- p0) .^ 2))^alpha
    d12 = sqrt(sum((p2 .- p1) .^ 2))^alpha
    d23 = sqrt(sum((p3 .- p2) .^ 2))^alpha
    d01 = max(d01, 1f-6)
    d12 = max(d12, 1f-6)
    d23 = max(d23, 1f-6)

    t0 = 0f0
    t1 = t0 + d01
    t2 = t1 + d12
    t3 = t2 + d23

    tt = t1 + t * (t2 - t1)

    A1 = p0 .* ((t1 - tt) / (t1 - t0)) .+ p1 .* ((tt - t0) / (t1 - t0))
    A2 = p1 .* ((t2 - tt) / (t2 - t1)) .+ p2 .* ((tt - t1) / (t2 - t1))
    A3 = p2 .* ((t3 - tt) / (t3 - t2)) .+ p3 .* ((tt - t2) / (t3 - t2))

    B1 = A1 .* ((t2 - tt) / (t2 - t0)) .+ A2 .* ((tt - t0) / (t2 - t0))
    B2 = A2 .* ((t3 - tt) / (t3 - t1)) .+ A3 .* ((tt - t1) / (t3 - t1))

    C  = B1 .* ((t2 - tt) / (t2 - t1)) .+ B2 .* ((tt - t1) / (t2 - t1))
    return Point3f(C)
end

"""
    interpolate_spline(points; resolution=10)

Interpolate a polyline with centripetal Catmull-Rom splines.
Returns a denser polyline. Each input segment produces `resolution` output points.
The first and last points are duplicated to serve as phantom control points.
"""
function interpolate_spline(points::AbstractVector{Point3f}; resolution::Int=10)
    n = length(points)
    n < 2 && return copy(points)

    # Pad with phantom points (reflection of first/last segment)
    p0 = points[1] + (points[1] - points[min(2, n)])
    pn = points[n] + (points[n] - points[max(n-1, 1)])
    padded = vcat([p0], points, [pn])

    result = Point3f[]
    for i in 1:(length(padded) - 3)
        for j in 0:(resolution - 1)
            t = Float32(j) / Float32(resolution)
            push!(result, catmull_rom(padded[i], padded[i+1], padded[i+2], padded[i+3], t))
        end
    end
    push!(result, points[end])
    return result
end

"""
Linearly interpolate per-vertex data to match the spline-interpolated point count.
Works for Float32, RGBA, or any type supporting lerp-style interpolation.
"""
function interpolate_vertex_data(data::AbstractVector{T}, n_orig::Int, n_interp::Int) where T
    n_orig == n_interp && return data
    length(data) != n_orig && return data
    result = Vector{T}(undef, n_interp)
    for i in 1:n_interp
        t = (i - 1) / max(n_interp - 1, 1) * (n_orig - 1)
        idx = clamp(floor(Int, t) + 1, 1, n_orig - 1)
        frac = Float32(t - (idx - 1))
        result[i] = _lerp_value(data[idx], data[min(idx + 1, n_orig)], frac)
    end
    return result
end

_lerp_value(a::T, b::T, t::Float32) where {T<:Number} = a + (b - a) * t
function _lerp_value(a::RGBA{Float32}, b::RGBA{Float32}, t::Float32)
    RGBA{Float32}(
        red(a) + (red(b) - red(a)) * t,
        green(a) + (green(b) - green(a)) * t,
        blue(a) + (blue(b) - blue(a)) * t,
        alpha(a) + (alpha(b) - alpha(a)) * t,
    )
end
_lerp_value(a, b, t::Float32) = a  # fallback: no interpolation

# ============================================================================
# Tube mesh generation
# ============================================================================

"""
    build_tube_mesh(points, radius, n_sides; colors=nothing)

Generate a triangle mesh for a tube along `points` with circular cross-section.

Returns `(positions, normals, faces, vertex_colors)` where vertex_colors is
`nothing` if no per-vertex colors were provided.
"""
function build_tube_mesh(
    points::AbstractVector{Point3f},
    radius,
    n_sides::Int;
    colors=nothing,
)
    n_pts = length(points)
    n_pts < 2 && return (Point3f[], Vec3f[], GLTriangleFace[], nothing)

    n_verts = n_pts * n_sides
    n_faces = (n_pts - 1) * n_sides * 2

    positions = Vector{Point3f}(undef, n_verts)
    normals = Vector{Vec3f}(undef, n_verts)
    faces = Vector{GLTriangleFace}(undef, n_faces)
    vert_colors = colors !== nothing ? Vector{eltype(colors)}(undef, n_verts) : nothing

    # Pre-compute circle template
    angles = [2f0 * Float32(pi) * (k - 1) / n_sides for k in 1:n_sides]
    cos_a = cos.(angles)
    sin_a = sin.(angles)

    # Compute tangent-normal-binormal frame at each point
    for i in 1:n_pts
        # Tangent: forward difference, backward at end, average in middle
        if i == 1
            tangent = Vec3f(points[2] - points[1])
        elseif i == n_pts
            tangent = Vec3f(points[n_pts] - points[n_pts - 1])
        else
            tangent = Vec3f(points[i + 1] - points[i - 1])
        end
        tangent_len = sqrt(sum(tangent .^ 2))
        tangent_len < 1f-10 && (tangent = Vec3f(0, 0, 1))
        tangent = tangent / max(tangent_len, 1f-10)

        # Stable perpendicular vector
        if abs(tangent[1]) < 0.9f0
            perp = Vec3f(1, 0, 0)
        else
            perp = Vec3f(0, 1, 0)
        end
        normal = cross(tangent, perp)
        normal = normal / max(sqrt(sum(normal .^ 2)), 1f-10)
        binormal = cross(tangent, normal)

        # Per-vertex radius
        r = radius isa AbstractVector ? Float32(radius[min(i, length(radius))]) : Float32(radius)

        # Generate ring vertices
        for k in 1:n_sides
            vi = (i - 1) * n_sides + k
            n_dir = normal * cos_a[k] + binormal * sin_a[k]
            positions[vi] = points[i] + Point3f(n_dir * r)
            normals[vi] = n_dir
            if vert_colors !== nothing
                ci = min(i, length(colors))
                vert_colors[vi] = colors[ci]
            end
        end
    end

    # Generate faces: two triangles per quad between adjacent rings
    fi = 1
    for i in 1:(n_pts - 1)
        for k in 1:n_sides
            k_next = k % n_sides + 1
            a = (i - 1) * n_sides + k
            b = (i - 1) * n_sides + k_next
            c = i * n_sides + k
            d = i * n_sides + k_next
            faces[fi] = GLTriangleFace(a, c, b)
            faces[fi + 1] = GLTriangleFace(b, c, d)
            fi += 2
        end
    end

    return (positions, normals, faces, vert_colors)
end

# ============================================================================
# Split polyline at NaN separators
# ============================================================================

function split_at_nan(points::AbstractVector{Point3f})
    segments = Vector{Point3f}[]
    current = Point3f[]
    for p in points
        if any(isnan, p)
            if !isempty(current)
                push!(segments, current)
                current = Point3f[]
            end
        else
            push!(current, p)
        end
    end
    !isempty(current) && push!(segments, current)
    return segments
end

"""Split per-vertex data at the same NaN positions as the points."""
function split_data_at_nan(points::AbstractVector{Point3f}, data::AbstractVector)
    segments = Vector{eltype(data)}[]
    current = eltype(data)[]
    for (i, p) in enumerate(points)
        if any(isnan, p)
            if !isempty(current)
                push!(segments, current)
                current = eltype(data)[]
            end
        else
            if i <= length(data)
                push!(current, data[i])
            end
        end
    end
    !isempty(current) && push!(segments, current)
    return segments
end

# ============================================================================
# Recipe plot! implementation
# ============================================================================

function Makie.plot!(p::Tubes{<:Tuple{<:AbstractVector{<:Point3f}}})
    positions_obs = p[1]

    # Resolve colors to RGBA vector (same logic as lines)
    resolved_colors = map(p, positions_obs, p.color, p.colormap, p.colorrange, p.colorscale) do pts, color, cmap, crange, cscale
        n = length(pts)
        if color isa AbstractVector{<:Number}
            # Numeric -> colormap. Filter NaN for extrema (NaN = segment separator).
            finite_vals = filter(isfinite, color)
            cr = crange === automatic ? (isempty(finite_vals) ? (0f0, 1f0) : extrema(finite_vals)) : crange
            cs = cscale === identity ? identity : cscale
            cmap_vec = Makie.to_colormap(cmap)
            transparent = RGBA{Float32}(0, 0, 0, 0)
            return [isfinite(color[i]) ?
                    Makie.interpolated_getindex(cmap_vec,
                        clamp(Float32(cs((color[i] - cr[1]) / max(cr[2] - cr[1], 1f-10))), 0f0, 1f0)) :
                    transparent
                    for i in 1:length(color)]
        elseif color isa AbstractVector{<:Colorant}
            return [RGBA{Float32}(c) for c in color]
        elseif color isa Colorant || color isa Symbol || color isa String
            c = RGBA{Float32}(Makie.to_color(color))
            return fill(c, n)
        else
            c = RGBA{Float32}(Makie.to_color(color))
            return fill(c, n)
        end
    end

    # Build the tube mesh reactively
    tube_mesh_obs = map(p, positions_obs, resolved_colors, p.radius, p.n_sides, p.spline, p.spline_resolution) do pts, colors, radius, n_sides, do_spline, spline_res
        segments = split_at_nan(pts)
        color_segments = split_data_at_nan(pts, colors)

        all_positions = Point3f[]
        all_normals = Vec3f[]
        all_faces = GLTriangleFace[]
        all_colors = RGBA{Float32}[]
        vertex_offset = 0

        for (seg_idx, seg) in enumerate(segments)
            length(seg) < 2 && continue
            seg_colors = seg_idx <= length(color_segments) ? color_segments[seg_idx] : nothing

            # Spline interpolation
            if do_spline && length(seg) >= 2
                n_orig = length(seg)
                seg = interpolate_spline(seg; resolution=spline_res)
                if seg_colors !== nothing && length(seg_colors) == n_orig
                    seg_colors = interpolate_vertex_data(seg_colors, n_orig, length(seg))
                end
                if radius isa AbstractVector
                    seg_radius = interpolate_vertex_data(Float32.(radius), n_orig, length(seg))
                else
                    seg_radius = radius
                end
            else
                seg_radius = radius
            end

            pos, norms, fcs, vcols = build_tube_mesh(seg, seg_radius, n_sides; colors=seg_colors)

            # Offset face indices
            offset_faces = [GLTriangleFace(f[1] + vertex_offset, f[2] + vertex_offset, f[3] + vertex_offset) for f in fcs]

            append!(all_positions, pos)
            append!(all_normals, norms)
            append!(all_faces, offset_faces)
            if vcols !== nothing
                append!(all_colors, vcols)
            end

            vertex_offset += length(pos)
        end

        return (all_positions, all_normals, all_faces, all_colors)
    end

    # Extract observables for mesh!
    mesh_data = map(p, tube_mesh_obs) do (positions, normals, faces, colors)
        isempty(positions) && return GeometryBasics.Mesh(
            Point3f[Point3f(0,0,0)], GLTriangleFace[])
        return GeometryBasics.mesh(positions, faces; position=positions, normal=normals)
    end

    mesh_colors = map(p, tube_mesh_obs) do (positions, normals, faces, colors)
        isempty(colors) ? nothing : colors
    end

    # Use mesh! for rendering -- works in all backends including RayMakie
    mat = p.material[]
    if mat !== nothing
        mesh!(p, mesh_data; color=mesh_colors, material=mat)
    else
        mesh!(p, mesh_data; color=mesh_colors)
    end

    return p
end
