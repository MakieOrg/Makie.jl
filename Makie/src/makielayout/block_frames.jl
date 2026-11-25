"""
    frame_transform!(f, block)

Sets the frame transform of the block's scene (including decorations) to
`f(bbox)`, recomputed whenever the layout moves the block. For example
`frame_transform!(bbox -> frame_rotation(pi / 8, center(bbox)), ax)`.
"""
function frame_transform!(f, block::Block)
    scene = block.blockscene
    return map!(bbox -> Mat3f(f(bbox)), scene, scene.frame_transform, block.layoutobservables.computedbbox)
end

"""
    alpha!(block, alpha)

Sets the opacity of the block's scene as a whole, including decorations.
"""
alpha!(block::Block, alpha::Real) = (block.blockscene.alpha[] = alpha)
