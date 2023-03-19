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
    color_lookup = to_colormap(plot.colormap[])
    density_lookup = [Vec3f(plot.absorption[])]

    mini, maxi = extrema(volume)
    vol_normed = (volume .- mini) ./ (maxi - mini)
    grid = RPR.VoxelGrid(context, vol_normed)
    gridsampler = RPR.GridSamplerMaterial(matsys)
    gridsampler.data = grid

    color_ramp = RPR.Image(context, color_lookup)
    density_sampler = RPR.GridSamplerMaterial(matsys)
    density_sampler.data = grid

    color_sampler = RPR.ImageTextureMaterial(matsys)
    color_sampler.data = color_ramp
    color_sampler.uv = density_sampler

    volmat = RPR.VolumeMaterial(matsys)
    volmat.density = Vec4f(plot.absorption[], plot.absorption[], plot.absorption[], 0.0)
    volmat.densitygrid = gridsampler
    volmat.color = color_sampler
    set!(cube, volmat)

    return [cube]
end
