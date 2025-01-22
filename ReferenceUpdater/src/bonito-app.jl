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

    # TODO: font size ignored?
    button_style = Styles(
        CSS("font-size" => "12", "font-weight" => "normal"),
        CSS("width" => "fit-content",
            "padding-right" => "6px", "padding-left" => "6px",
            "padding-bottom" => "2px", "padding-top" => "2px",
        ),
        CSS("display" => "inline-block", "float" => "left")
    )

    score_style = Styles(
        CSS("font-size" => "10", "font-weight" => "normal"),
        CSS("width" => "fit-content",
            "padding-right" => "6px", "padding-left" => "6px",
            "padding-bottom" => "2px", "padding-top" => "2px",
            "margin" => "0.25em"
        ),
        CSS("display" => "inline-block", "float" => "right")
    )

    # TODO: fit checkbox size to text
    checkbox_style = Styles(
        CSS("transform" => "scale(1)")
    )

    # TODO: Is there a better way to handle default with overwrites?
    card_css = CSS(
        "margin" => "0.1em", # outside
        "padding" => "0.5em", # inside
        "border" => "2px solid lightblue",
        # "background-color" => "#eee",
        "border-radius" => "1em",
    )

    max_width = Styles(CSS("max-width" => "100%"))

    marked = Set{String}()

    cards = Any[]
    for img_name in imgs_with_score

        # [] $path
        # [Showing Reference/Recorded]  ---  Score: $score # TODO:
        # image
        for backend in backends

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
                selection = 2 # Recorded (new), Reference (old)
                local_path = map(path_button.value) do click
                    selection = mod1(selection + 1, 2)
                    path_button.content[] = selection_string[selection]
                    folder = selected_folder[selection]
                    local_path = normpath(joinpath(root_path, folder, backend, img_name))
                    return Bonito.Asset(local_path)
                end


                filetype = split(img_name, ".")[end]
                media = if filetype == "png"
                    DOM.img(src = local_path, style = max_width)
                else
                    DOM.video(
                        DOM.source(; src = local_path, type="video/mp4"),
                        autoplay = false, controls = true, style = max_width
                    )
                end

                card = Card(
                    DOM.div(
                        cb,
                        DOM.div(
                            path_button,
                            DOM.div("Score: $score", style = score_style)
                        ),
                        media
                    ),
                    style = card_style
                )
                push!(cards, card)
            else
                push!(cards, DOM.div())
            end
        end

    end

    update_section = DOM.div(
        DOM.h2("Images to update"),
        Bonito.Button("Update reference images with selection"),
        DOM.div("After pressing the button you will be asked which version to upload the reference images listed below to. After that the reference images on github will be replaced with an updated set if you have the rights to do so."),
        DOM.h3("[TODO] images selected for updating:"),
        DOM.div("TODO: image grid"),
        DOM.h3("[TODO] images selected for removal:"),
        DOM.div("TODO: image grid")
    )

    new_image_section = DOM.div(
        DOM.h2("New images without references"),
        DOM.div("The selected CI run produced an image for which no reference image exists. Selected images will be added as new reference images."),
        DOM.div("TODO: toggle all"),
        DOM.div("TODO: image grid")
    )

    missing_recordings_section = DOM.div(
        DOM.h2("Old reference images without recordings"),
        DOM.div("The selected CI run did not produce an image, but a reference image exists. This implies that a reference test was deleted or renamed. Selected images will be deleted from the reference images."),
        DOM.div("TODO: toggle all"),
        DOM.div("TODO: image grid")
    )

    main_section = DOM.div(
        DOM.h2("Images with references"),
        DOM.div("This is the normal case where the selected CI run produced an image and the reference image exists. Each row shows one image per backend from the same reference image test, which can be compared with its reference image. Rows are sorted based on the maximum row score (bigger = more different). Red cells fail CI (assuming the thresholds are up to date), yellow cells may but likely don't have significant visual difference and gray cells are visually equivalent."),
        Grid(cards, columns = "1fr 1fr 1fr")
    )

    return DOM.div(
        update_section,
        new_image_section,
        missing_recordings_section,
        main_section,
        style = Styles(CSS("font-family" => "sans-serif"))
    )
end



if @isdefined server
    close(server)
end
server = Bonito.Server("0.0.0.0", 8080)
display(server)
route!(server, "/" => App(create_app))
