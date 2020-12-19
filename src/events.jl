macro handle(accessor, body)
    obj, field = accessor.args
    key = string(field.value)
    efield = esc(field.value)
    obj = esc(obj)
    return quote
        if haskey($(obj), $(key))
            $(efield) = $(obj)[$(key)]
            $(esc(body))
            return nothing
        end
    end
end

function code_to_keyboard(code::String)
    if length(code) == 1 && isnumeric(code[1])
        return getfield(Keyboard, Symbol("_" * code))
    end
    button = lowercase(code)
    if startswith(button, "arrow")
        return getfield(Keyboard, Symbol(button[6:end]))
    end
    if startswith(button, "digit")
        return getfield(Keyboard, Symbol("_" * button[6:end]))
    end
    if startswith(button, "key")
        return getfield(Keyboard, Symbol(button[4:end]))
    end
    button = replace(button, r"(.*)left" => s"left_\1")
    button = replace(button, r"(.*)right" => s"right_\1")
    sym = Symbol(button)
    return if isdefined(Keyboard, sym)
        return getfield(Keyboard, sym)
    elseif sym == :backquote
        return Keyboard.grave_accent
    elseif sym == :pageup
        return Keyboard.page_up
    elseif sym == :pagedown
        return Keyboard.page_down
    elseif sym == :end
        return Keyboard._end
    elseif sym == :capslock
        return Keyboard.caps_lock
    elseif sym == :contextmenu
        return Keyboard.menu
    else
        return Keyboard.unknown
    end
end

function connect_scene_events!(session::Session, scene::Scene, comm::Observable)
    e = events(scene)
    on(comm) do msg
        @handle msg.mouseposition begin
            x, y = Float64.((mouseposition...,))
            e.mouseposition[] = (x, size(scene)[2] - y)
        end
        @handle msg.mousedown begin
            set = e.mousebuttons[]
            empty!(set)
            mousedown & 1 != 0 && push!(set, Mouse.left)
            mousedown & 2 != 0 && push!(set, Mouse.right)
            mousedown & 4 != 0 && push!(set, Mouse.middle)
            e.mousebuttons[] = set
        end
        @handle msg.mouseup begin
            set = e.mousebuttons[]
            empty!(set)
            mouseup & 1 != 0 && push!(set, Mouse.left)
            mouseup & 2 != 0 && push!(set, Mouse.right)
            mouseup & 4 != 0 && push!(set, Mouse.middle)
            e.mousebuttons[] = set
        end
        @handle msg.scroll begin
            e.scroll[] = Float64.((sign.(scroll)...,))
        end
        @handle msg.keydown begin
            set = e.keyboardbuttons[]
            button = code_to_keyboard(keydown)
            # don't add unknown buttons...we can't work with them
            # and they won't get removed
            if button != Keyboard.unknown
                push!(set, button)
                e.keyboardbuttons[] = set
            end
        end
        @handle msg.keyup begin
            set = e.keyboardbuttons[]
            if keyup == "delete_keys"
                empty!(set)
            else
                delete!(set, code_to_keyboard(keyup))
            end
            e.keyboardbuttons[] = set
        end
        return
    end
    return
end

function AbstractPlotting.pick(scene::Scene, THREE::ThreeDisplay, xy::Vec{2,Float64})
    return @warn "Picking not supported yet by WGLMakie"
end
