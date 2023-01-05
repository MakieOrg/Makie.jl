module SankeyPlots

    # The Sankey layout algorithm was ported from https://github.com/d3/d3-sankey and modified.
    # The BSD 3-Clause license is reproduced below:

    # Copyright 2015, Mike Bostock
    # All rights reserved.

    # Redistribution and use in source and binary forms, with or without modification,
    # are permitted provided that the following conditions are met:

    # * Redistributions of source code must retain the above copyright notice, this
    #   list of conditions and the following disclaimer.

    # * Redistributions in binary form must reproduce the above copyright notice,
    #   this list of conditions and the following disclaimer in the documentation
    #   and/or other materials provided with the distribution.

    # * Neither the name of the author nor the names of contributors may be used to
    #   endorse or promote products derived from this software without specific prior
    #   written permission.

    # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    # DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    # ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    mutable struct Link{N}
        source::N
        target::N
        value::Float64
        index::Int
        y0::Float64
        y1::Float64
        width::Float64
    end

    mutable struct Node
        sourcelinks::Vector{Link{Node}}
        targetlinks::Vector{Link{Node}}
        value::Float64
        fixedvalue::Union{Nothing, Float64}
        index::Int
        depth::Union{Nothing, Int}
        x0::Float64
        x1::Float64
        y0::Float64
        y1::Float64
        height::Float64
        layer::Int
    end


    function compute_node_links(nodelist, linklist)
        nodes = map(enumerate(nodelist)) do (i, node)
            Node(
                [],
                [],
                node.value,
                nothing,
                i,
                nothing,
                NaN,
                NaN,
                NaN,
                NaN,
                NaN,
                0,
            )
        end

        nodedict = Dict(n.index => n for n in nodes)

        links = map(enumerate(linklist)) do (i, link)
            source = nodedict[link.source]
            target = nodedict[link.target]
            l = Link(
                source,
                target,
                link.value,
                i,
                NaN,
                NaN,
                NaN,
            )
            push!(source.sourcelinks, l)
            push!(target.targetlinks, l)
            return l
        end

        nodes, links
    end

    function compute_node_value!(node)
        node.value = node.fixedvalue === nothing ? 
            max(sum(x -> x.value, node.sourcelinks, init = 0.0), sum(x -> x.value, node.targetlinks, init = 0.0)) :
            node.fixedvalue
    end

    function compute_node_depths!(nodes)
        n = length(nodes)
        current = Set(nodes)
        next = typeof(current)()
        x = 0
        while !isempty(current)
            for node in current
                node.depth = x
                for link in node.sourcelinks
                    push!(next, link.target)
                end
            end
            x += 1
            if x > n
                error("Circular link")
            end
            current = next
            next = typeof(current)()
        end
        return
    end

    function compute_node_heights!(nodes)
        n = length(nodes)
        current = Set(nodes)
        next = typeof(current)()
        x = 0
        while !isempty(current)
            for node in current
                node.height = x
                for link in node.targetlinks
                    push!(next, link.source)
                end
            end
            x += 1
            if x > n
                error("Circular link")
            end
            current = next
            next = typeof(current)()
        end
        return
    end

    function compute_node_breadths!(nodes, settings)
        columns = compute_node_layers(nodes, settings)
        dy = settings.dy
        settings.py = min(dy, (settings.y1 - settings.y0) / (maximum(c -> length(c), columns) - 1))
        initialize_node_breadths!(columns, settings)
        iterations = settings.iterations
        for i in 0:iterations-1
            alpha = 0.99 ^ i
            beta = max(1 - alpha, (i + 1) / iterations)
            relax_right_to_left!(columns, alpha, beta, settings)
            relax_left_to_right!(columns, alpha, beta, settings)
        end
    end

    function compute_node_layers(nodes, settings)
        align = settings.align
        x = maximum(n -> n.depth, nodes) + 1
        kx = (settings.x1 - settings.x0 - settings.dx) / (x - 1)
        columns = [eltype(nodes)[] for _ in 1:x]
        for node in nodes
            i = max(0, min(x - 1, floor(align(node, x))))
            node.layer = i
            node.x0 = settings.x0 + i * kx
            node.x1 = node.x0 + settings.dx
            push!(columns[i+1], node)
        end
        # TODO sort
        return columns
    end

    function initialize_node_breadths!(columns, settings)
        ky = minimum(columns) do c
            settings.y1 - settings.y0 - (length(c) - 1) * settings.py / sum(_c -> _c.value, c)
        end
        for nodes in columns
            y = settings.y0
            for node in nodes
                node.y0 = y
                node.y1 = y + node.value * ky
                y = node.y1 + settings.py
                for link in node.sourcelinks
                    link.width = link.value * ky
                end
            end
            y = (settings.y1 - y + settings.py) / (length(nodes) + 1)
            for i in 0:length(nodes)-1
                node = nodes[i+1]
                node.y0 += y * (i + 1)
                node.y1 += y * (i + 1)
            end
            reorder_links!(nodes)
        end
    end

    function reorder_links!(nodes)
        # TODO if linksort == undefined
        for node in nodes
            sort!(node.sourcelinks, lt = ascending_target_breadth)
            sort!(node.targetlinks, lt = ascending_source_breadth)
        end
    end

    ascending_breadth(a, b) = a.y0 - b.y0
    function ascending_target_breadth(a, b)
        x = ascending_breadth(a.target, b.target)
        isnan(x) ? Float64(a.index - b.index) > 0 : x > 0
    end
    function ascending_source_breadth(a, b)
        x = ascending_breadth(a.source, b.source)
        isnan(x) ? Float64(a.index - b.index) > 0 : x > 0
    end

    function justify(node, n)
        !isempty(node.sourcelinks) ? node.depth : n - 1
    end

    function relax_right_to_left!(columns, alpha, beta, settings)
        n = length(columns)
        for i in n-2:-1:0
            column = columns[i+1]
            for source in column
                y = 0.0
                w = 0.0
                for sourcelink in source.sourcelinks
                    v = sourcelink.value * (sourcelink.target.layer - source.layer)
                    y += sourcetop(source, sourcelink.target, settings) * v
                    w += v
                end
                if !(w > 0)
                    continue
                end
                dy = (y / w - source.y0) * alpha
                source.y0 += dy
                source.y1 += dy
                reorder_node_links!(source)
            end
            # TODO if sort === undefined
            sort!(column, lt = >(0) ∘ ascending_breadth)
            resolve_collisions!(column, beta, settings)
        end
    end

    function relax_left_to_right!(columns, alpha, beta, settings)
        n = length(columns)
        for i in 1:n-1
            column = columns[i+1]
            for target in column
                y = 0.0
                w = 0.0
                for targetlink in target.targetlinks
                    v = targetlink.value * (target.layer - targetlink.source.layer)
                    y += targettop(targetlink.source, target, settings) * v
                    w += v
                end
                if !(w > 0)
                    continue
                end
                dy = (y / w - target.y0) * alpha
                target.y0 += dy
                target.y1 += dy
                reorder_node_links!(target)
            end
            # TODO if sort === undefined
            sort!(column, lt = >(0) ∘ ascending_breadth)
            resolve_collisions!(column, beta, settings)
        end
    end

    function sourcetop(source, target, settings)
        y = target.y0 - (length(target.targetlinks) - 1) * settings.py / 2
        for targetlink in target.targetlinks
            if targetlink.source === source
                break
            end
            y += targetlink.width + settings.py
        end
        for sourcelink in source.sourcelinks
            if sourcelink.target === target
                break
            end
            y -= sourcelink.width
        end
        return y
    end

    function targettop(source, target, settings)
        y = source.y0 - (length(source.sourcelinks) - 1) * settings.py / 2
        for sourcelink in source.sourcelinks
            if sourcelink.target === target
                break
            end
            y += sourcelink.width + settings.py
        end
        for targetlink in target.targetlinks
            if targetlink.source === source
                break
            end
            y -= targetlink.width
        end
        return y
    end

    function reorder_node_links!(node)
        # TODO if linksort === undefined
        (;sourcelinks, targetlinks) = node
        for link in targetlinks
            sort!(link.source.sourcelinks, lt = ascending_target_breadth)
        end
        for link in sourcelinks
            sort!(link.target.targetlinks, lt = ascending_source_breadth)
        end
        return
    end

    function resolve_collisions!(nodes, alpha, settings)
        i = length(nodes) >> 1
        subject = nodes[i+1]
        resolve_collisions_bottom_to_top!(nodes, subject.y0 - settings.py, i - 1, alpha, settings)
        resolve_collisions_top_to_bottom!(nodes, subject.y1 + settings.py, i + 1, alpha, settings)
        resolve_collisions_bottom_to_top!(nodes, settings.y1, length(nodes) - 1, alpha, settings)
        resolve_collisions_top_to_bottom!(nodes, settings.y0, 0, alpha, settings)
    end

    function resolve_collisions_top_to_bottom!(nodes, y, i, alpha, settings)
        for j in i:length(nodes)-1
            node = nodes[j+1]
            dy = (y - node.y0) * alpha
            if dy > 1e-6
                node.y0 += dy
                node.y1 += dy
            end
            y = node.y1 + settings.py
        end
    end

    function resolve_collisions_bottom_to_top!(nodes, y, i, alpha, settings)
        for j in i:-1:0
            node = nodes[j+1]
            dy = (node.y1 - y) * alpha
            if dy > 1e-6
                node.y0 -= dy
                node.y1 -= dy
            end
            y = node.y0 - settings.py
        end
    end

    function compute_link_breadths!(nodes)
        for node in nodes
            y0 = node.y0
            y1 = y0
            for link in node.sourcelinks
                link.y0 = y0 + link.width / 2
                y0 += link.width
            end
            for link in node.targetlinks
                link.y1 = y1 + link.width / 2
                y1 += link.width
            end
        end
    end

    function align_left(node, n)
        node.depth
    end

    function align_right(node, n)::Int
        n - 1 - node.height
    end

    function align_center(node, n)::Int
        !isempty(node.targetlinks) ? node.depth :
            !isempty(node.sourcelinks) ? minimum(l -> l.target.depth, node.sourcelinks) - 1 : 0
    end

    Base.@kwdef mutable struct SankeySettings
        x0::Float64 = 0
        y0::Float64 = 0
        x1::Float64 = 1
        y1::Float64 = 1
        dx::Float64 = 24
        dy::Float64 = 8
        py::Float64 = NaN
        iterations::Int = 6
        align::Function = justify
    end
end

using .SankeyPlots: SankeyPlots

@recipe(Sankey) do scene
    Attributes(
        align = :center,
        dy = 12,
    )
end

function Makie.plot!(p::Sankey)
    connections = p[1]

    scene = Makie.parent_scene(p)

    sz = (800, 100)

    nodelist_linklist = lift(connections) do connections
        nodelist = let
            list = union(unique(first.(connections)), unique(last.(connections)))
            map(list) do label
                (value = NaN, label = label)
            end
        end
    
        linklist = let 
            map(connections) do conn
                (
                    source = findfirst(==(conn[1]), (x.label for x in nodelist)),
                    target = findfirst(==(conn[3]), (x.label for x in nodelist)),
                    value = Float64(conn[2]) / 1000,
                )
            end
        end
        return nodelist, linklist
    end

    nodes_and_links_pre_solve = lift(nodelist_linklist) do (nodelist, linklist)    
        nodes, links = SankeyPlots.compute_node_links(nodelist, linklist)
        SankeyPlots.compute_node_value!.(nodes)
        SankeyPlots.compute_node_depths!(nodes)
        SankeyPlots.compute_node_heights!(nodes)

        return nodes, links
    end

    nodes_and_links = lift(nodes_and_links_pre_solve, p.align, p.dy) do (nodes, links), align, dy
        align_func = if align === :center
            SankeyPlots.align_center
        elseif align === :left
            SankeyPlots.align_left
        elseif align === :right
            SankeyPlots.align_right
        elseif align === :justify
            SankeyPlots.justify
        else
            error("Unknown alignment value $(repr(align)). Options are :center, :left, :right, :justify.")
        end
        settings = SankeyPlots.SankeySettings(
            align = align_func,
            x1 = sz[1],
            y1 = sz[2],
            dy = dy,
            dx = 10,
            iterations = 6
        )
        SankeyPlots.compute_node_breadths!(nodes, settings)
        SankeyPlots.compute_link_breadths!(nodes)
        return nodes, links
    end

    linkpolys = lift(nodes_and_links, scene.camera.projectionview, scene.px_area) do (_, links), _, _
        map(links) do l
            x0 = l.source.x1
            x1 = l.target.x0
            corners = Makie.scene_to_screen(
                Point2f[
                    (x0, l.y0 - l.width/2),
                    (x1, l.y1 - l.width/2),
                    (x1, l.y1 + l.width/2),
                    (x0, l.y0 + l.width/2),
                ],
                scene
            )

            start = 0.5 * (corners[1] + corners[4])
            stop =  0.5 * (corners[2] + corners[3])
            thickness = corners[4][2] - corners[1][2]
            width = stop[1] - start[1]
            height = stop[2] - start[2]

            n = 30

            x0pix = start[1]
            x1pix = stop[1]

            points = Vector{Point2f}(undef, n * 2)
            for (i, x) in enumerate(range(x0pix, x1pix, length = n))

                y = height * (1 - cos(pi * (x - x0pix) / width)) / 2 + start[2]
                deriv = pi * height * sin((pi * (x - x0pix)) / width) / (2 * width)

                xortho = sqrt(1 / (1 + deriv^2))
                yortho = xortho * deriv

                ortho = Point2f(-yortho, xortho)
                _xy = Point2f(x, y)

                points[i] = _xy - ortho * thickness/2
                points[2n - i + 1] = _xy + ortho * thickness/2
            end

            Makie.Polygon(points)
            # Makie.Polygon(corners)
        end
    end

    noderects = lift(nodes_and_links) do (nodes, links)
        map(nodes) do node
            BBox(node.x0, node.x1, node.y0, node.y1)
        end
    end

    textattrs = lift(nodes_and_links) do (nodes, links)
        map(nodes) do node
            xmid = (node.x0 + node.x1) * 0.5
            ymid = (node.y0 + node.y1) * 0.5
            rightaligned = xmid > sz[1]/2
            point = if rightaligned
                Point2f(node.x0, ymid)
            else
                Point2f(node.x1, ymid)
            end
            align = rightaligned ? :right : :left
            offset = (rightaligned ? -5 : 5, 0)
            (; point, align, offset)
        end
    end

    poly!(p, linkpolys, space = :pixel, color = 1:length(linkpolys[]), colormap = (:viridis, 0.5))
    poly!(p, noderects, color = :gray30)
    text!(p,
        @lift(map(x -> x.point, $textattrs)),
        text = @lift(map(x -> x.label, $nodelist_linklist[1])),
        align = @lift(map(x -> (x.align, :center), $textattrs)),
        offset = @lift(map(x -> x.offset, $textattrs))
    )

    return p
end

data_limits(s::Sankey) = data_limits(s.plots[2])