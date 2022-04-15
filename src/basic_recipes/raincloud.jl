####
#### Helper functions to make the cloud plot!
####
function cloud_plot_check_args(category_labels, data_array)
    length(category_labels) == length(data_array) || DimensionMismatch("Length of category_labels must match with length of data_array")
    return nothing
end

# Allow to globally set jitter RNG for testing
# A bit of a lazy solution, but it doesn't seem to be desirably to
# pass the RNG through the plotting command
const RAINCLOUD_RNG = Ref{Random.AbstractRNG}(Random.GLOBAL_RNG)

# quick custom function for jitter
rand_localized(min, max) = rand_localized(RAINCLOUD_RNG[], min, max)
rand_localized(RNG::Random.AbstractRNG, min, max) = rand(RNG) * (max - min) .+ min

"""
    rainclouds!(ax, category_labels, combined_data_array; plot_boxplots=true, plot_clouds=true, kwargs...)

Plot a scatter, vilin, and boxplot for the `combined_data_array`. Each data array in `combined_data_array` will be labeled using a
corresponding label from `category_labels`.

# Arguments
- `ax`: Axis used to place all these plots onto.
- `category_labels`: Typically `Vector{String}` used for storing the labels of each category on the x axis of the plot.
- `combined_data_array`: Typically `Vector{Vector{Float64}}` used for storing the data array in each element of the `combined_data_array`.

# Keywords
- `plot_boxplots=true`: Boolean to show boxplots to summarize distribution of data.
- `clouds=violin`: [violin, hist, nothing] to show cloud plots either as violin or histogram plot, or no cloud plot.
- `hist_bins=30`: if `clouds=hist`, this passes down the number of bins to the histogram call.
- `dist_between_categories=1.0`: Reduce this value to bring categories closer together.
- `side=:left`: Can take values of `:left` or `:right`. Determines which side the violin plot will be on.
- `center_boxplot=true`: Determines whether or not to have the boxplot be centered in the category.

## Violin Plot Specific Keywords
- `cloud_width=1.0`: Determines size of violin plot. Corresponds to `width` keyword arg in `violin`.

## Box Plot Specific Keywords
- `boxplot_width=0.1`: Width of the boxplot in category x-axis absolute terms.
- `whiskerwidth=0.5`: The width of the Q1, Q3 whisker in the boxplot. Value as a portion of the `boxplot_width`.
- `strokewidth=1.0`: Determines the stroke width for the outline of the boxplot.
- `show_median=true`: Determines whether or not to have a line should the median value in the boxplot.
- `boxplot_nudge=0.075`: Determines the distance away the boxplot should be placed from the center line when `center_boxplot` is `false`.
    This is the value used to recentering the boxplot.

## Scatter Plot Specific Keywords
- `side_scatter_nudge`: Default value is 0.02 if `plot_boxplots` is true, otherwise `0.075` default.
- `jitter_width=0.05`: Determines the width of the scatter-plot bar in category x-axis absolute terms.
- `markersize=2`: Size of marker used for the scatter plot.

## Axis General Keywords
- `title`
- `xlabel`
- `ylabel`
"""
@recipe(RainClouds, category_labels, data_array) do scene
    return Attributes(
        dist_between_categories = 1.0,
        side = :left,
        center_boxplot = true,
        # Cloud plot
        cloud_width = 1.0,
        # Box Plot Settings
        boxplot_width = 0.1,
        whiskerwidth =  0.5,
        strokewidth = 1.0,
        show_median = true,
        boxplot_nudge = 0.075,

        markersize = 2.0,

        plot_boxplots = true,
        clouds = violin,
        hist_bins = 30,
        palette = Makie.wong_colors(1)
    )
end

# create_jitter_array(length_data_array; jitter_width = 0.1, clamped_portion = 0.1)
# Returns a array containing random values with a mean of 0, and a values from `-jitter_width/2.0` to `+jitter_width/2.0`, where a portion of a values are clamped right at the edges.
function create_jitter_array(length_data_array; jitter_width = 0.1, clamped_portion = 0.1)
    jitter_width < 0 && ArgumentError("`jitter_width` should be positive.")
    !(0 <= clamped_portion <= 1) || ArgumentError("`clamped_portion` should be between 0.0 to 1.0")

    # Make base jitter, note base jitter minimum-to-maximum span is 1.0
    base_min, base_max = (-0.5, 0.5)
    jitter = [rand_localized(base_min, base_max) for _ in 1:length_data_array]

    # created clamp_min, and clamp_max to clamp a portion of the data
    @assert (base_max - base_min) == 1.0
    @assert (base_max + base_min) / 2.0 == 0
    clamp_min = base_min + (clamped_portion / 2.0)
    clamp_max = base_max - (clamped_portion / 2.0)

    # clamp if need be
    clamp!(jitter, clamp_min, clamp_max)

    # Based on assumptions of clamp_min and clamp_max above
    jitter = jitter * (jitter_width / clamp_max)

    return jitter
end

####
#### Functions that make the cloud plot
####
function plot!(
        ax::Makie.Axis, P::Type{<: RainClouds},
        allattrs::Attributes, category_labels, data_array)

    plot = plot!(ax.scene, P, allattrs, category_labels, data_array)
    category_labels, data_array = group_args(category_labels, data_array)

    ax.xticks = (plot.x_positions_of_categories[], category_labels)
    if haskey(allattrs, :title)
        ax.title = allattrs.title[]
    end
    if haskey(allattrs, :xlabel)
        ax.xlabel = allattrs.xlabel[]
    end
    if haskey(allattrs, :ylabel)
        ax.ylabel = allattrs.ylabel[]
    end
    reset_limits!(ax)
    return plot
end

function group_args(category_labels, data_array)
    if !(eltype(data_array) isa AbstractVector)
        grouped = Dict{String, typeof(data_array)}()
        for (label, data) in zip(category_labels, data_array)
            push!(get!(grouped, string(label), eltype(data_array)[]), data)
        end

        @info "Converting parameters"
        category_labels = collect(keys(grouped))
        data_array = collect(values(grouped))
    end
    return category_labels, data_array
end

function convert_arguments(::Type{<: RainClouds}, category_labels, data_array)
    cloud_plot_check_args(category_labels, data_array)
    return (category_labels, data_array)
end


function plot!(plot::RainClouds)
    category_labels = plot.category_labels[]
    data_array = plot.data_array[]
    category_labels, data_array = group_args(category_labels, data_array)

    # Checking kwargs, and assigning defaults if they are not in kwargs
    # General Settings
    # Define where categories should lie
    dist_between_categories = plot.dist_between_categories[]
    x_positions_of_categories = 1:length(category_labels)
    x_positions_of_categories *= dist_between_categories

    side = plot.side[]
    center_boxplot_bool = plot.center_boxplot[]
    # Cloud plot
    cloud_width =  plot.cloud_width[]
    cloud_width[] < 0 && ArgumentError("`cloud_width` should be positive.")

    # Box Plot Settings
    boxplot_width = plot.boxplot_width[]
    whiskerwidth = plot.whiskerwidth[]
    strokewidth = plot.strokewidth[]
    show_median = plot.show_median[]
    boxplot_nudge = plot.boxplot_nudge[]

    plot_boxplots = plot.plot_boxplots[]
    clouds = plot.clouds[]
    hist_bins = plot.hist_bins[]

    # Scatter Plot defaults dependent on if there is a boxplot
    side_scatter_nudge_default = plot_boxplots ? 0.2 : 0.075
    jitter_width_default = 0.05

    # Scatter Plot Settings
    side_scatter_nudge = to_value(get(plot, :side_nudge, side_scatter_nudge_default))
    side_scatter_nudge < 0 && ArgumentError("`side_nudge` should be positive. Change `side` to :left, :right if you wish.")
    jitter_width = abs(to_value(get(plot, :jitter_width, jitter_width_default)))
    jitter_width < 0 && ArgumentError("`jitter_width` should be positive.")
    markersize = plot.markersize[]


    # Set-up
    (side == :left) && (side_nudge_direction = 1.0)
    (side == :right) && (side_nudge_direction = -1.0)
    side_scatter_nudge_with_direction = side_scatter_nudge * side_nudge_direction
    side_boxplot_nudge_with_direction = boxplot_nudge * side_nudge_direction

    recenter_to_boxplot_nudge_value = center_boxplot_bool ? side_boxplot_nudge_with_direction : 0.0
    plot_boxplots || (recenter_to_boxplot_nudge_value = 0.0)
    palette = plot.palette[]
    # Note: these cloud plots are horizontal
    for (category_index, (_, data_points)) in enumerate(zip(category_labels, data_array))
        if any(ismissing, data_points)
            error("missing values in data not supported. Please filter out any missing values before plotting")
        end
        color = palette[mod1(category_index, length(palette))]
        category_x_position_array = fill(x_positions_of_categories[category_index], length(data_points))

        jitter = create_jitter_array(length(data_points); jitter_width = jitter_width)

        if !isnothing(clouds)
            if clouds === violin
                violin!(plot, category_x_position_array .- recenter_to_boxplot_nudge_value, data_points;
                        show_median=show_median, side=side, width=cloud_width, color=color)
            elseif clouds === hist
                xoffset = x_positions_of_categories[category_index] .- recenter_to_boxplot_nudge_value
                hist!(plot, data_points; direction=:x, color=color, offset=xoffset, scale_to=-cloud_width, bins=hist_bins)
            else
                error("cloud attribute accepts (violin, hist, nothing), but not: $(clouds)")
            end
        end

        scatter!(plot, category_x_position_array .+ side_scatter_nudge_with_direction .+ jitter .- recenter_to_boxplot_nudge_value,
            data_points; markersize=markersize, color=color)

        plot_boxplots && boxplot!(plot, category_x_position_array .+ side_boxplot_nudge_with_direction .- recenter_to_boxplot_nudge_value, data_points, strokewidth=strokewidth, whiskerwidth=whiskerwidth, width=boxplot_width, markersize=markersize, color=color)
    end
    # store the x positions, to set the axis
    plot[:x_positions_of_categories] = x_positions_of_categories

    return plot
end
