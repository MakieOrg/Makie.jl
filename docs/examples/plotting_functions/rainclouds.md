# rainclouds

"Raincloud" plots are a combination of a (half) violin plot, box plot and scatter plots. The
three together can make an appealing and informative visual, particularly for large N datasets.

{{doc rainclouds}}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

using Random
using Makie: rand_localized

####
#### Below is used for testing the plotting functionality.
####

function mockup_distribution(N)
    all_possible_labels = ["Single Mode", "Double Mode", "Random Exp", "Uniform"]
    category_type = rand(all_possible_labels)

    if category_type == "Single Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(N) .+ random_mean

    elseif category_type == "Double Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean

        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = vcat(data_points, random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean)

    elseif category_type == "Random Exp"
        data_points = randexp(N)

    elseif category_type == "Uniform"
        min = rand_localized(0, 4)
        max = min + rand_localized(0.5, 4)
        data_points = [rand_localized(min, max) for _ in 1:N]

    else
        error("Unidentified category.")
    end

    return data_points
end

function mockup_categories_and_data_array(num_categories; N = 500)
    category_labels = String[]
    data_array = Float64[]

    for category_label in string.(('A':'Z')[1:min(num_categories, end)])
        data_points = mockup_distribution(N)

        append!(category_labels, fill(category_label, N))
        append!(data_array, data_points)
    end
    return category_labels, data_array
end

category_labels, data_array = mockup_categories_and_data_array(3)

colors = Makie.wong_colors()
rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = false, cloud_width=0.5, clouds=hist, hist_bins=50,
    color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
rainclouds(category_labels, data_array;
    ylabel = "Categories of Distributions",
    xlabel = "Samples", title = "My Title",
    orientation = :horizontal,
    plot_boxplots = true, cloud_width=0.5, clouds=hist,
    color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions",
    ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, clouds=hist,
    color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, side = :right,
    violin_limits = extrema, color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5, side = :right,
    color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
more_category_labels, more_data_array = mockup_categories_and_data_array(6)

rainclouds(more_category_labels, more_data_array;
    xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5,
    color = colors[indexin(more_category_labels, unique(more_category_labels))])
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
category_labels, data_array = mockup_categories_and_data_array(6)
rainclouds(category_labels, data_array;
    xlabel = "Categories of Distributions",
    ylabel = "Samples", title = "My Title",
    plot_boxplots = true, cloud_width=0.5,
    color = colors[indexin(category_labels, unique(category_labels))])
```
\end{examplefigure}
