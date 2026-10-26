using Test
using Bonito
using ShoelaceWidgets


close_button = SLButton("Close"; variant="primary")
drawer = SLDrawer(DOM.div("Drawer content"); label="Settings", footer=close_button)

on(close_button.value) do _
    drawer.open[] = false
end

on(drawer.open) do open
    @show open
end

app = App() do session
    DOM.div(DOM.h1("Hello World"), drawer; style="height:300px; background-color:gray")
end

@test !drawer.open[]
@test drawer.placement == "end"
drawer.open[] = true
@test drawer.open[]
drawer.value[] = DOM.div("Drawer content 2")


contained = SLDrawer(DOM.div("Contained content"); label="Contained", placement="start", contained=true, no_header=true)

app = App() do session
    DOM.div(contained; style="position: relative; height: 300px; border: dashed 1px var(--sl-color-neutral-200); overflow: hidden;")
end

@test contained.contained
@test contained.no_header
@test isnothing(contained.footer)

@test_throws ArgumentError SLDrawer(DOM.div("x"); placement="left")
