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
                return :(to_node($(esc.(args)...), x-> $(esc(f))(Makie.current_backend[], x))), a
            end
        end
    end
    return esc(b), a
end

macro theme(assignment)
    expr, name = matchnode(assignment)
    expr
end


# BIG TODO: make themes + defaults + conversion function @default + @theme macro suck less!
# Right now there is a lot of annoying and unecessary dublication going on

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
    tickfont3d = ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), tickrotations[i], tickalign[i]), 3)
    tickfont2d = ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), Vec4f0(0,0,0,1), tickalign[i]), 2)
    showaxis = ntuple(i-> true, 3)
    showgrid = ntuple(i-> true, 3)

    scalefuncs = ntuple(i-> identity, 3)
    gridthickness = ntuple(x-> 1f0, 3)
    colors = UniqueColorIter(:Set1)
    meshrotation = Vec4f0(0, 0, 0, 1)
    @theme theme = begin

        rotation = to_rotation(Vec4f0(0, 0, 0, 1))
        scale = to_scale(Vec3f0(1))
        offset = to_offset(Vec3f0(0))

        camera = to_camera(:auto)
        visible = to_bool(true)
        show = to_bool(true)

        drawover = to_bool(false)

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
            markersize = to_markersize2d(0.1)
            strokecolor = to_color(RGBA(0, 0, 0, 0))
            strokewidth = to_float(0)
            glowcolor = to_color(RGBA(0, 0, 0, 0))
            glowwidth = to_float(0)
            rotations = to_rotations(Billboard())
        end

        meshscatter = begin
            marker = to_mesh(Sphere(Point3f0(0), 0.1f0))
            markersize = to_markersize3d(1)
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
            tickfont2d = tickfont2d
            tickfont3d = tickfont3d
            showaxis = showaxis
            showgrid = showgrid

            scalefuncs = scalefuncs
            gridcolors = to_color(ntuple(x-> RGBAf0(0.5, 0.5, 0.5, 0.4), 3))
            gridthickness = gridthickness
            axiscolors = to_color(ntuple(x-> dark_text, 3))
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
        legend = begin
            backgroundcolor = to_color(:white)
            strokecolor = to_color(RGBA(0.3, 0.3, 0.3, 0.9))
            strokewidth = to_float(2)
            position = to_position((0.1, 0.5))
            gap = to_float(20)
            textgap = to_float(15)
            labelwidth = to_float(20)
            padding = to_float(10)
            align = to_textalign((:left, :hcenter))
            rotation = to_rotation(Vec4f0(0, 0, 0, 1))
            textcolor = to_color(:black)
            textsize = to_float(16)
            markersize = to_markersize2d(5)
            linepattern = to_positions(Point2f0[(0, 0), (1, 0.0)])
            scatterpattern = to_positions(Point2f0[(0.5, 0.0)])
        end
    end
    scene[:theme] = theme
end
