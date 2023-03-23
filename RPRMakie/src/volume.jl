function to_rpr_object(context, matsys, scene, plot::Makie.Volume)

    cube = RPR.VolumeCube(context)

    function update_cube(m, xyz...)
        mi = minimum.(xyz)
        maxi = maximum.(xyz)
        w = maxi .- mi
        m2 = Makie.transformationmatrix(mi, w) # Mat4f(w[1], 0, 0, 0, 0, w[2], 0, 0, 0, 0, w[3], 0, mi[1], mi[2], mi[3], 1)
        mat = convert(Mat4f, m) * m2
        transform!(cube, mat)
        return
    end

    lift(update_cube, plot.model, plot.x, plot.y, plot.z; ignore_equal_values = true)
    update_cube(plot.model[], plot.x[], plot.y[], plot.z[])

    vol_normed_obs = lift(plot.volume, plot.colorrange) do vol, crange
        mini, maxi = crange
        normed_vol = clamp.((vol .- mini) ./ (maxi - mini), 0f0, 1f0)
    end

    grid_sampler = RPR.GridSamplerMaterial(matsys)

    lift(vol_normed_obs) do vol_normed
        grid_sampler.data = RPR.VoxelGrid(context, vol_normed)
    end

    color_sampler = RPR.ImageTextureMaterial(matsys)

    lift(plot.colormap) do cmap
        color_sampler.data = RPR.Image(context, reverse(to_colormap(cmap))')
    end

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
