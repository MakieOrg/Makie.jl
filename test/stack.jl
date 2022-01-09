using Makie: stack_grouped_from_to, default_width

@testset "grouped bar: stack" begin
    x1         = [1, 1,  1,  1]
    grp_dodge1 = [2, 2,  1,  1]
    grp_stack1 = [1, 2,  1,  2]
    y1         = [2, 3, -3, -2]

    x2         = [2, 2,  2,  2]
    grp_dodge2 = [3, 4,  3,  4]
    grp_stack2 = [3, 4,  3,  4]
    y2         = [2, 3, -3, -2]

    from, to = stack_grouped_from_to(grp_stack1, y1, (; x1 = x1, grp_dodge1 = grp_dodge1))
    from1 = [0.0, 2.0,  0.0, -3.0]
    to1   = [2.0, 5.0, -3.0, -5.0]
    @test from == from1
    @test to   == to1

    from, to = stack_grouped_from_to(grp_stack2, y2, (; x2 = x2, grp_dodge2 = grp_dodge2))
    from2 = [0.0,  0.0,  0.0,  0.0]
    to2   = [2.0,  3.0, -3.0, -2.0]
    @test from == from2
    @test to   == to2

    perm = [1, 4, 2, 7, 5, 3, 8, 6]
    x = [x1; x2][perm]
    y = [y1; y2][perm]
    grp_dodge = [grp_dodge1; grp_dodge2][perm]
    grp_stack = [grp_stack1; grp_stack2][perm]

    from_test = [from1; from2][perm]
    to_test = [to1; to2][perm]

    from, to = stack_grouped_from_to(grp_stack, y, (; x = x, grp_dodge = grp_dodge))
    @test from == from_test
    @test to == to_test
end

@testset "bar: width" begin
    @test default_width([1, 3, 1, -Inf, NaN]) == 2
    @test default_width(1:3:7) == 3
    @test default_width(-1:-3:-7) == 3
    @test default_width([12]) == 1
    @test default_width(Int[]) == 1
end
