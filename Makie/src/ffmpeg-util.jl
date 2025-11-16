# TODO move to something like FFMPEGUtil.jl ?

"""
- `format = "mkv"`: The format of the video. If a path is present, will be inferred from the file extension.
    Can be one of the following:
    * `"mkv"`  (open standard, the default)
    * `"mp4"`  (good for Web, most supported format)
    * `"webm"` (smallest file size)
    * `"gif"`  (largest file size for the same quality)

    `mp4` and `mk4` are marginally bigger than `webm`. `gif`s can be significantly (as much as
    6x) larger with worse quality (due to the limited color palette) and only should be used
    as a last resort, for playing in a context where videos aren't supported.
- `framerate = 24`: The target framerate.
- `compression = 20`: Controls the video compression via `ffmpeg`'s `-crf` option, with
    smaller numbers giving higher quality and larger file sizes (lower compression), and
    higher numbers giving lower quality and smaller file sizes (higher compression). The
    minimum value is `0` (lossless encoding).
    - For `mp4`, `51` is the maximum. Note that `compression = 0` only works with `mp4` if
      `profile = "high444"`.
    - For `webm`, `63` is the maximum.
    - `compression` has no effect on `mkv` and `gif` outputs.
- `profile = "high422"`: A ffmpeg compatible profile. Currently only applies to `mp4`. If
  you have issues playing a video, try `profile = "high"` or `profile = "main"`.
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (`-pix_fmt`). Currently only
  applies to `mp4`. Defaults to `yuv444p` for `profile = "high444"`.
- `loop = 0`: Number of times the video is repeated, for a `gif` or `html` output. Defaults to `0`, which
  means infinite looping. A value of `-1` turns off looping, and a value of `n > 0`
  means `n` repetitions (i.e. the video is played `n+1` times) when supported by backend.

!!! warning
    `profile` and `pixel_format` are only used when `format` is `"mp4"`; a warning will be issued if `format`
    is not `"mp4"` and those two arguments are not `nothing`. Similarly, `compression` is only
    valid when `format` is `"mp4"` or `"webm"`.
"""
struct VideoStreamOptions
    format::String
    framerate::Int
    compression::Union{Nothing, Int}
    profile::Union{Nothing, String}
    pixel_format::Union{Nothing, String}
    loop::Union{Nothing, Int}

    loglevel::String
    input::String
    rawvideo::Bool

    function VideoStreamOptions(
            format::AbstractString, framerate::Real, compression, profile,
            pixel_format, loop, loglevel::String, input::String, rawvideo::Bool = true
        )

        if !isa(framerate, Integer)
            @warn "The given framefrate is not a subtype of `Integer`, and will be rounded to the nearest integer. To suppress this warning, provide an integer as the framerate."
            framerate = round(Int, framerate)
        end

        if format == "mp4"
            (profile === nothing) && (profile = "high422")
            (pixel_format === nothing) && (pixel_format = (profile == "high444" ? "yuv444p" : "yuv420p"))
        end

        if format in ("mp4", "webm")
            (compression === nothing) && (compression = 20)
        end

        (loop === nothing) && (loop = 0)

        # items are name, value, allowed_formats
        allowed_kwargs = [
            ("compression", compression, ("mp4", "webm")),
            ("profile", profile, ("mp4",)),
            ("pixel_format", pixel_format, ("mp4",)),
        ]

        for (name, value, allowed_formats) in allowed_kwargs
            if !(format in allowed_formats) && value !== nothing
                @warn(
                    """`$name`, with value $(repr(value))
                    was passed as a keyword argument to `record` or `VideoStream`,
                    which only has an effect when the output video's format is one of: $(collect(allowed_formats)).
                    But the actual video format was $(repr(format)).
                    Keyword arg `$name` will be ignored.
                    """
                )
            end
        end

        if !((input == "pipe:0" || isfile(input)))
            error("file needs to be \"pipe:0\" or a valid file path")
        end

        loglevels = Set(
            [
                "quiet",
                "panic",
                "fatal",
                "error",
                "warning",
                "info",
                "verbose",
                "debug",
            ]
        )

        if !(loglevel in loglevels)
            error("loglevel needs to be one of $(loglevels)")
        end
        return new(format, framerate, compression, profile, pixel_format, loop, loglevel, input, rawvideo)
    end
end

function VideoStreamOptions(; format = "mp4", framerate = 24, compression = nothing, profile = nothing, pixel_format = nothing, loop = nothing, loglevel = "quiet", input = "pipe:0", rawvideo = true)
    return VideoStreamOptions(format, framerate, compression, profile, pixel_format, loop, loglevel, input, rawvideo)
end

function to_ffmpeg_cmd(vso::VideoStreamOptions, xdim::Integer = 0, ydim::Integer = 0)
    # explanation of ffmpeg args. note that the order of args is important; args pertaining
    # to the input have to go before -i and args pertaining to the output have to go after.
    # -y: "yes", overwrite any existing without confirmation
    # -f: format is raw video (from frames)
    # -framerate: set the input framerate
    # -pixel_format: the buffer we're sending ffmpeg via stdin contains rgb24 pixels
    # -s:v: sets the dimensions of the input to xdim × ydim
    # -i: read input from stdin (pipe:0)
    # -vf: video filter for the output
    # -c:v, -c:a: video and audio codec, respectively
    # -b:v, -b:a: video and audio bitrate, respectively
    # -crf: "constant rate factor", the lower the better the quality (0 is lossless, 51 is
    #   maximum compression)
    # -pix_fmt: (mp4 only) the output pixel format
    # -profile:v: (mp4 only) the output video profile
    # -an: no audio in output
    # -loop: (gif only) number of times to loop
    (format, framerate, compression, profile, pixel_format, loop) = (vso.format, vso.framerate, vso.compression, vso.profile, vso.pixel_format, vso.loop)

    cpu_cores = length(Sys.cpu_info())
    ffmpeg_prefix = `
        -y
        -loglevel $(vso.loglevel)
        -threads $(cpu_cores)`
    # options for raw video input via pipe
    if vso.rawvideo
        ffmpeg_prefix = `
            $ffmpeg_prefix
            -framerate $(framerate)
            -pixel_format rgb24
            -f rawvideo`
    end
    xdim > 0 && ydim > 0 && (ffmpeg_prefix = `$ffmpeg_prefix -s:v $(xdim)x$(ydim)`)
    ffmpeg_prefix = `$ffmpeg_prefix -r $(framerate) -i $(vso.input)`
    # Sigh, it's not easy to specify this for all
    if vso.rawvideo && format != "gif"
        ffmpeg_prefix = `$ffmpeg_prefix -vf vflip`
    end
    ffmpeg_options = if format == "mkv"
        `-an`
    elseif format == "mp4"
        `-profile:v $(profile)
         -crf $(compression)
         -preset slow
         -c:v libx264
         -pix_fmt $(pixel_format)
         -an
        `
    elseif format == "webm"
        # this may need improvement, see here: https://trac.ffmpeg.org/wiki/Encode/VP9
        `-crf $(compression)
         -c:v libvpx-vp9
         -b:v 0
         -an
        `
    elseif format == "gif"
        # from https://superuser.com/a/556031
        # avoids creating a PNG file of the palette
        if vso.rawvideo
            `-vf "vflip,fps=$(framerate),scale=$(xdim):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop $(loop)`
        else
            `-vf "fps=$(framerate),scale=$(xdim):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop $(loop)`
        end
    else
        error("Video type $(format) not known")
    end

    return `$(ffmpeg_prefix) $(ffmpeg_options)`
end

mutable struct TickController
    tick::Observable{Tick}
    frame_counter::Int
    frame_time::Float64
    filter_ticks::Bool
    filter_callback::Observables.ObserverFunction
end

function TickController(figlike, frametime, filter = true)
    tick = events(figlike).tick
    cb = if filter
        on(tick -> Consume(tick.state != OneTimeRenderTick), tick, priority = typemax(Int))
    else
        on(tick -> nothing, tick, priority = typemax(Int))
    end
    controller = TickController(tick, 0, frametime, filter, cb)
    finalizer(stop!, controller)
    next_tick!(controller)
    return controller
end

function next_tick!(controller::TickController)
    controller.tick[] = Tick(
        OneTimeRenderTick,
        controller.frame_counter,
        controller.frame_counter * controller.frame_time,
        controller.frame_time
    )
    controller.frame_counter += 1
    return
end

stop!(controller::TickController) = off(controller.filter_callback)

mutable struct VideoStream
    io::Base.PipeEndpoint
    process::Base.Process
    screen::MakieScreen
    tick_controller::TickController
    buffer::Matrix{RGB{N0f8}}
    path::String
    options::VideoStreamOptions
end

"""
    VideoStream(fig::FigureLike;
            format="mp4", framerate=24, compression=nothing, profile=nothing, pixel_format=nothing, loop=nothing,
            loglevel="quiet", visible=false, connect=false, filter_ticks=true, backend=current_backend(),
            screen_config...)

Returns a `VideoStream` which can pipe new frames into the ffmpeg process with few allocations via [`recordframe!(stream)`](@ref).
When done, use [`save(path, stream)`](@ref) to write the video out to a file.

# Arguments

## Video options

$(Base.doc(VideoStreamOptions))

## Backend options

* `backend=current_backend()`: backend used to record frames
* `visible=false`: make window visible or not
* `connect=false`: connect window events or not
* `screen_config...`: See `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options that can be passed and forwarded to the backend.

## Other

* `filter_ticks`: When true, tick events other than `tick.state = Makie.OneTimeRenderTick` are removed until `save()` is called or the VideoStream object gets deleted.
"""
function VideoStream(
        fig::FigureLike;
        format = "mp4", framerate = 24, compression = nothing, profile = nothing, pixel_format = nothing, loop = nothing,
        loglevel = "quiet", visible = false, update = true, filter_ticks = true,
        backend = current_backend(), screen_config...
    )

    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).$(format)")
    scene = get_scene(fig)
    update && update_state_before_display!(fig)
    config = Dict{Symbol, Any}(screen_config)
    get!(config, :visible, visible)
    get!(config, :start_renderloop, false)
    screen = getscreen(backend, scene, config, GLNative)
    # Use colorbuffer to get the actual dimensions for the backend,
    # since the backend might have a different size from the Monitor scaling.
    # In case of WGLMakie, this isn't easy to find out otherwise,
    # So for now we just use colorbuffer until we have a reliable pixel_size(screen) function.
    first_frame = colorbuffer(screen)
    _ydim, _xdim = size(first_frame)
    xdim = iseven(_xdim) ? _xdim : _xdim + 1
    ydim = iseven(_ydim) ? _ydim : _ydim + 1
    buffer = Matrix{RGB{N0f8}}(undef, xdim, ydim)
    vso = VideoStreamOptions(format, framerate, compression, profile, pixel_format, loop, loglevel, "pipe:0", true)
    cmd = to_ffmpeg_cmd(vso, xdim, ydim)
    # a plain `open` without the `pipeline` causes hangs when IOCapture.capture closes over a function that creates
    # a `VideoStream` without closing the process explicitly, such as when returning `Record` in a cell in Documenter or quarto
    process = open(pipeline(`$(FFMPEG_jll.ffmpeg()) $cmd $path`; stdout = devnull, stderr = devnull), "w")
    tick_controller = TickController(fig, 1.0 / vso.framerate, filter_ticks)
    result = VideoStream(process.in, process, screen, tick_controller, buffer, abspath(path), vso)
    finalizer(result) do x
        @async rm(x.path; force = true)
        stop!(x.tick_controller)
    end
    return result
end

"""
    recordframe!(io::VideoStream)

Adds a video frame to the VideoStream `io`.
"""
function recordframe!(io::VideoStream)
    glnative = colorbuffer(io.screen, GLNative)
    # Make no copy if already Matrix{RGB{N0f8}}
    # There may be a 1px padding for odd dimensions
    xdim, ydim = size(glnative)
    if eltype(glnative) == eltype(io.buffer) && size(glnative) == size(io.buffer)
        write(io.io, glnative)
    else
        copy!(view(io.buffer, 1:xdim, 1:ydim), glnative)
        write(io.io, io.buffer)
    end
    next_tick!(io.tick_controller)
    return
end

"""
    save(path::String, io::VideoStream)

Flushes the video stream and saves it to `path`. Ideally, `path`'s file extension is the same as
the format that the `VideoStream` was created with (e.g., if created with format "mp4" then
`path`'s file extension must be ".mp4"). Otherwise, the video will get converted to the target format.
If using [`record`](@ref) then this is handled for you,
as the `VideoStream`'s format is deduced from the file extension of the path passed to `record`.
"""
function save(path::String, io::VideoStream; video_options...)
    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    video_fmt = io.options.format
    if typ != ".$(video_fmt)" || !isempty(video_options)
        # Maybe warn?
        convert_video(io.path, path; video_options...)
    else
        cp(io.path, path; force = true)
    end
    return path
end

function convert_video(input_path, output_path; video_options...)
    p, typ = splitext(output_path)
    format = lstrip(typ, '.')
    vso = VideoStreamOptions(; format = format, input = input_path, rawvideo = false, video_options...)
    cmd = to_ffmpeg_cmd(vso)
    return run(`$(FFMPEG_jll.ffmpeg()) $cmd $output_path`)
end

function extract_frames(video, frame_folder; loglevel = "quiet")
    path = joinpath(frame_folder, "frame%04d.png")
    return run(`$(FFMPEG_jll.ffmpeg()) -loglevel $(loglevel) -i $video -y $path`)
end
