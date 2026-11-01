module ShaderAssetCacheTests
using Test, RayMakie
import GLMakie
RayMakie.activate!()

@testset "precompiled GL shader sources track their assets" begin
    caches = Base.find_all_in_cache_path(Base.PkgId(GLMakie))
    @test !isempty(caches)
    shaders = collect(values(GLMakie.LOADED_SHADERS))
    @test !isempty(shaders)
    dependencies = map(caches) do cache
        _, includes = Base.cache_dependencies(cache)
        Set(normpath.(includes))
    end
    # Shader strings are stored in GLMakie's package image. Every asset must
    # participate in invalidation, or editing only a .frag/.vert file leaves
    # its old source active in a fresh Julia process.
    @test any(paths -> all(shader -> normpath(shader.name) in paths, shaders), dependencies)
    for shader in shaders
        @test shader.source == read(shader.name, String)
    end
end
end
