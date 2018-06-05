struct VideoStream
    io
    process
    screen
    path::String
end


"""
    VideoStream(scene::Scene, dir = mktempdir(), name = "video")

returns a stream and a buffer that you can use to not allocate for new frames.
Use `add_frame!(stream, window, buffer)` to add new video frames to the stream.
Use `finish(stream)` to save the video to 'dir/name.mkv'. You can also call
`finish(stream, "mkv")`, `finish(stream, "mp4")`, `finish(stream, "gif")` or `finish(stream, "webm")` to convert the stream to those formats.
"""
function VideoStream(scene::Scene)
    if !has_ffmpeg[]
        error("You can't create a video stream without ffmpeg installed.
         Please install ffmpeg, e.g. via https://ffmpeg.org/download.html.
         When you download the binaries, please make sure that you add the path to your PATH
         environment variable.
         On unix you can install ffmpeg with `sudo apt-get install ffmpeg`.
        ")
    end
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    dir = mktempdir()
    path = joinpath(dir, "video.mkv")
    if isempty(scene.current_screens)
        error("Scene doesn't contain any screen")
    end
    screen = first(scene.current_screens)
    _xdim, _ydim = widths(pixelarea(scene)[])
    xdim = _xdim % 2 == 0 ? _xdim : _xdim + 1
    ydim = _ydim % 2 == 0 ? _ydim : _ydim + 1
    io, process = open(`ffmpeg -loglevel quiet -f rawvideo -pixel_format rgb24 -r 24 -s:v $(xdim)x$(ydim) -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(io, process, screen, abspath(path))
end

"""
Adds a video frame to the VideoStream
"""
function recordframe!(io::VideoStream)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    frame = colorbuffer(io.screen)
    _xdim, _ydim = size(frame)
    xdim = _xdim % 2 == 0 ? _xdim : _xdim + 1
    ydim = _ydim % 2 == 0 ? _ydim : _ydim + 1
    buff = zeros(RGB{N0f8}, xdim, ydim)
    view(buff, 1:_xdim, 1:_ydim) .= RGB{N0f8}.(frame)
    write(io.io, buff)
    return
end

"""
    finish(io::VideoStream, path = "video.mkv")

Flushes the video stream and converts the file to the extension found in `path` which can
be `mkv` is default and doesn't need convert, `gif`, `mp4` and `webm`.
mp4 is recommended for the internet, since it's the most supported format.
webm yields the smallest file size, mp4 and mk4 are marginally bigger and gifs are up to
6 times bigger with same quality!
"""
function finish(io::VideoStream, out::String = "video.mkv")
    flush(io.io)
    close(io.io)
    wait(io.process)
    p, typ = splitext(out)
    if typ == ".mkv"
        cp(io.path, out)
    elseif typ == ".mp4"
        run(`ffmpeg -i $(io.path) -c:v libx264 -preset slow -crf 24 -pix_fmt yuv420p -c:a libvo_aacenc -b:a 128k -y $out`)
    elseif typ == "webm"
        run(`ffmpeg -loglevel quiet -i $(io.path) -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -vf scale=iw:ih -y $out`)
    elseif typ == ".gif"
        palette_path = mktempdir()
        pname = joinpath(palette_path, "palette.png")
        filters = "fps=15,scale=iw:ih:flags=lanczos"
        run(`ffmpeg -loglevel quiet -v warning -i $(io.path) -vf "$filters,palettegen" -y $pname`)
        run(`ffmpeg -loglevel quiet -v warning -i $(io.path) -i $pname -lavfi "$filters [x]; [x][1:v] paletteuse" -y $out`)
    else
        rm(io.path)
        error("Video type $typ not known")
    end
    rm(io.path)
    return out
end


"""
    record(func, scene, path)
usage:
```example
    record(scene, "test.gif") do io
        for i = 1:100
            scene.plots[:color] = ...# animate scene
            recordframe!(io) # record a new frame
        end
    end
```
"""
function record(func, scene, path)
    io = VideoStream(scene)
    func(io)
    finish(io, path)
end
"""
    record(func, scene, path, iter)
usage:
```example
    record(scene, "test.gif", 1:100) do i
        scene.plots[:color] = ...# animate scene
    end
```
"""
function record(func, scene, path, iter)
    io = VideoStream(scene)
    for i in iter
        t1 = time()
        func(i)
        recordframe!(io)
        diff = (1/24) - (time() - t1)
        if diff > 0.0
            sleep(diff)
        else
            yield()
        end
    end
    finish(io, path)
end



function show(io::IO, mime::MIME"text/html", vs::VideoStream)
    mktempdir() do dir
        path = finish(vs, joinpath(dir, "video.mp4"))
        print(
            io,
            """<video autoplay controls><source src="data:video/x-m4v;base64,""",
            base64encode(open(read, path)),
            """" type="video/mp4"></video>"""
        )
    end
end
