module MakieFFMPEGExt

import Makie
import FFMPEG_jll

Makie._ffmpeg_jll_path() = FFMPEG_jll.ffmpeg()

end
