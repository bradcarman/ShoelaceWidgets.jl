using Test
using Bonito
using ShoelaceWidgets


checkbox = SLCheckbox("Accept terms"; help="test <strong>test</strong>")

on(checkbox.value) do checked
    println("Checkbox state: $checked")
end

app = App() do session
    checkbox
end

checkbox.value[] = true
checkbox.disabled[] = true


@test true
