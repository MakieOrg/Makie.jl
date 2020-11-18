function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(Scene, ())
    @assert precompile(update_limits!, (Scene,))
    @assert precompile(update_limits!, (Scene, Automatic))
    @assert precompile(update_limits!, (Scene, FRect3D))

    @assert precompile(boundingbox, (Scene,))
    Ngonf0 = GeometryBasics.Ngon{2, Float32, 3, Point2f0}
    # @assert precompile(boundingbox, (Mesh{Tuple{Vector{GeometryBasics.Mesh{2, Float32, Ngonf0, FaceView{Ngonf0}}}}},))  # doesn't seem to work
    @assert precompile(boundingbox, (Poly{Tuple{Vector{Vector{Point2f0}}}},))
    @assert precompile(boundingbox, (String, Vector{Point3f0}, Vector{Float32}, Vector{FTFont}, Vec2f0, Vector{Quaternionf0}, SMatrix{4, 4, Float32, 16}, Float64, Float64))

    @assert precompile(poly_convert, (Vector{Vector{Point2f0}},))
    @assert precompile(rotatedrect, (FRect2D, Float32))

    @assert precompile(plot!, (Scene, Type{Poly{Tuple{IRect2D}}}, Attributes, Tuple{Observable{IRect2D}}, Observable{Tuple{Vector{Vector{Point2f0}}}}))
    @assert precompile(plot!, (Mesh{Tuple{Vector{GeometryBasics.Mesh{2, Float32, Ngonf0, FaceView{Ngonf0}}}}},))
    @assert precompile(plot!, (Scene, Type{Annotations{Tuple{Vector{Tuple{String, Point2f0}}}}}, Attributes, Tuple{Observable{Vector{Tuple{String, Point2f0}}}}, Observable{Tuple{Vector{Tuple{String, Point2f0}}}}))
end
