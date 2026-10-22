using Test
using Bonito
using ShoelaceWidgets
using Markdown


textarea = SLTextarea(""; label="Comments", placeholder="Enter your comments here", help="test <strong>test</strong>")

display = Observable{Markdown.MD}()

on(textarea.value) do text
    println("Textarea value: $text")
    display[] = Markdown.MD(Markdown.parse(text))
end

app = App() do session
    DOM.div(
        textarea,
        display
    )
end

textarea.value[] = "Test content"
textarea.disabled[] = true
textarea.rows[] = 10

@test true
