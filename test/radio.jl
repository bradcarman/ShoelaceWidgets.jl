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

radio = SLRadioGroup([SLRadio("one"; disabled=true), SLRadio("two")]; label="Test", help="test <strong>test</strong>")
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

insert!(radio, 1, SLRadio("one"))
popat!(radio, 2)
radio.index=1
radio.index=2

select1 = SLSelect(["A", "B"])
option1 = SLRadio(DOM.div("option 1", select1; style="display:flex; align-items: center; gap: 0.5rem"); object=select1)
option2 = SLRadio(DOM.div(SLSelect(["C", "D"]; label="option 2"); style="display:flex; align-items: center; gap: 0.5rem"))
option3 = SLRadio(DOM.div(SLSelect(["C", "D"]; label="option 3")))


radio = SLRadioGroup([option1, option2, option3]; label="Complex Options")
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