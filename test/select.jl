using Test
using Bonito
using ShoelaceWidgets

select = SLSelect(["one", "two", "three"]; label="Test", help="test <strong>test</strong>")
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

select.index[]=1
insert!(select, 1, "four")

@test select.index[] == 1
@test select.value == "four"





select = SLSelect(["one", "two", "three"]; label="Test", index=1)
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
@test select.value == "one"
push!(select, "four")
select.index[] = 4
@test select.value == "four"

popat!(select, select.index[])
@test select.value == "three"

select.index[] = 1
popat!(select, select.index[])
@test select.index[] == 0
@test isnothing(select.value)
select.index[] = 1
@test select.value == "two"

empty!(select)
@test isnothing(select.value)

