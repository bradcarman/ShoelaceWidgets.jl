using Test
using Bonito
using ShoelaceWidgets


checkbox = SLCheckbox("Accept terms")

on(checkbox.value) do checked
    println("Checkbox state: $checked")
end

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            checkbox
        )
    )
end

checkbox.value[] = true
checkbox.disabled[] = true


@test true
