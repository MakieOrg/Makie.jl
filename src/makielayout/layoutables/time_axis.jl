# struct TimeAxis
#     axis::Axis
#     function TimeAxis(args...;
#             xlabel="",
#             xunits_in_label=false,
#             xticks=automatic,#TimeTicks(;units_in_label=xunits_in_label),
#             ylabel="",
#             yunits_in_label=false,
#             yticks=automatic,#TimeTicks(;units_in_label=yunits_in_label),
#             kw...)

#         # xticks=to_timeticks(xticks)
#         # yticks=to_timeticks(yticks)

#         if xunits_in_label
#             xticks isa TimeTicks || error("To print units in label, xticks need to be of type TimeTicks")
#             xlabel = map(convert(Observable, xlabel), xticks.time_unit) do label, unit
#                 string(label, " ", unit_symbol(unit))
#             end
#         end

#         if yunits_in_label
#             yticks isa TimeTicks || error("To print units in label, yticks need to be of type TimeTicks")
#             ylabel = map(convert(Observable, ylabel), yticks.time_unit) do label, unit
#                 string(label, " ", unit_symbol(unit))
#             end
#         end

#         ax = Axis(args...; xlabel=xlabel, xticks=xticks, yticks=yticks, ylabel=ylabel, kw...)
#         return new(ax)
#     end
# end


# function Makie.plot!(
#         ta::TimeAxis, P::Makie.PlotFunc,
#         attributes::Makie.Attributes, args...)

#     converted_args = axis_convert(ta, convert.(Observable, args)...)
#     return Makie.plot!(ta.axis, P, attributes, converted_args...)
# end

# function Makie.plot!(P::Makie.PlotFunc, ax::TimeAxis, args...; kw_attributes...)
#     Makie.plot!(ax, P, Attributes(kw_attributes), args...)
# end

# export TimeAxis
