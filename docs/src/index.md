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
input = SLInput(""; label="Enter text:", placeholder="Type something...")

# Create a Bonito app
app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            input
        )
    )
end
```


The `get_shoelace()` function returns the necessary Shoelace CSS and JavaScript includes that should be added to your document head.

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
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            btn
        )
    )
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
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            select
        )
    )
end
```


## Available Components

ShoelaceWidgets.jl provides Julia wrappers for common Shoelace components:

### Web Components
- [`SLInput`](@ref) - Text input fields with various types
- [`SLSelect`](@ref) - Dropdown selection components
- [`SLButton`](@ref) - Interactive buttons
- [`SLRadio`](@ref) / [`SLRadioGroup`](@ref) - Radio button controls
- [`SLTree`](@ref) / [`SLTreeItem`](@ref) - Tree menu
- [`SLDialog`](@ref) - Dialog window


### UI Elements
- `sl_tab_group`, `sl_tab`, `sl_tab_panel` - Tab navigation
- `sl_tag` - Tags for labels and categories
- `sl_format_date` - Date formatting
- `sl_spinner` - Loading indicators
- `sl_icon` - Icons from the Shoelace icon library

## Learn More

- Check out the [API Reference](api.md) for detailed documentation of all components
- Visit the [Shoelace documentation](https://shoelace.style/) to learn more about the underlying web components
- See the [Bonito.jl documentation](https://bonito.jl.org/) for information about the Julia web framework