function initialize_block!(box::Box)
    blockscene = box.blockscene

    strokecolor_with_visibility = lift(blockscene, box.strokecolor, box.strokevisible) do col, vis
        vis ? col : RGBAf(0, 0, 0, 0)
    end

    ibbox = lift(round_to_IRect2D, blockscene, box.layoutobservables.computedbbox)

    poly!(blockscene, ibbox, color = box.color, visible = box.visible,
        strokecolor = strokecolor_with_visibility, strokewidth = box.strokewidth,
        inspectable = false)

    # trigger bbox
    box.layoutobservables.suggestedbbox[] = box.layoutobservables.suggestedbbox[]

    return
end
