// Taken from THREEJS documentation

export function getWebGLErrorMessage() {
    return getErrorMessage(1);
}

function getErrorMessage(version) {
    var names = {
        1: "WebGL",
        2: "WebGL 2",
    };

    var contexts = {
        1: window.WebGLRenderingContext,
        2: window.WebGL2RenderingContext,
    };

    var message =
        'Your $0 does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation" style="color:#000">$1</a>';

    var element = document.createElement("div");
    element.id = "webglmessage";
    element.style.fontFamily = "monospace";
    element.style.fontSize = "13px";
    element.style.fontWeight = "normal";
    element.style.textAlign = "center";
    element.style.background = "#fff";
    element.style.color = "#000";
    element.style.padding = "1.5em";
    element.style.width = "400px";
    element.style.margin = "5em auto 0";

    if (contexts[version]) {
        message = message.replace("$0", "graphics card");
    } else {
        message = message.replace("$0", "browser");
    }

    message = message.replace("$1", names[version]);

    element.innerHTML = message;

    return element;
}
