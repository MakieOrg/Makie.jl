using PackageCompiler


userimg = Pkg.dir("Makie", "test", "makie_precompile.jl")
image_path = PackageCompiler.sysimg_folder()
PackageCompiler.build_sysimg(image_path, userimg, compilecache = "yes")
isfile(backup) || mv(syspath, backup)
cp(imgfile, syspath)
