using Test
using Bonito
using ShoelaceWidgets


button = SLButton("Test"; style="padding:5px")

on(button.value) do x::Union{Session,Nothing}
    println("Hello World")
    if x isa Session
        button.loading[] = true
        println("openning google...")
        sleep(1)
        #NOTE: this only works in the browser, if in VS Code Plot Pane, use Bonito.HTTPServer.openurl
        Bonito.evaljs(x, js"window.open(`https://www.google.com/`, '_blank')")
        button.loading[] = false
    end
end

app = App() do session
    sl_tooltip(button; content="click me")
end

button.disabled[] = true



button = SLButton("Test"; disabled=true, style="padding:5px")

app = App() do session
    DOM.div(SLTheme(:dark), button)
end


link_button = SLButton("Open Google"; href="https://www.google.com/", target="_blank", rel="noreferrer noopener", style="padding:5px")
on(link_button.value) do session
    println("clicked...")
end


app = App() do session
    link_button
end


@test true