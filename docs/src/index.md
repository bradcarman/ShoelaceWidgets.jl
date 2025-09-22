# ShoelaceWidgets.jl

ShoelaceWidgets.jl provides Julia bindings for [Shoelace](https://shoelace.style/) web components, enabling you to create interactive web UIs in Julia using the Bonito.jl framework.

## Installation

```julia
using Pkg
Pkg.add("ShoelaceWidgets")
```

## Quick Start

To get started with ShoelaceWidgets.jl, you need to include the Shoelace CSS and JavaScript files in your HTML head:

```julia
using ShoelaceWidgets
using Bonito

app = App() do session::Session
    input = SLInput("Hello World"; label="Enter text:", placeholder="Type something...")
    
    return DOM.div(
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

## Available Components

ShoelaceWidgets.jl provides Julia wrappers for common Shoelace components:

### Input Components
- [`SLInput`](@ref) - Text input fields with various types
- [`SLSelect`](@ref) - Dropdown selection components
- [`SLButton`](@ref) - Interactive buttons
- [`SLRadio`](@ref) / [`SLRadioGroup`](@ref) - Radio button controls

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