const Theme = Scene


# this should probably be part of @default or actually replace it.
# but a seperate macro for a node conversion seemed easier right now
# So this just works like @default, but for individual nodes with concrete values -
# it's there to build themes etc.

function matchnode(assignment)
    @capture(assignment, a_ = b_) || error("needs to be an assignment. Found: $assignment")
    if isa(b, Expr)
        if b.head == :block
            rhs = []
            for elem in b.args
                Base.is_linenumber(elem) && continue
                expr, name = matchnode(elem)
                push!(rhs, :($(QuoteNode(name)) => $expr))
            end
            expr = quote
                $(esc(a)) = Scene($(rhs...))
                $(esc(a))
            end
            return expr, a
        else
            if @capture(b,
                    (f_(args__)) |
                    (args__::f_)
                )
                return :(to_node($(esc.(args)...), x-> $(esc(f))(MakiE.current_backend[], x))), a
            end
        end
    end
    return esc(b), a
end

macro theme(assignment)
    expr, name = matchnode(assignment)
    expr
end


function default_theme(scene)
    q1 = qrotation(Vec3f0(1, 0, 0), -0.5f0*pi)
    q2 = qrotation(Vec3f0(0, 0, 1), 1f0*pi)
    tickrotations = (
        qrotation(Vec3f0(0,0,1), -1.5pi),
        q2,
        qmul(qmul(q2, q1), qrotation(Vec3f0(0, 1, 0), 1pi))
    )

    tickalign = (
        (:hcenter, :left), # x axis
        (:right, :vcenter), # y axis
        (:right, :vcenter), # z axis
    )
    dark_text = RGBAf0(0.0, 0.0, 0.0, 0.4)

    axisnames = map(x-> ("$x Axis", 0.1, dark_text, Vec4f0(0,0,0,1), (:center, :bottom)), (:X, :Y, :Z))
    showticks = ntuple(i-> true, 3)
    tickfont = ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), tickrotations[i], tickalign[i]), 3)
    showaxis = ntuple(i-> true, 3)
    showgrid = ntuple(i-> true, 3)

    scalefuncs = ntuple(i-> identity, 3)
    gridcolors = ntuple(x-> RGBAf0(0.5, 0.5, 0.5, 0.4), 3)
    axiscolors = ntuple(x-> dark_text, 3)
    colors = UniqueColorIter(:Set1)
    meshrotation = Vec3f0(0, 0, 1)
    @theme theme = begin
        color = colors
        linewidth = to_float(1)
        colormap = to_colormap(:YlGnBu)
        colornorm = nothing # nothing for calculating it from intensity

        surface = begin
            image = nothing
        end

        contour = begin
            levels = to_float(5)
            fillrange = false
        end

        scatter = begin
            marker = to_spritemarker(Circle)
            markersize = to_markersize(0.1)
            strokecolor = to_color(RGBA(0, 0, 0, 0))
            strokewidth = to_float(0)
            glowcolor = to_color(RGBA(0, 0, 0, 0))
            glowwidth = to_float(0)
            rotations = to_rotations(Billboard())
        end

        meshscatter = begin
            marker = to_mesh(Sphere(Point3f0(0), 0.1f0))
            markersize = to_markersize(1)
            rotations = meshrotation
        end

        lines = begin
            linestyle = to_linestyle(nothing)
        end

        image = begin
            spatialorder = :yx
        end

        mesh = begin
            shading = true
            attribute_id = nothing
            indices = nothing
        end

        axis = begin
            axisnames = axisnames
            visible = true

            showticks = showticks
            tickfont = tickfont
            showaxis = showaxis
            showgrid = showgrid

            scalefuncs = scalefuncs
            gridcolors = gridcolors
            axiscolors = axiscolors
        end

        heatmap = begin
            linewidth = to_float(0)
            levels = to_float(1f0)
        end
        volume = begin
            algorithm = to_volume_algorithm(GLVisualize.MaximumIntensityProjection)
            absorption = to_float(1f0)
            isovalue = to_float(0.5f0)
            isorange = to_float(0.01f0)
        end
    end
    scene[:theme] = theme
end
