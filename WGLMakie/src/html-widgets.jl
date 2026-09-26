using Bonito, WGLMakie, Colors

# Global styles for widget containers
const WIDGET_CONTAINER_STYLES = Styles(
    "position" => "absolute",
    "padding" => "0px",
    "margin" => "0px",
    "display" => "flex",
    "align-items" => "center",
    "justify-content" => "center",
    "font-family" => "'TeXGyreHerosMakie', sans-serif",
    "white-space" => "nowrap"
)

const FONT_STYLE = Styles(
    CSS(
        "@font-face",
        "font-family" => "TeXGyreHerosMakie",
        "src" => Asset(assetpath("fonts", "TeXGyreHerosMakie-Regular.otf"))
    ),
)


function resize_parent(parent, block)
    scene = Makie.rootparent(block.blockscene)
    height_box = map(block.layoutobservables.computedbbox, scene.viewport; ignore_equal_values = true) do box, vp
        (xmin, ymin), (xmax, ymax) = extrema(box)
        fig_height = vp.widths[2]  # Get figure height
        return [fig_height, xmin, ymin, xmax, ymax]
    end
    return js"""
        $(scene).then(scene => {
            const div = $(parent);
            const {canvas, winscale} = scene.screen;

            // The wrapper (canvas.parentElement) has position: relative, so widgets
            // positioned absolute will be relative to the wrapper, not the document
            const wrapper = canvas.parentElement;

            // Update position when either bbox or viewport changes
            function update_position(height_box) {
                const [fig_height, xmin, ymin, xmax, ymax] = height_box;
                const web_top = fig_height - ymax;

                // Since the wrapper has position: relative and widgets are position: absolute,
                // widgets are positioned relative to the wrapper.
                // Canvas and widgets are both children of wrapper, so we just need the canvas offset
                // within the wrapper (which should be 0,0 since canvas is the first child)
                const canvasRect = canvas.getBoundingClientRect();
                const wrapperRect = wrapper.getBoundingClientRect();

                const offsetX = canvasRect.left - wrapperRect.left;
                const offsetY = canvasRect.top - wrapperRect.top;

                // Scale coordinates by winscale to match canvas CSS scaling
                // Canvas CSS size = logical_size * winscale (where winscale = scalefactor / devicePixelRatio)
                div.style.left = (xmin * winscale + offsetX) + "px";
                div.style.top = (web_top * winscale + offsetY) + "px";
                div.style.width = ((xmax - xmin) * winscale) + "px";
                div.style.height = ((ymax - ymin) * winscale) + "px";

                // Set CSS variable for winscale so children can use calc(var(--winscale) * 1px)
                div.style.setProperty('--winscale', winscale);
            }
            $(height_box).on(update_position);
            update_position($(height_box).value); // Initial positioning
        });
    """
end

function replace_widget!(slider::Makie.Slider)
    Makie.hide!(slider)
    initial_value = slider.value[]
    range_vals = slider.range[]
    min_val = minimum(range_vals)
    max_val = maximum(range_vals)
    step_val = length(range_vals) > 1 ? range_vals[2] - range_vals[1] : 0.01
    is_horizontal = slider.horizontal[]

    # Extract Makie styling attributes
    linewidth = slider.linewidth[]
    color_inactive = slider.color_inactive[]
    color_active = slider.color_active[]
    color_active_dimmed = slider.color_active_dimmed[]

    # Common style pairs to avoid duplication
    base_input = [
        "-webkit-appearance" => "none",
        "appearance" => "none",
        "margin" => "0",
        "padding" => "0",
        "outline" => "none",
        "cursor" => "pointer",
        "width" => "100%",
        "background" => "transparent",
    ]

    track_common = [
        "background" => color_inactive,
        "border-radius" => "calc(var(--winscale) * $(linewidth / 2) * 1px)",
    ]

    thumb_common = [
        "-webkit-appearance" => "none",
        "appearance" => "none",
        "width" => "calc(var(--winscale) * $(linewidth) * 1px)",
        "height" => "calc(var(--winscale) * $(linewidth) * 1px)",
        "border-radius" => "50%",
        "background" => color_active,
        "cursor" => "pointer",
        "border" => "none",
    ]

    # Build styles based on orientation
    input_styles, vertical_attrs = if is_horizontal
        styles = Styles(
            CSS(base_input...),
            CSS("::-webkit-slider-runnable-track", track_common..., "height" => "calc(var(--winscale) * $(linewidth) * 1px)"),
            CSS("::-webkit-slider-thumb", thumb_common..., "transition" => "transform 0.1s ease"),
            CSS(":hover::-webkit-slider-thumb", "transform" => "scale(1.25)"),
            # Firefox uses ::-moz-range-progress for the filled portion
            CSS("::-moz-range-track", track_common..., "height" => "calc(var(--winscale) * $(linewidth) * 1px)"),
            CSS(
                "::-moz-range-progress",
                "background" => color_active_dimmed,
                "border-radius" => "calc(var(--winscale) * $(linewidth / 2) * 1px)",
                "height" => "calc(var(--winscale) * $(linewidth) * 1px)",
            ),
            CSS("::-moz-range-thumb", thumb_common..., "transition" => "transform 0.1s ease"),
            CSS(":hover::-moz-range-thumb", "transform" => "scale(1.25)"),
        )
        (styles, Dict())
    else
        styles = Styles(
            CSS(
                base_input...,
                "writing-mode" => "vertical-lr",
                "direction" => "rtl",
                "vertical-align" => "middle",
                "width" => "calc(var(--winscale) * $(linewidth) * 1px)",
                "height" => "100%",
            ),
            CSS("::-webkit-slider-runnable-track", track_common..., "width" => "calc(var(--winscale) * $(linewidth) * 1px)"),
            CSS("::-webkit-slider-thumb", thumb_common..., "transition" => "transform 0.1s ease"),
            CSS(":hover::-webkit-slider-thumb", "transform" => "scale(1.25)"),
            CSS("::-moz-range-track", track_common..., "width" => "calc(var(--winscale) * $(linewidth) * 1px)", "height" => "100%"),
            CSS(
                "::-moz-range-progress",
                "background" => color_active_dimmed,
                "border-radius" => "calc(var(--winscale) * $(linewidth / 2) * 1px)",
                "width" => "calc(var(--winscale) * $(linewidth) * 1px)",
                "height" => "100%",
            ),
            CSS("::-moz-range-thumb", thumb_common..., "transition" => "transform 0.1s ease"),
            CSS(":hover::-moz-range-thumb", "transform" => "scale(1.25)"),
        )
        (styles, Dict(:orient => "vertical"))
    end
    callback = js"""
        function(event) {
            const value = event.srcElement.valueAsNumber
            $(slider.value).notify(value);
        }
    """
    callback_kw = if slider.update_while_dragging[]
        (; oninput = callback)
    else
        (; onchange = callback)
    end


    slider_input = DOM.input(;
        type = "range",
        min = "$(min_val)",
        max = "$(max_val)",
        step = "$(step_val)",
        value = "$(initial_value)",
        style = input_styles,
        callback_kw...,
        vertical_attrs...
    )
    value_from_index = map(slider.selected_index) do idx
        return slider.range[][idx]
    end
    update_val_js = js"""
        $(value_from_index).on(x=> {
            const sliderInput = $(slider_input);
            sliderInput.value = x;
        });
    """

    slider_div = DOM.div(
        slider_input,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(slider_div, slider)
    return DOM.div(FONT_STYLE, slider_div, jss, update_val_js)
end

function replace_widget!(menu::Makie.Menu)
    Makie.hide!(menu)
    initial_selection_idx = menu.i_selected[]
    prompt_label = menu.prompt[]

    # Extract Makie styling attributes
    cell_color_inactive = menu.cell_color_inactive_even[]
    cell_color_hover = menu.cell_color_hover[]
    cell_color_active = menu.cell_color_active[]
    selection_cell_color_inactive = menu.selection_cell_color_inactive[]
    text_color = menu.textcolor[]
    text_size = menu.fontsize[]
    text_padding = menu.textpadding[]

    # The option entries are (re)built in JavaScript whenever `menu.options`
    # changes, so they can't rely on Bonito's per-node `Styles`. Instead we inject
    # a stylesheet with a class unique to this menu and apply it to items in JS.
    option_class = "makie-menu-option-" * string(objectid(menu); base = 16)
    option_padding = "calc(var(--winscale) * $(text_padding[1]) * 1px) calc(var(--winscale) * $(text_padding[2]) * 1px) calc(var(--winscale) * $(text_padding[3]) * 1px) calc(var(--winscale) * $(text_padding[4]) * 1px)"
    option_css = DOM.style(
        """
            .$(option_class) {
                background-color: $(Bonito.convert_css_attribute(cell_color_inactive));
                color: $(Bonito.convert_css_attribute(text_color));
                font-size: calc(var(--winscale) * $(text_size) * 1px);
                padding: $(option_padding);
                cursor: pointer;
            }
            .$(option_class):hover { background-color: $(Bonito.convert_css_attribute(cell_color_hover)); }
            .$(option_class).selected { background-color: $(Bonito.convert_css_attribute(cell_color_active)); }
        """
    )

    # A label-only, reactive view of the options that is cheap to send to the
    # frontend and updates whenever options are added/removed/changed.
    option_labels = map(menu.options) do options
        String[Makie.optionlabel(option) for option in collect(options)]
    end

    # Initial (server-side rendered) option list.
    dropdown_items = map(enumerate(option_labels[])) do (i, label_text)
        DOM.div(
            label_text;
            dataValue = i,
            class = i == initial_selection_idx ? "$(option_class) selected" : option_class,
        )
    end

    # Current selection display
    current_label = (initial_selection_idx == 0 || initial_selection_idx > length(option_labels[])) ?
        prompt_label : option_labels[][initial_selection_idx]
    dropdown_style = Styles(
        CSS(
            "width" => "100%",
            "height" => "100%",
            "background-color" => selection_cell_color_inactive,
            "color" => text_color,
            "font-size" => "calc(var(--winscale) * $(text_size) * 1px)",
            "cursor" => "pointer",
            "outline" => "none",
            "user-select" => "none",
            "box-sizing" => "border-box",
            "display" => "flex",
            "align-items" => "center",
            "justify-content" => "flex-start",
            "padding" => "calc(var(--winscale) * $(text_padding[1]) * 1px) calc(var(--winscale) * $(text_padding[2]) * 1px) calc(var(--winscale) * $(text_padding[3]) * 1px) calc(var(--winscale) * $(text_padding[4]) * 1px)",
        ),
        CSS(":hover", "background-color" => cell_color_hover),
    )
    dropdown_display = DOM.div(
        current_label,
        class = "dropdown-display",
        style = dropdown_style
    )

    # Dropdown list container
    dropdown_list = DOM.div(
        dropdown_items...,
        class = "dropdown-list",
        style = Styles(
            "position" => "absolute",
            "left" => "0",
            "right" => "0",
            "background-color" => "red",
            "display" => "none",
            "z-index" => "1000",
            "max-height" => "500px",
            "overflow-y" => "auto",
        )
    )

    select_element = DOM.div(
        dropdown_display,
        dropdown_list,
        style = Styles(
            "position" => "relative",
            "width" => "100%",
            "height" => "100%",
            "margin" => "0px",
            "padding" => "0px",
        )
    )

    # JavaScript for dropdown functionality
    dropdown_js = js"""
    const dropdown = $(select_element);
    const display = dropdown.querySelector('.dropdown-display');
    const list = dropdown.querySelector('.dropdown-list');
    const option_class = $(option_class);
    const prompt_label = $(prompt_label);
    let labels = $(option_labels).value;

    // Toggle dropdown
    display.onclick = function() {
        if (list.style.display === 'none' || list.style.display === '')  {
            // Check available space and position dropdown
            const dropdownRect = dropdown.getBoundingClientRect();
            const listHeight = 400; // max-height
            const spaceBelow = window.innerHeight - dropdownRect.bottom;
            const spaceAbove = dropdownRect.top;

            if (spaceBelow < listHeight && spaceAbove > spaceBelow) {
                // Open upward
                list.style.top = 'auto';
                list.style.bottom = '100%';
            } else {
                // Open downward (default)
                list.style.top = '100%';
                list.style.bottom = 'auto';
            }
            list.style.display = 'block';
        } else {
            list.style.display = 'none';
        }
    };

    // Rebuild the option entries. Called whenever `menu.options` changes on the
    // Julia side, so newly added panels (etc.) show up in the dropdown.
    function rebuild(new_labels) {
        labels = new_labels;
        const frag = document.createDocumentFragment();
        new_labels.forEach((label_text, idx) => {
            const item = document.createElement('div');
            item.className = option_class;
            item.setAttribute('data-value', idx + 1);
            item.textContent = label_text;
            frag.appendChild(item);
        });
        list.replaceChildren(frag);
    }

    // Sync the selected-entry highlight and the displayed label from i_selected.
    function update_selection() {
        const selected_index = $(menu.i_selected).value;
        list.querySelectorAll('[data-value]').forEach(item => {
            if (parseInt(item.dataset.value) === selected_index) {
                item.classList.add('selected');
            } else {
                item.classList.remove('selected');
            }
        });
        display.textContent = (selected_index >= 1 && selected_index <= labels.length) ?
            labels[selected_index - 1] : prompt_label;
    }

    // Event delegation so dynamically rebuilt options keep working.
    list.addEventListener('click', function(e) {
        const item = e.target.closest('[data-value]');
        if (!item || !list.contains(item)) return;
        $(menu.i_selected).notify(parseInt(item.dataset.value));
        list.style.display = 'none';
    });

    $(option_labels).on(function(new_labels) {
        rebuild(new_labels);
        update_selection();
    });
    $(menu.i_selected).on(update_selection);
    update_selection();

    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        if (!dropdown.contains(e.target)) {
            list.style.display = 'none';
        }
    });
    """

    menu_div = DOM.div(
        select_element,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(menu_div, menu)
    return DOM.div(FONT_STYLE, option_css, menu_div, jss, dropdown_js)
end

function replace_widget!(textbox::Makie.Textbox)
    Makie.hide!(textbox)
    scene = Makie.rootparent(textbox.blockscene)
    initial_value = textbox.displayed_string[]
    validator = textbox.validator[]

    # Extract Makie styling attributes
    text_padding = textbox.textpadding[]
    fontsize = textbox.fontsize[]
    textcolor = textbox.textcolor[]
    boxcolor = textbox.boxcolor[]
    boxcolor_hover = textbox.boxcolor_hover[]
    boxcolor_focused = textbox.boxcolor_focused[]
    bordercolor = Bonito.convert_css_attribute(textbox.bordercolor[])
    bordercolor_hover = textbox.bordercolor_hover[]
    bordercolor_focused = textbox.bordercolor_focused[]
    borderwidth = textbox.borderwidth[]
    cornerradius = textbox.cornerradius[]

    # Determine input type based on validator
    input_type = "text"

    # Input styled directly - no padding (which causes clipping due to browser's
    # `overflow: clip !important` for text <input>), instead use text-indent for horizontal offset
    input_styles = Styles(
        CSS(
            "width" => "100%",
            "height" => "100%",
            "box-sizing" => "border-box",
            "font-family" => "inherit",
            "font-size" => "calc(var(--winscale) * $(fontsize) * 1px)",
            "color" => textcolor,
            "border" => "calc(var(--winscale) * $(borderwidth) * 1px) solid $(bordercolor)",
            "border-radius" => "calc(var(--winscale) * $(cornerradius) * 1px)",
            "background-color" => boxcolor,
            "padding" => "0",
            "outline" => "none",
            "transition" => "border-color 0.2s, background-color 0.2s",
            # Use text-indent for horizontal padding (doesn't affect content box)
            "text-indent" => "calc(var(--winscale) * $(text_padding[4]) * 1px)",
        ),
        CSS(
            ":hover",
            "border-color" => bordercolor_hover,
            "background-color" => boxcolor_hover,
        ),
        CSS(
            ":focus",
            "border-color" => bordercolor_focused,
            "background-color" => boxcolor_focused,
        ),
    )

    # Add number-specific attributes for numeric validators
    input_attrs = Dict(
        :type => input_type,
        :value => string(initial_value),
        :placeholder => textbox.placeholder[],
    )
    if input_type == "number"
        input_attrs[:step] = "any"  # Allow any decimal precision
    end

    textbox_input = DOM.input(;
        input_attrs...,
        style = input_styles,
        value = textbox.displayed_string,
        onchange = js"""
            function(event) {
                let value = event.target.value;
                // Handle validation for numeric types
                if ($(input_type) === "number") {
                    const numValue = parseFloat(value);
                    if (!isNaN(numValue)) {
                        $(textbox.displayed_string).notify(value);
                        $(textbox.stored_string).notify(value);
                    }
                } else {
                    $(textbox.displayed_string).notify(value);
                    $(textbox.stored_string).notify(value);
                }
            }
        """,
        oninput = js"""
            function(event) {
                const value = event.target.value;
                $(textbox.displayed_string).notify(value);
            }
        """
    )

    textbox_div = DOM.div(
        textbox_input,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(textbox_div, textbox)
    return DOM.div(FONT_STYLE, textbox_div, jss)
end

function replace_widget!(button::Makie.Button)
    Makie.hide!(button)

    # Extract Makie styling attributes
    button_text = button.label[]
    fontsize = button.fontsize[]
    # Not sure why the button needs extra scaling for padding
    padding = round.(Int, button.padding[] ./ 1.5)
    cornerradius = button.cornerradius[]
    strokewidth = button.strokewidth[]
    strokecolor = button.strokecolor[]
    buttoncolor = button.buttoncolor[]
    buttoncolor_hover = button.buttoncolor_hover[]
    buttoncolor_active = button.buttoncolor_active[]
    labelcolor = button.labelcolor[]
    labelcolor_hover = button.labelcolor_hover[]
    labelcolor_active = button.labelcolor_active[]

    button_element = DOM.button(
        button_text,
        style = Styles(
            CSS(
                "width" => "100%",
                "height" => "100%",
                "font-family" => "inherit",
                "font-size" => "calc(var(--winscale) * $(fontsize) * 1px)",
                "padding" => "calc(var(--winscale) * $(padding[1]) * 1px) calc(var(--winscale) * $(padding[2]) * 1px) calc(var(--winscale) * $(padding[3]) * 1px) calc(var(--winscale) * $(padding[4]) * 1px)",
                "border" => "calc(var(--winscale) * $(strokewidth) * 1px) solid $(strokecolor)",
                "border-radius" => "calc(var(--winscale) * $(cornerradius) * 1px)",
                "background-color" => buttoncolor,
                "color" => labelcolor,
                "cursor" => "pointer",
                "outline" => "none",
                "transition" => "background-color 0.2s, color 0.2s",
            ),
            CSS(
                ":hover",
                "background-color" => buttoncolor_hover,
                "color" => labelcolor_hover,
            ),
            CSS(
                ":active",
                "background-color" => buttoncolor_active,
                "color" => labelcolor_active,
            ),
        ),
        onclick = js"""
            function(event) {
                console.log("Button clicked");
                $(button.clicks).notify($(button.clicks).value + 1);
            }
        """
    )
    button_div = DOM.div(
        button_element,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(button_div, button)
    return DOM.div(FONT_STYLE, button_div, jss)
end

function replace_widget!(checkbox::Makie.Checkbox)
    Makie.hide!(checkbox)

    # Extract Makie styling attributes
    size = checkbox.size[]
    checkmarksize = checkbox.checkmarksize[]
    roundness = checkbox.roundness[]
    checkboxstrokewidth = checkbox.checkboxstrokewidth[]
    checkboxcolor_checked = checkbox.checkboxcolor_checked[]
    checkboxcolor_unchecked = checkbox.checkboxcolor_unchecked[]
    checkboxstrokecolor_checked = checkbox.checkboxstrokecolor_checked[]
    checkmarkcolor_checked = checkbox.checkmarkcolor_checked[]

    checkbox_element = DOM.input(
        type = "checkbox",
        checked = checkbox.checked[],
        style = Styles(
            CSS(
                "width" => "calc(var(--winscale) * $(size + 2checkboxstrokewidth) * 1px)",
                "height" => "calc(var(--winscale) * $(size + 2checkboxstrokewidth) * 1px)",
                "flex-shrink" => "0",
                "appearance" => "none",
                "-webkit-appearance" => "none",
                "-moz-appearance" => "none",
                "cursor" => "pointer",
                "border-style" => "solid",
                "border-width" => "calc(var(--winscale) * $(checkboxstrokewidth) * 1px)",
                "border-color" => checkboxcolor_checked,
                "background-color" => checkboxcolor_unchecked,
                "outline" => "none",
                "position" => "relative",
                "transition" => "background-color 0.2s, border-color 0.2s",
            ),
            CSS(
                ":checked",
                "background-color" => checkboxcolor_checked,
                "border-color" => checkboxstrokecolor_checked,
            ),
            # Create checkmark using ::after pseudo-element
            CSS(
                "::after",
                "content" => "\"\"",
                "position" => "absolute",
                "display" => "none",
                "left" => "50%",
                "top" => "40%",
                "width" => "calc(var(--winscale) * $(size * checkmarksize * 0.3) * 1px)",
                "height" => "calc(var(--winscale) * $(size * checkmarksize * 0.6) * 1px)",
                "border" => "solid $(checkmarkcolor_checked)",
                "border-width" => "0 calc(var(--winscale) * $(checkboxstrokewidth * 1.5) * 1px) calc(var(--winscale) * $(checkboxstrokewidth * 1.5) * 1px) 0",
                "transform" => "translate(-50%, -50%) rotate(45deg)",
            ),
            CSS(
                ":checked::after",
                "display" => "block",
            ),
        ),
        onchange = js"""
            function(event) {
                const isChecked = event.target.checked;
                $(checkbox.checked).notify(isChecked);
            }
        """
    )

    checkbox_div = DOM.div(
        checkbox_element,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(checkbox_div, checkbox)
    return DOM.div(FONT_STYLE, checkbox_div, jss)
end

function replace_widget!(toggle::Makie.Toggle)
    Makie.hide!(toggle)

    # Extract Makie styling attributes
    length = toggle.length[]
    markersize = toggle.markersize[]
    framecolor_inactive = toggle.framecolor_inactive[]
    framecolor_active = toggle.framecolor_active[]
    buttoncolor = toggle.buttoncolor[]
    rimfraction = toggle.rimfraction[]

    # Calculate dimensions
    track_height = markersize
    track_width = length
    button_size = markersize * (1 - rimfraction)
    border_width = markersize * rimfraction / 2

    toggle_input = DOM.input(
        type = "checkbox",
        checked = toggle.active[],
        style = Styles(
            CSS(
                "appearance" => "none",
                "-webkit-appearance" => "none",
                "-moz-appearance" => "none",
                "width" => "calc(var(--winscale) * $(track_width) * 1px)",
                "height" => "calc(var(--winscale) * $(track_height) * 1px)",
                "min-width" => "calc(var(--winscale) * $(track_width) * 1px)",
                "min-height" => "calc(var(--winscale) * $(track_height) * 1px)",
                "flex-shrink" => "0",
                "cursor" => "pointer",
                "background-color" => framecolor_inactive,
                "border-radius" => "calc(var(--winscale) * $(track_height / 2) * 1px)",
                "position" => "relative",
                "outline" => "none",
                "box-sizing" => "border-box",
                "transition" => "background-color 0.15s",
            ),
            CSS(
                ":checked",
                "background-color" => framecolor_active,
            ),
            # Create toggle button using ::before pseudo-element
            CSS(
                "::before",
                "content" => "\"\"",
                "position" => "absolute",
                "width" => "calc(var(--winscale) * $(button_size) * 1px)",
                "height" => "calc(var(--winscale) * $(button_size) * 1px)",
                "border-radius" => "50%",
                "background-color" => buttoncolor,
                "left" => "calc(var(--winscale) * $(border_width) * 1px)",
                "top" => "50%",
                "transform" => "translateY(-50%)",
                "transition" => "left 0.15s",
            ),
            CSS(
                ":checked::before",
                "left" => "calc(var(--winscale) * $(track_width - button_size - border_width) * 1px)",
            ),
        ),
        onchange = js"""
            function(event) {
                const isActive = event.target.checked;
                $(toggle.active).notify(isActive);
            }
        """
    )

    toggle_div = DOM.div(
        toggle_input,
        style = WIDGET_CONTAINER_STYLES
    )
    jss = resize_parent(toggle_div, toggle)
    return DOM.div(FONT_STYLE, toggle_div, jss)
end

replace_widget!(x::Any) = nothing # not implemented
function replace_widget!(fig::Figure)
    return DOM.div(map(replace_widget!, fig.content))
end
