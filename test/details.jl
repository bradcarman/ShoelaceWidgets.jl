using Test
using Bonito
using ShoelaceWidgets


select = SLSelect(["one", "two", "three"]; label="Test", index=1)
details = SLDetails(DOM.div(select); summary="Select a Test")

on(details.open) do open
    @show open
end


app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            DOM.h1("Hello World"),
            details
        )
    )
end
details.open[] = true





details.value[] = DOM.div("Test 2")

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
# port = 80
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)

@test true