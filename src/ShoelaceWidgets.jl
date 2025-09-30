module ShoelaceWidgets
using Bonito: m, @js_str
using Bonito
using Hyperscript
using Dates

# header
export get_shoelace

# controls
export SLInput, SLSelect, SLButton, SLRadio, SLRadioGroup, SLDialog, SLTree, SLTreeItem

# tags
export sl_tab_group, sl_tab, sl_tab_panel, sl_tag, sl_format_date, sl_spinner, sl_icon, sl_card



# ----------------------------------------

"""
    get_shoelace()

Returns an array of DOM elements (link and script tags) needed to load the Shoelace web component library from CDN.
This should be included in the document head of your Bonito application.

# Example
```julia
app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(input)
    )
end
```
"""
get_shoelace() = [
    DOM.link(;rel="stylesheet", href="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/themes/light.css"),
    DOM.script(;type="module", src="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/shoelace-autoloader.js")
]

"""
    sl_tab_group(args...; kw...)

Creates a Shoelace tab group component. Tab groups organize content into multiple panels with tab navigation.
"""
sl_tab_group(args...; kw...) = m("sl-tab-group", args...; kw...)

"""
    sl_tab(args...; kw...)

Creates a Shoelace tab component. Tabs are used as navigation items within a tab group.
"""
sl_tab(args...; kw...) = m("sl-tab", args...; kw...)

"""
    sl_tab_panel(args...; kw...)

Creates a Shoelace tab panel component. Tab panels contain the content associated with each tab.
"""
sl_tab_panel(args...; kw...) = m("sl-tab-panel", args...; kw...)

"""
    sl_tag(args...; kw...)

Creates a Shoelace tag component. Tags are used for labels, categories, and keyword indicators.
"""
sl_tag(args...; kw...) = m("sl-tag", args...; kw...)

"""
    sl_format_date(args...; kw...)

Creates a Shoelace date formatting component. Formats dates according to specified locale and options.
"""
sl_format_date(args...; kw...) = m("sl-format-date", args...; kw...)

"""
    sl_spinner(args...; kw...)

Creates a Shoelace spinner component. Spinners indicate loading or processing states.
"""
sl_spinner(args...; kw...) = m("sl-spinner", args...; kw...)

"""
    sl_icon(args...; kw...)

Creates a Shoelace icon component. Icons provide visual representations from the Shoelace icon library.
"""
sl_icon(args...; kw...) = m("sl-icon", args...; kw...)

sl_card(args...; kw...) = m("sl-card", args...; kw...)

# ----------------------------------------
# Input
# ----------------------------------------
sl_input(args...; kw...) = m("sl-input", args...; kw...)

"""
    SLInput(default; label="", help="", placeholder="")

Creates a reactive input field widget. The input value is synchronized with Julia through an Observable.

# Fields
- `value::Observable{T}` - Observable containing the current input value
- `label::String` - Label text displayed above the input
- `type::String` - HTML input type (automatically determined from value type)
- `help::String` - Help text displayed below the input
- `placeholder::String` - Placeholder text shown when input is empty

# Examples
```julia
# Text input
input = SLInput(""; label="Name", placeholder="Enter your name")

# Number input
num_input = SLInput(0.0; help="Enter a number from 1 to 10")

# Date input
date_input = SLInput(Date(2024, 1, 1); label="Select date")

# Access the value
println(input.value[])  # Get current value
input.value[] = "New value"  # Set value
```
"""
struct SLInput{T}
    value::Observable{T}
    label::String
    type::String
    help::String
    placeholder::String
end

get_type(::Type{String}) = ""
get_type(::Type{T}) where T <: Number = "number"

SLInput(default::T; label::String="", help::String="", placeholder::String="") where T = SLInput{T}(Observable(default), label, get_type(T), help, placeholder)
SLInput(default::Date; label::String="", help::String="")  = SLInput{String}(Observable(string(default)), label, "date", help, "Date")

function Bonito.jsrender(session::Session, x::SLInput{T}) where T

    setup = js"""
    function onload(element) {
        function onchange(e) {
            if ($(x.type) == "number"){
                $(x.value).notify(Number(element.value))
            } else {
                console.log(element.value)
                $(x.value).notify(element.value)
            }
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    dom = if T <: Number
        sl_input(; label=x.label, type=x.type, value=x.value, helpText=x.help, placeholder=x.placeholder)
    else
        sl_input(; label=x.label, type=x.type, value=x.value, helpText=x.help, clearable=nothing, placeholder=x.placeholder)
    end

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Select
# ----------------------------------------
sl_option(args...; kw...) = m("sl-option", args...; kw...)
sl_select(args...; kw...) = m("sl-select", args...; kw...)

"""
    SLSelect(values; label="", index=0)

Creates a dropdown select widget with reactive selection tracking.

# Fields
- `label::String` - Label text displayed above the dropdown
- `options::Observable{Vector{Hyperscript.Node}}` - Observable containing the option elements
- `values::Vector{T}` - Array of selectable values
- `index::Observable{Int}` - Observable containing the currently selected index (1-based)
- `value` - Computed property returning `values[index[]]` (the currently selected value)

# Methods
- `push!(select, value)` - Add a new option
- `empty!(select)` - Remove all options
- `popat!(select, i)` - Remove option at index i

# Examples
```julia
# Create select with string options
select = SLSelect(["Option 1", "Option 2", "Option 3"]; label="Choose one", index=1)

# Access selected value
println(select.value)  # Returns "Option 1"

# Change selection
select.index[] = 2

# Add new option dynamically
push!(select, "Option 4")
```
"""
struct SLSelect{T}
    label::String
    options::Observable{Vector{Hyperscript.Node}}
    values::Vector{T}
    index::Observable{Int}
    # value from getproperty
end

function get_options(values::Vector)
    options = Hyperscript.Node[]
    for (i,x) in enumerate(values)
        push!(options, sl_option(x; value=i))
    end
    return options
end

function SLSelect(values::Vector{T}; label::String = "", index=0) where T 
    
    return SLSelect(label, Observable(get_options(values)), values, Observable(index))
end

function Base.getproperty(x::SLSelect, name::Symbol)
    if name == :value
        if !isempty(x.values) & (x.index[] > 0)
            return x.values[x.index[]]
        else
            return nothing
        end
    else
        return getfield(x, name)
    end
end

function Base.push!(x::SLSelect{T}, value::T) where T
    push!(x.values, value)
    push!(x.options[], sl_option(value; value=length(x.values)))
    notify(x.options)
end

function Base.empty!(x::SLSelect)
    empty!(x.values)
    empty!(x.options[])
    x.index[] = 0
    notify(x.options)
end

function Base.popat!(x::SLSelect, i::Int)
    popat!(x.values, i)
    x.options[] = get_options(x.values) #<-- ensure options are re-ordered

    x.index[] = i-1
    notify(x.options)
end

function Bonito.jsrender(session::Session, x::SLSelect)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            $(x.index).notify(parseInt(element.value))
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    dom = sl_select(x.options; label=x.label, value=string(x.index[]))
    update_value = js""" function (value) { 
        $(dom).value = value.toString()
        } 
    """
    onjs(session, x.index, update_value)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end

# ----------------------------------------
# Button
# ----------------------------------------
sl_button(args...; kw...) = m("sl-button", args...; kw...)

"""
    SLButton(label; disabled=false, variant=nothing)

Creates a clickable button widget with reactive state management.

# Fields
- `value::Observable{Bool}` - Observable that triggers (set to true) when button is clicked
- `disabled::Observable{Bool}` - Observable controlling whether button is disabled
- `label::String` - Button text label
- `loading::Observable{Bool}` - Observable controlling loading spinner state
- `variant::Union{String, Nothing}` - Button style variant (e.g., "primary", "success", "danger")

# Examples
```julia
# Create button
btn = SLButton("Click Me"; variant="primary")

# React to button clicks
on(btn.value) do _
    println("Button was clicked!")
end

# Disable button
btn.disabled[] = true

# Show loading state
btn.loading[] = true
```
"""
struct SLButton
    value::Observable{Bool}
    disabled::Observable{Bool}
    label::String
    loading::Observable{Bool}
    variant::Union{String, Nothing}
end

SLButton(label::String; disabled::Bool = false, variant=nothing) = SLButton(Observable(true), Observable(disabled), label, Observable(false), variant)

function Bonito.jsrender(session::Session, x::SLButton)

    click = js"""
        function (value) { 
            $(x.value).notify(true)
        } 
    """

    kwargs = Pair[]
    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    if !isnothing(x.variant)
        push!(kwargs, :variant => x.variant)
    end

    dom = sl_button(x.label; onclick=click, kwargs...)

    
    disable = js"""
        function (value) {
            if (value) {
                $(dom).setAttribute("disabled","")
            } else {
                $(dom).removeAttribute("disabled")
            }
        }
    """
    onjs(session, x.disabled, disable)

    loading = js"""
        function (value) {
            if (value) {
                $(dom).setAttribute("loading","")
            } else {
                $(dom).removeAttribute("loading")
            }
        }
    """
    onjs(session, x.loading, loading)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Radio
# ----------------------------------------
sl_radio_group(args...; kw...) = m("sl-radio-group", args...; kw...)
sl_radio(args...; kw...) = m("sl-radio", args...; kw...)

"""
    SLRadio(value; disabled=false, object=nothing)

Represents a single radio button option within a radio group.

# Fields
- `value::String` - Display text for the radio button
- `disabled::Bool` - Whether this option is disabled
- `object::Any` - Optional associated data object

# Example
```julia
radio1 = SLRadio("Option A"; object=1)
radio2 = SLRadio("Option B"; object=2, disabled=true)
```
"""
struct SLRadio
    value::String
    disabled::Bool
    object::Any
end
SLRadio(value::String; disabled=false, object=nothing) = SLRadio(value, disabled, object)

"""
    SLRadioGroup(values; label="", index=0)

Creates a radio button group widget with reactive selection tracking.

# Fields
- `label::String` - Label text displayed above the radio group
- `options::Observable{Vector{Hyperscript.Node}}` - Observable containing the radio button elements
- `values::Vector{SLRadio}` - Array of SLRadio options
- `value::Observable{String}` - Observable containing the selected index as a string
- `index` - Computed property returning the currently selected index (Int or nothing)
- `object` - Computed property returning the associated object of the selected radio

# Methods
- `push!(group, radio)` - Add a new radio button
- `empty!(group)` - Remove all radio buttons
- `popat!(group, i)` - Remove radio button at index i
- `setproperty!(group, :index, i)` - Set selection by index

# Examples
```julia
# Create radio group
radios = [
    SLRadio("Small"; object="S"),
    SLRadio("Medium"; object="M"),
    SLRadio("Large"; object="L")
]
group = SLRadioGroup(radios; label="Select size", index=1)

# Access selected value
println(group.index)   # Returns 1
println(group.object)  # Returns "S"

# Change selection
group.index = 2
```
"""
struct SLRadioGroup
    label::String
    options::Observable{Vector{Hyperscript.Node}}
    values::Vector{SLRadio}
    value::Observable{String}
    # index from getproperty
    # object from getproperty
end

function get_sl_radio(x::SLRadio, i::Int)
    r = if x.disabled
        sl_radio(x.value; value=string(i), disabled=true)
    else
        sl_radio(x.value; value=string(i))
    end

    return r
end

function SLRadioGroup(values::Vector{SLRadio}; label::String = "", index=0) 
    options = Hyperscript.Node[]
    for (i,x) in enumerate(values)
        push!(options, get_sl_radio(x, i))
    end
    return SLRadioGroup(label, Observable(options), values, Observable(string(index)))
end

function Base.getproperty(x::SLRadioGroup, name::Symbol)
    if name == :index
        i = tryparse(Int, x.value[])
        return i
    elseif name == :object
        i = tryparse(Int, x.value[])
        if !isnothing(i) && (i > 0)
            radio = x.values[i] 
            return radio.object
        else
            return nothing
        end
    else
        return getfield(x, name)
    end
end

function Base.setproperty!(x::SLRadioGroup, name::Symbol, value::Int)
    if name == :index
        x.value[] = string(value)
    end
end

function Base.push!(x::SLRadioGroup, value::SLRadio)
    push!(x.values, value)
    i = length(x.values)
    push!(x.options[], get_sl_radio(value, i))
    notify(x.options)
end

function Base.empty!(x::SLRadioGroup)
    empty!(x.values)
    empty!(x.options[])
    x.value[] = "0"
    notify(x.options)
end

function Base.popat!(x::SLRadioGroup, i::Int)
    popat!(x.values, i)
    popat!(x.options[], i)
    x.value[] = "0"
    notify(x.options)
end

function Bonito.jsrender(session::Session, x::SLRadioGroup)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            console.log(e)
            console.log(element.value)
            $(x.value).notify(element.value)
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    dom = sl_radio_group(x.options; label=x.label, value=x.value)
    update_value = js""" function (value) { 
        $(dom).value = value
        } 
    """
    onjs(session, x.value, update_value)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end

# ----------------------------------------
# Dialog
# ----------------------------------------
sl_dialog(args...; kw...) = m("sl-dialog", args...; kw...)

"""
    SLDialog(content; label="")

Creates a modal dialog widget that can be shown or hidden.

# Fields
- `value::Observable{Hyperscript.Node}` - Observable containing the dialog content
- `label::String` - Dialog title/header text
- `open::Observable{Bool}` - Observable controlling dialog visibility

# Examples
```julia
# Create dialog with content
dialog = SLDialog(DOM.div("This is dialog content"); label="My Dialog")

# Show dialog
dialog.open[] = true

# Hide dialog
dialog.open[] = false

# Update content dynamically
dialog.value[] = DOM.div("New content")
```
"""
struct SLDialog
    value::Observable{Hyperscript.Node}
    label::String
    open::Observable{Bool}
end

SLDialog(value::Hyperscript.Node; label::String) = SLDialog(Observable(value), label, Observable(false))

function Bonito.jsrender(session::Session, x::SLDialog)

    # setup = js"""
    # function onload(element) {
    #     element.addEventListener("sl-change", onchange);
    # }
    # """

    dom = sl_dialog(x.value; label=x.label)
    open_close = js""" function (value) { 
        if (value)
            {
                $(dom).show();
            }else{
                $(dom).hide();
            }
        } 
    """
    onjs(session, x.open, open_close)

    # Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Tree
# ----------------------------------------
sl_tree(args...; kw...) = m("sl-tree", args...; kw...)
sl_tree_item(args...; kw...) = m("sl-tree-item", args...; kw...)

"""
    SLTreeItem(value)
    SLTreeItem(value, children)

Represents a single item in a tree structure.

# Fields
- `value::String` - Display text for the tree item
- `values::Vector{SLTreeItem}` - Child tree items

# Examples
```julia
# Leaf node
item = SLTreeItem("File.txt")

# Node with children
folder = SLTreeItem("Documents", [
    SLTreeItem("Report.pdf"),
    SLTreeItem("Notes.txt")
])
```
"""
struct SLTreeItem
    value::String
    values::Vector{SLTreeItem}

    SLTreeItem(value::String) = new(value, SLTreeItem[])
    SLTreeItem(value::String, values::Vector{SLTreeItem}) = new(value, values)
end

"""
    SLTree(items)

Creates a hierarchical tree menu widget with reactive selection tracking.

# Fields
- `values::Vector{SLTreeItem}` - Array of root-level tree items
- `value::Observable{String}` - Observable containing the selected item's text

# Construction Methods

1. **Using SLTreeItem objects**:
```julia
tree = SLTree([
    SLTreeItem("Folder A", [
        SLTreeItem("File 1"),
        SLTreeItem("File 2")
    ]),
    SLTreeItem("Folder B", [SLTreeItem("File 3")])
])
```

2. **Using simplified nested syntax** (strings and pairs):
```julia
tree = SLTree([
    "Deciduous" => [
        "Birch",
        "Maple" => ["Field", "Red", "Sugar"],
        "Oak"
    ],
    "Coniferous" => ["Cedar", "Pine", "Spruce"]
])
```

# Selection
```julia
# Monitor selection changes
on(tree.value) do selected
    println("Selected: ", selected)
end

# Programmatically select item
tree.value[] = "Maple"
```
"""
struct SLTree
    values::Vector{SLTreeItem}
    value::Observable{String}
end
SLTree(values::Vector{SLTreeItem}) = SLTree(values, Observable(""))

# Helper function to convert nested structures to SLTreeItem
function _convert_to_tree_item(item::String)
    return SLTreeItem(item)
end

function _convert_to_tree_item(item::Pair{String, <:Vector})
    label, children = item
    child_items = SLTreeItem[_convert_to_tree_item(child) for child in children]
    return SLTreeItem(label, child_items)
end

# Constructor that accepts nested Vector{Union{String, Pair{String, Vector}}}
function SLTree(items::Vector)
    tree_items = SLTreeItem[_convert_to_tree_item(item) for item in items]
    return SLTree(tree_items)
end

function get_sl_tree_item(x::SLTreeItem)
    item = if !isempty(x.values)
        sl_tree_item(x.value, get_sl_tree_item.(x.values); expanded=true)
    else
        sl_tree_item(x.value)
    end

    return item
end

function Bonito.jsrender(session::Session, x::SLTree)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            console.log(e.detail);
            console.log(e.detail.selection);
            console.log(e.detail.selection[0]);
            console.log(e.detail.selection[0].innerText);
            if (e.detail.selection.length > 0){
                $(x.value).notify(e.detail.selection[0].innerText);
            }
        }
        element.addEventListener("sl-selection-change", onchange);
    }
    """

    dom = sl_tree(get_sl_tree_item.(x.values))

    update_value = js""" function (value) {
        // Find all tree items
        const items = $(dom).querySelectorAll('sl-tree-item');

        // Deselect all items first
        items.forEach(item => item.selected = false);

        // Find and select the item with matching text
        for (const item of items) {
            // Get direct text content (not including children)
            const directText = Array.from(item.childNodes)
                .filter(node => node.nodeType === Node.TEXT_NODE)
                .map(node => node.textContent.trim())
                .join('');

            if (directText === value) {
                item.selected = true;
                break;
            }
        }
    }
    """
    onjs(session, x.value, update_value)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end





end # module ShoelaceWidgets
