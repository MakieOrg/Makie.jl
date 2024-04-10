
struct MyDimConversion <: Makie.AbstractDimConversion end
struct MyUnit
    value::Float64
end

# This is currently needed because expand_dimensions can only be narrowly defined for real vectors in Makie.
# so if you want to make `plot(some_y_values)` for your own types, you need to define this method:
Makie.expand_dimensions(::PointBased, y::AbstractVector{<:MyUnit}) = (keys(y.values), y)

function Makie.needs_tick_update_observable(conversion::MyDimConversion)
    # return an observable that indicates when ticks need to update e.g. in case the unit changes or new categories get added.
    # For a simple unit conversion this is not needed, so we return nothing.
    return nothing
end

# Indicate that this type should be converted using MyDimConversion
# The Type gets extracted via `Makie.get_element_type(plot_argument_for_dim_n)`
# so e.g. `plot(1:10, ["a", "b", "c"])` would call `Makie.get_element_type(["a", "b", "c"])` and return `String` for axis dim 2.
Makie.create_dim_conversion(::Type{MyUnit}) = MyDimConversion()
# This function needs to be overloaded too, even though it's redundant to the above in a sense.
# We did not want to use `hasmethod(MakieCore.should_dim_convert, ::Type{MyDimTypes})` because it can be slow and error prown.
Makie.MakieCore.should_dim_convert(::Type{MyUnit}) = true

# The non obersable version of the conversion function
function Makie.convert_dim_value(conversion::MyDimConversion, values)
    return [v.value for v in values]
end

function Makie.convert_dim_observable(conversion::MyDimConversion, values_obs::Observable, deregister)
    # Do the actual conversion here
    # e.g. like this
    result = Observable(Float64[])
    f = on(values_obs; update=true) do values
        result[] = [v.value for v in values]
    end
    # any observable operation like `on` or `map` should be pushed to `deregister`, to clean up state properly if e.g. the plot gets destroyed.
    # for `result = map(func, values_obs)` one can use `append!(deregister, result.inputs)`
    push!(deregister, f)
    return result
end

function Makie.get_ticks(conversion::MyDimConversion, user_set_ticks, user_dim_scale, user_formatter, limits_min, limits_max)
    # Don't do anything special to ticks for this example
    ticknumbers, ticklabels = get_ticks(user_set_ticks, user_dim_scale, user_formatter, limits_min,
                                        limits_max)
    return ticknumbers, ticklabels .* "myunit"
end

barplot([MyUnit(1), MyUnit(2), MyUnit(3)], 1:3)
