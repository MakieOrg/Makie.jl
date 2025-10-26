# Reference test for WGLMakie HTML widgets
# This test verifies that all widgets render correctly with proper positioning when use_html_widgets=true

using ReferenceTests: RNG, @reference_test
using ReferenceTests, WGLMakie
using Test
import Electron, Bonito

struct EScreenshot
    display
    fig
end

function snapshot_figure(edisplay, fig, path)
    rm(path; force = true)
    display(edisplay, Bonito.App(fig))
    win = edisplay.window.window
    win_size = run(
        win, """(()=>{
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.documentElement.style.margin = '0';
            document.documentElement.style.padding = '0';
            // Find the canvas element (Makie renders to canvas)
            const canvas = document.querySelector('canvas');
            const rect = canvas.getBoundingClientRect();
            return [
                    Math.ceil(rect.width),
                    Math.ceil(rect.height)
                ];
            })();
        """
    )
    Electron.ElectronAPI.setContentSize(win, win_size...)
    winid = win.id
    sleep(0.5) # do we need time for resize?
    run(
        edisplay.window.app,
        """
        const win = BrowserWindow.fromId($winid)
        win.webContents.capturePage().then(image => {
            const screenshotPath = '$(path)';
            require('fs').writeFileSync(screenshotPath, image.toPNG());
            console.log('Screenshot saved to', screenshotPath);
        }).catch(err => {
            console.error('Screenshot error:', err);
        });
        """,
    )
    Bonito.wait_for(() -> isfile(path); timeout = 30)
    return path
end

# YAY we can just overload save_results for our own EScreenshot type :)
function ReferenceTests.save_result(path::String, es::EScreenshot)
    isfile(path * ".png") && rm(path * ".png"; force = true)
    snapshot_figure(es.display, es.fig, path * ".png")
    return true
end

function create_test_figure()
    fig = Figure(size = (1200, 900))

    # Top row - Plots with vertical slider next to ax2
    ax1 = Axis(fig[1, 1], title = "Sine Wave (Slider controlled)")
    ax2 = Axis(fig[1, 2], title = "Scatter (Button controlled)")
    sl_vertical = Makie.Slider(fig[1, 3], range = 0:0.1:10, startvalue = 5, horizontal = false)
    ax3 = Axis(fig[1, 4], title = "Heatmap (Menu controlled)")

    # Row 2 - Horizontal sliders with labels
    Label(fig[2, 1], "Frequency:", halign = :right, tellwidth = false)
    sl_freq = Makie.Slider(fig[2, 2:3], range = 0.5:0.1:5, startvalue = 2, tellwidth = false)
    freq_label = Label(fig[2, 4], lift(x -> "$(round(x, digits = 1))", sl_freq.value), halign = :left, tellwidth = false)

    Label(fig[3, 1], "Amplitude:", halign = :right, tellwidth = false)
    sl_amp = Makie.Slider(fig[3, 2:3], range = 0.5:0.1:3, startvalue = 1.5, tellwidth = false)
    amp_label = Label(fig[3, 4], lift(x -> "$(round(x, digits = 1))", sl_amp.value), halign = :left, tellwidth = false)

    Label(fig[4, 1], "Phase:", halign = :right, tellwidth = false)
    sl_phase = Makie.Slider(fig[4, 2:3], range = 0:0.1:2π, startvalue = 0, tellwidth = false)
    phase_label = Label(fig[4, 4], lift(x -> "$(round(x, digits = 2))", sl_phase.value), halign = :left, tellwidth = false)

    # Row 5 - Buttons
    btn_add = Makie.Button(fig[5, 2:3], label = "Add Point", tellwidth = false)
    click_counter = Label(fig[5, 4], lift(n -> "Total: $n clicks", btn_add.clicks), halign = :left, tellwidth = false)

    # Row 6 - Menus
    Label(fig[6, 1], "Colormap:", halign = :right, tellwidth = false)
    menu_cmap = Makie.Menu(fig[6, 2], options = ["viridis", "plasma", "inferno", "magma"], default = "viridis", tellwidth = false)

    num_func = GridLayout(fig[6:7, 3:4])
    Label(num_func[1, 1], "Function:"; halign = :right, tellwidth = false)
    funcs = [sin, cos, tan]
    menu_func = Makie.Menu(
        num_func[1, 2];
        options = zip(["Sine", "Cosine", "Tangent"], funcs),
        default = "Sine", tellwidth = false
    )

    # Row 7 - Textboxes
    Label(fig[7, 1], "Text input:", halign = :right, tellwidth = false)
    textbox_text = Makie.Textbox(fig[7, 2], placeholder = "Type here...", stored_string = "Hello!", tellwidth = false)

    Label(num_func[2, 1], "Number:"; halign = :right, tellwidth = false)
    textbox_num = Makie.Textbox(num_func[2, 2]; validator = Float64, stored_string = "3.14", tellwidth = false)

    # Row 8 - Checkboxes
    Label(fig[8, 1], "Enable feature:", halign = :right, tellwidth = false)
    checkbox_feature = Makie.Checkbox(fig[8, 2], checked = true, tellwidth = false)

    Label(fig[8, 3], "Show grid:", halign = :right, tellwidth = false)
    checkbox_grid = Makie.Checkbox(fig[8, 4], checked = false, tellwidth = false)

    # Row 9 - Toggles
    Label(fig[9, 1], "Dark mode:", halign = :right, tellwidth = false)
    toggle_dark = Makie.Toggle(fig[9, 2], active = false, tellwidth = false)

    Label(fig[9, 3], "Auto-update:", halign = :right, tellwidth = false)
    toggle_update = Makie.Toggle(fig[9, 4], active = true, tellwidth = false)

    # Plot 1: Sine wave controlled by sliders
    xs = 0:0.01:10
    ys = lift(sl_freq.value, sl_amp.value, sl_phase.value) do freq, amp, phase
        amp .* sin.(freq .* xs .+ phase)
    end
    sine_line = lines!(ax1, xs, ys, linewidth = 3, color = :blue)

    # Connect checkbox to control sine wave visibility
    on(checkbox_feature.checked) do checked
        sine_line.visible[] = checked
    end

    # Plot 2: Scatter plot controlled by buttons and vertical slider
    points = Observable(Point2f[])
    scatter!(ax2, points, color = :red, markersize = 15)
    on(btn_add.clicks) do n
        new_point = Point2f(RNG.rand() * 10, sl_vertical.value[])
        push!(points[], new_point)
        notify(points)
    end
    # Current position indicator
    current_marker = lift(sl_vertical.value) do y
        [Point2f(5, y)]
    end
    scatter!(ax2, current_marker, color = :green, markersize = 25, marker = :cross)
    limits!(ax2, 0, 10, 0, 10)

    # Connect checkbox to control grid visibility
    on(checkbox_grid.checked) do checked
        ax2.xgridvisible[] = checked
        ax2.ygridvisible[] = checked
    end

    # Plot 3: Heatmap controlled by menu
    data = RNG.randn(25, 25)
    hmap = heatmap!(ax3, data, colormap = menu_cmap.selection)

    # Connect toggles to control plot features
    on(toggle_dark.active) do active
        # Toggle background color
        color = to_color(active ? :gray20 : :white)
        foreach((ax1, ax2, ax3)) do ax
            ax.backgroundcolor[] = color
        end
    end

    # Bottom row - Live text preview
    preview_text = lift(textbox_text.displayed_string, textbox_num.displayed_string, toggle_update.active) do text, num, auto
        status = auto ? "Auto-update: ON" : "Auto-update: OFF"
        "Preview: \"$text\" | Number: $num | $status"
    end
    Label(fig[10, 1:4], preview_text, fontsize = 18, color = :gray50, tellwidth = false)

    # Show modified function plot
    modified_xs = 0:0.1:10
    modified_ys = lift(menu_func.selection, textbox_num.stored_string) do f, numstr
        multiplier = something(tryparse(Float64, numstr), 1.0)
        multiplier .* f.(modified_xs) .+ 5
    end
    lines!(ax2, modified_xs, modified_ys, color = :orange, linewidth = 4)

    # Manipulate all widgets to test that they update correctly in HTML
    # This verifies bidirectional sync between Julia and HTML widgets
    for i in 1:3
        btn_add.clicks[] = btn_add.clicks[] + 1
    end
    set_close_to!(sl_freq, 3.5)
    set_close_to!(sl_amp, 2.0)
    set_close_to!(sl_phase, π)
    set_close_to!(sl_vertical, 7.5)
    menu_cmap.i_selected[] = 3  # Select "inferno"
    menu_func.i_selected[] = 2  # Select "Cosine"
    Makie.set!(textbox_text, "Updated!")
    Makie.set!(textbox_num, "2.71")
    checkbox_grid.checked[] = false
    toggle_dark.active[] = true
    # Simulate 3 clicks
    return EScreenshot(edisplay, fig)
end

# Makie.inline!(Makie.automatic)
# edisplay = Bonito.use_electron_display(; devtools=true)
# ReferenceTests.RECORDING_DIR[] = pwd()
# ReferenceTests.REGISTERED_TESTS |> empty!
function close_devtools(w)
    return run(w.app, "electron.BrowserWindow.fromId($(w.id)).webContents.closeDevTools()")
end

# Devtools cut off the screenshot!
close_devtools(edisplay.window.window)

@reference_test "Widgets layout" begin
    WGLMakie.activate!(; use_html_widgets = false, px_per_unit = Makie.automatic, scalefactor = Makie.automatic)
    create_test_figure()
end

@reference_test "HTML Widgets layout" begin
    WGLMakie.activate!(; use_html_widgets = true, px_per_unit = Makie.automatic, scalefactor = Makie.automatic)
    create_test_figure()
end
@reference_test "HTML Widgets layout px_per_unit=1" begin
    WGLMakie.activate!(; use_html_widgets = true, px_per_unit = 1, scalefactor = 1)
    create_test_figure()
end

@reference_test "HTML Widgets layout px_per_unit=2" begin
    WGLMakie.activate!(; use_html_widgets = true, px_per_unit = 2, scalefactor = 2)
    create_test_figure()
end
# Reset to default
WGLMakie.activate!(; use_html_widgets = false, px_per_unit = Makie.automatic, scalefactor = Makie.automatic)
