function writebmp(io, img)
    h, w = size(img)
    filesize = 54 + sizeof(img) #w is your image width, h is image height, both int
    # How many bytes of padding to add to each
    # horizontal line - the size of which must
    # be a multiple of 4 bytes.
    extrabytes = 4 - ((w * 3) % 4)
    (extrabytes == 4) && (extrabytes = 0)
    paddedsize = ((w * 3) + extrabytes) * h;

    # file header
    write(io, b"BM")
    write(io, UInt32(paddedsize))
    write(io, UInt32(0)) # app data
    write(io, UInt32(40 + 14)) # offset

    write(io, UInt32(40))
    write(io, Int32(w))
    write(io, Int32(h))

    write(io, UInt16(1)) # number color planes
    write(io, UInt16(24)) # number color planes
    write(io, UInt32(0)) # compression is none
    write(io, UInt32(0)) # image bits size
    write(io, Int32(0)) # horz resoluition in pixel / m
    write(io, Int32(0)) # vert resolutions (0x03C3 = 96 dpi, 0x0B13 = 72 dpi)
    write(io, Int32(0)) #colors in pallete
    write(io, Int32(0)) #important colors

    for i in h:-1:1
        for j in 1:w
            @inbounds rgb = RGB{N0f8}(img[i, j])
            write(io, reinterpret(UInt8, blue(rgb)))
            write(io, reinterpret(UInt8, green(rgb)))
            write(io, reinterpret(UInt8, red(rgb)))
        end
        for i = 1:extrabytes
            write(io, UInt8(0))
        end
    end
end

using Images, Colors
using FileIO

x = load(joinpath(homedir(), "Desktop", "test.jpg"))
open("test.bmp", "w") do io
    @time writebmp(io, x)
end
