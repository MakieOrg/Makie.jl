Pkg.develop(path="./ReferenceTests")
using ReferenceTests
@testset "reference image tests" begin
    ReferenceTests.run_tests()
end

