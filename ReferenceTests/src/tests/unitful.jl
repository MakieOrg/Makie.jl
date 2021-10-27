using Dates, Unitful

f, ax, pl = scatter(rand(Second(1):Second(60):Second(20*60), 10), 1:10)
scatter!(ax, rand(Hour(1):Hour(1):Hour(20), 10), 1:10)
scatter!(ax, rand(10), 1:10) # should error!

scatter(u"ns" .* (1:10), u"d" .* rand(10) .* 10)

linesegments(1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))

scatter(u"cm" .* (1:10), u"d" .* rand(10) .* 10)
