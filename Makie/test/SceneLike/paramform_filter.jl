module ParamFormFilterTests
using Test
import Makie as M
@testset "ParamForm filtering retains fields, collapses rows and restores nested accessories" begin
    fig=M.Figure()
    pf=M.ParamForm(fig[1,1],(first=(1.,nothing),second=(2.,nothing),third=(3.,nothing)),
        (field,gp)->begin
            grid=M.GridLayout(gp)
            M.Button(grid[1,1];label=string(field))
            grid
        end;title="Parameters")
    first=pf.widgets[:first];second=pf.widgets[:second]
    initial=M.GridLayoutBase.determinedirsize(pf.layout,M.GridLayoutBase.Row())
    second.focused[]=true
    M.filter_fields!(name->name===:first,pf)
    @test first.blockscene.visible[]
    @test !second.blockscene.visible[] && !second.focused[]
    @test M.GridLayoutBase.determinedirsize(pf.layout,M.GridLayoutBase.Row())<initial
    @test pf.graph[:values][]==(first=1.,second=2.,third=3.)
    @test all(!b.blockscene.visible[] for b in M.flatten_layout_content(pf.accessories[:second]))
    # A parent Card's unfolding can unhide descendants. Reapplying an unchanged
    # row mask must hide those fields again without rebuilding their controls.
    M.set_content_visible!(pf.layout,true)
    M.filter_fields!(name->name===:first,pf)
    @test !second.blockscene.visible[]
    M.filter_fields!(_->true,pf)
    @test pf.widgets[:first]===first && pf.widgets[:second]===second
    @test second.blockscene.visible[]
    @test all(b.blockscene.visible[] for b in M.flatten_layout_content(pf.accessories[:second]))
    @test M.GridLayoutBase.determinedirsize(pf.layout,M.GridLayoutBase.Row())≈initial
    M.filter_fields!(_->false,pf)
    @test all(!b.blockscene.visible[] for b in values(pf.widgets))
    M.filter_fields!(_->true,pf)
    @test pf.graph[:values][]==(first=1.,second=2.,third=3.)
    empty=M.ParamForm(fig[2,1],NamedTuple())
    @test M.filter_fields!(_->false,empty)===empty
    M.clear!(pf);M.clear!(empty)
end
end
