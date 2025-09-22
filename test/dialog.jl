using Test
using Bonito
using ShoelaceWidgets


input = SLInput(""; label="Test", placeholder="Name")
body = DOM.div(
    DOM.h1("Test"),
    input; 
    style="height: 150vh; border: dashed 2px var(--sl-color-neutral-200); padding: 0 1rem;"
)
dialog = SLDialog(body; label="Test")

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            dialog
        )
    )
end
dialog.open[] = true

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
# port = 80
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)

@test true