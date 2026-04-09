module MakieFFMPEGExt

import Makie
import FFMPEG_jll

Makie.ffmpeg_path() = FFMPEG_jll.ffmpeg()

end
