to_signal(obj) = Signal(obj)
to_signal(obj::Signal) = obj
to_signal(obj::Scene) = obj
#
#
# function Base.map(f, x::Signal{T}) where T <: AbstractArray
#     invoke(map, (Function, Signal), x-> f(x), x)
# end
