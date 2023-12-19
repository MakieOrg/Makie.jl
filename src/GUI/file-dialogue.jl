using NativeFileDialog_jll

function choose_file_dialogue(filter=C_NULL)
    path = Ref(Ptr{UInt8}())
    r = @ccall libnfd.NFD_OpenDialog(filter::Ptr{Cchar}, C_NULL::Ptr{Cchar},
                                     path::Ref{Ptr{UInt8}})::Cint
    if r == 2
        # User clicked "Cancel"
        out = nothing
    elseif r == 1
        out = unsafe_string(path[])
    else
        error()
    end
    return out
end

function save_file_dialogue(filter=C_NULL)
    path = Ref(Ptr{UInt8}())
    r = @ccall libnfd.NFD_SaveDialog(filter::Ptr{Cchar}, C_NULL::Ptr{Cchar},
                                     path::Ref{Ptr{UInt8}})::Cint
    if r == 2
        # User clicked "Cancel"
        out = nothing
    elseif r == 1
        out = unsafe_string(path[])
    else
        error()
    end
    return out
end
