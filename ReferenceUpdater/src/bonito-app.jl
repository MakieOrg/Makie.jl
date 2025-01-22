using Bonito, FileIO, DelimitedFiles

root_path = joinpath(pwd(), "ReferenceImages")


function create_app()

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



    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')

    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

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

    function refimage_selection_checkbox(marked_set, current_file)
        local_marked = Observable(false)
        on(local_marked) do is_marked
            if is_marked
                push!(marked_set, current_file)
            else
                delete!(marked_set, current_file)
            end
            @info marked_set
        end
        return DOM.div(
            Checkbox(local_marked, Dict{Symbol, Any}(:style => checkbox_style)),
            " $current_file"
        )
    end

    function media_element(img_name, local_path)
        filetype = split(img_name, ".")[end]
        if filetype == "png"
            return DOM.img(src = local_path, style = max_width)
        else
            return DOM.video(
                DOM.source(; src = local_path, type="video/mp4"),
                autoplay = false, controls = true, style = max_width
            )
        end
    end

    sort!(imgs_with_score; by=get_score, rev=true)

    backends = ["GLMakie", "CairoMakie", "WGLMakie"]
    selected_folder = ["recorded", "reference"]
    selection_string = ["Showing new recorded", "Showing old reference"]
    score_thresholds = [0.05, 0.03, 0.01]

    marked_for_update = Set{String}()

    updated_cards = Any[]
    for img_name in imgs_with_score
        for backend in backends

            current_file = backend * "/" * img_name
            if haskey(lookup, current_file)

                cb = refimage_selection_checkbox(marked_for_update, current_file)

                score = round(lookup[current_file]; digits=4)
                card_style = Styles(card_css, CSS(
                    "background-color" => if score > score_thresholds[1]
                        "#ffbbbb"
                    elseif score > score_thresholds[2]
                        "#ffddbb"
                    elseif score > score_thresholds[3]
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

                media = media_element(img_name, local_path)

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
                push!(updated_cards, card)
            else
                push!(updated_cards, DOM.div())
            end
        end

    end

    missing_files = readlines(joinpath(root_path, "missing_files.txt"))
    missing_refimages = unique(map(missing_files) do img
        replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
    end)

    marked_for_deletion = Set{String}()

    missing_cards = Any[]
    for img_name in missing_refimages
        for backend in backends

            current_file = backend * "/" * img_name
            if current_file in missing_files

                cb = refimage_selection_checkbox(marked_for_deletion, current_file)

                local_path = map(path_button.value) do click
                    local_path = normpath(joinpath(root_path, "reference", backend, img_name))
                    return Bonito.Asset(local_path)
                end

                media = media_element(img_name, local_path)

                card = Card(DOM.div(cb, media), style = card_style)
                push!(missing_cards, card)
            else
                push!(missing_cards, DOM.div())
            end
        end

    end

    update_section = DOM.div(
        DOM.h2("Images to update"),
        Bonito.Button("Update reference images with selection"),
        DOM.div("After pressing the button you will be asked which version to upload the reference images listed below to. After that the reference images on github will be replaced with an updated set if you have the rights to do so."),
        DOM.h3("[TODO:] images selected for updating:"),
        DOM.div("TODO: image grid"),
        DOM.h3("[TODO:] images selected for removal:"),
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
        Grid(missing_cards, columns = "1fr 1fr 1fr")
    )

    main_section = DOM.div(
        DOM.h2("Images with references"),
        DOM.div("This is the normal case where the selected CI run produced an image and the reference image exists. Each row shows one image per backend from the same reference image test, which can be compared with its reference image. Rows are sorted based on the maximum row score (bigger = more different). Background colors are based on this score, with red > $(score_thresholds[1]), orange > $(score_thresholds[2]), yellow > $(score_thresholds[3]) and the rest being light gray."),
        DOM.br(),
        Grid(updated_cards, columns = "1fr 1fr 1fr")
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
