"""
    bresenham_line(x1, y1, x2, y2)

Bresenham's line algorithm to get all pixels between two points.

# References
- Bresenham, J.E., 1965.  \
  Algorithm for computer control of a digital plotter. \
  IBM Systems Journal 4, 25-30. \
  https://doi.org/10.1147/sj.41.0025
"""
function bresenham_line!(buffer::Matrix{Float64}, x1::Int, y1::Int, x2::Int, y2::Int, max_x::Int, max_y::Int)
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    sx = x1 < x2 ? 1 : -1
    sy = y1 < y2 ? 1 : -1
    err = dx - dy

    x, y = x1, y1

    while true
        if 1 <= x <= max_x && 1 <= y <= max_y
            buffer[x, y] = 1.0
        end

        if x == x2 && y == y2
            break
        end

        e2 = 2 * err
        if e2 > -dy
            err -= dy
            x += sx
        end
        if e2 < dx
            err += dx
            y += sy
        end
    end
end

"""
    compute_normalized_density(
        density_buffer::Matrix{Float64},
        series::AbstractVector,
        bins_x::Int,
        bins_y::Int,
        value_min::AbstractFloat,
        value_max::AbstractFloat,
    )::Matrix{Float64}

Compute arc-length normalized density for a single time series using Bresenham-style line
rendering.

# References
- Moritz, D., & Fisher, D. (2018). \
  Visualizing a Million Time Series with the Density Line Chart. \
  arXiv:1808.06019 [cs.HC] \
  https://doi.org/10.48550/arXiv.1808.06019

# Arguments
- `density_buffer`: Cache for density values
- `series`: A single time series (vector of values over time)
- `bins_x`: Number of bins in the time dimension (horizontal resolution)
- `bins_y`: Number of bins in the value dimension (vertical resolution)
"""
function compute_normalized_density!(
    density_buffer::Matrix{Float64},
    series::AbstractVector,
    bins_x::Int,
    bins_y::Int,
    value_min::AbstractFloat,
    value_max::AbstractFloat,
)::Nothing
    n_times = length(series)

    # Map time indices to bins
    time_to_bin = range(1, bins_x, n_times)

    # Map values to bins (higher values -> higher row indices)
    value_range = value_max - value_min
    value_to_bin(v) = clamp(round(Int, (v - value_min) / value_range * (bins_y - 1)) + 1, 1, bins_y)

    # Render each line segment
    for i in 1:(n_times - 1)
        x1 = round(Int, time_to_bin[i])
        y1 = value_to_bin(series[i])
        x2 = round(Int, time_to_bin[i + 1])
        y2 = value_to_bin(series[i + 1])

        bresenham_line!(density_buffer, x1, y1, x2, y2, bins_x, bins_y)
    end

    # Apply arc length normalization
    @views for row in 1:bins_x
        col_sum = sum(view(density_buffer, row, :))
        if col_sum > 0
            density_buffer[row, :] ./= col_sum
        end
    end

    return nothing
end

function denseline_data(ts_matrix::T, bins_x::Int64, bins_y::Int64)::T where {T<:AbstractMatrix}
    # Define value range for binning
    value_min = minimum(ts_matrix)
    value_max = maximum(ts_matrix)

    density_map = zeros(bins_x, bins_y)
    density_tmp = zeros(bins_x, bins_y)

    # Process each time series
    for series_idx in axes(ts_matrix, 2)
        series = view(ts_matrix, :, series_idx)
        compute_normalized_density!(density_tmp, series, bins_x, bins_y, value_min, value_max)
        density_map .+= density_tmp
        fill!(density_tmp, 0.0)
    end

    return density_map
end

"""
    DenseLines

A Makie recipe for creating density line visualizations of multiple time series.

# References
- Moritz, D., & Fisher, D. (2018).
  Visualizing a Million Time Series with the Density Line Chart.
  arXiv:1808.06019 [cs.HC]
  https://doi.org/10.48550/arXiv.1808.06019
"""
@recipe DenseLines (ts_matrix,) begin
    "Number of bins in time dimension"
    bins_x = 400
    "Number of bins in value dimension"
    bins_y = 300
    "Color scheme for the density heatmap"
    colormap = :plasma
    "Show colorbar"
    colorbar = true
    "Label for colorbar"
    colorbar_label = "Density"

    # Inherit standard plot attributes
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(dl::DenseLines)
    # Compute density data with dynamic updating
    map!(
        dl.attributes, [:ts_matrix, :bins_x, :bins_y], [:density_map, :value_min, :value_max]
    ) do ts_mat, bx, by
        density_map = denseline_data(ts_mat, bx, by)

        # Define value range for binning
        val_min = minimum(ts_mat)
        val_max = maximum(ts_mat)

        return (density_map, val_min, val_max)
    end

    # Compute coordinate ranges
    map!(
        dl.attributes, [:ts_matrix, :bins_x, :bins_y, :value_min, :value_max], [:x_range, :y_range]
    ) do ts_mat, bx, by, val_min, val_max
        n_times = size(ts_mat, 1)
        x_rng = range(1, n_times, bx)
        y_rng = range(val_min, val_max, by)
        return (x_rng, y_rng)
    end

    hm = heatmap!(dl, dl.x_range, dl.y_range, dl.density_map; colormap=dl.colormap)

    return dl
end

Makie.argument_names(::Type{<:DenseLines}) = (:ts_matrix,)
