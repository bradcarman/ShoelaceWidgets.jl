using Test
using Bonito
using ShoelaceWidgets
using Dates


input = SLInput(""; label="Test", placeholder="Name")
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end

input.value[] = "Hello World"
# change to Brad
@test input.value[] == "Hello World"

input = SLInput(0.0; help="enter a number from 1 to 10")
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end


input = SLInput(NaN)
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end


input = SLInput(NaN)
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end


input = SLInput{String}(Observable(""), "Date", "date", "", "Date")
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end