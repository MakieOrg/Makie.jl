initialize_block!(block::Container) = init_layout!(block)

# For SpecApi, to mirror `plot(spec)` with `Block(spec)`
Block(args...; kwargs...) = Container(args...; kwargs...)