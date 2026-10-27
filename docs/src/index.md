# ShoelaceWidgets.jl

ShoelaceWidgets.jl provides Julia bindings for [Shoelace](https://shoelace.style/) web components, enabling you to create interactive web UIs in Julia using the Bonito.jl framework.

## Installation

```julia
using Pkg
Pkg.add("ShoelaceWidgets")
```

## Quick Start

To get started with ShoelaceWidgets.jl you simply need to include Bonito.jl.  The following example shows how to provide an input box.

```@example quickstart
using ShoelaceWidgets
using Bonito

# Create an input widget
input = SLInput(""; label="Enter text:", placeholder="Type something...", help="help text can be in <strong>HTML</strong>")

# Create a Bonito app
app = App() do session
    input
end
```


Every widget loads Shoelace itself: the first one on a page adds the Shoelace scripts and styles
to the document head, so an app can return a widget directly without any setup.

### Dark Mode

By default the widgets follow the browser/OS color scheme: both Shoelace themes are loaded,
each gated on `prefers-color-scheme`, so changing the system theme reskins a running page without a
reload.  Place an `SLTheme` anywhere in the app to pin one instead:

```julia
app = App() do session
    DOM.div(
        SLTheme(:dark),  # or :light, :auto is the default
        input
    )
end
```

Shoelace themes only define CSS custom properties, they never style the page itself, so
ShoelaceWidgets.jl also sets the document background and text color from those tokens the way
[shoelace.style](https://shoelace.style/) does.  Those rules use `:where(body)`, which has zero
specificity, so any styling of your own overrides them.

### More Examples

#### Button
Create a button with click handling:

```@example quickstart
# Create button
btn = SLButton("Click Me"; variant="primary")

# Set up click handler
on(btn.value) do _
    btn.loading[] = true
    println("Button was clicked!")
    sleep(2)
    btn.loading[] = false
end

app = App() do session
    btn
end
```

Setting `href` renders the button as a link, opening a URL instead of firing a click handler:

```@example quickstart
link_btn = SLButton("Visit Julia"; href="https://julialang.org/", target="_blank", rel="noreferrer noopener")

app = App() do session
    link_btn
end
```


#### Dropdown
Create a dropdown select:

```@example quickstart
# Create select widget
select = SLSelect(["Small", "Medium", "Large"]; label="Choose size", index=1)

on(select.index) do i
    println("Selected value: $(select.value)")
end

app = App() do session
    select
end
```

Use `placeholder` to show hint text when no option is selected (`index=0`):

```@example quickstart
select = SLSelect(["Small", "Medium", "Large"]; label="Choose size", placeholder="Select a size...")
```

#### Progress Bar
Create a progress bar with reactive updates:

```@example quickstart
# Create progress bar
progress = SLProgressBar(0.0; label="Loading", height="20px")

# Simulate progress updates
@async begin
    for i in 0:10:100
        sleep(0.5)
        progress.value[] = i
    end
end

app = App() do session
    progress
end
```
You can also show and hide progress bars dynamically:

```@example quickstart
# Create initially hidden progress bar
progress = SLProgressBar(50.0; visible=false, label="Background task")

# Show the progress bar
progress.visible[] = true

# Hide it again
progress.visible[] = false
```

#### Alert
Create an alert to display information...

```@example quickstart
alert = SLAlert(DOM.div(DOM.strong("This is super informative"), DOM.br(), DOM.div("You can tell by how pretty the alert is.")))
app = App() do session
    alert
end
```

#### Drawer
Create a drawer that slides in from an edge of the page. `open` controls its visibility, and is set back
to `false` when the user closes it:

```@example quickstart
close_button = SLButton("Close"; variant="primary")
drawer = SLDrawer(DOM.div("Drawer content"); label="Settings", placement="end", footer=close_button)

on(close_button.value) do _
    drawer.open[] = false
end

open_button = SLButton("Open Drawer")
on(open_button.value) do _
    drawer.open[] = true
end

app = App() do session
    DOM.div(open_button, drawer)
end
```

Use `contained=true` to open the drawer inside its parent element instead of over the page; the parent
needs `position: relative`.

#### Menu
Create a menu of selectable items. `value` holds the value of the last selected item, and checkbox
items track their state in `checked`:

```@example quickstart
wrap = SLMenuItem("Word wrap"; checkbox=true)

menu = SLMenu([
    SLMenuLabel("Edit"),
    SLMenuItem("Undo"; prefix=sl_icon(; name="arrow-counterclockwise"), suffix="Ctrl+Z"),
    SLMenuItem("Copy"; value="copy"),
    sl_divider(),
    SLMenuLabel("View"),
    wrap,
    SLMenuItem("Zoom"; submenu=[
        SLMenuItem("Zoom in"; value="zoom-in"),
        SLMenuItem("Zoom out"; value="zoom-out"),
    ]),
]; style="max-width: 200px;")

on(menu.value) do value
    println("Selected: ", value)
end

on(wrap.checked) do checked
    println("Word wrap: ", checked)
end

app = App() do session
    menu
end
```


## Available Components

ShoelaceWidgets.jl provides Julia wrappers for common Shoelace components:

### Web Components
- [`SLInput`](@ref) - Text input fields with various types
- [`SLSelect`](@ref) - Dropdown selection components
- [`SLButton`](@ref) - Interactive buttons
- [`SLCheckbox`](@ref) - Checkbox controls
- [`SLTextarea`](@ref) - Multi-line text input
- [`SLRadio`](@ref) / [`SLRadioGroup`](@ref) - Radio button controls (also available as `SLListItem` / `SLList` that provide different selection styling )
- [`SLProgressBar`](@ref) - Progress indicators and loading bars
- [`SLDialog`](@ref) - Dialog window
- [`SLDrawer`](@ref) - Panel that slides in from an edge of the page
- [`SLAlert`](@ref) - Alerts used to display important messages inline
- [`SLMenu`](@ref) / [`SLMenuItem`](@ref) / [`SLMenuLabel`](@ref) - Menus of selectable items, with checkbox items and submenus

### UI Elements
- `sl_tab_group`, `sl_tab`, `sl_tab_panel` - Tab navigation

```@example quickstart
tabs = sl_tab_group(
    
    sl_tab("Tab 1"; slot="nav", panel="tab1"),
    sl_tab("Tab 2"; slot="nav", panel="tab2"),
    

    sl_tab_panel(DOM.div("Hello World"); name="tab1"),
    sl_tab_panel(DOM.div("Goodbye"); name="tab2")
)

app = App() do session
    tabs
end
```

- `sl_tag` - Tags for labels and categories
- `sl_format_date` - Date formatting
- `sl_spinner` - Loading indicators
- `sl_icon` - Icons from the [Shoelace Icon Library](https://shoelace.style/components/icon)
- `sl_tooltop` - Tooltip display during mouse hover 

```@example quickstart
button = SLButton("Test")

app = App() do session
    sl_tooltip(button; content="click me")
end
```

- `sl_divider` - Visual separator, e.g. between groups of menu items
- `sl_copy_button` - send contents of value to the clipboard
```@example quickstart
app = App() do session
    DOM.div("Copy Button:", sl_copy_button(;value="clipboard contents"))
end
```

## Learn More

- Check out the [API Reference](api.md) for detailed documentation of all components
- Visit the [Shoelace documentation](https://shoelace.style/) to learn more about the underlying web components
- See the [Bonito.jl documentation](https://bonito.jl.org/) for information about the Julia web framework