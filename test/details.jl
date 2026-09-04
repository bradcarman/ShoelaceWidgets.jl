using Test
using Bonito
using ShoelaceWidgets


select = SLSelect(["one", "two", "three"]; label="Test", index=1)
details = SLDetails(DOM.div(select); summary="Select a Test")

on(details.open) do open
    @show open
end


app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            DOM.h1("Hello World"),
            details
        )
    )
end
details.open[] = true





details.value[] = DOM.div("Test 2")

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
port = 80
url = "0.0.0.0"
server = Bonito.Server(app, url, port)

@test true

# ----------------------------------------
# Dark mode
#
# The summary of `sl-details` inherits its color from the page, so a dark page
# used to leave the title invisible on the still light panel.  Both the theme
# tokens and the color pinned by `STYLE_CSS` need to be in place.
# ----------------------------------------

head_html(; kw...) = join(repr(MIME"text/html"(), el) for el in get_shoelace(; kw...))

auto = head_html()
@test occursin("themes/light.css", auto)
@test occursin("themes/dark.css", auto)
@test occursin("(prefers-color-scheme: light)", auto)
@test occursin("(prefers-color-scheme: dark)", auto)
@test occursin("sl-theme-dark", auto)

light = head_html(; theme=:light)
@test occursin("themes/light.css", light)
@test !occursin("themes/dark.css", light)
@test !occursin("prefers-color-scheme", light)
@test !occursin("sl-theme-dark", light)

dark = head_html(; theme=:dark)
@test occursin("themes/dark.css", dark)
@test !occursin("themes/light.css", dark)
@test !occursin("prefers-color-scheme", dark)
@test occursin("sl-theme-dark", dark)

# the summary must take its color from a theme token rather than inherit it
@test occursin("sl-details::part(base)", auto)

@test_throws ArgumentError get_shoelace(; theme=:blue)

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace(; theme=:dark)...
        ),
        DOM.body(
            DOM.h1("Hello World"),
            SLDetails(DOM.div(SLSelect(["one", "two", "three"]; label="Test", index=1)); summary="Select a Test")
        )
    )
end

@test true
