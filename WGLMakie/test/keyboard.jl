using Electron, WGLMakie, Bonito, Test

@testset "Keyboard" begin
    WGLMakie.activate!(use_html_widgets = false)

    fig = Figure()
    textbox = Makie.Textbox(fig[1, 1], stored_string = "abc")
    app = App(fig)
    display(edisplay, app)
    Bonito.wait_for(() -> events(fig.scene).window_open[])
    evaljs_value(app.session[], js"""document.querySelector("canvas").focus()""")
    textbox.focused[] = true

    # Trusted input, as from a real keyboard, so that the browser also runs its
    # default actions such as paste
    function send_input(events...)
        return run(
            edisplay.window.app, """
            const {BrowserWindow} = require("electron");
            const wc = BrowserWindow.fromId($(edisplay.window.window.id)).webContents;
            wc.focus();
            for (const e of [$(join(events, ", "))]) {
                wc.sendInputEvent(e);
            }
            true
            """
        )
    end
    press(key; modifiers = "[]") = (
        "{type: 'keyDown', keyCode: '$key', modifiers: $modifiers}",
        "{type: 'char', keyCode: '$key', modifiers: $modifiers}",
        "{type: 'keyUp', keyCode: '$key', modifiers: $modifiers}",
    )
    function ctrl(key)
        return (
            "{type: 'keyDown', keyCode: 'Control'}",
            press(key; modifiers = "['control']")...,
            "{type: 'keyUp', keyCode: 'Control'}",
        )
    end
    function wait_for_text(text)
        Bonito.wait_for(() -> textbox.displayed_string[] == text; timeout = 10)
        return textbox.displayed_string[]
    end

    @testset "typing" begin
        send_input(press("1")...)
        @test wait_for_text("1abc") == "1abc"
    end

    @testset "paste uses the browser's clipboard" begin
        run(edisplay.window.app, """require("electron").clipboard.writeText("xyz"); true""")
        send_input(ctrl("V")...)
        # no stray "v" from the shortcut
        @test wait_for_text("1xyzabc") == "1xyzabc"
    end

    @testset "shortcuts don't type their character" begin
        # the "2" shows that Ctrl+B has been handled
        send_input(ctrl("B")..., press("2")...)
        @test wait_for_text("1xyz2abc") == "1xyz2abc"
    end

    @testset "AltGr still types" begin
        # e.g. "@" on a German layout, which Windows reports as Ctrl+Alt
        evaljs_value(
            app.session[], js"""document.querySelector("canvas").dispatchEvent(new KeyboardEvent("keydown", {
                code: "KeyQ", key: "@", ctrlKey: true, altKey: true, modifierAltGraph: true,
                bubbles: true, cancelable: true,
            }))"""
        )
        @test wait_for_text("1xyz2@abc") == "1xyz2@abc"
    end
end
