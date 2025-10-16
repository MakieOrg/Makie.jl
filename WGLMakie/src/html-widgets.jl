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
            // Update position when either bbox or viewport changes
            function update_position(height_box) {
                const [fig_height, xmin, ymin, xmax, ymax] = height_box;
                const web_top = fig_height - ymax;
                // Get canvas offset to account for container positioning
                const canvasRect = canvas.getBoundingClientRect();
                const offsetX = canvasRect.left;
                const offsetY = canvasRect.top;

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
            CSS("::-moz-range-progress",
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
            CSS("::-moz-range-progress",
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
    scene = Makie.rootparent(menu.blockscene)
    initial_selection = menu.selection[]
    initial_selection_idx = menu.i_selected[]
    options = menu.options[]

    # Extract Makie styling attributes
    cell_color_inactive = menu.cell_color_inactive_even[]
    cell_color_hover = menu.cell_color_hover[]
    cell_color_active = menu.cell_color_active[]
    selection_cell_color_inactive = menu.selection_cell_color_inactive[]
    text_color = menu.textcolor[]
    text_size = menu.fontsize[]
    text_padding = menu.textpadding[]
    # Create custom dropdown items
    dropdown_items = []
    option_style = Styles(
        CSS(
            "background-color" => cell_color_inactive,
            "color" => text_color,
            "font-size" => "calc(var(--winscale) * $(text_size) * 1px)",
            "padding" => "calc(var(--winscale) * $(text_padding[1]) * 1px) calc(var(--winscale) * $(text_padding[2]) * 1px) calc(var(--winscale) * $(text_padding[3]) * 1px) calc(var(--winscale) * $(text_padding[4]) * 1px)",
            "cursor" => "pointer",
        ),
        CSS(":hover", "background-color" => cell_color_hover),
        CSS(".selected", "background-color" => cell_color_active),
    )
    for (i, option) in enumerate(options)
        label_text = Makie.optionlabel(option)
        is_selected = (i == initial_selection_idx)

        push!(
            dropdown_items, DOM.div(
                label_text,
                dataValue = i,
                style = option_style,
            )
        )
    end

    # Current selection display
    current_label = Makie.optionlabel(initial_selection)
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
    const items = list.querySelectorAll('[data-value]');

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

    function update_background() {
        const selected_index = $(menu.i_selected).value;
        items.forEach((item, index) => {
            if (index + 1 === selected_index) {
                item.classList.add('selected');
            } else {
                item.classList.remove('selected');
            }
        });
    }

    // Handle item selection
    items.forEach(item => {
        item.onclick = function() {
            const selected_index = parseInt(this.dataset.value);
            $(menu.i_selected).notify(selected_index);
            display.textContent = this.textContent;
            list.style.display = 'none';
            // Update active styling
            update_background();
        };
    });
    update_background()
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
    return DOM.div(FONT_STYLE, menu_div, jss, dropdown_js)
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
    input_styles = Styles(
        CSS(
            "width" => "100%",
            "height" => "100%",
            "font-family" => "inherit",
            "font-size" => "calc(var(--winscale) * $(fontsize) * 1px)",
            "color" => textcolor,
            "border" => "calc(var(--winscale) * $(borderwidth) * 1px) solid $(bordercolor)",
            "border-radius" => "calc(var(--winscale) * $(cornerradius) * 1px)",
            "background-color" => boxcolor,
            "padding" => "calc(var(--winscale) * $(text_padding[1]) * 1px) calc(var(--winscale) * $(text_padding[2]) * 1px) calc(var(--winscale) * $(text_padding[3]) * 1px) calc(var(--winscale) * $(text_padding[4]) * 1px)",
            "outline" => "none",
            "box-sizing" => "border-box",
            "transition" => "border-color 0.2s, background-color 0.2s",
        ),
        CSS(":hover",
            "border-color" => bordercolor_hover,
            "background-color" => boxcolor_hover,
        ),
        CSS(":focus",
            "border-color" => bordercolor_focused,
            "background-color" => boxcolor_focused,
        ),
    )

    # Add number-specific attributes for numeric validators
    input_attrs = Dict(:type => input_type, :value => string(initial_value))
    if input_type == "number"
        input_attrs[:step] = "any"  # Allow any decimal precision
    end

    textbox_input = DOM.input(;
        input_attrs...,
        style = input_styles,
        onchange = js"""
            function(event) {
                let value = event.target.value;
                console.log("Textbox value changed:", value);
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
            CSS(":hover",
                "background-color" => buttoncolor_hover,
                "color" => labelcolor_hover,
            ),
            CSS(":active",
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

replace_widget!(x::Any) = nothing # not implemented
function replace_widget!(fig::Figure)
    return DOM.div(map(replace_widget!, fig.content))
end
