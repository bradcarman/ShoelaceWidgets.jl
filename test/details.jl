using Test
using Bonito
using ShoelaceWidgets


select = SLSelect(["one", "two", "three"]; label="Test", index=1)
details = SLDetails(DOM.div(select); summary="Select a Test")

on(details.open) do open
    @show open
end


app = App() do session
    DOM.div(
        DOM.h1("Hello World"),
        details
    )
end
details.open[] = true





details.value[] = DOM.div("Test 2")

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
# port = 80
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)

@test true

# ----------------------------------------
# Dark mode
#
# The summary of `sl-details` inherits its color from the page, so a dark page
# used to leave the title invisible on the still light panel.  Both the theme
# tokens and the color pinned in `assets/shoelace_widgets.css` need to be in place.
# ----------------------------------------

asset_text(asset) = read(Bonito.local_path(asset), String)

css = asset_text(ShoelaceWidgets.SHOELACE_CSS)
js = read(ShoelaceWidgets.SHOELACE_LOADER_FILE, String)

# the summary must take its color from a theme token rather than inherit it
@test occursin("sl-details::part(base)", css)

# the loader brings in both themes, gated on the system setting unless forced
@test occursin("/themes/", js)
@test occursin("prefers-color-scheme", js)
@test occursin("sl-theme-dark", js)
@test occursin("shoelace-autoloader.js", js)

# a bare widget registers the stylesheet and the loader with the session, once per render
session = Session(NoConnection(); asset_server=NoServer())
Bonito.jsrender(session, DOM.div(SLDetails(DOM.div("a"); summary="a"), SLDetails(DOM.div("b"); summary="b"), sl_card("c")))
@test collect(session.imports) == [ShoelaceWidgets.SHOELACE_CSS]
@test count(js -> js === ShoelaceWidgets.SHOELACE_LOADER, session.on_document_load) == 1

@test SLTheme(:dark).theme == :dark
@test_throws ArgumentError SLTheme(:blue)

# `get_shoelace` is deprecated but still works, passing a forced theme to the loader
head_html(; kw...) = join(repr(MIME"text/html"(), el) for el in get_shoelace(; kw...) if el isa Bonito.Hyperscript.Node)
@test !occursin("slTheme", head_html())
@test occursin("slTheme = 'dark'", head_html(; theme=:dark))
@test_throws ArgumentError get_shoelace(; theme=:blue)

app = App() do session
    DOM.div(
        DOM.h1("Hello World"),
        SLDetails(DOM.div(SLSelect(["one", "two", "three"]; label="Test", index=1)); summary="Select a Test"),
        SLTheme(:dark)
    )
end

@test true
