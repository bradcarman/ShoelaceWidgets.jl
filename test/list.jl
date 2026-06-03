using Test
using Bonito
using ShoelaceWidgets

button = SLButton("Test")

on(button.value) do x
    println("Hello World")
end

item1 = SLListItem(DOM.div("test 1", button))
item2 = SLListItem("test 2")

radio = SLList([item1, item2]; label="Test")
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            radio
        )
    )
end
# Bonito.Server(app, "0.0.0.0", 80)
radio.value[] = "1"
@test radio.value[] == "1"
@test radio.index == 1
radio.index = 2
@test radio.index == 2

radio = SLList([SLListItem("one"; disabled=true), SLListItem("two")]; label="Test")
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            radio
        )
    )
end

@test true