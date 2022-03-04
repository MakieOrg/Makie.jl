
# raincloud

{{doc rainclouds}}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!(type = "png")
using Random
using Makie: rand_localized

####
#### Below is used for testing the plotting functionality.
####

function mockup_distribution(N)
    all_possible_labels = ["Single Mode", "Double Mode", "Single Mode", "Double Mode", "Random Exp", "Uniform"]
    category_label = rand(all_possible_labels)

    if category_label == "Single Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(N) .+ random_mean

    elseif category_label == "Double Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean

        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = vcat(data_points, random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean)

    elseif category_label == "Random Exp"
        data_points = randexp(N)

    elseif category_label == "Uniform"
        min = rand_localized(0, 4)
        max = min + rand_localized(0.5, 4)
        data_points = [rand_localized(min, max) for _ in 1:N]

    else
        error("Unidentified category.")
    end

    return category_label, data_points
end

function mockup_categories_and_data_array(num_categories; N = 500)
    category_labels = String[]
    data_array = Vector{Float64}[]

    for _ in 1:num_categories
        category_label, data_points = mockup_distribution(N)

        push!(category_labels, category_label)
        push!(data_array, data_points)
    end
    return category_labels, data_array
end

category_labels, data_array = mockup_categories_and_data_array(3)

fig = rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = false, cloud_width=0.5, clouds=hist, hist_bins=50)
fig
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
fig = rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions",
    ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, clouds=hist)
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
fig = rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, side = :right)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
more_category_labels = repeat(category_labels, 2)
more_data_array = repeat(data_array, 2)

fig = rainclouds(more_category_labels, more_data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
more_category_labels = repeat(category_labels, 3)
more_data_array = repeat(data_array, 3)
fig = rainclouds(more_category_labels, more_data_array;
    xlabel = "Categories of Distributions",
    ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
more_category_labels = repeat(category_labels, 3)
more_data_array = repeat(data_array, 3)
rainclouds(more_category_labels, more_data_array;
    xlabel = "Categories of Distributions",
    ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, dist_between_categories = 0.6)
```
\end{examplefigure}

4 of these, between 3 distributions
Left and Right example
With and Without Box Plot

\begin{examplefigure}{}
```julia
fig = Figure(resolution = (800*2, 600*5))

category_labels, data_array = mockup_categories_and_data_array(3)
rainclouds!(Axis(fig[1, 1]), category_labels, data_array;
    title = "Left Side, with Box Plot",
    side = :left,
    plot_boxplots = true)

rainclouds!(Axis(fig[2, 1]), category_labels, data_array;
    title = "Left Side, without Box Plot",
    side = :left,
    plot_boxplots = false)

rainclouds!(Axis(fig[1, 2]), category_labels, data_array;
    title = "Right Side, with Box Plot",
    side = :right,
    plot_boxplots = true)

rainclouds!(Axis(fig[2, 2]), category_labels, data_array;
    title = "Right Side, without Box Plot",
    side = :right,
    plot_boxplots = false)

# Plots wiht more categories
# dist_between_categories (0.6, 1.0)
# with and without clouds

category_labels, data_array = mockup_categories_and_data_array(12)
rainclouds!(Axis(fig[3, 1:2]), category_labels, data_array;
    title = "More categories. Default spacing.",
    plot_boxplots = true,
    dist_between_categories = 1.0)

rainclouds!(Axis(fig[4, 1:2]), category_labels, data_array;
    title = "More categories. Adjust space. (smaller cloud widths and smaller category distances)",
    plot_boxplots = true,
    cloud_width = 0.3,
    dist_between_categories = 0.5)

rainclouds!(Axis(fig[5, 1:2]), category_labels, data_array;
    title = "More categories. Adjust space. No clouds.",
    plot_boxplots = true,
    clouds = nothing,
    dist_between_categories = 0.5)

supertitle = Label(fig[0, :], "Cloud Plot Testing (Scatter, Violin, Boxplot)", textsize=30)
fig
```
\end{examplefigure}
