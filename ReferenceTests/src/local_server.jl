function serve_update_page(folder)

    folder = realpath(folder)
    @assert isdir(folder) "$folder is not a valid directory."
    refimages_name = last(splitpath(realpath(folder)))
    @assert refimages_name in ["refimages", "refimages_glmakie"] "$refimages_name as folder not recognized"

    router = HTTP.Router()

    function receive_update(req)
        images = JSON3.read(req.body)
        
        tempdir = tempname()
        recorded_folder = joinpath(folder, "recorded")
        reference_folder = joinpath(folder, "reference")

        @info "Copying reference folder to $tempdir"
        cp(reference_folder, tempdir)

        for image in images
            @info "Overwriting $image in new reference folder"
            cp(joinpath(recorded_folder, image), joinpath(tempdir, image), force = true)
        end

        @info "Uploading updated reference images"
        try
            upload_reference_images(tempdir, "julius-test-tag"; name = refimages_name)

            HTTP.Response(200, "Upload successful")
        catch e
            showerror(stdout, e, catch_backtrace())
            HTTP.Response(404)
        end
    end

    function serve_local_file(req)
        req.target == "/" && return HTTP.Response(200,
            read(normpath(joinpath(dirname(pathof(ReferenceTests)), "reference_images.html"))))
        file = HTTP.unescapeuri(req.target[2:end])
        filepath = normpath(joinpath(folder, file))
        # check that we don't go outside of the artifact folder
        if !startswith(filepath, folder)
            @info "$file leads to $filepath which is outside of the artifact folder."
            return HTTP.Response(404)
        end

        if !isfile(filepath)
            return HTTP.Response(404)
        else
            return HTTP.Response(200, read(filepath))
        end
    end

    HTTP.@register(router, "POST", "/", receive_update)
    HTTP.@register(router, "GET", "/", serve_local_file)

    @info "Starting server"
    HTTP.serve(router, HTTP.Sockets.localhost, 8000)
end
