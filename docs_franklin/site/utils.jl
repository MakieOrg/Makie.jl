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


function env_examplefigure(com, _)
  content = Franklin.content(com)

  _, middle = split(content, r"```(julia)?", limit = 2)
  kwargs = eval(Meta.parse("Dict(pairs((;" * Franklin.content(com.braces[1]) * ")))"))

  name = get(kwargs, :name, "example_" * string(hash(content)))
  svg = get(kwargs, :svg, false)::Bool

  middle, _ = split(middle, r"```\s*$")
  s = "```julia:$name" *
  middle *
  """
  save(joinpath(@OUTPUT, "$name.png"), current_figure()) # hide
  if $svg # hide
    save(joinpath(@OUTPUT, "$name.svg"), current_figure()) # hide
  end # hide
  ```
  \\fig{$name.$(svg ? "svg" : "png")}
  """

  s
end

@delay function hfun_list_folder_with_images(param)

    folder = param[1]

    mds = @chain begin
        readdir(joinpath(@__DIR__, folder))
        filter(endswith(".md"), _)
        filter(!=("index.md"), _)
    end


    divs = join(map(mds) do page
        name = splitext(page)[1]

        outputpath = joinpath(@__DIR__, "__site", "assets",
            folder, name, "code", "output")

        !isdir(outputpath) && return ""

        pngpaths = @chain readdir(outputpath) begin
            filter(endswith(".png"), _)
            "/assets/$folder/$name/code/output/" .* _
        end

        """
        <a href="$(name)">
        <div class="plotting-functions-item">
          <h2>$name</h2>
            <div class="plotting-functions-thumbcontainer">
              $(
                  map(pngpaths) do pngpath
                      "<img class='plotting-function-thumb' src=\"$pngpath\"/>"
                  end |> join
              )
            </div>
        </div>
        </a>
        """
    end)

    "<div class=\"plotting-functions-grid\">$divs</div>"
end