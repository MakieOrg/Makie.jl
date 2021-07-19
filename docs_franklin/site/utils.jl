using Chain
using Markdown


function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end


function hfun_doc(params)
  fname = params[1]
  head = length(params) > 1 ? params[2] : fname
  type = length(params) == 3 ? params[3] : ""
  doc = eval(Meta.parse("using Makie; @doc Makie.$fname"))
  txt = Markdown.plain(doc)
  # possibly further processing here
  #body = Markdown.html(Markdown.parse(txt))
  body = fd2html(txt, internal = true)
  return """
    <div class="docstring">
        <h2 class="doc-header" id="$fname">
          <a href="#$fname">$head</a>
          <div class="doc-type">$type</div>
        </h2>
        <div class="doc-content">$body</div>
    </div>
  """
end


function lx_examplefigure(com, _)
  content = Franklin.content(com.braces[1])

  preamble, middle = split(content, r"```(julia)?", limit = 2)
  args = split(strip(preamble), r"\s*[=,]\s*", keepempty = false)

  if !iseven(length(args))
    error("Uneven argument lengths, should be a=b pairs")
  end
  d = Dict(args[1:2:end] .=> args[2:2:end])

  name = get(d, "name", "example_" * string(hash(content)))
  svg = parse(Bool, get(d, "svg", "false"))

  middle, _ = split(middle, r"```\s*$")
  s = "```julia:$name" *
  middle *
  """
  save(joinpath(@OUTPUT, "$name.png"), current_figure()) # hide
  if $svg
    save(joinpath(@OUTPUT, "$name.svg"), current_figure()) # hide
  end
  ```
  \\fig{$name.$(svg ? "svg" : "png")}
  """

  s
end

@delay function hfun_list_plotting_functions()
    mds = @chain begin
        readdir(joinpath(@__DIR__, "plotting_functions"))
        filter(endswith(".md"), _)
        filter(!=("index.md"), _)
    end


    divs = join(map(mds) do page
        name = splitext(page)[1]

        outputpath = joinpath(@__DIR__, "__site", "assets",
            "plotting_functions", name, "code", "output")

        pngpaths = @chain readdir(outputpath) begin
            filter(endswith(".png"), _)
            "/assets/plotting_functions/$name/code/output/" .* _
        end

        """
        <a href="$(name)">
        <div class="plotting-functions-item">
          <h2>$name</h2>
            $(
                map(pngpaths) do pngpath
                    "<img class='plotting-function-thumb' src=\"$pngpath\"/>"
                end |> join
            )
        </div>
        </a>
        """
    end)

    "<div class=\"plotting-functions-grid\">$divs</div>"
end