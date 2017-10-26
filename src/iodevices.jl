
module Keyboard

    @enum(Button,
            unknown            = -1,
            # printable keys,
            space              = 32,
            apostrophe         = 39,  # ',
            comma              = 44,  # ,,
            minus              = 45,  # -,
            period             = 46,  # .,
            slash              = 47,  # /,
            _0                  = 48,
            _1                  = 49,
            _2                  = 50,
            _3                  = 51,
            _4                  = 52,
            _5                  = 53,
            _6                  = 54,
            _7                  = 55,
            _8                  = 56,
            _9                  = 57,
            semicolon          = 59,  # ;,
            equal              = 61,  # =,
            a                  = 65,
            b                  = 66,
            c                  = 67,
            d                  = 68,
            e                  = 69,
            f                  = 70,
            g                  = 71,
            h                  = 72,
            i                  = 73,
            j                  = 74,
            k                  = 75,
            l                  = 76,
            m                  = 77,
            n                  = 78,
            o                  = 79,
            p                  = 80,
            q                  = 81,
            r                  = 82,
            s                  = 83,
            t                  = 84,
            u                  = 85,
            v                  = 86,
            w                  = 87,
            x                  = 88,
            y                  = 89,
            z                  = 90,
            left_bracket       = 91,  # [,
            backslash          = 92,  # ,
            right_bracket      = 93,  # ],
            grave_accent       = 96,  # `,
            world_1            = 161, # non-us #1,
            world_2            = 162, # non-us #2,
            # function keys,
            escape             = 256,
            enter              = 257,
            tab                = 258,
            backspace          = 259,
            insert             = 260,
            delete             = 261,
            right              = 262,
            left               = 263,
            down               = 264,
            up                 = 265,
            page_up            = 266,
            page_down          = 267,
            home               = 268,
            _end               = 269,
            caps_lock          = 280,
            scroll_lock        = 281,
            num_lock           = 282,
            print_screen       = 283,
            pause              = 284,
            f1                 = 290,
            f2                 = 291,
            f3                 = 292,
            f4                 = 293,
            f5                 = 294,
            f6                 = 295,
            f7                 = 296,
            f8                 = 297,
            f9                 = 298,
            f10                = 299,
            f11                = 300,
            f12                = 301,
            f13                = 302,
            f14                = 303,
            f15                = 304,
            f16                = 305,
            f17                = 306,
            f18                = 307,
            f19                = 308,
            f20                = 309,
            f21                = 310,
            f22                = 311,
            f23                = 312,
            f24                = 313,
            f25                = 314,
            kp_0               = 320,
            kp_1               = 321,
            kp_2               = 322,
            kp_3               = 323,
            kp_4               = 324,
            kp_5               = 325,
            kp_6               = 326,
            kp_7               = 327,
            kp_8               = 328,
            kp_9               = 329,
            kp_decimal         = 330,
            kp_divide          = 331,
            kp_multiply        = 332,
            kp_subtract        = 333,
            kp_add             = 334,
            kp_enter           = 335,
            kp_equal           = 336,
            left_shift         = 340,
            left_control       = 341,
            left_alt           = 342,
            left_super         = 343,
            right_shift        = 344,
            right_control      = 345,
            right_alt          = 346,
            right_super        = 347,
            menu               = 348,
    )

end

"""
Backend independant Mouse enums and fields
"""
module Mouse
    using Base: @enum
    @enum Button left = 0 middle = 2 right = 1 # Be GLFW conform
    @enum DragEnum down up pressed notpressed
end



button_key{T}(x::Type{T}) = error("Must be a keyboard or mouse button. Found: $T")
button_key(x::Type{Keyboard.Button}) = :keyboardbuttons
button_key(x::Type{Mouse.Button}) = :mousebuttons
button_key{T}(x::Set{T}) = button_key(T)
button_key{T}(x::T) = button_key(T)

"""
returns true if `button` is pressed in scene[:mousebuttons or :keyboardbuttons]
"""
function ispressed(scene::Scene, button)
    buttons = to_value(scene, button_key(button))
    if isa(button, Set)
        return buttons == button
    else
        return length(buttons) == 1 && first(buttons) == button
    end
end



function IRect(x, y, w, h)
    SimpleRectangle{Int}(round(Int, x), round(Int, y), round(Int, w), round(Int, h))
end
function IRect(xy::StaticVector, w, h)
    IRect(xy[1], xy[2], w, h)
end
function IRect(x, y, wh::StaticVector)
    IRect(x, y, wh[1], wh[2])
end
function IRect(xy::StaticVector, wh::StaticVector)
    IRect(xy[1], xy[2], wh[1], wh[2])
end
function FRect(x, y, w, h)
    SimpleRectangle{Float32}(x, y, w, h)
end
function FRect(r::SimpleRectangle)
    SimpleRectangle{Float32}(r.x, r.y, r.w, r.h)
end
function FRect(xy::StaticVector, w, h)
    SimpleRectangle{Float32}(xy[1], xy[2], w, h)
end
function FRect(x, y, wh::StaticVector)
    SimpleRectangle{Float32}(x, y, wh[1], wh[2])
end
function FRect(xy::StaticVector, wh::StaticVector)
    SimpleRectangle{Float32}(xy[1], xy[2], wh[1], wh[2])
end

export ispressed, IRect, FRect, Keyboard, Mouse