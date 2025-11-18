@testset "argument_docs format validation" begin
    # Get all concrete plot types
    internal_plot_types = [
        :PlotList,
        :PlotSpecPlot,
        :PrimitivePlotTypes,
        :Atomic,
        :Axis3D,
        :ComputePlots,
        :Plot,
        :Arrows, # This is just a deprecated alias
    ]
    plot_types = filter(names(Makie, all = true)) do name
        isdefined(Makie, name) || return false
        val = getfield(Makie, name)
        name in internal_plot_types && return false
        return val isa Type && val <: Makie.Plot && !isabstracttype(val)
    end

    # Track plot types without argument docs
    plot_types_without_docs = Set{Symbol}()

    for ptype_sym in plot_types
        PT = getfield(Makie, ptype_sym)
        docs = Makie.argument_docs(PT)

        # Test 1: Should return a Markdown.MD object
        @test isa(docs, Markdown.MD)

        # If empty, record it and skip further tests
        if isempty(docs.content)
            push!(plot_types_without_docs, ptype_sym)
            continue
        end

        # Test 2: First element should be a List
        @test isa(docs.content[1], Markdown.List)

        list = docs.content[1]

        # Test 3: Each list item should be formatted correctly
        for (i, item) in enumerate(list.items)
            # Each item should be non-empty
            @test !isempty(item)

            # First element should be a Paragraph
            @test isa(item[1], Markdown.Paragraph)

            para = item[1]

            # Paragraph should have content
            @test !isempty(para.content)

            # First element should be a Code block containing the argument signature
            @test isa(para.content[1], Markdown.Code)

        end
    end
    # Test that we have no plot types without docs
    @test isempty(plot_types_without_docs)
end
