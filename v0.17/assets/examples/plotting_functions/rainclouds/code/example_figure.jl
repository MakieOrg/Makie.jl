# This file was generated, do not modify it. # hide
__result = begin # hide
    fig = Figure(resolution = (800*2, 600*5))
colors = [Makie.wong_colors(); Makie.wong_colors()]

category_labels, data_array = mockup_categories_and_data_array(3)
rainclouds!(Axis(fig[1, 1]), category_labels, data_array;
    title = "Left Side, with Box Plot",
    side = :left,
    plot_boxplots = true,
    color = colors[indexin(category_labels, unique(category_labels))])

rainclouds!(Axis(fig[2, 1]), category_labels, data_array;
    title = "Left Side, without Box Plot",
    side = :left,
    plot_boxplots = false,
    color = colors[indexin(category_labels, unique(category_labels))])

rainclouds!(Axis(fig[1, 2]), category_labels, data_array;
    title = "Right Side, with Box Plot",
    side = :right,
    plot_boxplots = true,
    color = colors[indexin(category_labels, unique(category_labels))])

rainclouds!(Axis(fig[2, 2]), category_labels, data_array;
    title = "Right Side, without Box Plot",
    side = :right,
    plot_boxplots = false,
    color = colors[indexin(category_labels, unique(category_labels))])

# Plots wiht more categories
# dist_between_categories (0.6, 1.0)
# with and without clouds

category_labels, data_array = mockup_categories_and_data_array(12)
rainclouds!(Axis(fig[3, 1:2]), category_labels, data_array;
    title = "More categories. Default spacing.",
    plot_boxplots = true,
    dist_between_categories = 1.0,
    color = colors[indexin(category_labels, unique(category_labels))])

rainclouds!(Axis(fig[4, 1:2]), category_labels, data_array;
    title = "More categories. Adjust space. (smaller cloud widths and smaller category distances)",
    plot_boxplots = true,
    cloud_width = 0.3,
    dist_between_categories = 0.5,
    color = colors[indexin(category_labels, unique(category_labels))])


rainclouds!(Axis(fig[5, 1:2]), category_labels, data_array;
    title = "More categories. Adjust space. No clouds.",
    plot_boxplots = true,
    clouds = nothing,
    dist_between_categories = 0.5,
    color = colors[indexin(category_labels, unique(category_labels))])

supertitle = Label(fig[0, :], "Cloud Plot Testing (Scatter, Violin, Boxplot)", textsize=30)
fig
end # hide
save(joinpath(@OUTPUT, "example_8783989339827969684.png"), __result; ) # hide

nothing # hide