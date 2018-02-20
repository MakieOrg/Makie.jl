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

    tickrotations3d = (
        qrotation(Vec3f0(0,0,1), -1.5pi),
        q2,
        qmul(qmul(q2, q1), qrotation(Vec3f0(0, 1, 0), 1pi))
    )
    axisnames_rotation3d = tickrotations3d
    tickalign3d = (
        (:hcenter, :left), # x axis
        (:right, :vcenter), # y axis
        (:right, :vcenter), # z axis
    )
    axisnames_align3d = tickalign3d

    darktext = RGBAf0(0.0, 0.0, 0.0, 0.4)
    tick_color = RGBAf0(0.5, 0.5, 0.5, 0.6)
    grid_color = RGBAf0(0.5, 0.5, 0.5, 0.4)
    darktext = RGB(0.4, 0.4, 0.4)
    grid_thickness = 1

    scalefuncs = ntuple(i-> identity, 3)
    gridthickness = ntuple(x-> 1f0, 3)
    colors = UniqueColorIter(:Set1)
    meshrotation = Vec4f0(0, 0, 0, 1)
    light = Vec3f0[Vec3f0(1.0,1.0,1.0), Vec3f0(0.1,0.1,0.1), Vec3f0(0.9,0.9,0.9), Vec3f0(20,20,20)]
    @theme theme = begin

        rotation = to_rotation(Vec4f0(0, 0, 0, 1))
        scale = to_scale(Vec3f0(1))
        offset = to_offset(Vec3f0(0))

        camera = to_camera(:auto)
        visible = to_bool(true)
        show = to_bool(true)

        light = to_static_vec(light)

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
            title_size = 6

            tickstyle = begin
                gap = 3
                title_gap = 3

                linewidth = (1, 1)
                linecolor = ((:black, 0.4), (:black, 0.4))
                linestyle = (nothing, nothing)

                textcolor = (darktext, darktext)
                textsize = (5, 5)
                rotation = (0.0, 0.0)
                align = ((:center, :top), (:right, :center))
                font = ("default", "default")
            end

            gridstyle = begin
                linewidth = (0.5, 0.5)
                linecolor = ((:black, 0.3), (:black, 0.3))
                linestyle = (nothing, nothing)
            end

            framestyle = begin
                linewidth = 1.0
                linecolor = :black
                linestyle = nothing
                axis_position = :origin
                axis_arrow = false
                arrow_size = 2.5
                frames = ((false, false), (false, false))
            end

            titlestyle = begin
                axisnames = ("X Axis", "Y Axis")
                textcolor = (darktext, darktext)
                textsize = (6, 6)
                rotation = (0.0, -1.5pi)
                align = ((:center, :top), (:center, :bottom))
                font = ("default", "default")
            end
        end

        # axis3d = begin
        #     visible = true
        #
        #     axisnames = ("X Axis", "Y Axis", "Z Axis")
        #
        #     names_color = (darktext, darktext, darktext)
        #     names_rotation = axisnames_rotation3d
        #     names_size = (5.0, 5.0, 5.0)
        #     names_align = axisnames_align3d
        #     names_font = "default"
        #
        #     showticks = (true, true, true)
        #     showaxis = (true, true, true)
        #     showgrid = (true, true, true)
        #
        #     tick_color = (tick_color, tick_color, tick_color)
        #     tick_rotation = tickrotations3d
        #     tick_size =  (2.0, 2.0, 2.0)
        #     tick_align = tickalign3d
        #     tick_font = "default"
        #
        #
        #     gridcolors = (grid_color, grid_color, grid_color)
        #     gridthickness = (grid_thickness, grid_thickness, grid_thickness)
        #     axiscolors = (darktext, darktext, darktext)
        # end

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
            strokewidth = to_float(1)
            position = to_position((0, 1))
            gap = to_float(20)
            textgap = to_float(15)
            labelwidth = to_float(20)
            padding = to_float(10)
            outerpadding = to_markersize2d(10)
            align = to_textalign((:left, :hcenter))
            rotation = to_rotation(Vec4f0(0, 0, 0, 1))
            textcolor = to_color(:black)
            textsize = to_float(16)
            markersize = to_markersize2d(5)
            linepattern = to_positions(Point2f0[(0, 0), (1, 0.0)])
            scatterpattern = to_positions(Point2f0[(0.5, 0.0)])
        end

        color_legend = begin
            width = to_markersize2d((20, 200))
            backgroundcolor = to_color(:white)
            strokecolor = to_color(RGBA(0.3, 0.3, 0.3, 0.9))
            strokewidth = to_float(1)
            position = to_position((1, 1))
            textgap = to_float(15)
            padding = to_markersize2d(10)
            outerpadding = to_markersize2d(10)
            align = to_textalign((:left, :hcenter))
            rotation = to_rotation(Vec4f0(0, 0, 0, 1))
            textcolor = to_color(:black)
            textsize = to_float(16)
        end
        text = begin
            color = to_color(:black)
            strokecolor = to_color((:black, 0.0))
            strokewidth = to_float(0)
            font = to_font(GLVisualize.defaultfont())
            align = to_textalign((:left, :bottom))
            rotation = to_rotation(Vec4f0(0, 0, 0, 1))
            textsize = to_float(20)
            position = to_position(Point2f0(0))
        end
    end
    scene[:theme] = theme
end
