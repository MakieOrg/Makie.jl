is_unitrange(x) = false, 0:0
is_unitrange(x::UnitRange) = true, 0:0
function is_unitrange(x::AbstractVector)
    length(x) < 2 && return false, 0:0
    diff = x[2] - x[1]
    length(x) < 3 && return true, x[1]:x[2]
    last = x[3]
    for elem in drop(x, 3)
        diff2 = elem - last
        diff2 != diff && return false, 0:0
    end
    return true, range(first(x), diff, length(x))
end

x1 = [2, 6.5, 7,2]
x2 = [3, 3.5, 4,6]
y  = [10.1, 19.9, 30.1, 40.3]

b = -24.70401416765054
w = [1.63684, 10.3377]
plot(x1,x2,y,marker=(10,0.8,:red),st=:surface)
f = (x,y)->b+w[1]*x+w[2]*y
x, y = 0:.1:10, 0:.1:10



plot!(0:.1:10, 0:.1:10, (x,y)->b+w[1]*x+w[2]*y, st=:surface)
plot!(x1,x2,y,marker=(10,0.8,:red),st=:surface)
plot!(x1,x2,y,marker=(10,0.8,:red))
plot!(x1,zeros(x2),y,line=(7,:green),marker=(10,0.8,:red),zlim=(0,50))
plot!(zeros(x1),x2,y,line=(7,:blue),marker=(10,0.8,:red))


T = Float64

z = similar(Array{Float64}, length(x), length(y))


z2 = [f(xx, yy) for xx in x, yy in y]

z2 == z

function surface(x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function, kw_args) where T1, T2
    T = Base.Core.Inference.return_type(f, (T1, T2))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    surface(x, y, z, kw_args)
end
function surface(x::AbstractMatrix{T1}, y::AbstractMatrix{T2}, f::Function, kw_args) where T1, T2
    if size(x) != size(y)
        error("x and y don't have the same size. Found: x: $(size(x)), y: $(size(y))")
    end
    T = Base.Core.Inference.return_type(f, (T1, T2))
    z = f.(x, y)
    surface(x, y, z, kw_args)
end

function wireframe(x::AbstractArray, y::AbstractArray, z::AbstractArray, kw_args)
    if length(x) != length(y) || length(y) == length(z)
        error("x, y and z must have the same length. Found: $(length(x)), $(length(y)), $(length(z))")
    end
    points = broadcast(Point3f0, vec(x), vec(y), vec(z))
    NF = (length(z) * 4) - ((size(z, 1) + size(z, 2)) * 2)
    faces = Vector{Cuint}(NF)
    idx = (i,j) -> sub2ind(size(z), i, j) - 1
    li = 1
    for i = 1:size(z, 1), j = 1:size(z, 2)
        if i < size(z, 1)
            faces[li] = idx(i, j); faces[li + 1] = idx(i + 1, j)
            li += 2
        end
        if j < size(z, 2)
            faces[li] = idx(i, j)
            faces[li + 1] = idx(i, j + 1)
            i += 2
        end
    end
    kw_args[:indices] = faces
    return visualize(points, Style(:linesegment), kw_args)
end


function surface_attributes(kw_args)


end


function surface(x, y, z::AbstractMatrix{T}, kw_args) where T <: AbstractFloat
    x_is_ur, xrange = is_unitrange(x)
    y_is_ur, yrange = is_unitrange(x)
    if x_is_ur && y_is_ur
        kw_args[:ranges] = (xrange, yrange)
    else
        if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
            main = map(s->map(Float32, s), (x, y, z))
        elseif isa(x, AbstractVector) || isa(y, AbstractVector)
            x = Float32[x[i] for i = 1:size(z,1), j = 1:size(z,2)]
            y = Float32[y[j] for i = 1:size(z,1), j = 1:size(z,2)]
            main = (x, y, map(Float32, z))
        else
            error("surface: combination of types not supported: $(typeof(x)) $(typeof(y)) $(typeof(z))")
        end
        if get(kw_args, :wireframe, false)
            return wireframe(x, y, z, kw_args)
        end
    end
    return visualize(main, Style(:surface), kw_args)
end


function heatmap(x,y,z, kw_args)
    get!(kw_args, :color_norm, Vec2f0(ignorenan_extrema(z)))
    get!(kw_args, :color_map, Plots.make_gradient(cgrad()))
    delete!(kw_args, :intensity)
    I = GLVisualize.Intensity{Float32}
    heatmap = I[z[j,i] for i=1:size(z, 2), j=1:size(z, 1)]
    tex = GLAbstraction.Texture(heatmap, minfilter=:nearest)
    kw_args[:stroke_width] = 0f0
    kw_args[:levels] = 1f0
    visualize(tex, Style(:default), kw_args)
end


function contour(x, y, z, kw_args)
    if kw_args[:fillrange] != nothing
        delete!(kw_args, :intensity)
        I = GLVisualize.Intensity{Float32}
        main = [I(z[j,i]) for i=1:size(z, 2), j=1:size(z, 1)]
        return visualize(main, Style(:default), kw_args)
    else
        h = kw_args[:levels]
        T = eltype(z)
        levels = Contour.contours(map(T, x), map(T, y), z, h)
        result = Point2f0[]
        zmin, zmax = get(kw_args, :limits, Vec2f0(ignorenan_extrema(z)))
        cmap = get(kw_args, :color_map, get(kw_args, :color, RGBA{Float32}(0,0,0,1)))
        colors = RGBA{Float32}[]
        for c in levels.contours
            for elem in c.lines
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                col = GLVisualize.color_lookup(cmap, c.level, zmin, zmax)
                append!(colors, fill(col, length(elem.vertices) + 1))
            end
        end
        kw_args[:color] = colors
        kw_args[:color_map] = nothing
        kw_args[:color_norm] = nothing
        kw_args[:intensity] = nothing
        return visualize(result, Style(:lines),kw_args)
    end
end





function poly(points, kw_args)
    last(points) == first(points) && pop!(points)
    polys = GeometryTypes.split_intersections(points)
    result = []
    for poly in polys
        mesh = GLNormalMesh(poly) # make polygon
        if !isempty(GeometryTypes.faces(mesh)) # check if polygonation has any faces
            push!(result, GLVisualize.visualize(mesh, Style(:default), kw_args))
        else
            warn("Couldn't draw the polygon: $points")
        end
    end
    result
end



function scatter(points, kw_args)
    prim = get(kw_args, :primitive, GeometryTypes.Circle)
    if isa(prim, GLNormalMesh)
        if haskey(kw_args, :model)
            p = get(kw_args, :perspective, eye(GeometryTypes.Mat4f0))
            kw_args[:scale] = GLAbstraction.const_lift(kw_args[:model], kw_args[:scale], p) do m, sc, p
                s  = Vec3f0(m[1,1], m[2,2], m[3,3])
                ps = Vec3f0(p[1,1], p[2,2], p[3,3])
                r  = sc ./ (s .* ps)
                r
            end
        end
    else # 2D prim
        kw_args[:scale] = to_vec(Vec2f0, kw_args[:scale])
    end

    if haskey(kw_args, :stroke_width)
        s = Reactive.value(kw_args[:scale])
        sw = kw_args[:stroke_width]
        if sw*5 > _cycle(Reactive.value(s), 1)[1] # restrict marker stroke to 1/10th of scale (and handle arrays of scales)
            kw_args[:stroke_width] = s[1] / 5f0
        end
    end
    kw_args[:scale_primitive] = false
    if isa(prim, String)
        kw_args[:position] = points
        if !isa(kw_args[:scale], Vector) # if not vector, we can assume it's relative scale
            kw_args[:relative_scale] = kw_args[:scale]
            delete!(kw_args, :scale)
        end
        return visualize(prim, Style(:default), kw_args)
    end
    visualize((prim, points), Style(:default), kw_args)
end



function image(img, kw_args)
    rect = kw_args[:primitive]
    kw_args[:primitive] = GeometryTypes.SimpleRectangle{Float32}(rect.x, rect.y, rect.h, rect.w) # seems to be flipped
    visualize(img, Style(:default), kw_args)
end

function handle_segment{P}(lines, line_segments, points::Vector{P}, segment)
    (isempty(segment) || length(segment) < 2) && return
    if length(segment) == 2
         append!(line_segments, view(points, segment))
    elseif length(segment) == 3
        p = view(points, segment)
        push!(line_segments, p[1], p[2], p[2], p[3])
    else
        append!(lines, view(points, segment))
        push!(lines, P(NaN))
    end
end

function lines(points, kw_args)
    result = []
    isempty(points) && return result
    P = eltype(points)
    lines = P[]
    line_segments = P[]
    last = 1
    for (i,p) in enumerate(points)
        if isnan(p) || i==length(points)
            _i = isnan(p) ? i-1 : i
            handle_segment(lines, line_segments, points, last:_i)
            last = i+1
        end
    end
    if !isempty(lines)
        pop!(lines) # remove last NaN
        push!(result, visualize(lines, Style(:lines), kw_args))
    end
    if !isempty(line_segments)
        push!(result, visualize(line_segments, Style(:linesegment), kw_args))
    end
    return result
end
