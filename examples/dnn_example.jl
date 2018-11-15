using Flux, Flux.Data.MNIST, Statistics
using Flux: onehotbatch, onecold, crossentropy, throttle
using Base.Iterators: repeated, partition
using CuArrays
using Colors, FileIO, ImageShow
using Makie
# Classify MNIST digits with a convolutional network
imgs = MNIST.images()
labels = onehotbatch(MNIST.labels(), 0:9)

# Partition into batches of size 1,000
train = [(cat(float.(imgs[i])..., dims = 4), labels[:,i])
         for i in partition(1:60_000, 1000)]

use_gpu = true # helper to easily switch between gpu/cpu

todevice(x) = use_gpu ? gpu(x) : x

train = todevice.(train)

# Prepare test set (first 1,000 images)
tX = cat(float.(MNIST.images(:test)[1:1000])..., dims = 4) |> todevice
tY = onehotbatch(MNIST.labels(:test)[1:1000], 0:9) |> todevice

m = Chain(
  Conv((2,2), 1=>16, relu),
  x -> maxpool(x, (2,2)),
  Conv((2,2), 16=>8, relu),
  x -> maxpool(x, (2,2)),
  x -> reshape(x, :, size(x, 4)),
  Dense(288, 10), softmax
) |> todevice

loss(x, y) = crossentropy(m(x), y)

accuracy(x, y) = mean(onecold(m(x)) .== onecold(y))

img_node = Node(tX[:, :, 1:1, 1:1])
scene = create_viz(m, img_node)

io = Makie.VideoStream(scene)

evalcb = throttle(0.01) do
  img_node[] = img_node[] # update image
  Makie.recordframe!(io)
end
opt = ADAM(Flux.params(m));

record(scene, "flux.mp4", 1:10) do i
    Flux.train!(loss, train, opt, cb = evalcb)
end
Makie.save(joinpath(homedir(), "Desktop", "flux.mp4"), io)



function imgviz!(scene, img)
  image!(scene, 0..16, 0..1, img, show_axis = false, scale_plot = false)
end
function d3tod2(input3d)
  rotr90(hcat((input3d[ :, :, i] for i in 1:size(input3d, 3))...))
end

AbstractPlotting.available_gradients()

function create_viz(m, input)
  scene = Scene(camera = cam2d!, raw = true)
  layer = input
  lastof = 0.0
  for i in 1:4
    layer = lift(x-> m[i](x), layer)
    img = lift(d3tod2 ∘ collect, layer)
    imgviz!(scene, img)
    im = scene[end]
    translate!(im, 0, lastof, 0)
    lastof += 2
  end
  # lay = vcat((hcat((collect(reshape(W[1:10, ((j-1)*36 + 1):(j*36)][x, :], (6,6))*lay4[:, :, j]) for x in 1:10)...) for j in 1:8)...)
  heatmap!(scene, 0..16, 0..1, lift(x-> collect(m[6].W'), layer))
  translate!(scene[end], 0, lastof, 0)
  lastof += 2
  height = lift(layer) do layer
    (collect(layer |>  m[5] |> m[6])[:, 1] .+ 10) ./ 10
  end
  xrange = range(1, stop = 15, length = 10)
  annotations!(scene,
    string.(0:9), Point2f0.(xrange, lastof - 0.6),
    textsize = 0.5
  )
  barplot!(scene, xrange, height, color = height, colormap = Reverse(:Spectral))
  translate!(scene[end], 0, lastof, 0)
  center!(scene)
  display(scene)
  scene
end
scene = create_viz(m, img_node)
