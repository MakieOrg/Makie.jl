function detach_parent!(gl::GridLayout)
    detach_parent!(gl, gl.parent)
    nothing
end

function detach_parent!(gl::GridLayout, parent::Scene)
    if isnothing(gl._update_func_handle)
        error("Trying to detach a Scene parent, but there is no update_func_handle. This must be a bug.")
    end
    Observables.off(pixelarea(parent), gl._update_func_handle)
    gl._update_func_handle = nothing
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::Node{<:Rect2D})
    if isnothing(gl._update_func_handle)
        error("Trying to detach a Rect Node parent, but there is no update_func_handle. This must be a bug.")
    end
    Observables.off(parent, gl._update_func_handle)
    gl._update_func_handle = nothing
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::GridLayout)
    if !isnothing(gl._update_func_handle)
        error("Trying to detach a GridLayout parent, but there is an update_func_handle. This must be a bug.")
    end
    gl.parent = nothing
    nothing
end

function detach_parent!(gl::GridLayout, parent::Nothing)
    if !isnothing(gl._update_func_handle)
        error("Trying to detach a Nothing parent, but there is an update_func_handle. This must be a bug.")
    end
    nothing
end

function attach_parent!(gl::GridLayout, parent::Scene)
    detach_parent!(gl)
    gl._update_func_handle = on(pixelarea(parent)) do px
        request_update(gl)
    end
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::Nothing)
    detach_parent!(gl)
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::GridLayout)
    detach_parent!(gl)
    gl.parent = parent
    nothing
end

function attach_parent!(gl::GridLayout, parent::Node{<:Rect2D})
    detach_parent!(gl)
    gl._update_func_handle = on(parent) do rect
        request_update(gl)
    end
    gl.parent = parent
    nothing
end

function request_update(gl::GridLayout)
    if !gl.block_updates
        request_update(gl, gl.parent)
    end
end

function request_update(gl::GridLayout, parent::Nothing)
    error("The GridLayout has no parent and therefore can't request an update.")
end

function request_update(gl::GridLayout, parent::Scene)
    sg = solve(gl, BBox(pixelarea(parent)[]))
    applylayout(sg)
end

function request_update(gl::GridLayout, parent::Node{<:Rect2D})
    sg = solve(gl, BBox(parent[]))
    applylayout(sg)
end

function request_update(gl::GridLayout, parent::GridLayout)
    parent.needs_update[] = true
end
