using Bonito, FileIO, DelimitedFiles

root_path = joinpath(pwd(), "ReferenceImages")

App() do

    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')

    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

    # TODO: don't filter out videos
    imgs_with_score = filter(x -> endswith(x, ".png"), unique(map(imgs) do img
        replace(img, r"(GLMakie|CairoMakie|WGLMakie)/" => "")
    end))

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

    backends = ["CairoMakie", "GLMakie", "WGLMakie"]
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

    marked = Set{String}()

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

                path_button = Bonito.Button("recorded", style = button_style)

                selection = 1 # Recorded (new), Reference (old)

                image_element = map(path_button.value) do click
                    selection = mod1(selection + 1, 2)
                    path_button.content[] = selection_string[selection]
                    folder = selected_folder[selection]

                    bin = read(normpath(joinpath(root_path, folder, backend, img_name)))
                    return DOM.img(src=Bonito.BinaryAsset(bin, "image/png"))
                end

                # TODO: background
                return Card(Col(cb, score_text, path_button, image_element))
            else
                return Card(DOM.h1("N/A"))
            end
        end

        return Grid(cards, columns = "1fr 1fr 1fr")
    end

    return DOM.div(images...)

end
