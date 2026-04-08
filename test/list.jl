using Test
using Bonito
using ShoelaceWidgets

item1 = SLListItem("test 1")
item2 = SLListItem(DOM.a("test 2"; href="https://www.google.com/"))

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