using Test
using Bonito
using ShoelaceWidgets

radio = SLRadioGroup(SLRadio.(["one", "two", "three"]); label="Test")
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

radio = SLRadioGroup([SLRadio("one"; disabled=true), SLRadio("two")]; label="Test")
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