using Bonito, FileIO, DelimitedFiles

root_path = joinpath(pwd(), "ReferenceImages")


function create_app()
    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')

    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

    # TODO: don't filter out videos
    imgs_with_score = unique(map(imgs) do img
        replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
    end)

    function get_score(img_name)
        backends = ["CairoMakie", "GLMakie", "WGLMakie"]
        scores = map(backends) do backend
            name = backend * "/" * img_name
            if haskey(lookup, name)
                return lookup[name]
            else
                return -Inf
            end
        end
        return maximum(scores)
    end

    sort!(imgs_with_score; by=get_score, rev=true)

    backends = ["GLMakie", "CairoMakie", "WGLMakie"]
    selected_folder = ["recorded", "reference"]
    selection_string = ["Showing new recorded", "Showing old reference"]

    # TODO: font size doesn't do anything below some threshold?
    # TODO: match up text & button styles
    button_style = Styles(
        CSS("font-size" => "8", "font-weight" => "normal"),
        CSS("width" => "fit-content")
    )

    # TODO: fit checkbox size to text
    checkbox_style = Styles()

    # TODO: Is there a better way to handle default with overwrites?
    card_css = CSS(
        "margin" => "0.25em",
        "padding" => "0.5em",
        "border" => "2px solid lightblue",
        # "background-color" => "#eee",
        "border-radius" => "1em",
    )

    max_width = Styles(CSS("max-width" => "100%"))

    marked = Set{String}()

    # TODO: one grid is probably better than a million single row grids...
    images = map(imgs_with_score) do img_name

        # [] $path
        # [Showing Reference/Recorded]  ---  Score: $score # TODO:
        # image
        cards = map(backends) do backend

            current_file = backend * "/" * img_name
            if haskey(lookup, current_file)

                local_marked = Observable(false)
                on(local_marked) do is_marked
                    if is_marked
                        push!(marked, current_file)
                    else
                        delete!(marked, current_file)
                    end
                    @info marked
                end
                cb = DOM.div(
                    Checkbox(local_marked, Dict{Symbol, Any}(:style => checkbox_style)),
                    " $current_file"
                )

                score = round(lookup[current_file]; digits=4)
                score_text = DOM.div("Score: $score")

                card_style = Styles(card_css, CSS(
                    "background-color" => if score > 0.05
                        "#ffbbbb"
                    elseif score > 0.03
                        "#ffddbb"
                    elseif score > 0.001
                        "#ffffdd"
                    else
                        "#eeeeee"
                    end
                ))

                path_button = Bonito.Button("recorded", style = button_style)
                selection = 1 # Recorded (new), Reference (old)
                local_path = map(path_button.value) do click
                    selection = mod1(selection + 1, 2)
                    path_button.content[] = selection_string[selection]
                    folder = selected_folder[selection]
                    return normpath(joinpath(root_path, folder, backend, img_name))
                    # local_path = normpath(joinpath(root_path, folder, backend, img_name))
                    # return Bonito.Asset(local_path)
                end


                filetype = split(img_name, ".")[end]
                media = if filetype == "png"
                    # DOM.img(src = local_path)
                    map(local_path) do local_path
                        bin = read(local_path)
                        DOM.img(
                            src = Bonito.BinaryAsset(bin, mimes[filetype]),
                            style = max_width
                        )
                    end
                else # TODO: broken
                    # DOM.video(
                    #     DOM.source(; src = local_path, type="video/mp4"),
                    #     autoplay = true, controls = true
                    # )
                    asset = map(local_path) do p
                        # Bonito.Asset(replace(p, ' ' => "\\ "))
                        Bonito.Asset("\"$p\"")
                    end
                    DOM.video(
                        DOM.source(; src = asset, type="video/mp4"),
                        autoplay = true, controls = true
                    )
                end

                # TODO: background
                return Card(Col(cb, score_text, path_button, media), style = card_style)
            else
                return Card(DOM.h1("N/A"))
            end
        end

        return Grid(cards, columns = "1fr 1fr 1fr")
    end

    return DOM.div(images...)


if @isdefined server
    close(server)
end
server = Bonito.Server("0.0.0.0", 8080)
display(server)
route!(server, "/" => App(create_app))
