@reference_test "sandbox changed manifest" begin
    f, ax, pl = scatter(1:10, 1:10; color = :red, markersize = 20)
    f
end

@reference_test "sandbox changed nomanifest" begin
    f, ax, pl = scatter(1:10, 10:-1:1; color = :green, markersize = 20)
    f
end

@reference_test "sandbox new manifest" begin
    f, ax, pl = lines(0 .. 10, sin; color = :blue, linewidth = 5)
    f
end

@reference_test "sandbox new nomanifest" begin
    f, ax, pl = lines(0 .. 10, cos; color = :orange, linewidth = 5)
    f
end
