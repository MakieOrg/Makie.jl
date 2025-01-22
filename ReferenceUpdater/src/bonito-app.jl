using Bonito, FileIO, DelimitedFiles

root_path = joinpath(pwd(), "ReferenceImages")

App() do

    scores_imgs = readdlm(joinpath(root_path, "scores.tsv"), '\t')

    scores = scores_imgs[:, 1]
    imgs = scores_imgs[:, 2]
    lookup = Dict(imgs .=> scores)

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

    button_style = Styles(
        CSS("font-size" => "8", "font-weight" => "100"),
        CSS("width" => "fit-content")
    )

    images = map(imgs_with_score) do img_name
        cards = map(backends) do backend
            # [] $path
            # [Showing Reference/Recorded]  ---  Score: $score
            # image

            if haskey(lookup, backend * "/" * img_name)

                path_button = Bonito.Button("recorded", style = button_style)
                selection = 1 # Recorded (new), Reference (old)

                image_element = map(path_button.value) do click
                    selection = mod1(selection + 1, 2)
                    path_button.content[] = selection_string[selection]
                    folder = selected_folder[selection]

                    bin = read(normpath(joinpath(root_path, folder, backend, img_name)))
                    return DOM.img(src=Bonito.BinaryAsset(bin, "image/png"))
                end

                # # score = round(lookup[name]; digits=4)
                # # b = Bonito.Button("$backend: $score")

                Card(Col(path_button, image_element))
            else
                Card(DOM.h1("N/A"))
            end
        end

        Grid(cards, columns = "1fr 1fr 1fr")
    end

    DOM.div(images...)

end
