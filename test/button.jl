using Test
using Bonito
using ShoelaceWidgets


button = SLButton("Test")

on(button.value) do x
    println("Hello World")
end

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