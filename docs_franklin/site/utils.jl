using Chain


function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
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


    html = join(map(mds) do page
        name = splitext(page)[1]

        outputpath = joinpath(@__DIR__, "__site", "assets",
            "plotting_functions", name, "code", "output")

        pngpaths = @chain readdir(outputpath) begin
            filter(endswith(".png"), _)
            "/assets/plotting_functions/$name/code/output/" .* _
        end

        """
        <div class="plotting-functions-item">
            <a href="$(name)">$name</a>
            $(
                map(pngpaths) do pngpath
                    "<img class='plotting-function-thumb' src=\"$pngpath\"/>"
                end |> join
            )
        </div>
        """
    end)

    html
end