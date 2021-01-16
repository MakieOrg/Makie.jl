using AbstractPlotting: PointTrans, xyz_boundingbox

@testset "Basic transforms" begin
    function point2(x::Point2)
        return Point2f0(x[1] + 10, x[2] - 77)
    end

    function point3(x::Point3)
        return Point3f0(x[1] + 10, x[2] - 77, x[3] /  4)
    end
    trans2 = PointTrans{2}(point2)
    trans3 = PointTrans{3}(point3)
    points = [Point2f0(0, 0), Point2f0(0, 1)]
    bb = xyz_boundingbox(trans2, points)
    @test bb == Rect(Vec3f0(10, -77, 0), Vec3f0(0, 1, 0))
    bb = xyz_boundingbox(trans3, points)
    @test bb == Rect(Vec3f0(10, -77, 0), Vec3f0(0, 1, 0))

    points = [Point3f0(0, 0, 4), Point3f0(0, 1, -8)]
    bb = xyz_boundingbox(trans2, points)
    @test bb == Rect(Vec3f0(10, -77, -8), Vec3f0(0, 1, 12))
    bb = xyz_boundingbox(trans3, points)
    @test bb == Rect(Vec3f0(10, -77, -2.0), Vec3f0(0, 1, 3.0))
end
