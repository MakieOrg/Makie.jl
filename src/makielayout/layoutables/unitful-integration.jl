
base_unit(q::Quantity) = base_unit(typeof(q))
base_unit(::Type{Quantity{NumT, DimT, U}}) where {NumT, DimT, U} = base_unit(U)
base_unit(::Type{Unitful.FreeUnits{U, DimT, nothing}}) where {DimT, U} = U[1]

function to_free_unit(unit, value::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    return Unitful.FreeUnits{(unit,), Dim, nothing}()
end

function next_smaller_unit(::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    next_smaller_unit(U[1])
end

function next_smaller_unit(::Unitful.FreeUnits{U, Dim, nothing}) where {Dim, U}
    next_smaller_unit(U[1])
end

function next_smaller_unit(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    return next_smaller_unit_generic(unit)
end

function next_bigger_unit(::Quantity{T, Dim, Unitful.FreeUnits{U, Dim, nothing}}) where {T, Dim, U}
    next_bigger_unit(U[1])
end

function next_bigger_unit(::Unitful.FreeUnits{U, Dim, nothing}) where {Dim, U}
    next_bigger_unit(U[1])
end

function next_bigger_unit(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    return next_bigger_unit_generic(unit)
end

function next_bigger_unit_generic(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    next = (unit.tens >= 3 || unit.tens <= -6) ? 3 : 1
    abs(next) > 24 && return unit
    return Unitful.Unit{USym, Dim}(unit.tens + next, unit.power)
end

function next_smaller_unit_generic(unit::Unitful.Unit{USym, Dim}) where {USym, Dim}
    next = (unit.tens >= 6 || unit.tens <= -3) ? 3 : 1
    abs(next) > 24 && return unit
    return Unitful.Unit{USym, Dim}(unit.tens - next, unit.power)
end

function next_bigger_unit(unit::Unitful.Unit{USym, Unitful.𝐓}) where {USym}
    irregular = (:Year, :Week, :Day, :Hour, :Minute, :Second)
    if USym === :Second && unit.tens < 0
        return next_bigger_unit_generic(unit)
    else
        idx = findfirst(==(USym), irregular)
        idx == 1 && return unit
        return Unitful.Unit{irregular[idx - 1], Unitful.𝐓}(0, 1//1)
    end
end

function next_smaller_unit(unit::Unitful.Unit{USym, Unitful.𝐓}) where {USym}
    USym === :Second && return next_smaller_unit_generic(unit)
    irregular = (:Year, :Week, :Day, :Hour, :Minute)
    idx = findfirst(==(USym), irregular)
    if isnothing(idx)
        error("What unit is this: $(unit)!?")
    else
        idx == length(irregular) && return Unitful.Unit{:Second, Unitful.𝐓}(0, 1//1)
        return Unitful.Unit{irregular[idx + 1], Unitful.𝐓}(0, 1//1)
    end
end

function best_unit(value)
    # factor we fell comfortable to display as tick values
    best_unit = to_free_unit(base_unit(value), value)
    raw_value = ustrip(value)
    while true
        if abs(raw_value) > 999
            _best_unit = to_free_unit(next_bigger_unit(best_unit), value)
        elseif abs(raw_value) > 0 && abs(raw_value) < 0.001
            _best_unit = to_free_unit(next_smaller_unit(best_unit), value)
        else
            return best_unit
        end
        if _best_unit == best_unit
            return best_unit # we reached max unit
        else
            best_unit = _best_unit
            raw_value = ustrip(uconvert(best_unit, value))
        end
    end
end

# TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs)
# TimeUnitsBig = map(TimeUnits[2:end]) do unit
#     next_bigger_unit(1.0 * getfield(Unitful, unit))
# end

# @test string.(TimeUnitsBig) == string.(TimeUnits[1:end-1])

# TimeUnitsSmaller = map(TimeUnits[1:end-1]) do unit
#     next_smaller_unit(1.0 * getfield(Unitful, unit))
# end

# @test string.(TimeUnitsSmaller) == string.(TimeUnits[2:end])

# PrefixFactors = last.(sort(collect(Unitful.prefixdict), by=first))
# MeterUnits = getfield.((Unitful,), Symbol.(PrefixFactors .* "m"))
# MeterUnits = map(MeterUnits[2:end]) do unit
#     next_bigger_unit(1.0 * unit)
# end

# TimeUnits = (:yr, :wk, :d, :hr, :minute, :s, :ds, :cs, :ms, :μs, :ns, :ps, :fs)
# UnitfulTimes = map(TimeUnits) do unit_name
#     Quantity{T,  Unitful.𝐓, typeof(getfield(Unitful, unit_name))} where T
# end
# TimeUnits2 = Union{UnitfulTimes...}
# const TimeLike = Union{UnitfulTimes..., Period}
