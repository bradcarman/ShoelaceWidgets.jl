# ShoelaceWidgets.jl
Implemented Widgets for [Shoelace](https://shoelace.style/) web components using [Bonito](https://simondanisch.github.io/Bonito.jl/stable/)

Currently implemented:
- Input
- Button 
- Select
- Radio

# Example
The following code produces an app with an input field.  On the Julia side, the `input` object contains the field `value` which is an Observable that stays synced with the contents of the input field.

```julia; eval=false
using Bonito
using ShoelaceWidgets

input = SLInput(""; label="Test", placeholder="Name")
app = App() do session
    input
end
```

```julia; echo=false, results="html"
using Bonito
using ShoelaceWidgets
input = SLInput(""; label="Test", placeholder="Name")
input
```




