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
@test input.value[] == "Hello World"
input.disabled[] = true
input.disabled[] = false

input = SLInput(0.0; help="<ul><li>1 = bad</li><li>10 = good</li></ul>")
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


input = SLInput(Date(now()))
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

input.value[] = "2026-03-01"

#=
struct SLInput{T}
    value::Observable{T}
    label::String
    type::String
    help::String
    placeholder::String
    disabled::Observable{Bool}
end
=#
input = SLInput{String}(Observable(""), "Date", "date", "", "Date", Observable(false))
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

file = Bonito.FileInput()
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            file
        )
    )
end

#=
port = 80
url = "0.0.0.0"
server = Bonito.Server(app, url, port)
=#