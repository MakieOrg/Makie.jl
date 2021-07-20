using Chain
using Markdown
using GLMakie
using FileIO
using ImageTransformations


# Pause renderloop for slow software rendering.
# This way, we only render if we actualy save e.g. an image
@show GLMakie.set_window_config!(;
    framerate = 15.0,
    pause_rendering = true
)


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
  s = """
    ```julia:$name
    $middle
    save(joinpath(@OUTPUT, "$name.png"), current_figure()) # hide
    if $svg # hide
      save(joinpath(@OUTPUT, "$name.svg"), current_figure()) # hide
    end # hide
    ```
    ~~~
    <a id="$name">
    ~~~
    \\fig{$name.$(svg ? "svg" : "png")}
    ~~~
    </a>
    ~~~
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
            filter(x -> endswith(x, ".png") && !endswith(x, "_thumb.png"), _)
            filter(_) do p
              if endswith(p, "_thumb.png")
                rm(joinpath(outputpath, p))
                false
              else
                true
              end

            end
        end

        max_thumb_height = 250

        thumbpaths = map(pngpaths) do p
          thumbpath = joinpath(outputpath, splitext(p)[1] * "_thumb.png")
          
          img = load(joinpath(outputpath, p))
          sz = size(img)
          new_size = round.(Int, sz .÷ (sz[2] / max_thumb_height))
          img_resized = imresize(img, new_size)
          save(thumbpath, img_resized)

          thumbpath
        end

        thumbpaths_website = "/assets/$folder/$name/code/output/" .* basename.(thumbpaths)

        """
        
        <div class="plotting-functions-item">
          <a href="$name"><h2>$name</h2></a>
          <div class="plotting-functions-thumbcontainer">
            $(
                map(thumbpaths_website, pngpaths) do thumbpath, pngpath
                    bn = splitext(basename(pngpath))[1]
                    "<a href=\"$name#$bn\"><img class='plotting-function-thumb' src=\"$thumbpath\"/></a>"
                end |> join
            )
          </div>
        </div>
        """
    end)

    "<div class=\"plotting-functions-grid\">$divs</div>"
end


function hfun_list_folder(param)

  folder = param[1]

  mds = @chain begin
      readdir(joinpath(@__DIR__, folder))
      filter(endswith(".md"), _)
      filter(!=("index.md"), _)
  end

  join(map(mds) do page
    name = splitext(page)[1]
    """<a href="$name"><h2>$name</h2></a>"""
  end)
end