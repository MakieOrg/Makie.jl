
struct SpriteElem{N,T}
    offset::Vec{2,T}
    uv_offset_width::Vec{4,T}
    position::Point{N, T}
    color::RGBA{Float32}
    scale::Vec{2,T}
end
mutable struct Text
    offsets
    uv_offset_width
    positions
    colors
    scales
    rotations
    atlas
end
Base.length(rt::Text) = length(rt.positions)
function Base.sizehint!(t::Text, size::Int)
    for elem in (:positions, :colors, :scales, :uv_offset_width, :offsets, :rotations)
        field = getfield(t, elem)
        if isa(field, AbstractArray) # all fields can be scalars
            sizehint!(field, size)
        end
    end
    nothing
end
function Base.resize!(t::Text, size::Int)
    for elem in (:positions, :colors, :scales, :uv_offset_width, :offsets, :rotations)
        field = getfield(t, elem)
        if isa(field, AbstractArray)
            resize!(field, size)
        end
    end
    nothing
end
function Base.setindex!(t::Text, value::NTuple{6}, i::Integer)
    char, offset, position, color, scale, rotation = value
    gs = GLVisualize.glyph_scale!(t.atlas, char, GLVisualize.defaultfont())
    guvw = GLVisualize.glyph_uv_width!(t.atlas, char, GLVisualize.defaultfont())
    t.offsets[i] = offset
    t.uv_offset_width[i] = guvw
    t.positions[i] = position
    t.colors[i] = color
    t.scales[i] = gs .* Vec2f0(scale)
    t.rotations[i] = rotation
    nothing
end

function Base.setindex!(t::Text, value::Char, i::Integer)
    gs = GLVisualize.glyph_scale!(rt.text.atlas, c, GLVisualize.defaultfont())
    guvw = GLVisualize.glyph_uv_width!(rt.text.atlas, c, GLVisualize.defaultfont())
    t.uv_offset_width[i] = guvw
    t.scales[i] = gs
end

function Base.setindex!(t::Text, value::Associative, i::Integer)
    for (k,v) in value
        getfield(t, k)[i] = v
    end
end
function Base.setindex!(t::Text, value::SpriteElem, i::Integer)
    for f=1:5
        getfield(t, f)[i] = getfield(value, f)
    end
end
function Text(robj::RenderObject)
    @materialize atlas, offset, uv_offset_width, position, color, scale, rotation = robj.uniforms
    text = Text(
        offset,
        uv_offset_width,
        position,
        color,
        scale,
        rotation,
        atlas
    )
end
mutable struct RichText
    text::Text
    inlined_objects::Vector
    links::Vector
    cursor
    defaults::Dict
end
function RichText(text::Text)
    style_default = Dict(
        :color => RGBA{Float32}(0,0,0,1),
        :scale => Vec2f0(1),
        :font => GLVisualize.defaultfont()
    )
    RichText(text, [], [], 0:1, style_default)
end

function Base.sizehint!(t::RichText, size::Int)
    sizehint!(t.text, size)
    nothing
end
function Base.resize!(t::RichText, size::Int)
    resize!(t.text, size)
    nothing
end
Base.length(rt::RichText) = length(rt.text)
make_iter(x) = repeated(x)
make_iter(x::AbstractArray) = x

function get_iter(defaultfunc, dictlike, key)
    make_iter(get(defaultfunc, dictlike, key))
end


function getposition(text, text2, fonts, scales, start_pos)
    GLVisualize.calc_position(text2, start_pos, scales, fonts, text.text.atlas)
end
function getoffsets(text, text2, fonts, scales)
    GLVisualize.calc_offset(text2, scales, fonts, text.text.atlas)
end
font_color(text::RichText) = text.defaults[:color]
font(text::RichText) = text.defaults[:font]
font_size(text::RichText) = text.defaults[:scale]
"""
Inserts text at [`position`] with `style`
"""
function Base.insert!(text::RichText, text2::AbstractString, position=text.cursor, style=text.defaults)
    fonts     = get_iter(()->font(text), style, :font)
    scales    = get_iter(()->font_size(text), style, :scale)
    start_pos = get(style, :start_position, text.text.positions[max(last(text.cursor), 1)])
    positions = get_iter(()->getposition(text, text2, fonts, scales, start_pos), style, :position)
    offsets   = get_iter(()->getoffsets(text, text2, fonts, scales), style, :offset)
    colors    = get_iter(()->font_color(text), style, :color)
    rotation  = get_iter(()->Vec3f0(0,0,1), style, :rotation)

    pos = max(last(text.cursor), 1)
    if pos + length(text2) > length(text)
        resize!(text, pos + length(text2))
    end
    for elem in zip(text2, offsets, positions, colors, scales, rotation)
        text.text[pos] = elem
        pos += 1
    end
    nothing
end


iter_or_array(x) = repeated(x)
iter_or_array(x::Repeated) = x
iter_or_array(x::Array) = x
iter_or_array(x::Vector{Ptr{FreeType.FT_FaceRec}}) = repeated(x)

function calc_position(
        last_pos, start_pos,
        atlas, glyph, font,
        scale, lineheight = 1.5
    )
    advance_x, advance_y = glyph_advance!(atlas, glyph, font, scale)
    if isnewline(glyph)
        return Point2f0(start_pos[1], last_pos[2] - advance_y * lineheight) #reset to startx
    else
        return last_pos + Point2f0(advance_x, 0)
    end
end
function calc_position(glyphs, start_pos, scales, fonts, atlas)
    positions = zeros(Point2f0, length(glyphs))
    last_pos  = Point2f0(start_pos)
    s, f = iter_or_array(scales), iter_or_array(fonts)
    c1 = first(glyphs)
    for (i, (c2, scale, font)) in enumerate(zip(glyphs, s, f))
        c2 == '\r' && continue # stupid windows!
        positions[i] = last_pos
        last_pos = calc_position(last_pos, start_pos, atlas, c2, font, scale)
        #k = FreeTypeAbstraction.kerning(c1, c2, font, scale)
        #last_pos += k # add kerning
    end
    positions
end

function calc_offset(glyphs, scales, fonts, atlas)
    offsets = fill(Point2f0(0.0), length(glyphs))
    s, f = iter_or_array(scales), iter_or_array(fonts)
    c1 = first(glyphs)
    for (i, (c2, scale, font)) in enumerate(zip(glyphs, s, f))
        c2 == '\r' && continue # stupid windows!
        offsets[i] = Point2f0(glyph_bearing!(atlas, c2, font, scale))
        c1 = c2
    end
    offsets # bearing is the glyph offset
end

isnewline(x) = x == '\n'
# i must be a valid character index
function next_newline(text, i::Integer)
    res = findnext(isnewline, text, i)
    res == 0 ? length(text) : res #jump to end of text if no newline found
end
previous_newline(text, i::Integer) = max(1, findprev(isnewline, text, i)) #jump to start

export previous_newline, next_newline

#=
textextetext\n
texttext<current pos>texttext\n
texttext<finds this pos>text\n
=#
function down_after_newline(text, current_position)
    i     = current_position
    pnl = previous_newline(text, i)
    nnl = next_newline(text, i)
    nl_distance = i-pnl # distance from previous newline
    min(length(text), nnl+nl_distance)
end
#=
textexte<finds this pos>text\n
texttext<current pos>texttext\n
texttexttext\n
=#
function up_before_newline(text, current_position)
    i      = current_position
    pnl  = previous_newline(text, i)
    ppnl = previous_newline(text, max(1, pnl-1))
    nl_distance = i-pnl # distance from previous newline
    min(length(text), ppnl+nl_distance)
end

function next_arrow_selection(dir, text, first_index, last_index)
    (dir == :up)    && return up_before_newline(text, first_index)
    (dir == :down)  && return down_after_newline(text, last_index)
    (dir == :left)  && return max(1, first_index-1)
    (dir == :right) && return min(length(text)+1, last_index+1)
    -1
end
function move_cursor(t0, dir, mouseselection, text_selection, is_movingselection)
    text, selection = text_selection.text, text_selection.selection
    mouseselection0, selection0 = t0
    selection0 = selection
    mouseselection0 != mouseselection && return (mouseselection, mouseselection) # if mouse selection has changed, return the new position
    if selection0 != 0:0
        first_i   = first(selection0) # first is always valid, if its not zero
        # last is not valid, if selection is in between characters
        last_i    = isempty(selection0) ? first(selection0) : last(selection0) # if only single char selected use first, otherwise last position of selection
        nas       = next_arrow_selection(dir, text, first_i, last_i) # -1 for no new arrow selection
        if nas != -1
            if is_movingselection
                return (mouseselection, nas:last_i)
            else
                return (mouseselection, nas:0)
            end
        end
    end
    (mouseselection0, selection0)
end
#
#
# immutable TextCursor
#     selections::Vector{UnitRange}
# end
# type Text{T <: Integer}
#     text::Vector{T}
# end
# function Base.setindex!(text, index::TextCursor, newtext)
#     for selection in index.selections
#
#     end
# end
deletetext(_, text_selection) = deletetext(text_selection)
function deletetext(text_selection)
    selection, text = text_selection.selection, text_selection.text
    offset = 0
    if first(selection) > 0 && last(selection) > 0
        if single_selection(selection)
            splice!(text, last(selection))
            offset = -1
        else
            splice!(text, selection)
        end
        text_selection.selection = max(1, first(selection)+offset):0 # when text gets removed, selection will turn into single selection
    end
    nothing
end
export inserttext

function inserttext(text_selection, to_insert)
    selection, text = text_selection.selection, text_selection.text
    if first(selection) > 0 && first(selection) <= length(text)
        splice!(text, selection, to_insert)
        chars_added = length(to_insert)
        text_selection.selection = (first(selection)+chars_added):0 # when text gets removed, selection will turn into single selection
    end
    nothing
end


function insert_text(text, cursor, new_text)
    text[cursor] = new_text
    push!(text, text)
    push!(cursor, text)
end

function selection_click(index)

    push!(cursor, )
end
function selection_drag(index)
    push!(cursor.selection, index)
    push!(cursor, )
end
function selection_add(cursor, selection)
    push!(cursor.selection, selection)
end
function selection_reset(cursor)
    push!(cursor)
end

function textedit_signals(inputs, background, text)
    @materialize unicodeinput, selection, buttonspressed, arrow_navigation, mousedragdiff_objectid = inputs
    # create object which can globally hold the text and selection
    text_raw    = TextWithSelection(text[:glyphs], 0:0)
    text_edit   = Signal(text_raw)
    shift       = const_lift(in, GLFW.KEY_LEFT_SHIFT, buttonspressed)
    selection   = preserve(const_lift(
        last,
        foldp(
            move_cursor,
            (selection.value, selection.value),
            arrow_navigation, selection,
            text_edit,
            shift
        )
    ))

    is_text(x) = x[2][1] == background.id || x[2][1] == text.id
    selection  = filterwhen(
        const_lift(is_text, mousedragdiff_objectid),
        0:0, selection
    )
    preserve(const_lift(s->(text_edit.value.selection=s), selection)) # is there really no other way?!

    strg_v          = const_lift(==, buttonspressed, Config.shortcuts["paste"])
    strg_c          = const_lift(==, buttonspressed, Config.shortcuts["copy"])
    strg_x          = const_lift(==, buttonspressed, Config.shortcuts["cut"])
    enter_key       = const_lift(==, buttonspressed, [GLFW.KEY_ENTER])
    del             = const_lift(==, buttonspressed, [GLFW.KEY_BACKSPACE])

    enter_insert    = const_lift(insert_enter,   filterwhen(enter_key, true, enter_key))
    clipboard_copy  = const_lift(copyclipboard,  filterwhen(strg_c,    true, strg_v), text_edit)

    delete_text     = const_lift(deletetext,     filterwhen(del,       true, del),    text_edit)
    cut_text        = const_lift(cutclipboard,   filterwhen(strg_x,    true, strg_x), text_edit)

    clipboard_paste = const_lift(clipboardpaste, filterwhen(strg_v,    true, strg_v))

    text_gate       = const_lift(isnotempty, unicodeinput)
    unicode_input   = filterwhen(text_gate, Char['0'], unicodeinput)
    text_to_insert  = merge(clipboard_paste, unicode_input, enter_insert)
    text_to_insert  = const_lift(process_for_gl, text_to_insert)

    text_inserted   = const_lift(inserttext, text_edit, text_to_insert)

    text_updates    = merge(
        const_lift(return_nothing, text_inserted),
        const_lift(return_nothing, clipboard_copy),
        const_lift(return_nothing, delete_text),
        const_lift(return_nothing, cut_text),
        const_lift(return_nothing, selection)
    )
    text_selection_signal = sampleon(text_updates, text_edit)

    selection   = const_lift(x->x.selection,  text_selection_signal)
    text_sig    = const_lift(x->x.text,       text_selection_signal)

    preserve(const_lift(update_positions, text_sig, Signal(text), Signal(background[:style_index])))
    preserve(foldp(visualize_selection, 0:0, selection,    Signal(background[:style_index])))
    const_lift(String, text_sig), selection
end


"""
Displayes an array of points with text labels. This should get moved into GLVisualize!
usage:
```
    points = Signal(Point2f0[(0, 0), (100, 100), (200, 200)]) # Doesn't need to be a signal
    labels = Signal(["label", "string", "α ∧ ¬β"]) # Doesn't need to be a signal
    annotated_text(points, labels)
```
"""
function annotated_text(
        points, labels_s;
        color = RGBA(0f0,0f0,0f0,1f0),
        scale = 5mm,
        base_offset = Point2f0(scale / 2)
    )
    # make this work for Signal(points) as well as constant points
    points_s = isa(points, Signal) ? points : Signal(points)
    font, atlas = GLVisualize.defaultfont(), GLVisualize.get_texture_atlas()
    # to display a text particle system, one needs
    # 1, glyph segmentation_centroids, offset to the bottom, position in the texture atlas
    # and the scale of the glyph. Then for bg labels, we also save a width
    v0 = (Point2f0[], Point2f0[], Vec4f0[], Vec2f0[], Vec2f0[])
    text = map(points_s) do points
        labels = value(labels_s)
        if length(labels) != length(points)
            error("""
                Colors, labels and points must have the same length! Found:
                Points: $(length(points)), labels: $(length(labels))""")
        end
        n = mapreduce(length, +, labels)
        rpoints, offsets, uv_widths, scales, widths = v0
        if length(labels) != length(widths)
            resize!(widths, length(labels))
        end
        if n != length(rpoints) # only resize if size changed
            resize!(rpoints, n); resize!(offsets, n)
            resize!(uv_widths, n); resize!(scales, n)
        end
        idx = 1
        # glyph height of a long glyph
        glyph_height = glyph_scale!(atlas, '|', font, scale)[2]
        for (i, (start_pos, label)) in enumerate(zip(points, labels))
            last_pos = start_pos .+ base_offset
            for c in label # calculate segmentation_centroids for each character/glyph
                rpoints[idx] = last_pos
                last_pos = calc_position(last_pos, start_pos, atlas, c, font, scale)
                offsets[idx] = glyph_bearing!(atlas, c, font, scale)
                uv_widths[idx] = glyph_uv_width!(atlas, c, font)
                scales[idx] = glyph_scale!(atlas, c, font, scale)
                idx += 1
            end
            # calculate label lengths + extra width
            widths[i] = Vec2f0(last_pos[1] - start_pos[1] + 1mm, glyph_height + 1mm)
        end
        rpoints, offsets, uv_widths, scales, widths
    end
    viz = visualize(
        (DISTANCEFIELD, map(x->x[1], text)), # render segmentation_centroids as a distance field particle type
        offset = map(x->x[2], text),
        uv_offset_width = map(x->x[3], text),
        scale = map(x->x[4], text),
        color = color,
        # drop down to low level opengl, to always render over image! (there should be a better API for this)
        prerender = () -> begin
            glDisable(GL_DEPTH_TEST)
            glDepthMask(GL_TRUE)
            glDisable(GL_CULL_FACE)
            enabletransparency()
        end,
        distancefield = atlas.images
    )
    viz, map(last, text) # return viz and widths
end

# # i must be a valid character index
# function next_newline(text, i::Integer)
#     res = findnext(isnewline, text, i)
#     res == 0 ? length(text) : res
# end
# previous_newline(text, i::Integer) = max(1, findprev(isnewline, text, i))
#
# export previous_newline
# export next_newline
#
#
#
# #=
# textextetext\n
# texttext<current pos>texttext\n
# texttext<finds this pos>text\n
# =#
# function down_after_newline(text, current_position)
#     i     = current_position
#     pnl = previous_newline(text, i)
#     nnl = next_newline(text, i)
#     nl_distance = i-pnl # distance from previous newline
#     min(length(text), nnl+nl_distance)
# end
# #=
# textexte<finds this pos>text\n
# texttext<current pos>texttext\n
# texttexttext\n
# =#
# function up_before_newline(text, current_position)
#     i      = current_position
#     pnl  = previous_newline(text, i)
#     ppnl = previous_newline(text, max(1, pnl-1))
#     nl_distance = i-pnl # distance from previous newline
#     min(length(text), ppnl+nl_distance)
# end
#
# function next_arrow_selection(dir, text, first_index, last_index)
#     (dir == :up)    && return up_before_newline(text, first_index)
#     (dir == :down)  && return down_after_newline(text, last_index)
#     (dir == :left)  && return max(1, first_index-1)
#     (dir == :right) && return min(length(text)+1, last_index+1)
#     -1
# end
#
# function move_cursor(t0, dir, mouseselection, text_selection, is_movingselection)
#     text, selection = text_selection.text, text_selection.selection
#     mouseselection0, selection0 = t0
#     selection0 = selection
#     mouseselection0 != mouseselection && return (mouseselection, mouseselection) # if mouse selection has changed, return the new position
#     if selection0 != 0:0
#         first_i   = first(selection0) # first is always valid, if its not zero
#         # last is not valid, if selection is in between characters
#         last_i    = isempty(selection0) ? first(selection0) : last(selection0) # if only single char selected use first, otherwise last position of selection
#         nas       = next_arrow_selection(dir, text, first_i, last_i) # -1 for no new arrow selection
#         if nas != -1
#             if is_movingselection
#                 return (mouseselection, nas:last_i)
#             else
#                 return (mouseselection, nas:0)
#             end
#         end
#     end
#     (mouseselection0, selection0)
# end
# export move_cursor
#
#
# function visualize_selection(
#         last_selection::UnitRange{Int},
#         selection       ::UnitRange{Int},
#         style           ::GPUVector{GLSpriteStyle}
#     )
#     fl, ll =  first(last_selection), last(last_selection)
#     if !isempty(last_selection) && fl > 0 && ll > 0 && (fl <= length(style)) && (ll <= length(style))
#         style[last_selection] = fill(GLSpriteStyle(0,0), length(last_selection))
#     end
#     fs, ls =  first(selection), last(selection)
#     if !isempty(selection) && fs > 0 && ls > 0 && (fs <= length(style)) && (ls <= length(style))
#         style[selection] = fill(GLSpriteStyle(1,0), length(selection))
#     end
#     selection
# end
#
#
# AND(a,b)       = a&&b
# isnotempty(x) = !isempty(x)
# return_nothing(x...) = nothing
# export AND
# export isnotempty
# export return_nothing
#
# single_selection(selection::UnitRange)     = isempty(selection) && first(selection)!=0
# is_textinput_modifiers(buttons::Vector{Int}) = isempty(buttons) || buttons == [GLFW.KEY_LEFT_SHIFT]
#
# function clipboardpaste(_)
#     clipboard_data = ""
#     try
#         clipboard_data = clipboard()
#     catch e # clipboard throws error when there is no data (WTF)
#     end
#     return String(clipboard_data)
# end
#
# export clipboardpaste
# export copyclipboard
#
# function back2julia(x::GLSprite)
#     isnewline(x[1]) && return '\n'
#     ID_TO_CHAR[x[1]]
# end
# function String(v::GPUVector{GLSprite})
#     data = gpu_data(v)
#     String(join(map(back2julia, data)))
# end
# # const_lift will have a boolean value at first argument position
# copyclipboard(_, text_selection) = copyclipboard(text_selection)
# function copyclipboard(text_selection)
#     selection, text = text_selection.selection, text_selection.text
#     if first(selection) > 0
#         if single_selection(selection) # for single selection we do a sublime style line copy
#             #i     = chr2ind(text, first(selection))
#             i     = min(length(text), first(selection)) # can be on position behind last character
#             pnl = previous_newline(text, i)
#             nnl = next_newline(text, i)
#             tocopy = text[pnl:nnl]
#         else # must be range selection
#             tocopy = text[selection]
#         end
#         clipboard(join(map(x->ID_TO_CHAR[x[1]], tocopy)))
#     end
#     nothing
# end
# export cutclipboard
# cutclipboard(_, text_selection) = cutclipboard(text_selection)
# function cutclipboard(text_selection)
#     copyclipboard(text_selection)
#     deletetext(text_selection)
#     nothing
# end
# export deletetext
# deletetext(_, text_selection) = deletetext(text_selection)
# function deletetext(text_selection)
#     selection, text = text_selection.selection, text_selection.text
#     offset = 0
#     if first(selection) > 0 && last(selection) > 0
#         if single_selection(selection)
#             splice!(text, last(selection))
#             offset = -1
#         else
#             splice!(text, selection)
#         end
#         text_selection.selection = max(1, first(selection)+offset):0 # when text gets removed, selection will turn into single selection
#     end
#     nothing
# end
# export inserttext
# inserttext(_, text_selection) = inserttext(text_selection)
# function inserttext(text_selection, to_insert)
#     selection, text = text_selection.selection, text_selection.text
#     if first(selection) > 0 && first(selection) <= length(text)
#         splice!(text, selection, to_insert)
#         chars_added = length(to_insert)
#         text_selection.selection = (first(selection)+chars_added):0 # when text gets removed, selection will turn into single selection
#     end
#     nothing
# end
#
# type TextWithSelection{S } #<: AbstractString}
#     text::S
#     selection::UnitRange{Int}
# end
# export TextWithSelection
#
#
#
#
# export visualize_selection
