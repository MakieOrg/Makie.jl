@testset "argument_docs format validation" begin
    # Get all concrete plot types
    plot_types = filter(names(Makie, all=true)) do name
        isdefined(Makie, name) || return false
        val = getfield(Makie, name)
        val isa Type && val <: Makie.Plot && !isabstracttype(val)
    end

    # Track plot types without argument docs
    plot_types_without_docs = Symbol[]

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

            # NEW format requirement: signatures should NOT contain colons
            # (old format was like `arg:` followed by description)
            code = para.content[1]
            @test !occursin(":", code.code)
        end
    end

    # Explicitly test that we know which plot types are missing docs
    # This list should shrink over time as we add documentation
    # NOTE: Many of these inherit from traits (PointBased, etc.) which already have docs
    expected_without_docs = [
        :Arrows,        # Type alias, uses Arrows2D/Arrows3D
        :Atomic,
        :Axis3D,
        :ComputePlots,
        :ECDFPlot,
        :Hist,
        :Plot,          # Base type
        :PlotList,
        :PlotSpecPlot,
        :PrimitivePlotTypes,
        :QQNorm,
        :QQPlot,
        :RainClouds,
        :StepHist,
        :TimeSeries,
    ]

    # Test that our expectation matches reality
    @test sort(plot_types_without_docs) == sort(expected_without_docs)

    # Print a helpful message about coverage
    if !isempty(plot_types_without_docs)
        total = length(plot_types)
        with_docs = total - length(plot_types_without_docs)
        coverage = round(100 * with_docs / total, digits=1)
        @info "argument_docs coverage: $with_docs/$total plot types ($coverage%)"
        @info "Plot types needing argument_docs: $(join(sort(plot_types_without_docs), ", "))"
    end
end
