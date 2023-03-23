function to_rpr_object(context, matsys, scene, plot::Makie.Volume)

    cube = RPR.VolumeCube(context)

    function update_cube(m, xyz...)
        mi = minimum.(xyz)
        maxi = maximum.(xyz)
        w = maxi .- mi
        m2 = Mat4f(w[1], 0, 0, 0, 0, w[2], 0, 0, 0, 0, w[3], 0, mi[1], mi[2], mi[3], 1)
        mat = convert(Mat4f, m) * m2
        transform!(cube, mat)
        return
    end

    onany(update_cube, plot.model, plot.x, plot.y, plot.z)
    update_cube(plot.model[], plot.x[], plot.y[], plot.z[])

    vol_normed_obs = lift(plot.volume) do vol
        mini, maxi = extrema(vol)
        (vol .- mini) ./ (maxi - mini)
    end

    grid_sampler = RPR.GridSamplerMaterial(matsys)

    lift(vol_normed_obs) do vol_normed
        grid_sampler.data = RPR.VoxelGrid(context, vol_normed)
    end

    # color_grid = lift(vol_normed_obs) do vol_normed
    #     return RPR.VoxelGrid(context, vol_normed)
        
    # end

    color_sampler = RPR.ImageTextureMaterial(matsys)

    lift(plot.colormap) do cmap
        color_sampler.data = RPR.Image(context, reverse(to_colormap(cmap))')
    end

    # gridsampler2 = RPR.GridSamplerMaterial(matsys)
    color_sampler.uv = grid_sampler

    volmat = RPR.VolumeMaterial(matsys)

    on(plot.absorption; update=true) do absorption
        return volmat.density = Vec4f(absorption, 0f0, 0f0, 0f0)
    end

    volmat.densitygrid = grid_sampler

    volmat.color = color_sampler

    # volmat.emission = color_sampler

    set!(cube, volmat)

    # set the light penetration to be higher

    set!(context, RPR.RPR_CONTEXT_MAX_RECURSION, 5)

    return [cube]
end
