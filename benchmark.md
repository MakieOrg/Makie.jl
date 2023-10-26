## Compile Times benchmark

Note, that these numbers may fluctuate on the CI servers, so take them with a grain of salt. All benchmark results are based on the mean time and negative percent mean faster than the base branch. Note, that GLMakie + WGLMakie run on an emulated GPU, so the runtime benchmark is much slower. Results are from running:

```julia
using_time = @ctime using Backend
# Compile time
create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime Makie.colorbuffer(display(fig))
# Runtime
create_time = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @benchmark Makie.colorbuffer(display(fig))
```

|            | using                                          | create                                                  | display                                             | create                                              | display                                               |
| ----------:|:---------------------------------------------- |:------------------------------------------------------- |:--------------------------------------------------- |:--------------------------------------------------- |:----------------------------------------------------- |
|    GLMakie | 4.68s (4.67, 4.69) 0.01+-                      | 346.52ms (345.28, 347.76) 1.75+-                        | 1.23s (1.22, 1.23) 0.00+-                           | 7.28ms (7.23, 7.32) 0.06+-                          | 29.72ms (28.89, 30.56) 1.19+-                         |
| sd/beta-20 | 4.47s (4.18, 4.83) 0.20+-                      | 400.80ms (355.11, 473.85) 32.01+-                       | 1.72s (1.61, 1.87) 0.08+-                           | 6.53ms (5.93, 7.40) 0.49+-                          | 37.61ms (29.79, 41.93) 4.70+-                         |
| evaluation | +4.63%, 0.22s slower X (1.12d, 0.00p, 0.11std) | -15.66%, -54.28ms **faster**✅ (-1.74d, 0.00p, 16.88std) | -40.67%, -0.5s **faster**✅ (-6.53d, 0.00p, 0.04std) | +10.29%, 0.75ms **slower**❌ (1.57d, 0.00p, 0.27std) | -26.53%, -7.89ms **faster**✅ (-1.71d, 0.00p, 2.94std) |
| CairoMakie | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
| sd/beta-20 | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
| evaluation | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
|   WGLMakie | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
| sd/beta-20 | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
| evaluation | –                                              | –                                                       | –                                                   | –                                                   | –                                                     |
