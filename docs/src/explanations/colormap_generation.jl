using Makie.PlotUtils, Makie.Colors

################################################################################
#                              Colormap reference                              #
################################################################################


function colors_svg(key::Symbol, cs, w, h; categorical)
    n = length(cs)
    ws = min(w / n, h)
    html = """
     <svg xmlns="http://www.w3.org/2000/svg" version="1.1"
          width="$(categorical ? n * ws : w)mm" height="$(h)mm"
          viewBox="0 0 $n 1" preserveAspectRatio="none"
          shape-rendering="crispEdges" stroke="none">
    """
    if categorical
        for (i, c) in enumerate(cs)
            html *= """
            <rect width="$(ws)mm" height="$(h)mm" x="$(i - 1)" y="0" fill="#$(hex(convert(RGB, c)))" />
            """
        end
    else
        html *= """
        <defs>                        |                      |
        <linearGradient id="lgrad_$key" x1="0" y1="0" x2="1" y2="0">
        """

        for (i, c) in enumerate(cs)
            html *= """
            <stop offset="$((i - 1) / (n - 1))" stop-color="#$(hex(convert(RGB, c)))" />
            """
        end

        html *= """
        </linearGradient>
        </defs>
        <rect width="100%" height="100%" x="0" y="0" fill="url(#lgrad_$key)" />
        """
    end
    html *= "</svg>"
    return html
end

function generate_colorschemes_table(ks)
    html = "<table><tr class=\"headerrow\">"
    for header in ["NAME", "Categorical variant", "Continuous variant"]
        html *= "<th>$header</th>"
    end
    html *= "</tr>"
    w, h = 70, 5
    for k in ks
        grad = cgrad(k)
        p = color_list(grad)
        cg = grad[range(0, 1, length = 100)]
        cp = length(p) <= 100 ? p : cg
        # cp7 = color_list(palette(k, 7))

        html *= "<tr><td class=\"attr\"><code>:$k</code></td><td>"
        html *= colors_svg(k, cp, w, h, categorical = true)
        html *= "</td><td>"
        html *= colors_svg(k, cp, w, h, categorical = false)
        # html *= "</td><td>"
        # html *= colors_svg(cp7, 35, h)
        html *= "</td></tr>"
    end
    html *= "</table>"
    return html
end

struct ColorTable
    keys::Vector{Symbol}
end

Base.show(io::IO, ::MIME"text/html", c::ColorTable) = print(io, generate_colorschemes_table(c.keys))
