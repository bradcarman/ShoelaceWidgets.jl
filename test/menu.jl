using Test
using Bonito
using ShoelaceWidgets


wrap = SLMenuItem("Word wrap"; checkbox=true, checked=true)
paste = SLMenuItem("Paste"; disabled=true)

menu = SLMenu([
    SLMenuLabel("Edit"),
    SLMenuItem("Undo"; prefix=sl_icon(; name="arrow-counterclockwise"), suffix="Ctrl+Z"),
    SLMenuItem("Copy"; value="copy"),
    paste,
    sl_divider(),
    SLMenuLabel("View"),
    wrap,
    SLMenuItem("Zoom"; submenu=[
        SLMenuItem("Zoom in"; value="zoom-in"),
        SLMenuItem("Zoom out"; value="zoom-out"),
    ]),
]; style="max-width: 200px;")

on(menu.value) do value
    println("Selected: $value")
end

on(wrap.checked) do checked
    println("Word wrap: $checked")
end

app = App() do session
    menu
end

@test menu.value[] == ""
@test length(menu.items[]) == 8
@test wrap.checkbox
@test wrap.checked[]
@test paste.disabled[]
@test menu.items[][3].value == "copy"
@test menu.items[][2].value == "Undo"

paste.disabled[] = false
wrap.checked[] = false

push!(menu, SLMenuItem("Delete"))
@test length(menu.items[]) == 9
popat!(menu, 9)
@test length(menu.items[]) == 8
empty!(menu)
@test isempty(menu.items[])
