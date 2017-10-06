function expand_kwargs(kw_args)
    # TODO get in all the shorthands from Plots.jl
    Dict{Symbol, Any}(kw_args)
end

# for func in (:contour, :image, :heatmap, :volume, :lines, :poly, :scatter, :text, :wireframe)
#     @eval begin
#         function $func(args...; kw_args...)
#              $func(args..., expand_kwargs(kw_args))
#         end
#     end
# end
