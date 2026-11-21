"""
old recipe docstring
"""
@recipe(OldRecipe, a, b) do scene
    a = Attributes(
        a = Attributes(a = 1),
        b = 2
    )
    return Attributes(
        a = a,
        b = theme(scene, :x),
        c = (
            a = 1,
            b = Attributes(c = 3),
        ),
        d = map(sin, theme(scene, :y))
    )
end


@testset "Old Recipe" begin
    @test isdefined(Main, :oldrecipe)
    @test isdefined(Main, :oldrecipe!)
    @test isdefined(Main, :OldRecipe)
    @test Makie.plotsym(OldRecipe) === :OldRecipe
    @test Makie.symbol_to_plot(:OldRecipe) === OldRecipe
    @test Makie.argument_names(OldRecipe, 0) === (:a, :b)
    @test string(Docs.doc(Docs.Binding(Main, :oldrecipe))) == "old recipe docstring\n"

    attr = Makie.documented_attributes(OldRecipe)
    flattened = Dict{Symbol, NamedTuple}(
        Symbol("a.a.a") => (default = 1, expr = "1"),
        Symbol("a.b") => (default = 2, expr = "2"),
        :b => (default = Makie.Inherit((:x,)), expr = "Makie.Inherit((:x,))"),
        Symbol("c.a") => (default = 1, expr = "1"),
        Symbol("c.b.c") => (default = 3, expr = "3"),
        :d => (default = Makie.Inherit(sin, (:y,)), expr = "Makie.Inherit(sin, (:y,))")
    )

    @test issetequal(attr.merged_keys, keys(flattened))
    for i in eachindex(attr.merged_keys)
        key = attr.merged_keys[i]
        meta = flattened[key]
        @test attr.defaults[i] == meta.default
        @test attr.default_expr[i] == meta.expr
        @test attr.leaf_docstring[i] === nothing
        @test attr.types[attr.type_index[i]] == Any
        if meta.default isa Makie.Inherit
            @test i in attr.inherit
        end
    end
    @test attr.nested_docstring == Union{Nothing, String}[nothing for _ in 1:5]
end

"""
new recipe docstring
"""
@recipe NewRecipe (a::Real, b::Int) begin
    "a doc"
    a = @attributes begin
        a = @attributes begin
            "a.a.a"
            a = 1
            "a.a.b inherit"
            b = @inherit (:x, :y) 2
            c = 3
        end
        b = 5
        "a.c nested inherit"
        c = @inherit(sin, :q, @inherit((:m, :n), 5))
    end
    b = @inherit(:z, :red)
end

@testset "New Recipe" begin
    @test isdefined(Main, :newrecipe)
    @test isdefined(Main, :newrecipe!)
    @test isdefined(Main, :NewRecipe)
    @test Makie.plotsym(NewRecipe) === :NewRecipe
    @test Makie.symbol_to_plot(:NewRecipe) === NewRecipe
    @test Makie.argument_names(NewRecipe, 0) === (:a, :b)
    @test contains(string(Docs.doc(Docs.Binding(Main, :newrecipe))), "new recipe docstring")
    @test Makie.types_for_plot_arguments(NewRecipe) == Tuple{Real, Int}

    attr = Makie.documented_attributes(NewRecipe)
    flattened = Dict{Symbol, NamedTuple}(
        Symbol("a.a.a") => (docstring = "a.a.a", default = 1, expr = "1"),
        Symbol("a.a.b") => (
            docstring = "a.a.b inherit",
            default = Makie.Inherit((:x, :y), 2),
            expr = "@inherit (:x, :y) 2",
        ),
        Symbol("a.a.c") => (docstring = nothing, default = 3, expr = "3"),
        Symbol("a.b") => (docstring = nothing, default = 5, expr = "5"),
        Symbol("a.c") => (
            docstring = "a.c nested inherit",
            default = Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
            expr = "@inherit sin :q @inherit((:m, :n), 5)",
        ),
        :b => (
            docstring = nothing,
            default = Makie.Inherit((:z,), :red),
            expr = "@inherit :z :red",
        )
    )

    @test issetequal(attr.merged_keys, keys(flattened))
    for i in eachindex(attr.merged_keys)
        key = attr.merged_keys[i]
        meta = flattened[key]
        @test attr.defaults[i] == meta.default
        @test attr.default_expr[i] == meta.expr
        @test attr.leaf_docstring[i] == meta.docstring
        @test attr.types[attr.type_index[i]] == Any
        if meta.default isa Makie.Inherit
            @test i in attr.inherit
        end
    end
    @test attr.nested_docstring == [nothing, "a doc", nothing]
end

# same as NewRecipe, just types added
"""
block recipe docstring
"""
@Block BlockRecipe (a::Real, b::Int) begin
    @attributes begin
        "a doc"
        a = @attributes begin
            a = @attributes begin
                "a.a.a"
                a::Int = 1
                "a.a.b inherit"
                b::Int = @inherit (:x, :y) 2
                c = 3
            end
            b::Float32 = 5
            "a.c nested inherit"
            c = @inherit(sin, :q, @inherit((:m, :n), 5))
        end
        b::RGBAf = @inherit(:z, :red)
    end
end

@testset "Block Recipe" begin
    @test isdefined(Main, :BlockRecipe)
    @test Makie.symbol_to_block(:BlockRecipe) === BlockRecipe
    # kinda redundant with block recipes, only used for SliderGrid
    @test Makie.has_forwarded_layout(BlockRecipe) == false
    @test Makie.argument_names(BlockRecipe) == [:a, :b]
    @test contains(string(Docs.doc(Docs.Binding(Main, :BlockRecipe))), "block recipe docstring")

    attr = Makie.documented_attributes(BlockRecipe)
    flattened = Dict{Symbol, NamedTuple}(
        Symbol("a.a.a") => (docstring = "a.a.a", default = 1, expr = "1", type = Int),
        Symbol("a.a.b") => (
            docstring = "a.a.b inherit",
            default = Makie.Inherit((:x, :y), 2),
            expr = "@inherit (:x, :y) 2",
            type = Int,
        ),
        Symbol("a.a.c") => (docstring = nothing, default = 3, expr = "3", type = Any),
        Symbol("a.b") => (docstring = nothing, default = 5, expr = "5", type = Float32),
        Symbol("a.c") => (
            docstring = "a.c nested inherit",
            default = Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
            expr = "@inherit sin :q @inherit((:m, :n), 5)",
            type = Any,
        ),
        :b => (
            docstring = nothing,
            default = Makie.Inherit((:z,), :red),
            expr = "@inherit :z :red",
            type = RGBAf,
        ),
        # Added by default:
        :halign => (docstring = "The horizontal alignment of the block in its suggested bounding box.", default = :center, expr = ":center", type = Any),
        :valign => (docstring = "The vertical alignment of the block in its suggested bounding box.", default = :center, expr = ":center", type = Any),
        :width => (docstring = "The width setting of the block.", default = Auto(), expr = "Auto()", type = Any),
        :height => (docstring = "The height setting of the block.", default = Auto(), expr = "Auto()", type = Any),
        :tellwidth => (docstring = "Controls if the parent layout can adjust to this block's width", default = true, expr = "true", type = Bool),
        :tellheight => (docstring = "Controls if the parent layout can adjust to this block's height", default = true, expr = "true", type = Bool),
        :alignmode => (docstring = "The align mode of the block in its parent GridLayout.", default = Inside(), expr = "Inside()", type = Any),
    )

    @test issetequal(attr.merged_keys, keys(flattened))
    for i in eachindex(attr.merged_keys)
        key = attr.merged_keys[i]
        meta = flattened[key]
        @test attr.defaults[i] == meta.default
        @test attr.default_expr[i] == meta.expr
        @test attr.leaf_docstring[i] == meta.docstring
        @test attr.types[attr.type_index[i]] == meta.type
        if meta.default isa Makie.Inherit
            @test i in attr.inherit
        end
    end
    @test attr.nested_docstring == [nothing, "a doc", nothing]
end

@testset "external mixin" begin
    external_mixin() = Makie.@DocumentedAttributes begin
        "documented"
        x = 1
        "nested"
        nested = @attributes begin
            a = 1
            "b"
            b = 2
        end
    end

    attr = Makie.@DocumentedAttributes begin
        external_mixin()...
        z = 1
    end

    flattened = Dict{Symbol, NamedTuple}(
        Symbol("x") => (docstring = "documented", default = 1, expr = "1"),
        Symbol("nested.a") => (docstring = nothing, default = 1, expr = "1"),
        Symbol("nested.b") => (docstring = "b", default = 2, expr = "2"),
        Symbol("z") => (docstring = nothing, default = 1, expr = "1"),
    )

    @test issetequal(attr.merged_keys, keys(flattened))
    for i in eachindex(attr.merged_keys)
        key = attr.merged_keys[i]
        meta = flattened[key]
        @test attr.defaults[i] == meta.default
        @test attr.default_expr[i] == meta.expr
        @test attr.leaf_docstring[i] == meta.docstring
        @test attr.types[attr.type_index[i]] == Any
        if meta.default isa Makie.Inherit
            @test i in attr.inherit
        end
    end
    @test attr.nested_docstring == [nothing, "nested"]
end

@testset "Makie owned mixin" begin
    attr = Makie.@DocumentedAttributes begin
        "shading"
        shading = @attributes begin
            Makie.mixin_shading_attributes()...
        end
        z = 1
    end

    flattened = Dict{Symbol, NamedTuple}(
        Symbol("z") => (docstring = nothing, default = 1, expr = "1"),
    )

    mixin = Makie.mixin_shading_attributes()
    for (i, name) in enumerate(Makie.flattened_keys(mixin))
        flattened[Symbol("shading.", name)] = (
            docstring = mixin.leaf_docstring[i],
            default = mixin.defaults[i],
            expr = mixin.default_expr[i],
        )
    end

    @test issetequal(attr.merged_keys, keys(flattened))
    for i in eachindex(attr.merged_keys)
        key = attr.merged_keys[i]
        meta = flattened[key]
        @test attr.defaults[i] == meta.default
        @test attr.default_expr[i] == meta.expr
        @test attr.leaf_docstring[i] == meta.docstring
        @test attr.types[attr.type_index[i]] == Any
        if meta.default isa Makie.Inherit
            @test i in attr.inherit
        end
    end
    @test attr.nested_docstring == [nothing, "shading"]
end

@testset "Modifying documented attributes" begin
    old = @DocumentedAttributes begin
        a = 1
        nested = @attributes begin
            b::Int = @inherit b 1
        end
    end

    patch = @DocumentedAttributes begin
        "a doc"
        a = 2
        "nested doc"
        nested = @attributes begin
            "bob doc"
            bob::Real = @inherit :bob 2
            "c doc"
            c = @inherit :c 2
            "b deprecated by bob"
            @deprecate b bob
        end
        "other doc"
        other = @attributes begin
            "d doc"
            d::String = "2"
        end
    end

    # These tests are a bit lazy. Technically these entries are allowed to move
    # around as long as the information of one attribute moves together.

    @testset "error on collision" begin
        # TODO: Maybe this should do a prepass to not add some attributes before erroring?
        @test_throws ErrorException Makie.merge_documented_attributes!(old, patch, on_collision = :error)

        # working case + nesting
        old = @DocumentedAttributes begin
            a = 1
            nested = @attributes begin
                b::Int = @inherit b 1
            end
        end

        Makie.merge_documented_attributes!(old, patch, :new, on_collision = :error)

        @test old.merged_key_to_index == Dict([:a => 1, Symbol("nested.b") => 2, Symbol("new.a") => 3, Symbol("new.nested.b") => 4, Symbol("new.nested.bob") => 5, Symbol("new.nested.c") => 6, Symbol("new.other.d") => 7])
        @test old.merged_keys == [:a, Symbol("nested.b"), Symbol("new.a"), Symbol("new.nested.b"), Symbol("new.nested.bob"), Symbol("new.nested.c"), Symbol("new.other.d")]
        @test old.defaults == Any[1, Makie.Inherit(:b, 1), 2, Makie.Inherit(:bob, 2), Makie.Inherit(:bob, 2), Makie.Inherit(:c, 2), "2"]
        @test old.leaf_docstring == Union{Nothing, String}[nothing, nothing, "a doc", "b deprecated by bob", "bob doc", "c doc", "d doc"]
        @test old.nested_docstring == Union{Nothing, String}[nothing, nothing, nothing, "nested doc", "other doc"]
        @test old.types == Type[Any, Int, Real, String]
        @test old.type_index == [1, 2, 1, 3, 3, 1, 4]
        @test old.type_indices == [[1, 3, 6], Int[2], [4, 5], [7]]
        @test old.inherit == [2, 4, 5, 6]
        @test old.deprecation_indices == [4 => 5]
    end

    @testset "skip on collision" begin
        old = @DocumentedAttributes begin
            a = 1
            nested = @attributes begin
                b::Int = @inherit b 1
            end
        end

        # TODO: The deprecation logic doesn't really make sense here...
        Makie.merge_documented_attributes!(old, patch, on_collision = :skip)

        @test old.merged_key_to_index == Dict([:a => 1, Symbol("nested.c") => 4, Symbol("nested.b") => 2, Symbol("other.d") => 5, Symbol("nested.bob") => 3])
        @test old.merged_keys == [:a, Symbol("nested.b"), Symbol("nested.bob"), Symbol("nested.c"), Symbol("other.d")]
        @test old.defaults == Any[1, Makie.Inherit(:b, 1), Makie.Inherit(:bob, 2), Makie.Inherit(:c, 2), "2"]
        @test old.leaf_docstring == Union{Nothing, String}[nothing, nothing, "bob doc", "c doc", "d doc"]
        @test old.nested_docstring == Union{Nothing, String}[nothing, nothing, "other doc"]
        @test old.types == Type[Any, Int, Real, String]
        @test old.type_index == [1, 2, 3, 1, 4]
        @test old.type_indices == [[1, 4], [2], [3], [5]]
        @test old.inherit == [2, 3, 4]
        @test old.deprecation_indices == [2 => 3]
    end

    @testset "replace on collision" begin
        old = @DocumentedAttributes begin
            a = 1
            nested = @attributes begin
                b::Int = @inherit b 1
            end
        end

        Makie.merge_documented_attributes!(old, patch, on_collision = :replace)

        @test old.merged_key_to_index == Dict([:a => 1, Symbol("nested.c") => 4, Symbol("nested.b") => 2, Symbol("other.d") => 5, Symbol("nested.bob") => 3])
        @test old.merged_keys == [:a, Symbol("nested.b"), Symbol("nested.bob"), Symbol("nested.c"), Symbol("other.d")]
        @test old.defaults == Any[2, Makie.Inherit(:bob, 2), Makie.Inherit(:bob, 2), Makie.Inherit(:c, 2), "2"]
        @test old.leaf_docstring == Union{Nothing, String}["a doc", "b deprecated by bob", "bob doc", "c doc", "d doc"]
        @test old.nested_docstring == Union{Nothing, String}[nothing, "nested doc", "other doc"]
        @test old.types == Type[Any, Int, Real, String]
        @test old.type_index == [1, 3, 3, 1, 4]
        @test old.type_indices == [[1, 4], Int[], [2, 3], [5]]
        @test old.inherit == [2, 3, 4]
        @test old.deprecation_indices == [2 => 3]
    end
end

@testset "Theme Observables" begin
    theme = Makie.current_default_theme()

    @testset "Plot" begin
        doc_attr = Makie.documented_attributes(Scatter)

        # Check assumptions - if these change just switch to a different inherited attribute
        @assert haskey(theme, :colormap)
        @assert haskey(doc_attr, :colormap)
        @assert Makie.get_flat_default(doc_attr, :colormap) isa Makie.Inherit
        @assert Makie.get_flat_default(doc_attr, :colormap).keys === (:colormap,)

        @test theme[:colormap] isa Union{Symbol, Vector, String, Tuple}
        inherited = theme[:colormap]
        f, a, p = scatter(rand(10))
        @test p.colormap[] === inherited

        @testset "Theme inherited" begin
            color_obs = Observable{Any}(:magma)
            with_theme(colormap = color_obs) do
                @test theme[:colormap] === color_obs
                @test isempty(color_obs.listeners)
                scene = Scene()
                @test isempty(color_obs.listeners)
                p = scatter!(scene, rand(10))
                @test length(color_obs.listeners) == 1
                @test p.colormap[] === :magma
                color_obs[] = :terrain
                @test p.colormap[] === :terrain
            end

            GC.gc(true)
            @test isempty(color_obs.listeners)
        end

        @testset "Theme overwrite" begin
            color_obs = Observable{Any}(:RdBu)
            with_theme(Scatter = Attributes(colormap = color_obs)) do
                @test theme[:Scatter][:colormap] === color_obs
                @test isempty(color_obs.listeners)
                scene = Scene()
                @test isempty(color_obs.listeners)
                p = scatter!(scene, rand(10))
                @test length(color_obs.listeners) == 1
                @test p.colormap[] === :RdBu
                color_obs[] = :greens
                @test p.colormap[] === :greens
            end

            GC.gc(true)
            @test isempty(color_obs.listeners)
        end
    end

    @testset "Block" begin
        doc_attr = Makie.documented_attributes(Axis)

        # Check assumptions - if these change just switch to a different inherited attribute
        @assert haskey(theme, :fontsize)
        @assert haskey(doc_attr, :titlesize)
        @assert Makie.get_flat_default(doc_attr, :titlesize) isa Makie.Inherit
        @assert Makie.get_flat_default(doc_attr, :titlesize).keys === (:fontsize,)

        @test theme[:fontsize] isa Real
        inherited = theme[:fontsize]
        f, a = Axis()
        @test a.titlesize[] ≈ inherited

        @testset "Theme inherited" begin
            fontsize_obs = Observable{Float32}(20.0)
            with_theme(fontsize = fontsize_obs) do
                @test theme[:fontsize] === fontsize_obs
                @test isempty(fontsize_obs.listeners)
                f, a = Axis()
                @test length(fontsize_obs.listeners) > 1
                @test a.titlesize[] === 20.0
                fontsize_obs[] = 10
                @test a.titlesize[] === 10.0
            end

            GC.gc(true)
            @test isempty(fontsize_obs.listeners)
        end

        @testset "Theme overwrite" begin
            fontsize_obs = Observable{Float32}(30.0)
            with_theme(Axis = Attributes(titlesize = fontsize_obs)) do
                @test theme[:Axis][:titlesize] === fontsize_obs
                @test isempty(fontsize_obs.listeners)
                f, a = Axis()
                @test length(fontsize_obs.listeners) == 1
                @test a.titlesize[] === 30.0
                fontsize_obs[] = 15
                @test a.titlesize[] === 15.0
            end

            GC.gc(true)
            @test isempty(fontsize_obs.listeners)
        end
    end
end
