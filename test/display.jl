module TestBackend
    using Makie
    struct Screen <: MakieScreen end
    Makie.backend_showable(::Type{Screen}, ::MIME"text/html") = true
    Makie.backend_showable(::Type{Screen}, ::MIME"image/png") = true
end

@testset "set_preferred_mime 'constructor'" begin
    @test_throws ErrorException Makie.set_preferred_mime!("text/htmle")
    @test nothing == Makie.set_preferred_mime!(MIME"text/html"())
    @test nothing == Makie.set_preferred_mime!(Symbol("text/html"))
    @test nothing == Makie.set_preferred_mime!()
end

@testset "preferred mime without backend" begin
    # Only text/plain
    Makie.set_active_backend!(missing)
    Makie.set_preferred_mime!("text/html")
    s = Scene();
    @test Base.showable("text/plain", s)
    @test !Base.showable("text/html", s)
end

@testset "with Backend + preferred mime" begin
    Makie.set_active_backend!(TestBackend)
    Makie.set_preferred_mime!("text/html")
    @test Base.showable("text/html", s)
    @test !Base.showable("image/png", s)
end

@testset "without preferred mime, backend capabilities should be returned" begin
    Makie.set_preferred_mime!()
    @test Base.showable("text/html", s)
    @test Base.showable("image/png", s)
    @test !Base.showable("text/plain", s)
    @test !Base.showable("image/jpeg", s)
end

@testset "only plain for missing backend" begin
    Makie.set_active_backend!(missing)
    @test Base.showable("text/plain", s)
    @test !Base.showable("image/png", s)
    @test !Base.showable("text/html", s)
end

@testset "preferred mime without backend should return false" begin
    Makie.set_preferred_mime!("text/html")
    @test !Base.showable("text/html", s)
end
