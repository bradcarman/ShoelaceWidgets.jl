using Test
using Bonito
using ShoelaceWidgets


textarea = SLTextarea(""; label="Comments", placeholder="Enter your comments here", help="test <strong>test</strong>")

on(textarea.value) do text
    println("Textarea value: $text")
end

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            textarea
        )
    )
end

textarea.value[] = "Test content"
textarea.disabled[] = true
textarea.rows[] = 10

@test true
