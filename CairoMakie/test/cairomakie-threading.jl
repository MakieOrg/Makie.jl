using CairoMakie

mkdir("threaded_cairo")

function save_plot(path)
    f = Figure()
    ax = Axis(f[1, 1])
    scatter!(ax, 1:10)
    save(path, f)
end

@time Threads.@threads for i in 1:500
    save_plot("threaded_cairo/test$(i).png")
end

using FileIO
save_plot("test.png")
comparison = load("test.png")

all(x-> load(x) ≈ comparison, readdir("threaded_cairo"; join=true))


# Color quickstart
# MakieGallery take it offline
# Show for plot
