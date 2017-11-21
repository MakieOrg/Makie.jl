


"""
calculates how much `child` needs to move to not touch `parent`
"""
function move_from_touch(
        parent::HyperRectangle{N, T}, child::HyperRectangle{N},
        pad::Vec{N}
    ) where {N, T}
    pmini, cmini = minimum(parent), minimum(child) .- pad
    pmaxi, cmaxi = maximum(parent), maximum(child) .+ pad

    move = ntuple(Val{N}) do i
        posdir = ifelse(cmini[i] < pmini[i], (pmini[i] - cmini[i]), zero(T)) #always positive
        negdir = ifelse(cmaxi[i] > pmaxi[i], (pmaxi[i] - cmaxi[i]), zero(T)) #always minus
        ifelse(posdir > abs(negdir), posdir, negdir) # move in the bigger direction
    end
    Vec{N, T}(move)
end

"""
Moves `child` so that it doesn't touch parent. Leaves a gap to parent defined by `pad`.
"""
function dont_touch(
        parent::HyperRectangle{N, T}, child::HyperRectangle{N},
        pad::Vec{N}
    ) where {N, T}

    child + move_from_touch(parent, child, pad)
end

function dont_touch(
        parent::SimpleRectangle, child::SimpleRectangle,
        pad::Vec
    )
    r = dont_touch(HyperRectangle(parent), HyperRectangle(child), pad)
    SimpleRectangle(minimum(r)..., widths(r)...)
end
function move_from_touch(
        parent::SimpleRectangle, child::SimpleRectangle,
        pad::Vec
    )
    move_from_touch(HyperRectangle(parent), HyperRectangle(child), pad)
end

# using GeometryTypes
#
# using Base.Test
#
# x = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# c = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# @test dont_touch(x, c, Vec3f0(0)) == x
# c = HyperRectangle(Vec3f0(-2), Vec3f0(1.5))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.75), Vec3f0(1.5))
# c = HyperRectangle(Vec3f0(0), Vec3f0(1, 1.75, 1))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.25, -2.0, -1.25), Vec3f0(1.0, 1.75, 1.0))
# x = SimpleRectangle(0, 0, 1, 1)
# SimpleRectangle(HyperRectangle(x))
