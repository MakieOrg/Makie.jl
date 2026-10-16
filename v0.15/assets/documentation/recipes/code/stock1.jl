# This file was generated, do not modify it. # hide
using CairoMakie
CairoMakie.activate!() # hide

struct StockValue{T<:Real}
    open::T
    close::T
    high::T
    low::T
end