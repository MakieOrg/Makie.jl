function to_rpr_object(context, matsys, scene, plot::Makie.Volume)
    volume = plot.volume[]
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

    mini, maxi = extrema(volume)
    vol_normed = (volume .- mini) ./ (maxi - mini)
    gridsampler = RPR.GridSamplerMaterial(matsys)
  
    on(vol_normed_obs; update=true) do vol_normed
        grid_sampler.data = RPR.VoxelGrid(context, vol_normed)
    end

    color_sampler = RPR.ImageTextureMaterial(matsys)
    color_sampler.uv = gridsampler
    on(plot.colormap; update=true) do cmap
        color_sampler.data = RPR.Image(context, reverse(to_colormap(cmap))')
    end

    volmat = RPR.VolumeMaterial(matsys)
    on(plot.absorption; update=true) do absorption
        return volmat.density = Vec4f(absorption, 0.0, 0.0, 0.0)
    end
    volmat.densitygrid = gridsampler
    volmat.color = color_sampler
    set!(cube, volmat)
    return [cube]
end
