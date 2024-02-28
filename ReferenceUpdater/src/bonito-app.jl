using Bonito, FileIO, DelimitedFiles

folder = joinpath(pwd(), "ReferenceImages")

App() do

    scores_imgs = readdlm(joinpath(folder, "scores.tsv"), '\t')

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
    images = map(imgs_with_score) do img_name
        image_path = Observable{Any}(DOM.div())
        path = Observable("recorded")
        path_button = Bonito.Button("recorded")
        on(path_button.value) do click
            if path[] == "recorded"
                path[] = "reference"
                path_button.content[] = "reference"
            else
                path[] = "recorded"
                path_button.content[] = "recorded"
            end
            return
        end
        buttons = map(backends) do backend
            name = backend * "/" * img_name
            if haskey(lookup, name)
                score = round(lookup[name]; digits=4)
                b = Bonito.Button("$backend: $score")
                onany(b.value, path; update=true) do click, rec_ref
                    bin = read(normpath(joinpath(folder, rec_ref, backend, img_name)))
                    image_path[] = DOM.img(src=Bonito.BinaryAsset(bin, "image/png"))
                end
                return b
            else
                return DOM.div("$backend: X")
            end
        end
        buttons = Row(path_button, buttons...; width="100%")

        Card(Col(buttons, image_path); width="fit-content")
    end

    DOM.div(images...)

end
