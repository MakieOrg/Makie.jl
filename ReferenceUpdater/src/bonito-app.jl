using Bonito, DelimitedFiles

include("cross_backend_score.jl")

"""
    serve_update_page(path_to_reference_images_folder)
"""
function create_app_content(root_path::String)

    # Styles

    # TODO: font size ignored?
    button_style = Styles(
        CSS("font-size" => "12", "font-weight" => "normal"),
        CSS(
            "width" => "fit-content",
            "padding-right" => "6px", "padding-left" => "6px",
            "padding-bottom" => "2px", "padding-top" => "2px",
        ),
        CSS("display" => "inline-block", "float" => "left")
    )

    score_style = Styles(
        CSS("font-size" => "12", "font-weight" => "normal"),
        CSS(
            "width" => "fit-content",
            "padding-right" => "6px", "padding-left" => "6px",
            "padding-bottom" => "2px", "padding-top" => "2px",
            "margin" => "0.25em"
        ),
        CSS("display" => "inline-block", "float" => "right")
    )

    checkbox_style = Styles(CSS("transform" => "scale(1)"))

    textfield_style = Styles(CSS("width" => "4rem", "font-size" => "12", "font-weight" => "normal"))

    card_css = CSS(
        "margin" => "0.1em", # outside
        "padding" => "0.5em", # inside
        "border" => "2px solid lightblue",
        "border-radius" => "1em",
        "color" => "black",
        "min-width" => "16rem" # effectively controls size of the whole layout
    )

    max_width = Styles(CSS("max-width" => "100%"))

    # Constants

    backends = ["GLMakie", "CairoMakie", "WGLMakie"]
    # for updated images:
    selected_folder = ["recorded", "reference"]
    selection_string = ["Showing new recorded", "Showing old reference"]
    score_thresholds = [0.05, 0.03, 0.01]

    # "globals"
    checkbox_obs = Dict{String, Observable{Bool}}()

    function refimage_selection_checkbox(marked, current_file, obs = Observable(false))
        local_marked = convert(Observable{Bool}, obs)
        on(local_marked) do is_marked
            if is_marked
                push!(marked[], current_file)
            else
                delete!(marked[], current_file)
            end
            notify(marked)
        end
        return DOM.div(
            Checkbox(local_marked, Dict{Symbol, Any}(:style => checkbox_style)),
            " $current_file"
        )
    end

    function check_all_checkbox()
        checked = Observable(false) # maps to individual checkboxes which update marked
        return DOM.div(
                Checkbox(checked, Dict{Symbol, Any}(:style => checkbox_style)),
                " Toggle All"
            ), checked
    end

    function media_element(img_name, local_path)
        filetype = split(img_name, ".")[end]
        if filetype == "png"
            return DOM.img(src = local_path, style = max_width)
        else
            return DOM.video(
                DOM.source(; src = local_path, type = "video/mp4"),
                autoplay = false, controls = true, style = max_width
            )
        end
    end

    function create_simple_grid_content(filename, image_folder)
        files = readlines(joinpath(root_path, filename))
        refimages = unique(
            map(files) do img
                replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
            end
        )

        marked = Observable(Set{String}())

        toggle_all_cb, mark_all = check_all_checkbox()

        cards = Any[]
        for img_name in refimages
            for backend in backends

                current_file = backend * "/" * img_name
                if current_file in files
                    checkbox_obs[current_file] = obs = map(identity, mark_all)
                    cb = refimage_selection_checkbox(marked, current_file, obs)
                    local_path = Bonito.Asset(normpath(joinpath(root_path, image_folder, backend, img_name)))
                    media = media_element(img_name, local_path)
                    card = Card(DOM.div(cb, media), style = Styles(card_css, CSS("background-color" => "#eeeeee")))
                    push!(cards, card)
                else
                    push!(cards, DOM.div())
                end
            end

        end

        return toggle_all_cb, cards, marked
    end


    # Newly added Images

    new_checkbox, new_cards, marked_for_upload =
        create_simple_grid_content("new_files.txt", "recorded")

    # Deleted/Missing Images

    missing_checkbox, missing_cards, marked_for_deletion =
        create_simple_grid_content("missing_files.txt", "reference")


    # Updates images

    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')

    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

    imgs_with_score = unique(
        map(imgs) do img
            replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
        end
    )

    function get_score(img_name)
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

    sort!(imgs_with_score; by = get_score, rev = true)

    update_multi_check = Observable(false)
    update_multi_textinput = Bonito.TextField("0.05", style = textfield_style)
    update_multi_checkbox = DOM.div(
        Checkbox(update_multi_check, Dict{Symbol, Any}(:style => checkbox_style)),
        " Toggle All with Score ≥",
        update_multi_textinput
    )

    updated_cards = Any[]
    for img_name in imgs_with_score
        for backend in backends

            current_file = backend * "/" * img_name
            if haskey(lookup, current_file)

                score = round(lookup[current_file]; digits = 3)

                local_marked = map(update_multi_check) do active
                    try
                        threshold = parse(Float64, update_multi_textinput.value[])
                        return active && (score >= threshold)
                    catch e
                        return false
                    end
                end
                on(local_marked) do is_marked
                    if is_marked
                        push!(marked_for_upload[], current_file)
                    else
                        delete!(marked_for_upload[], current_file)
                    end
                    notify(marked_for_upload)
                end
                cb = DOM.div(
                    Checkbox(local_marked, Dict{Symbol, Any}(:style => checkbox_style)),
                    " $current_file"
                )
                checkbox_obs[current_file] = local_marked

                # TODO: Is there a better way to handle default with overwrites?
                card_style = Styles(
                    card_css, CSS(
                        "background-color" => if score > score_thresholds[1]
                            "#ffbbbb"
                        elseif score > score_thresholds[2]
                            "#ffddbb"
                        elseif score > score_thresholds[3]
                            "#ffffdd"
                        else
                            "#eeeeee"
                        end
                    )
                )

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

    # upload

    function upload_selection(tag)
        recorded_path = joinpath(root_path, "recorded")

        @info "Downloading latest reference image folder for $tag"
        tmpdir = try
            download_refimages(tag)
        catch e
            @error "Failed to download refimg folder. Is the tag $tag correct? Exiting without upload." exception = (e, catch_backtrace())
            return
        end

        @info "Updating files in $tmpdir"

        try
            for image in marked_for_upload[]
                @info "Overwriting or adding $image"
                target = joinpath(tmpdir, normpath(image))
                # make sure the path exists
                mkpath(splitdir(target)[1])

                source = joinpath(recorded_path, normpath(image))
                cp(source, target, force = true)
            end
        catch e
            @error "Failed to overwrite/add images. Exiting without upload." exception = (e, catch_backtrace())
            return
        end

        try
            for image in marked_for_deletion[]
                @info "Deleting $image"
                target = joinpath(tmpdir, normpath(image))
                @show target
                if isfile(target)
                    rm(target)
                else
                    @warn "Cannot delete $image - does not exist."
                end
            end
        catch e
            @error "Failed to remove images. Exiting without upload." exception = (e, catch_backtrace())
            return
        end

        try
            @info "Uploading..."
            upload_reference_images(tmpdir, tag)
            @info "Upload successful."
        catch e
            @error "Upload failed: " exception = (e, catch_backtrace())
        finally
            @info "Deleting temp directory..."
            rm(tmpdir; force = true, recursive = true)
            @info "Done. You can ctrl+c out now."
        end
        return
    end

    # TODO: no less than 8rem width?
    tag_textfield = Bonito.TextField("$(last_major_version())", style = Styles("width" => "8rem"))
    upload_button = Bonito.Button("Update reference images with selection")
    on(_ -> upload_selection(tag_textfield.value[]), upload_button.value)

    # compare to GLMakie

    compare_button = Bonito.Button("Compare current selection")
    glmakie_compare_grid = Observable{Any}(DOM.div())
    on(compare_button.value) do _

        without_backend = unique(
            map(collect(marked_for_upload[])) do img
                replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
            end
        )
        file2score = compare_selection(root_path, marked_for_upload[])

        function get_score(img_name)
            scores = map(backends) do backend
                name = backend * "/" * img_name
                if haskey(file2score, name)
                    return file2score[name]
                else
                    return -Inf
                end
            end
            return maximum(scores)
        end
        sort!(without_backend; by = get_score, rev = true)

        updated_cards = Any[]
        for img_name in without_backend
            for backend in backends
                backend == "GLMakie" && continue

                current_file = backend * "/" * img_name
                if haskey(file2score, current_file)
                    obs = checkbox_obs[current_file]
                    cb = refimage_selection_checkbox(marked_for_upload, current_file, obs)

                    score = round(get(file2score, current_file, -1.0); digits = 3)
                    # TODO: Is there a better way to handle default with overwrites?
                    card_style = Styles(
                        card_css, CSS(
                            "background-color" => if score > score_thresholds[1]
                                "#ffbbbb"
                            elseif score > score_thresholds[2]
                                "#ffddbb"
                            elseif score > score_thresholds[3]
                                "#ffffdd"
                            elseif score < -0.1
                                "#bbbbff"
                            else
                                "#eeeeee"
                            end
                        )
                    )

                    path_button = Bonito.Button("", style = button_style)
                    selection = 2 # Recorded (new), Reference (old)
                    ref_name = "GLMakie/$img_name"
                    local_path = map(path_button.value) do click
                        selection = mod1(selection + 1, 2)
                        path_button.content[] = [backend, "GLMakie"][selection]
                        file = [current_file, ref_name][selection]
                        local_path = normpath(joinpath(root_path, "recorded", file))
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

        glmakie_compare_grid[] = Grid(updated_cards, columns = "33% 33%")
    end

    # Create page

    update_section = DOM.div(
        DOM.h2("Images to update"),
        DOM.div("Pressing the button below will download the latest reference images for the selected version; add, update and/or remove the selected images listed below and then upload the changed reference image folder. See Julia terminal for progress updates."),
        DOM.div(tag_textfield, upload_button),
        DOM.h3(map(set -> "$(length(set)) images selected for updating:", marked_for_upload)),
        map(set -> DOM.ul([DOM.li(name) for name in set]), marked_for_upload),
        DOM.h3(map(set -> "$(length(set)) images selected for removal:", marked_for_deletion)),
        map(set -> DOM.ul([DOM.li(name) for name in set]), marked_for_deletion),
    )

    glmakie_compare_section = DOM.div(
        DOM.h2("Compare Selection to GLMakie"),
        DOM.div("Compares every selected refimg with it's corresponding GLMakie refimg. If there is none the score will be -1.0. (This may take a minute if all images are selected.)"),
        compare_button,
        glmakie_compare_grid
    )

    new_image_section = DOM.div(
        DOM.h2("New images without references"),
        DOM.div("The selected CI run produced an image for which no reference image exists. Selected images will be added as new reference images."),
        new_checkbox, DOM.br(),
        Grid(new_cards, columns = "1fr 1fr 1fr")
    )

    missing_recordings_section = DOM.div(
        DOM.h2("Old reference images without recordings"),
        DOM.div("The selected CI run did not produce an image, but a reference image exists. This implies that a reference test was deleted or renamed. Selected images will be deleted from the reference images."),
        missing_checkbox, DOM.br(),
        Grid(missing_cards, columns = "1fr 1fr 1fr")
    )

    main_section = DOM.div(
        DOM.h2("Images with references"),
        DOM.div("This is the normal case where the selected CI run produced an image and the reference image exists. Each row shows one image per backend from the same reference image test, which can be compared with its reference image. Rows are sorted based on the maximum row score (bigger = more different). Background colors are based on this score, with red > $(score_thresholds[1]), orange > $(score_thresholds[2]), yellow > $(score_thresholds[3]) and the rest being light gray."),
        update_multi_checkbox,
        DOM.br(),
        Grid(updated_cards, columns = "1fr 1fr 1fr")
    )

    return DOM.div(
        update_section,
        glmakie_compare_section,
        new_image_section,
        missing_recordings_section,
        main_section,
        style = Styles(CSS("font-family" => "sans-serif", "min-width" => "4rem"))
    )
end

function serve_update_page_from_dir(root_path)
    return App(() -> create_app_content(root_path))
end

function serve_update_page(; commit = nothing, pr = nothing)
    tmpdir = download_artifacts(commit = commit, pr = pr)
    @info "Creating Bonito app from folder $tmpdir."
    return serve_update_page_from_dir(tmpdir)
end
