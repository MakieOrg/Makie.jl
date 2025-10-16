using Electron, WGLMakie, Bonito, Test

WGLMakie.activate!(use_html_widgets = true)

@testset "HTML Widgets" begin
    @testset "Slider - basic horizontal" begin
        fig = Figure()
        ax = Axis(fig[1, 1])
        sl = Makie.Slider(fig[2, 1], range = 0:0.01:10, startvalue = 3)

        point = lift(sl.value) do x
            Point2f(x, 5)
        end
        scatter!(point, color = :red, markersize = 20)
        limits!(ax, 0, 10, 0, 10)

        app = App(fig)
        display(edisplay, app)

        # Test that slider renders as HTML range input
        slider_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=range]");
                return {
                    value: parseFloat(node.value),
                    min: parseFloat(node.min),
                    max: parseFloat(node.max),
                    step: parseFloat(node.step),
                    exists: node !== null
                }
            })()"""
        )

        @test slider_props["exists"] == true
        @test slider_props["value"] ≈ 3.0
        @test slider_props["min"] ≈ 0.0
        @test slider_props["max"] ≈ 10.0
        @test slider_props["step"] ≈ 0.01

        # Test interaction - change value via JS
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=range]");
                node.value = 7.5;
                node.dispatchEvent(new Event('input', { bubbles: true }));
                node.dispatchEvent(new Event('change', { bubbles: true }));
            })()"""
        )
        @test sl.value[] ≈ 7.5
    end

    @testset "Slider - vertical and update_while_dragging" begin
        fig = Figure()
        ax = Axis(fig[1, 1])
        sl_x = Makie.Slider(fig[2, 1], range = 0:0.01:10, startvalue = 3, update_while_dragging = false)
        sl_y = Makie.Slider(fig[1, 2], range = 0:0.01:10, horizontal = false, startvalue = 6)

        point = lift(sl_x.value, sl_y.value) do x, y
            Point2f(x, y)
        end
        scatter!(point, color = :red, markersize = 20)
        limits!(ax, 0, 10, 0, 10)

        app = App(fig)
        display(edisplay, app)

        # Test both sliders exist
        sliders = evaljs_value(
            app.session[], js"""(() => {
                const nodes = document.querySelectorAll("input[type=range]");
                return {
                    count: nodes.length,
                    values: Array.from(nodes).map(n => parseFloat(n.value))
                }
            })()"""
        )

        @test sliders["count"] == 2
        @test sliders["values"][1] ≈ 3.0
        @test sliders["values"][2] ≈ 6.0

        # Test changing first slider
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelectorAll("input[type=range]")[0];
                node.value = 2;
                node.dispatchEvent(new Event('input', { bubbles: true }));
                node.dispatchEvent(new Event('change', { bubbles: true }));
            })()"""
        )

        @test sl_x.value[] ≈ 2.0
    end

    @testset "Button - click counting" begin
        fig = Figure()
        btn = Makie.Button(fig[1, 1], label = "Click Me!")

        click_count = Observable(0)
        on(btn.clicks) do n
            click_count[] = n
        end

        app = App(fig)
        display(edisplay, app)

        # Test that button renders as HTML button
        button_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("button");
                return {
                    exists: node !== null,
                    text: node.textContent.trim()
                }
            })()"""
        )

        @test button_props["exists"] == true
        @test button_props["text"] == "Click Me!"

        # Test clicking the button
        initial_clicks = btn.clicks[]
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("button");
                node.click();
            })()"""
        )

        @test btn.clicks[] == initial_clicks + 1

        # Click multiple times
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("button");
                node.click();
                node.click();
            })()"""
        )

        @test btn.clicks[] == initial_clicks + 3
    end

    @testset "Menu - string options" begin
        fig = Figure()
        menu = Makie.Menu(fig[1, 1], options = ["Option A", "Option B", "Option C"], default = "Option B")

        app = App(fig)
        display(edisplay, app)

        # Test that menu renders as custom dropdown with divs
        menu_props = evaljs_value(
            app.session[], js"""(() => {
                const dropdown = document.querySelector('.dropdown-display');
                const list = document.querySelector('.dropdown-list');
                const items = document.querySelectorAll('[data-value]');

                return {
                    exists: dropdown !== null,
                    displayText: dropdown ? dropdown.textContent.trim() : "",
                    itemCount: items.length,
                    itemTexts: Array.from(items).map(item => item.textContent.trim())
                }
            })()"""
        )

        @test menu_props["exists"] == true
        @test menu_props["displayText"] == "Option B"
        @test menu_props["itemCount"] == 3
        @test menu_props["itemTexts"] == ["Option A", "Option B", "Option C"]
        @test menu.selection[] == "Option B"
        @test menu.i_selected[] == 2

        # Test selecting a different option
        evaljs_value(
            app.session[], js"""(() => {
                const items = document.querySelectorAll('[data-value]');
                items[2].click(); // Select "Option C" (0-indexed, so index 2)
            })()"""
        )

        @test menu.selection[] == "Option C"
        @test menu.i_selected[] == 3

        # Test selecting first option
        evaljs_value(
            app.session[], js"""(() => {
                const items = document.querySelectorAll('[data-value]');
                items[0].click(); // Select "Option A"
            })()"""
        )

        @test menu.selection[] == "Option A"
        @test menu.i_selected[] == 1
    end

    @testset "Menu - function values" begin
        fig = Figure()
        ax = Axis(fig[1, 1])

        funcs = [sin, cos, tan, sqrt]
        menu = Makie.Menu(
            fig[2, 1],
            options = zip(["Sine", "Cosine", "Tangent", "Square Root"], funcs),
            default = "Cosine"
        )

        # Plot based on selected function
        xs = 0:0.1:5
        ys = lift(menu.selection) do f
            f.(xs)
        end

        lines!(ax, xs, ys)

        app = App(fig)
        display(edisplay, app)

        # Verify initial state
        @test menu.selection[] == cos
        @test menu.i_selected[] == 2

        # Select "Sine" function
        evaljs_value(
            app.session[], js"""(() => {
                const items = document.querySelectorAll('[data-value]');
                items[0].click(); // Select first option (Sine)
            })()"""
        )

        @test menu.selection[] == sin
        @test menu.i_selected[] == 1

        # Select "Square Root" function
        evaljs_value(
            app.session[], js"""(() => {
                const items = document.querySelectorAll('[data-value]');
                items[3].click(); // Select fourth option (Square Root)
            })()"""
        )

        @test menu.selection[] == sqrt
        @test menu.i_selected[] == 4
    end

    @testset "Textbox - text entry" begin
        fig = Figure()
        textbox = Makie.Textbox(fig[1, 1], placeholder = "Enter text...")

        app = App(fig)
        display(edisplay, app)

        # Test that textbox renders as HTML input
        textbox_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=text]");
                return {
                    exists: node !== null,
                    type: node ? node.type : "",
                    value: node ? node.value : ""
                }
            })()"""
        )

        @test textbox_props["exists"] == true
        @test textbox_props["type"] == "text"
        # Initial value is the placeholder text
        @test textbox_props["value"] == "Enter text..."

        # Test entering text
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=text]");
                node.value = "Hello World";
                node.dispatchEvent(new Event('input', { bubbles: true }));
                node.dispatchEvent(new Event('change', { bubbles: true }));
            })()"""
        )

        @test textbox.displayed_string[] == "Hello World"
        @test textbox.stored_string[] == "Hello World"
    end

    @testset "Textbox - numeric validator" begin
        fig = Figure()
        textbox = Makie.Textbox(fig[1, 1], validator = Float64, stored_string = "3.14")

        app = App(fig)
        display(edisplay, app)

        # Test that textbox renders as HTML number input
        textbox_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=number]");
                return {
                    exists: node !== null,
                    type: node ? node.type : "",
                    value: node ? node.value : ""
                }
            })()"""
        )

        @test textbox_props["exists"] == true
        @test textbox_props["type"] == "number"
        @test textbox_props["value"] == "3.14"

        # Test entering a new number
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=number]");
                node.value = "2.71";
                node.dispatchEvent(new Event('input', { bubbles: true }));
                node.dispatchEvent(new Event('change', { bubbles: true }));
            })()"""
        )

        @test textbox.displayed_string[] == "2.71"
        @test textbox.stored_string[] == "2.71"
    end

    @testset "Checkbox - toggle state" begin
        fig = Figure()
        checkbox = Makie.Checkbox(fig[1, 1])

        app = App(fig)
        display(edisplay, app)

        # Test that checkbox renders as HTML checkbox input
        checkbox_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=checkbox]");
                return {
                    exists: node !== null,
                    checked: node ? node.checked : false
                }
            })()"""
        )

        @test checkbox_props["exists"] == true
        @test checkbox_props["checked"] == false
        @test checkbox.checked[] == false

        # Test checking the checkbox
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=checkbox]");
                node.click();
            })()"""
        )

        @test checkbox.checked[] == true

        # Test unchecking the checkbox
        evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=checkbox]");
                node.click();
            })()"""
        )

        @test checkbox.checked[] == false
    end

    @testset "Checkbox - initial checked state" begin
        fig = Figure()
        checkbox = Makie.Checkbox(fig[1, 1], checked = false)

        app = App(fig)
        display(edisplay, app)

        # Test that checkbox is initially checked
        checkbox_props = evaljs_value(
            app.session[], js"""(() => {
                const node = document.querySelector("input[type=checkbox]");
                return {
                    checked: node ? node.checked : false
                }
            })()"""
        )

        @test checkbox_props["checked"] == false
        @test checkbox.checked[] == false
    end

    @testset "Widget interactions - Slider + Button" begin
        fig = Figure()
        ax = Axis(fig[1, 1], title = "Interactive Plot")

        # Create slider to control x position
        sl_x = Makie.Slider(fig[2, 1], range = 0:0.1:10, startvalue = 5)

        # Create button to add random points
        btn = Makie.Button(fig[3, 1], label = "Add Point")

        # Points to plot
        points = Observable(Point2f[])

        # When button is clicked, add a point at slider position
        on(btn.clicks) do n
            x = sl_x.value[]
            y = rand() * 10
            push!(points[], Point2f(x, y))
            notify(points)
        end

        scatter!(ax, points, color = :blue, markersize = 15)
        limits!(ax, 0, 10, 0, 10)

        app = App(fig)
        display(edisplay, app)

        # Verify widgets exist
        widgets_exist = evaljs_value(
            app.session[], js"""(() => {
                return {
                    slider: document.querySelector("input[type=range]") !== null,
                    button: document.querySelector("button") !== null
                }
            })()"""
        )

        @test widgets_exist["slider"] == true
        @test widgets_exist["button"] == true

        initial_count = length(points[])

        # Move slider to position 7
        evaljs_value(
            app.session[], js"""(() => {
                const slider = document.querySelector("input[type=range]");
                slider.value = 7.0;
                slider.dispatchEvent(new Event('input', { bubbles: true }));
                slider.dispatchEvent(new Event('change', { bubbles: true }));
            })()"""
        )

        @test sl_x.value[] ≈ 7.0

        # Click button to add a point
        evaljs_value(
            app.session[], js"""(() => {
                const button = document.querySelector("button");
                button.click();
            })()"""
        )

        @test length(points[]) == initial_count + 1
        @test points[][end][1] ≈ 7.0  # X position should be slider value
    end
end
