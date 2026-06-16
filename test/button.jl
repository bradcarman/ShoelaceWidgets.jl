using Test
using Bonito
using ShoelaceWidgets


button = SLButton("Test")

on(button.value) do x::Union{Session,Nothing}
    println("Hello World")
    if x isa Session
        button.loading[] = true
        println("openning google...")
        sleep(1)
        #NOTE: this only works in the browser, if in VS Code Plot Pane, use Bonito.HTTPServer.openurl
        Bonito.evaljs(x, js"window.open(`https://www.google.com/`, '_blank')")
        button.loading[] = false
    end
end

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            sl_tooltip(button; content="click me")
        )
    )
end

button.disabled[] = true



button = SLButton("Test"; disabled=true)

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            button
        )
    )
end


@test true