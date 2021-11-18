function to_rpr_object(context, matsys, scene, plot::Makie.Volume)
    volume = plot.volume[]
    xyz = plot.x[], plot.y[], plot.z[]
    mini_maxi = extrema.(xyz)
    mini = first.(mini_maxi)
    maxi = last.(mini_maxi)

    vol_cube = RadeonProRender.Shape(context, Rect3f(mini, maxi .- mini))
    color_lookup = to_colormap(plot.colormap[])
    density_lookup = [Vec3f(plot.absorption[])]

    mini, maxi = extrema(volume)
    grid = RPR.VoxelGrid(context, (volume .- mini) ./ (maxi - mini))
    rpr_vol = RPR.HeteroVolume(context)

    RPR.set_albedo_grid!(rpr_vol, grid)
    RPR.set_albedo_lookup!(rpr_vol, color_lookup)

    RPR.set_density_grid!(rpr_vol, grid)
    RPR.set_density_lookup!(rpr_vol, density_lookup)

    mat = RPR.TransparentMaterial(matsys)
    mat.color = Vec4f(1)

    set!(vol_cube, rpr_vol)
    set!(vol_cube, mat)

    return [vol_cube, rpr_vol]
end
