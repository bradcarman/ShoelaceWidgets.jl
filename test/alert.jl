using Test
using Bonito
using ShoelaceWidgets

alert = SLAlert(DOM.div(DOM.strong("This is super informative"), DOM.br(), DOM.div("You can tell by how pretty the alert is.")))
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            alert            
        )
    )
end

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
# port = 80
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)
alert.open[] = false
alert.open[] = true

@test true