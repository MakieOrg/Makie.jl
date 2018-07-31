@block SimonDanisch ["dataset_examples"] begin
    @cell "WorldClim visualization" [visualization, dataset, bigdata] begin
        using FileIO, GeometryTypes, Colors, GDAL

        #=
        This example requires the GDAL package, from https://github.com/JuliaGeo/GDAL.jl
        For more information about GDAL, see the official documentation at: https://gdal.org/
        =#

        # register GDAL drivers
        GDAL.allregister()

        # function to check if a file is a .tif file
        istiff(x) = endswith(x, ".tif")

        # set up 7zip
        exe7z = is_windows() ? joinpath(JULIA_HOME, "7z.exe") : joinpath(JULIA_HOME, "7z")
        unzip(in, out) = run(`$exe7z x -y $in -o$out`)

        # function to read the raster data from the GeoTIFF
        function loadf0(x)
            img = GDAL.open(x, GDAL.GA_ReadOnly)
            band = GDAL.getrasterband(img, 1)
            xsize = GDAL.getrasterbandxsize(band)
            ysize = GDAL.getrasterbandysize(band)
            data = Array{Float32}(xsize, ysize)
            GDAL.rasterio(band, GDAL.GF_Read, 0, 0, xsize, ysize, data, xsize, ysize, GDAL.GDT_Float32, 0, 0)
            data'
        end

        # since we cannot re-distribute the dataset, this function grabs the dataset from the host server
        function load_dataset(name)
            # get the dataset from:
            # http://worldclim.org/version2
            """
            This is WorldClim 2.0 Beta version 1 (June 2016) downloaded from http://worldclim.org
            They represent average monthly climate data for 1970-2000.
            The data were created by Steve Fick and Robert Hijmans
            You are not allowed to redistribute these data.
            """
            if !isfile("$name.zip")
                # This might fail on windows - just try again a couple of times -.-
                download("http://biogeo.ucdavis.edu/data/worldclim/v2.0/tif/base/wc2.0_10m_$name.zip", "$name.zip")
            end
            if !isdir(name)
                unzip("$name.zip", name)
            end
            loadf0.(filter(istiff, joinpath.(name, readdir(name))))
        end

        # load the actual datasets!
        water = load_dataset("prec")
        temperature = load_dataset("tmax")

        # calculate geometries
        m = GLNormalUVMesh(Sphere(Point3f0(0), 1f0), 200)
        p = decompose(Point3f0, m)
        uv = decompose(UV{Float32}, m)
        norms = decompose(Normal{3, Float32}, m)

        # plot the temperature as color map on the globe
        cmap = [:darkblue, :deepskyblue2, :deepskyblue, :gold, :tomato3, :red, :darkred]
        scene = Makie.mesh(m, color = temperature[10], colorrange = (-50, 50), colormap = cmap, shading = true, show_axis = false)
        temp_plot = scene[end];

        # function to scale precipitation to a suitable marker size
        function to_msize(uv, water, xysize = 0.008, normalization = 908f0 * 4f0)
            markersize = map(uv) do uv
                wh = size(water) .- 1
                x, y = round.(Int, Tuple(uv) .* wh) .+ 1
                val = water[x, y] / normalization
                val = val < 0.0 ? 0f0 : val
                Vec3f0(xysize, xysize, val)
            end
        end

        # plot precipitation as vertical bars
        meshscatter!(scene,
            p, rotations = norms,
            marker = Rect3D(Vec3f0(0), Vec3f0(1)), markersize = to_msize(uv, water[1]), raw = true,
            color = (:skyblue2, 0.9)
        )
        wplot = scene[end]

        # update eye position
        eye_position, lookat, upvector = Vec3f0(0.5, 0.8, 2.5), Vec3f0(0), Vec3f0(0, 1, 0)
        update_cam!(scene, eye_position, lookat, upvector)
        scene

        # save animation
        record(scene, joinpath(homedir(), "Desktop", "earth.gif"), 0:(11*4)) do i
            # Make simulation slower. TODO figure out how do this nicely with ffmpeg
            if i % 4 == 0
                i2 = (i ÷ 4) + 1
                temp_plot[:color] = temperature[i2]
                wplot[:markersize] = to_msize(uv, water[i2])
            end
        end
    end
    
end
