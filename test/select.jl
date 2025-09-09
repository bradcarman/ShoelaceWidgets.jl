using Test
using Bonito
using ShoelaceWidgets


select = SLSelect("Test", ["one", "two", "three"])
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            select
        )
    )
end
# Bonito.Server(app, "0.0.0.0", 80)
select.index[] = 1
@test select.value == "one"
push!(select, "four")
select.index[] = 4
@test select.value == "four"
empty!(select)
@test isnothing(select.value)