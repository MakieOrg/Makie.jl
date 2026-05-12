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
        c = Attributes(
            a = 1,
            b = Attributes(c = 3)
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

    da = Makie.documented_attributes(OldRecipe)
    expected = Makie.DocumentedAttributes(
        :a => Makie.AttributeMetadata(nothing, Makie.DocumentedAttributes(
            :a => Makie.AttributeMetadata(nothing, Makie.DocumentedAttributes(
                :a => Makie.AttributeMetadata(nothing, 1, "1", Any)
            ), "Attributes(...)", Any),
            :b => Makie.AttributeMetadata(nothing, 2, "2", Any)
        ), "a", Any), # This can't parse `Attributes` because it's a variable...
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:x,)), "Makie.Inherit((:x,))", Any),
        :c => Makie.AttributeMetadata(nothing, Makie.DocumentedAttributes(
            :a => Makie.AttributeMetadata(nothing, 1, "1", Any),
            :b => Makie.AttributeMetadata(nothing, Makie.DocumentedAttributes(
                :c => Makie.AttributeMetadata(nothing, 3, "3", Any)
            ), "Attributes(...)", Any),
        ), "Attributes(...)", Any),
        :d => Makie.AttributeMetadata(nothing, Makie.Inherit(sin, (:y,)), "Makie.Inherit(sin, (:y,))", Any)
    )
    @test da == expected

    ma = Makie.meta_attributes(OldRecipe)
    flattened = Dict{Symbol, Makie.AttributeMetadata}(
        Symbol("a.a.a") => Makie.AttributeMetadata(nothing, 1, "1", Any),
        Symbol("a.b") => Makie.AttributeMetadata(nothing, 2, "2", Any),
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:x,)), "Makie.Inherit((:x,))", Any),
        Symbol("c.a") => Makie.AttributeMetadata(nothing, 1, "1", Any),
        Symbol("c.b.c") => Makie.AttributeMetadata(nothing, 3, "3", Any),
        :d => Makie.AttributeMetadata(nothing, Makie.Inherit(sin, (:y,)), "Makie.Inherit(sin, (:y,))", Any)
    )

    @test issetequal(ma.merged_keys, keys(flattened))
    for i in eachindex(ma.merged_keys)
        key = ma.merged_keys[i]
        meta = flattened[key]
        @test meta.default_value == ma.defaults[i]
        @test meta.default_expr == ma.default_expr[i]
        @test meta.docstring == ma.leaf_docstring[i]
        @test meta.type == ma.types[ma.type_index[i]]
        if meta.default_value isa Makie.Inherit
            @test i in ma.inherit
        end
    end
    @test ma.nested_docstring == Union{Nothing, String}[nothing for _ in 1:5]
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

    da = Makie.documented_attributes(NewRecipe)
    expected = Makie.DocumentedAttributes(
        :a => Makie.AttributeMetadata(
            "a doc",
            Makie.DocumentedAttributes(
                :a => Makie.AttributeMetadata(
                    nothing,
                    Makie.DocumentedAttributes(
                        :a => Makie.AttributeMetadata("a.a.a", 1, "1", Any),
                        :b => Makie.AttributeMetadata("a.a.b inherit", Makie.Inherit((:x, :y), 2), "@inherit (:x, :y) 2", Any),
                        :c => Makie.AttributeMetadata(nothing, 3, "3", Any),
                    ),
                    "Attributes(...)",
                    Any
                ),
                :b => Makie.AttributeMetadata(nothing, 5, "5", Any),
                :c => Makie.AttributeMetadata(
                    "a.c nested inherit",
                    Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
                    "@inherit sin :q @inherit((:m, :n), 5)",
                    Any
                )
            ),
            "Attributes(...)",
            Any
        ),
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:z,), :red), "@inherit :z :red", Any)
    )
    @test da == expected

    ma = Makie.meta_attributes(NewRecipe)
    flattened = Dict{Symbol, Makie.AttributeMetadata}(
        Symbol("a.a.a") => Makie.AttributeMetadata("a.a.a", 1, "1", Any),
        Symbol("a.a.b") => Makie.AttributeMetadata("a.a.b inherit", Makie.Inherit((:x, :y), 2), "@inherit (:x, :y) 2", Any),
        Symbol("a.a.c") => Makie.AttributeMetadata(nothing, 3, "3", Any),
        Symbol("a.b") => Makie.AttributeMetadata(nothing, 5, "5", Any),
        Symbol("a.c") => Makie.AttributeMetadata(
            "a.c nested inherit",
            Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
            "@inherit sin :q @inherit((:m, :n), 5)",
            Any
        ),
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:z,), :red), "@inherit :z :red", Any)
    )

    @test issetequal(ma.merged_keys, keys(flattened))
    for i in eachindex(ma.merged_keys)
        key = ma.merged_keys[i]
        meta = flattened[key]
        @test meta.default_value == ma.defaults[i]
        @test meta.default_expr == ma.default_expr[i]
        @test meta.docstring == ma.leaf_docstring[i]
        @test meta.type == ma.types[ma.type_index[i]]
        if meta.default_value isa Makie.Inherit
            @test i in ma.inherit
        end
    end
    @test ma.nested_docstring == [nothing, "a doc", nothing]
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

    da = Makie.documented_attributes(BlockRecipe)

    expected = Makie.DocumentedAttributes(
        :a => Makie.AttributeMetadata(
            "a doc",
            Makie.DocumentedAttributes(
                :a => Makie.AttributeMetadata(
                    nothing,
                    Makie.DocumentedAttributes(
                        :a => Makie.AttributeMetadata("a.a.a", 1, "1", Int),
                        :b => Makie.AttributeMetadata("a.a.b inherit", Makie.Inherit((:x, :y), 2), "@inherit (:x, :y) 2", Int),
                        :c => Makie.AttributeMetadata(nothing, 3, "3", Any),
                    ),
                    "Attributes(...)",
                    Any
                ),
                :b => Makie.AttributeMetadata(nothing, 5, "5", Float32),
                :c => Makie.AttributeMetadata(
                    "a.c nested inherit",
                    Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
                    "@inherit sin :q @inherit((:m, :n), 5)",
                    Any
                )
            ),
            "Attributes(...)",
            Any
        ),
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:z,), :red), "@inherit :z :red", RGBAf),
        # Added by default:
        :halign => Makie.AttributeMetadata("The horizontal alignment of the block in its suggested bounding box.", :center, ":center", Any),
        :valign => Makie.AttributeMetadata("The vertical alignment of the block in its suggested bounding box.", :center, ":center", Any),
        :width => Makie.AttributeMetadata("The width setting of the block.", Auto(), "Auto()", Any),
        :height => Makie.AttributeMetadata("The height setting of the block.", Auto(), "Auto()", Any),
        :tellwidth => Makie.AttributeMetadata("Controls if the parent layout can adjust to this block's width", true, "true", Bool),
        :tellheight => Makie.AttributeMetadata("Controls if the parent layout can adjust to this block's height", true, "true", Bool),
        :alignmode => Makie.AttributeMetadata("The align mode of the block in its parent GridLayout.", Inside(), "Inside()", Any),
    )
    @test da == expected

    ma = Makie.meta_attributes(BlockRecipe)
    flattened = Dict{Symbol, Makie.AttributeMetadata}(
        Symbol("a.a.a") => Makie.AttributeMetadata("a.a.a", 1, "1", Int),
        Symbol("a.a.b") => Makie.AttributeMetadata("a.a.b inherit", Makie.Inherit((:x, :y), 2), "@inherit (:x, :y) 2", Int),
        Symbol("a.a.c") => Makie.AttributeMetadata(nothing, 3, "3", Any),
        Symbol("a.b") => Makie.AttributeMetadata(nothing, 5, "5", Float32),
        Symbol("a.c") => Makie.AttributeMetadata(
            "a.c nested inherit",
            Makie.Inherit(sin, (:q,), Makie.Inherit((:m, :n), 5)),
            "@inherit sin :q @inherit((:m, :n), 5)",
            Any
        ),
        :b => Makie.AttributeMetadata(nothing, Makie.Inherit((:z,), :red), "@inherit :z :red", RGBAf),
        # Added by default:
        :halign => Makie.AttributeMetadata("The horizontal alignment of the block in its suggested bounding box.", :center, ":center", Any),
        :valign => Makie.AttributeMetadata("The vertical alignment of the block in its suggested bounding box.", :center, ":center", Any),
        :width => Makie.AttributeMetadata("The width setting of the block.", Auto(), "Auto()", Any),
        :height => Makie.AttributeMetadata("The height setting of the block.", Auto(), "Auto()", Any),
        :tellwidth => Makie.AttributeMetadata("Controls if the parent layout can adjust to this block's width", true, "true", Bool),
        :tellheight => Makie.AttributeMetadata("Controls if the parent layout can adjust to this block's height", true, "true", Bool),
        :alignmode => Makie.AttributeMetadata("The align mode of the block in its parent GridLayout.", Inside(), "Inside()", Any),
    )

    @test issetequal(ma.merged_keys, keys(flattened))
    for i in eachindex(ma.merged_keys)
        key = ma.merged_keys[i]
        meta = flattened[key]
        @test meta.default_value == ma.defaults[i]
        @test meta.default_expr == ma.default_expr[i]
        @test meta.docstring == ma.leaf_docstring[i]
        @test meta.type == ma.types[ma.type_index[i]]
        if meta.default_value isa Makie.Inherit
            @test i in ma.inherit
        end
    end
    @test ma.nested_docstring == [nothing, "a doc", nothing]
end
