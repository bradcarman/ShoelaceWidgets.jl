module ShoelaceWidgets
using Bonito: m, @js_str
using Bonito
using Hyperscript
using Dates

# header
export get_shoelace, SLTheme

# controls
export SLInput, SLSelect, SLButton, SLRadio, SLRadioGroup, SLDialog, SLList, SLListItem, SLCheckbox, SLTextarea, SLProgressBar, SLAlert, SLDetails, SLMenu, SLMenuItem, SLMenuLabel, SLDrawer

# composite controls
export ListManager, DialogManager

# tags
export sl_tab_group, sl_tab, sl_tab_panel, sl_tag, sl_format_date, sl_spinner, sl_icon, sl_card, sl_checkbox, sl_tooltip, sl_copy_button, sl_divider


const LABEL_STYLE = "display: inline-block; color: var(--sl-input-label-color); font-size: var(--sl-input-label-font-size-medium); margin-bottom: var(--sl-spacing-3x-small);"

# ----------------------------------------
# Shoelace loading
# ----------------------------------------
# Every sl-* element built by `sl` carries a `ShoelaceLoader` as a child.  It
# renders to nothing in place, so an App can return a bare widget without any
# setup in the head:
#
# - the stylesheet is a Bonito Asset, registered in `session.imports`, which
#   puts one <link> in the head however many widgets use it.
# - the loader script is run by Bonito rather than placed in a <script> tag.
#   Apps shown in the VS Code plot pane are inserted with innerHTML, and the
#   browser never runs scripts inserted that way.  The script guards itself
#   with `window.ShoelaceWidgets`, so running it more than once is harmless.
#
# `@path` embeds the bytes so the stylesheet survives relocation (e.g. PackageCompiler).
const SHOELACE_CSS = Asset(Bonito.@path(joinpath(@__DIR__, "..", "assets", "shoelace_widgets.css")))

const SHOELACE_LOADER_FILE = joinpath(@__DIR__, "..", "assets", "shoelace_widgets.js")
include_dependency(SHOELACE_LOADER_FILE)
const SHOELACE_LOADER = Bonito.JSCode(read(SHOELACE_LOADER_FILE, String))

struct ShoelaceLoader end

function Bonito.jsrender(session::Session, ::ShoelaceLoader)
    Bonito.jsrender(session, SHOELACE_CSS)
    # once per render pass, Bonito empties the queue when it sends it
    if !any(js -> js === SHOELACE_LOADER, session.on_document_load)
        Bonito.on_document_load(session, SHOELACE_LOADER)
    end
    return nothing
end

"""
    sl(tag, args...; kw...)

Creates the `tag` Shoelace element with the Shoelace loader attached, so rendering it loads Shoelace.
"""
sl(tag, args...; kw...) = m(tag, ShoelaceLoader(), args...; kw...)

check_theme(theme) = theme in (:auto, :light, :dark) || throw(ArgumentError("theme must be :auto, :light or :dark, got :$theme"))

"""
    SLTheme(theme)

Forces the Shoelace theme for the page.  Shoelace widgets follow the browser/OS setting by default,
place an `SLTheme` anywhere in the app to override it.

# Themes
- `:auto` - Follows the browser/OS setting, switching the system theme reskins a running page.
- `:light` - Always the light theme.
- `:dark` - Always the dark theme.
"""
struct SLTheme
    theme::Symbol
    SLTheme(theme::Symbol) = (check_theme(theme); new(theme))
end

function Bonito.jsrender(session::Session, x::SLTheme)
    dom = DOM.span(ShoelaceLoader(); style="display: none;")
    # The loader reads `data-sl-theme` when it starts, in case it has not run yet.
    set_theme = js"""() => {
        const theme = $(string(x.theme));
        if (window.ShoelaceWidgets) {
            window.ShoelaceWidgets.setTheme(theme);
        } else {
            document.documentElement.dataset.slTheme = theme;
        }
    }"""
    rendered = Bonito.jsrender(session, dom)
    Bonito.onload(session, dom, set_theme)
    return rendered
end

"""
    get_shoelace(charset="UTF-8"; theme=:auto)

!!! warning "Deprecated"
    Shoelace is loaded automatically by every widget, `get_shoelace` is no longer needed.  Use
    [`SLTheme`](@ref) to force a theme.

Returns an array of elements for the document head: `DOM.head(get_shoelace()...)`.
"""
function get_shoelace(charset="UTF-8"; theme=:auto)
    Base.depwarn("`get_shoelace` is no longer needed, Shoelace is loaded automatically by every widget. Use `SLTheme(theme)` to force a theme.", :get_shoelace)
    check_theme(theme)

    # The loader reads `data-sl-theme` when it starts, which is after the head is parsed.
    head = Any[DOM.meta(;charset), ShoelaceLoader()]
    theme === :auto || push!(head, DOM.script("document.documentElement.dataset.slTheme = '$theme';"))

    return head
end

"""
    sl_tab_group(args...; kw...)

Creates a Shoelace tab group component. Tab groups organize content into multiple panels with tab navigation.
"""
sl_tab_group(args...; kw...) = sl("sl-tab-group", args...; kw...)

"""
    sl_tab(args...; kw...)

Creates a Shoelace tab component. Tabs are used as navigation items within a tab group.
"""
sl_tab(args...; kw...) = sl("sl-tab", args...; kw...)

"""
    sl_tab_panel(args...; kw...)

Creates a Shoelace tab panel component. Tab panels contain the content associated with each tab.
"""
sl_tab_panel(args...; kw...) = sl("sl-tab-panel", args...; kw...)

"""
    sl_tag(args...; kw...)

Creates a Shoelace tag component. Tags are used for labels, categories, and keyword indicators.
"""
sl_tag(args...; kw...) = sl("sl-tag", args...; kw...)

"""
    sl_tooltip(args...; kw...)

Creates a Shoelace tooltip component. Use the `content` keyword to set the tooltip contents.
"""
sl_tooltip(args...; kw...) = sl("sl-tooltip", args...; kw...)

"""
    sl_format_date(args...; kw...)

Creates a Shoelace date formatting component. Formats dates according to specified locale and options.
"""
sl_format_date(args...; kw...) = sl("sl-format-date", args...; kw...)

"""
    sl_spinner(args...; kw...)

Creates a Shoelace spinner component. Spinners indicate loading or processing states.
"""
sl_spinner(args...; kw...) = sl("sl-spinner", args...; kw...)

"""
    sl_icon(args...; kw...)

Creates a Shoelace icon component. Icons provide visual representations from the Shoelace icon library.
"""
sl_icon(args...; kw...) = sl("sl-icon", args...; kw...)

"""
    sl_card(args...; kw...)

Creates a Shoelace card component. Cards provide a container for grouping related content.
"""
sl_card(args...; kw...) = sl("sl-card", args...; kw...)

"""
    sl_checkbox(args...; kw...)

Creates a Shoelace checkbox component. Checkboxes allow users to toggle an option on or off.
"""
sl_checkbox(args...; kw...) = sl("sl-checkbox", args...; kw...)

"""
    sl_copy_button(args...; kw...)

Creates a Shoelace copy button component, contents passed to the `value` keyword are sent to the clipboard.
"""
sl_copy_button(args...; kw...) = sl("sl-copy-button", args...; kw...)

"""
    sl_divider(args...; kw...)

Creates a Shoelace divider component. Dividers visually separate content, such as groups of items in an [`SLMenu`](@ref).
"""
sl_divider(args...; kw...) = sl("sl-divider", args...; kw...)


# ----------------------------------------
# Input
# ----------------------------------------
sl_input(args...; kw...) = sl("sl-input", args...; kw...)

"""
    SLInput(default; label="", help="", placeholder="", disabled=false, style="", select_on_focus=false, min=NaN, max=NaN)

Creates a reactive input field widget. The input value is synchronized with Julia through an Observable.

The `type` attribute follows the type of `default`: `String` gives a text input, any `Number` gives a
numeric input, and a `Date` gives a date picker. `min` and `max` apply to numeric inputs only.

# Fields
- `value::Observable{T}` - Observable containing the current input value
- `label::String` - Label text displayed above the input
- `type::String` - HTML input type (automatically determined from value type)
- `help::String` - Help text displayed below the input, rendered as HTML
- `placeholder::String` - Placeholder text shown when input is empty
- `disabled::Observable{Bool}` - Observable controlling whether input is disabled
- `style::String` - Inline CSS style applied to the input element
- `select_on_focus::Bool` - Highlight the existing contents on focus, so typing replaces them
- `min::Real` - Minimum value for numeric inputs, `NaN` for no minimum
- `max::Real` - Maximum value for numeric inputs, `NaN` for no maximum
"""
struct SLInput{T}
    value::Observable{T}
    label::String
    type::String
    help::String
    placeholder::String
    disabled::Observable{Bool}
    style::String
    select_on_focus::Bool
    min::Real
    max::Real
end

get_type(::Type{String}) = ""
get_type(::Type{T}) where T <: Number = "number"

SLInput(default::T; label::String="", help::String="", placeholder::String="", disabled::Bool=false, style::String="", select_on_focus::Bool=false, min=NaN, max=NaN) where T = SLInput{T}(Observable(default), label, get_type(T), help, placeholder, Observable(disabled), style, select_on_focus, min, max)
SLInput(default::Date; label::String="", help::String="", disabled::Bool=false, style::String="", select_on_focus::Bool=false) = SLInput{String}(Observable(string(default)), label, "date", help, "Date", Observable(disabled), style, select_on_focus, NaN, NaN) #TODO: support date min/max


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
        if ($(x.select_on_focus)) {
            // highlight existing contents on focus so the user can type over them
            element.addEventListener("sl-focus", function () { element.select(); });
        }
    }
    """

    kwargs = Pair[]
    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    if T <: Number
        push!(kwargs, :clearable => nothing)
        if !isnan(x.min)
            push!(kwargs, :min => x.min)
        end
        if !isnan(x.max)
            push!(kwargs, :max => x.max)
        end
    end

    dom = sl_input(DOM.div(Bonito.HTML(x.help); slot="help-text"); 
                    label=x.label, 
                    type=x.type, 
                    value=x.value, 
                    placeholder=x.placeholder, 
                    style=x.style, 
                    kwargs...)

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


    # focus = js"""
    #     function (value) {
    #         if (value) {
    #             $(dom).select()
    #         } 
    #     }            
    # """
    # onjs(session, x.focus, focus)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Select
# ----------------------------------------
sl_option(args...; kw...) = sl("sl-option", args...; kw...)
sl_select(args...; kw...) = sl("sl-select", args...; kw...)

"""
    SLSelect(values; label="", index=0, help="", style="", clearable=false)

Creates a dropdown select widget with reactive selection tracking.

# Fields
- `label::String` - Label text displayed above the dropdown
- `options::Observable{Vector{Hyperscript.Node}}` - Observable containing the option elements
- `values::Vector{T}` - Array of selectable values
- `index::Observable{Int}` - Observable containing the currently selected index (1-based)
- `value` - Computed property returning `values[index[]]` (the currently selected value)
- `style::String` - Inline CSS style applied to the select element
- `clearable::Bool` - Show a clear button when an option is selected; clearing sets `index[]` to `0` (so `value` returns `nothing`)

# Methods
- `push!(select, value)` - Add a new option
- `empty!(select)` - Remove all options
- `popat!(select, i)` - Remove option at index i

"""
struct SLSelect{T}
    label::String
    options::Observable{Vector{Hyperscript.Node}}
    values::Vector{T}
    index::Observable{Int}
    help::String
    style::String
    clearable::Bool
    # value from getproperty
end

function get_options(values::Vector)
    options = Hyperscript.Node[]
    for (i,x) in enumerate(values)
        push!(options, sl_option(x; value=i))
    end
    return options
end

function SLSelect(values::Vector{T}; label::String="", index=0, help::String="", style::String="", clearable::Bool=false) where T
    return SLSelect(label, Observable(get_options(values)), values, Observable(index), help, style, clearable)
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

function Base.insert!(x::SLSelect{T}, i, value::T) where T
    insert!(x.values, i, value)
    x.options[] = get_options(x.values)
    notify(x.options)
    # trigger a display refresh
    if x.index[] == i
        x.index[] = 0
        x.index[] = i
    end
end

#TODO: add append!

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
            // Guard against empty/non-numeric element.value: parseInt("") is NaN,
            // and pushing NaN into an Observable{Int} throws InexactError server-side.
            const idx = parseInt(element.value)
            if (Number.isInteger(idx)) {
                $(x.index).notify(idx)
            }
        }
        element.addEventListener("sl-change", onchange);
        // Clearing sets element.value to "", which onchange ignores; map it to index 0 (no selection).
        element.addEventListener("sl-clear", function () { $(x.index).notify(0); });
    }
    """

    kwargs = Pair[]
    if x.clearable
        push!(kwargs, :clearable => true)
    end

    dom = sl_select(x.options, DOM.div(Bonito.HTML(x.help); slot="help-text"); label=x.label, value=string(x.index[]), style=x.style, kwargs...)
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
sl_button(args...; kw...) = sl("sl-button", args...; kw...)

"""
    SLButton(label; disabled=false, variant=nothing, size=nothing, style="", href=nothing, target=nothing, download=nothing, rel=nothing)

Creates a clickable button widget with reactive state management.

Setting `href` renders the button as a link (Shoelace renders an internal `<a>` instead of a `<button>`), enabling navigation to a URL. `target`, `download`, and `rel` are only meaningful when `href` is set.

# Fields
- `value::Observable{Union{Session,Nothing}}` - Observable set to the active `Session` when the button is clicked (`nothing` before any click), enabling handlers to call `Bonito.evaljs(session, ...)`
- `disabled::Observable{Bool}` - Observable controlling whether button is disabled
- `label::Union{String, Hyperscript.Node}` - Button content: text, or a node such as an `sl_icon` for an icon-only button
- `loading::Observable{Bool}` - Observable controlling loading spinner state
- `variant::Union{String, Nothing}` - Button style variant (e.g., "primary", "success", "danger")
- `size::Union{String, Nothing}` - Button size (e.g., "small", "medium", "large")
- `style::String` - Inline CSS style applied to the button element
- `href::Union{String, Nothing}` - URL to navigate to; when set, the button renders as a link
- `target::Union{String, Nothing}` - Where to open the linked URL (e.g., "_blank", "_parent", "_self", "_top"); only used when `href` is set
- `download::Union{String, Nothing}` - Filename to prompt a download instead of navigating; only used when `href` is set
- `rel::Union{String, Nothing}` - The `rel` attribute for the underlying link (e.g., "noreferrer noopener"); only used when `href` is set

"""
struct SLButton
    value::Observable{Union{Session,Nothing}}
    disabled::Observable{Bool}
    label::Union{String, Hyperscript.Node}
    loading::Observable{Bool}
    variant::Union{String, Nothing}
    size::Union{String, Nothing}
    style::String
    href::Union{String, Nothing}
    target::Union{String, Nothing}
    download::Union{String, Nothing}
    rel::Union{String, Nothing}
end

SLButton(label::Union{String, Hyperscript.Node}; disabled::Bool=false, variant=nothing, size=nothing, style::String="", href=nothing, target=nothing, download=nothing, rel=nothing) = SLButton(Observable(nothing), Observable(disabled), label, Observable(false), variant, size, style, href, target, download, rel)

function Bonito.jsrender(session::Session, x::SLButton)

    # The active Session is only available here, as the first argument to
    # jsrender. The browser cannot send it back to us, so JS just notifies a
    # local trigger and we set `value` to the captured `session` Julia-side.
    clicked = Observable(false)

    click = js"""
        function (event) {
            $(clicked).notify(true)
        }
    """

    on(session, clicked) do _
        x.value[] = session
    end

    kwargs = Pair[]
    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    if !isnothing(x.variant)
        push!(kwargs, :variant => x.variant)
    end

    if !isnothing(x.size)
        push!(kwargs, :size => x.size)
    end

    if !isnothing(x.href)
        push!(kwargs, :href => x.href)
    end

    if !isnothing(x.target)
        push!(kwargs, :target => x.target)
    end

    if !isnothing(x.download)
        push!(kwargs, :download => x.download)
    end

    if !isnothing(x.rel)
        push!(kwargs, :rel => x.rel)
    end

    dom = sl_button(x.label; onclick=click, style=x.style, kwargs...)

    
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
# Checkbox
# ----------------------------------------

"""
    SLCheckbox(label; checked=false, disabled=false, help="", style="")

Creates a checkbox widget with reactive state management.

# Fields
- `value::Observable{Bool}` - Observable containing the checkbox state (checked/unchecked)
- `disabled::Observable{Bool}` - Observable controlling whether checkbox is disabled
- `label::String` - Checkbox label text
- `help::String` - Help text displayed below the checkbox
- `style::String` - Inline CSS style applied to the checkbox element

"""
struct SLCheckbox
    value::Observable{Bool}
    disabled::Observable{Bool}
    label::String
    help::String
    style::String
end

SLCheckbox(label::String; checked::Bool=false, disabled::Bool=false, help::String="", style::String="") = SLCheckbox(Observable(checked), Observable(disabled), label, help, style)

function Bonito.jsrender(session::Session, x::SLCheckbox)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            $(x.value).notify(element.checked)
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    kwargs = Pair[]
    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    dom = sl_checkbox(x.label, DOM.div(Bonito.HTML(x.help); slot="help-text"); checked=x.value[], style=x.style, kwargs...)

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

    update_checked = js"""
        function (value) {
            $(dom).checked = value
        }
    """
    onjs(session, x.value, update_checked)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Textarea
# ----------------------------------------
sl_textarea(args...; kw...) = sl("sl-textarea", args...; kw...)

"""
    SLTextarea(default; label="", help="", placeholder="", rows=3, disabled=false, style="")

Creates a reactive textarea widget for multi-line text input. The textarea value is synchronized with Julia through an Observable.

# Fields
- `value::Observable{String}` - Observable containing the current textarea value
- `label::String` - Label text displayed above the textarea
- `help::String` - Help text displayed below the textarea
- `placeholder::String` - Placeholder text shown when textarea is empty
- `rows::Int` - Number of visible text rows
- `disabled::Observable{Bool}` - Observable controlling whether textarea is disabled
- `style::String` - Inline CSS style applied to the textarea element

"""
struct SLTextarea
    value::Observable{String}
    label::String
    help::String
    placeholder::String
    rows::Observable{Int}
    disabled::Observable{Bool}
    style::String
end

SLTextarea(default::String=""; label::String="", help::String="", placeholder::String="", rows::Int=3, disabled::Bool=false, style::String="") = SLTextarea(Observable(default), label, help, placeholder, Observable(rows), Observable(disabled), style)

function Bonito.jsrender(session::Session, x::SLTextarea)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            console.log(element.value)
            $(x.value).notify(element.value)
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    kwargs = Pair[]
    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    dom = sl_textarea(DOM.div(Bonito.HTML(x.help); slot="help-text"); label=x.label, value=x.value, placeholder=x.placeholder, rows=x.rows, style=x.style, kwargs...)

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

    rows = js"""
        function (value) {
            $(dom).setAttribute("rows", value)
        }
    """
    onjs(session, x.rows, rows)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Radio & List
# ----------------------------------------
abstract type SLRadioLike end

sl_radio_group(args...; kw...) = sl("sl-radio-group", args...; kw...)
sl_radio(args...; kw...) = sl("sl-radio", args...; kw...)

sl_list(args...; kw...) = sl("sl-radio-group", args...; kw...)
sl_list_item(args...; kw...) = sl("sl-radio", args...; class="tree-style tree-style-hidden-circle", kw...)

"""
    SLRadio(value; disabled=false, object=nothing)

Represents a single radio button option within a radio group.

# Fields
- `value::String` - Display text for the radio button
- `disabled::Bool` - Whether this option is disabled
- `object::Any` - Optional associated data object
- `index::Int` - Position in the group (set automatically when added to an SLRadioGroup)

"""
mutable struct SLRadio <: SLRadioLike
    value::Union{String, Hyperscript.Node}
    disabled::Bool
    object::Any
    index::Int
end
SLRadio(value::Union{String, Hyperscript.Node}; disabled=false, object=nothing) = SLRadio(value, disabled, object, 0)

"""
    SLListItem(value; disabled=false, object=nothing, visible=true)

A single row in an [`SLList`](@ref). Identical to [`SLRadio`](@ref) except for its styling: the radio
circle is hidden and the selected row is marked with a coloured bar, so the group reads as a list
rather than a set of radio buttons.

`value` is the displayed content, either a `String` or a `Hyperscript.Node`, so a row can hold live
widgets. `object` is arbitrary data carried alongside, recoverable from the group with `list.object`
and used by [`ListManager`](@ref) to hold the underlying value.

# Fields
- `value::Union{String, Hyperscript.Node}` - Display content for the row
- `disabled::Bool` - Whether this row can be selected
- `object::Any` - Optional associated data
- `index::Int` - Position in the group, assigned when added to an `SLList`
- `visible::Observable{Bool}` - Whether the row is shown; a hidden row stays in the list, which is
  how [`ListManager`](@ref) filters without removing anything
"""
mutable struct SLListItem <: SLRadioLike
    value::Union{String, Hyperscript.Node}
    disabled::Bool
    object::Any
    index::Int
    visible::Observable{Bool}
end
SLListItem(value::Union{String, Hyperscript.Node}; disabled=false, object=nothing, visible=true) = SLListItem(value, disabled, object, 0, Observable(visible))

function Bonito.jsrender(session::Session, x::SLRadioLike)
    kwargs = Pair{Symbol, Any}[]
    x.disabled && push!(kwargs, :disabled => true)
    f = if x isa SLRadio
        sl_radio
    elseif x isa SLListItem
        # set the initial display statically so a hidden row never flashes on render
        x.visible[] || push!(kwargs, :style => "display: none;")
        sl_list_item
    end
    dom = f(x.value; value=string(x.index), kwargs...)

    # toggling visibility only touches this row's style, rather than re-rendering the whole list
    if x isa SLListItem
        onjs(session, x.visible, js"""function (visible) {
            $(dom).style.display = visible ? "" : "none";
        }""")
    end

    return Bonito.jsrender(session, dom)
end

"""
    SLRadioGroup(values; label="", index=0, help="", style="")

Creates a radio button group widget with reactive selection tracking.

# Fields
- `label::String` - Label text displayed above the radio group
- `values::Observable{Vector{SLRadio}}` - Observable containing the radio button options
- `value::Observable{String}` - Observable containing the selected index as a string
- `index` - Computed property returning the currently selected index (Int or nothing)
- `object` - Computed property returning the associated object of the selected radio
- `style::String` - Inline CSS style applied to the radio group element

# Methods
- `push!(group, radio)` - Add a new radio button
- `empty!(group)` - Remove all radio buttons
- `popat!(group, i)` - Remove radio button at index i
- `setproperty!(group, :index, i)` - Set selection by index

"""
struct SLRadioGroup
    label::String
    values::Observable{Vector{<:SLRadioLike}}
    value::Observable{String}
    help::String
    style::String
    # index from getproperty
    # object from getproperty
end

"""
    SLList(values::Vector{<:SLListItem}; label="", index=0, help="", style="")

An alias for [`SLRadioGroup`](@ref), sharing all of its fields and methods. Populate it with
[`SLListItem`](@ref) rather than [`SLRadio`](@ref) to get list styling: the radio circles are hidden
and the selected row is marked with a coloured bar.

Nothing enforces the pairing, so an `SLList` built from `SLRadio` renders as an ordinary radio group
and an `SLRadioGroup` built from `SLListItem` renders as a list. The alias exists to make intent
clear at the call site.

[`ListManager`](@ref) wraps this with add, delete, clear and reorder buttons.
"""
SLList = SLRadioGroup

function SLRadioGroup(values::Vector{<:SLRadioLike}; label::String="", index=0, help::String="", style::String="")
    for (i, r) in enumerate(values)
        r.index = i
    end
    return SLRadioGroup(label, Observable(values), Observable(string(index)), help, style)
end

function Base.getproperty(x::SLRadioGroup, name::Symbol)
    if name == :index
        i = tryparse(Int, x.value[])
        return i
    elseif name == :object
        i = tryparse(Int, x.value[])
        if !isnothing(i) && (i > 0)
            radio = x.values[][i]
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

function Base.push!(x::SLRadioGroup, value::SLRadioLike)
    value.index = length(x.values[]) + 1
    push!(x.values[], value)
    notify(x.values)
end

function Base.insert!(x::SLRadioGroup, i, value::SLRadioLike)
    insert!(x.values[], i, value)
    notify(x.values)
end

function Base.empty!(x::SLRadioGroup)
    empty!(x.values[])
    x.value[] = "0"
    notify(x.values)
end

function Base.popat!(x::SLRadioGroup, i::Int)
    popat!(x.values[], i)
    for (j, r) in enumerate(x.values[])
        r.index = j
    end
    x.value[] = "0"
    notify(x.values)
end

function Bonito.jsrender(session::Session, x::SLRadioGroup)

    setup = js"""
    function onload(element) {
        function onchange(e) {
            $(x.value).notify(element.value)
        }
        element.addEventListener("sl-change", onchange);
    }
    """

    dom = sl_radio_group(x.values, DOM.div(Bonito.HTML(x.help); slot="help-text"); label=x.label, value=x.value, style=x.style)
    update_value = js""" function (value) {
        $(dom).value = value
        }
    """
    onjs(session, x.value, update_value)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end

function get_values(list::SLRadioGroup)
    values = []
    for x in list.values[]
        push!(values, x.value)
    end

    return values
end

function get_objects(list::SLRadioGroup)
    values = []
    for x in list.values[]
        push!(values, x.object)
    end

    return values
end




# ----------------------------------------
# Dialog
# ----------------------------------------
sl_dialog(args...; kw...) = sl("sl-dialog", args...; kw...)

"""
    SLDialog(content; label="", style="")

Creates a modal dialog widget that can be shown or hidden.

# Fields
- `value::Observable{Hyperscript.Node}` - Observable containing the dialog content
- `label::String` - Dialog title/header text
- `open::Observable{Bool}` - Observable controlling dialog visibility
- `style::String` - Inline CSS style applied to the dialog element

"""
struct SLDialog
    value::Observable{Hyperscript.Node}
    label::String
    open::Observable{Bool}
    style::String
end

SLDialog(value::Hyperscript.Node; label::String, style="") = SLDialog(Observable(value), label, Observable(false), style)

function Bonito.jsrender(session::Session, x::SLDialog)

    setup = js"""
    function onload(element) {

        //function show(e){
        //    $(x.open).notify(true);
        //}

        function hide(e){
            if (e.target === element) {
                $(x.open).notify(false);
            }
        }

        //element.addEventListener("sl-show", show);
        element.addEventListener("sl-hide", hide);
    }
    """

    dom = sl_dialog(x.value; label=x.label, style=x.style)
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

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Drawer
# ----------------------------------------
sl_drawer(args...; kw...) = sl("sl-drawer", args...; kw...)

const DRAWER_PLACEMENTS = ("start", "end", "top", "bottom")

"""
    SLDrawer(content; label="", placement="end", contained=false, no_header=false, footer=nothing, style="")

Creates a drawer: a panel that slides in from an edge of the page, or of its parent element when `contained`.

`open` tracks the drawer's visibility in both directions. Setting it from Julia shows or hides the drawer,
and closing it in the browser (close button, Escape, or clicking the overlay) sets it back to `false`.

# Fields
- `value::Observable{Hyperscript.Node}` - Observable containing the drawer content
- `label::String` - Drawer title/header text
- `open::Observable{Bool}` - Observable controlling drawer visibility
- `placement::String` - Edge the drawer slides in from: "start", "end", "top" or "bottom"
- `contained::Bool` - Open within the parent element rather than over the page; the parent needs `position: relative`
- `no_header::Bool` - Hide the header, including the label and close button
- `footer::Any` - Content for the footer, such as an `SLButton` or a `DOM.div` of buttons; `nothing` for no footer
- `style::String` - Inline CSS style applied to the drawer element
"""
struct SLDrawer
    value::Observable{Hyperscript.Node}
    label::String
    open::Observable{Bool}
    placement::String
    contained::Bool
    no_header::Bool
    footer::Any
    style::String
end

function SLDrawer(value::Hyperscript.Node; label::String="", placement::String="end", contained::Bool=false, no_header::Bool=false, footer=nothing, style::String="")
    placement in DRAWER_PLACEMENTS || throw(ArgumentError("placement must be one of $(join(DRAWER_PLACEMENTS, ", ")), got \"$placement\""))
    return SLDrawer(Observable(value), label, Observable(false), placement, contained, no_header, footer, style)
end

function Bonito.jsrender(session::Session, x::SLDrawer)

    setup = js"""
    function onload(element) {
        // sl-hide bubbles up from components inside the drawer, only react to our own
        function hide(e){
            if (e.target === element) {
                $(x.open).notify(false);
            }
        }
        element.addEventListener("sl-hide", hide);
    }
    """

    kwargs = Pair[]
    if x.contained
        push!(kwargs, :contained => true)
    end

    if x.no_header
        push!(kwargs, Symbol("no-header") => true)
    end

    children = Any[x.value]
    if !isnothing(x.footer)
        push!(children, DOM.div(x.footer; slot="footer"))
    end

    dom = sl_drawer(children...; label=x.label, placement=x.placement, style=x.style, kwargs...)
    open_close = js""" function (value) {
        if (value) {
            $(dom).show();
        } else {
            $(dom).hide();
        }
    }
    """
    onjs(session, x.open, open_close)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Details
# ----------------------------------------
sl_details(args...; kw...) = sl("sl-details", args...; kw...)


"""
    SLDetails(value::Hyperscript.Node; summary, style="")

Creates a disclosure widget: a summary line that expands to reveal `value` when clicked.

`open` tracks the expanded state in both directions. Setting it from Julia expands or collapses the
panel, and collapsing it in the browser sets it back to `false`.

# Fields
- `value::Observable{Hyperscript.Node}` - The content revealed when expanded
- `summary::String` - The always visible summary line
- `open::Observable{Bool}` - Observable controlling whether the panel is expanded
- `style::String` - Inline CSS style applied to the details element
"""
struct SLDetails
    value::Observable{Hyperscript.Node}
    summary::String
    open::Observable{Bool}
    style::String
end

SLDetails(value::Hyperscript.Node; summary::String, style="") = SLDetails(Observable(value), summary, Observable(false), style)

function Bonito.jsrender(session::Session, x::SLDetails)

    setup = js"""
    function onload(element) {

        //function show(e){
        //    $(x.open).notify(true);
        //}

        function hide(e){
            if (e.target === element) {
                $(x.open).notify(false);
            }
        }

        //element.addEventListener("sl-show", show);
        element.addEventListener("sl-hide", hide);
    }
    """

    dom = sl_details(x.value; summary=x.summary, style=x.style)
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

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end




# -------------------------------------------------------
# List (Same of SLRadio with SLTree like selection style)
# -------------------------------------------------------





# NOTE: SLTree needs more work to be done properly, will remove for now
# # ----------------------------------------
# # Tree
# # ----------------------------------------
# sl_tree(args...; kw...) = sl("sl-tree", args...; kw...)
# sl_tree_item(args...; kw...) = sl("sl-tree-item", args...; kw...)

# """
#     SLTreeItem(value)
#     SLTreeItem(value, children)

# Represents a single item in a tree structure.

# # Fields
# - `value::String` - Display text for the tree item
# - `values::Vector{SLTreeItem}` - Child tree items

# # Examples
# ```julia
# # Leaf node
# item = SLTreeItem("File.txt")

# # Node with children
# folder = SLTreeItem("Documents", [
#     SLTreeItem("Report.pdf"),
#     SLTreeItem("Notes.txt")
# ])
# ```
# """
# struct SLTreeItem
#     value::String
#     values::Vector{SLTreeItem}
#     selected::Observable{Bool}

#     SLTreeItem(value::String; selected=false) = new(value, SLTreeItem[], Observable(selected))
#     SLTreeItem(value::String, values::Vector{SLTreeItem}; selected=false) = new(value, values, Observable(selected))
# end

# """
#     SLTree(items)

# Creates a hierarchical tree menu widget with reactive selection tracking.

# # Fields
# - `items::Observable{Vector{SLTreeItem}}` - Observable containing the root-level tree items
# - `value::Observable{String}` - Observable containing the selected item's text

# # Construction Methods

# **Using SLTreeItem objects**:
# ```julia
# tree = SLTree([
#     SLTreeItem("Folder A", [
#         SLTreeItem("File 1"),
#         SLTreeItem("File 2")
#     ]),
#     SLTreeItem("Folder B", [SLTreeItem("File 3")])
# ])
# ```

# # Selection
# ```julia
# # Monitor selection changes
# on(tree.value) do selected
#     println("Selected: ", selected)
# end

# # Programmatically select an item
# tree.items[][1].selected[] = true
# ```
# """
# struct SLTree
#     items::Observable{Vector{SLTreeItem}}
#     value::Observable{String}
# end

# SLTree(values::Vector{SLTreeItem}) = SLTree(Observable(values), Observable(""))
# SLTree() = SLTree(Observable(SLTreeItem[]), Observable(""))

# function Base.push!(x::SLTree, value::SLTreeItem)
#     push!(x.items[], value)
#     notify(x.items)
# end

# function Base.empty!(x::SLTree)
#     empty!(x.items[])
#     notify(x.items)
# end

# function Base.popat!(x::SLTree, i::Int)
#     popat!(x.items[], i)
#     notify(x.items)
# end

# function Bonito.jsrender(session::Session, x::SLTreeItem)
    
#     # setup = js"""
#     # function onload(element) {
#     #     function onchange(e) {
#     #         $(x.value).notify(element.selected)
#     #     }
#     #     element.addEventListener("sl-change", onchange);
#     # }
#     # """
    
#     kwargs = x.selected[] ? [:selected => true] : []
#     dom = if !isempty(x.values)
#         sl_tree_item(x.value, x.values; expanded=true, kwargs...)
#     else
#         sl_tree_item(x.value; kwargs...)
#     end

#     update_selected = js"""
#         function (value) {
#             $(dom).selected = value
#         }
#     """
#     onjs(session, x.selected, update_selected)

#     # Bonito.onload(session, dom, setup)

#     return Bonito.jsrender(session, dom)
# end

# function Bonito.jsrender(session::Session, x::SLTree)

#     setup = js"""
#     function onload(element) {
#         function onchange(e) {
#             if (e.detail.selection.length > 0){
#                 $(x.value).notify(e.detail.selection[0].innerText);
#             }
#         }
#         element.addEventListener("sl-selection-change", onchange);
#     }
#     """

#     dom = sl_tree(x.items)

#     Bonito.onload(session, dom, setup)

#     return Bonito.jsrender(session, dom)
# end


# ----------------------------------------
# Progress Bar
# ----------------------------------------
sl_progress_bar(args...; kw...) = sl("sl-progress-bar", args...; kw...)

"""
    SLProgressBar(value=0; label="", height="", show_value=true, indeterminate=false, visible=true)

Creates a progress bar widget with reactive state management.

# Fields
- `value::Observable{Float64}` - Observable containing the progress percentage (0.0 to 100.0)
- `label::String` - Label text for assistive devices
- `height::String` - CSS height value (e.g., "20px", "1rem")
- `show_value::Bool` - Whether to display the percentage value
- `indeterminate::Observable{Bool}` - Observable controlling indeterminate/loading state
- `visible::Observable{Bool}` - Observable controlling visibility of the progress bar

"""
struct SLProgressBar
    value::Observable{Float64}
    label::String
    height::String
    show_value::Bool
    indeterminate::Observable{Bool}
    visible::Observable{Bool}
end

SLProgressBar(value::Real=0.0; label::String="", height::String="", show_value::Bool=true, indeterminate::Bool=false, visible::Bool=true) =
    SLProgressBar(Observable(Float64(value)), label, height, show_value, Observable(indeterminate), Observable(visible))

function Bonito.jsrender(session::Session, x::SLProgressBar)

    kwargs = Pair[]

    if !isempty(x.label)
        push!(kwargs, :label => x.label)
    end

    if x.indeterminate[]
        push!(kwargs, :indeterminate => true)
    end

    # Apply custom height and label visibility via CSS custom properties
    style_attrs = Pair[]
    if !isempty(x.height)
        push!(style_attrs, Symbol("--height") => x.height)
    end

    # Hide the label (which contains the percentage) if show_value is false
    if !x.show_value
        push!(style_attrs, Symbol("--label-color") => "transparent")
    end

    # Set initial visibility
    if !x.visible[]
        push!(style_attrs, :display => "none")
    end

    dom = sl_progress_bar(; value=x.value[], kwargs..., style=join(("$k: $v" for (k, v) in style_attrs), ";"))

    # Update value when Observable changes
    update_value = js"""
        function (value) {
            $(dom).value = value
        }
    """
    onjs(session, x.value, update_value)

    # Update indeterminate state when Observable changes
    update_indeterminate = js"""
        function (value) {
            if (value) {
                $(dom).setAttribute("indeterminate", "")
            } else {
                $(dom).removeAttribute("indeterminate")
            }
        }
    """
    onjs(session, x.indeterminate, update_indeterminate)

    # Update visibility when Observable changes
    update_visible = js"""
        function (value) {
            if (value) {
                $(dom).style.display = ""
            } else {
                $(dom).style.display = "none"
            }
        }
    """
    onjs(session, x.visible, update_visible)

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Alert
# ----------------------------------------
sl_alert(args...; kw...) = sl("sl-alert", args...; kw...)

"""
    SLAlert(content; label="")

Creates an alert with several variants

# Fields
- `value::Observable{Hyperscript.Node}` - Observable containing the dialog content
- `variant::String` - type of alert: 'primary', 'success', 'neutral', 'warning', or 'danger'
- `open::Observable{Bool}` - Observable controlling alert visibility
- `icon::String` - type of icon: `info-circle` or `check2-circle` for example.  See full list [here](https://shoelace.style/components/icon)
"""
struct SLAlert
    value::Observable{Hyperscript.Node}
    variant::String
    open::Observable{Bool}
    icon::String
end

SLAlert(value::Hyperscript.Node; variant = "primary", open = true, icon="info-circle") = SLAlert(Observable(value), variant, Observable(open), icon)

function Bonito.jsrender(session::Session, x::SLAlert)

    setup = js"""
    function onload(element) {

        //function show(e){
        //    $(x.open).notify(true);
        //}

        function hide(e){
            if (e.target === element) {
                $(x.open).notify(false);
            }
        }

        //element.addEventListener("sl-show", show);
        element.addEventListener("sl-hide", hide);
    }
    """

    dom = sl_alert(x.value, sl_icon(;slot="icon", name=x.icon); variant=x.variant, open=x.open[], icon=x.icon)
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

    return Bonito.jsrender(session, dom)
end


# ----------------------------------------
# Menu
# ----------------------------------------
sl_menu(args...; kw...) = sl("sl-menu", args...; kw...)
sl_menu_item(args...; kw...) = sl("sl-menu-item", args...; kw...)
sl_menu_label(args...; kw...) = sl("sl-menu-label", args...; kw...)

"""
    SLMenuLabel(label)

A non-selectable heading used to group items within an [`SLMenu`](@ref).

# Fields
- `label::String` - Label text
"""
struct SLMenuLabel
    label::String
end

Bonito.jsrender(session::Session, x::SLMenuLabel) = Bonito.jsrender(session, sl_menu_label(x.label))

"""
    SLMenuItem(label; value=label, checkbox=false, checked=false, disabled=false, prefix=nothing, suffix=nothing, submenu=[])

A single option within an [`SLMenu`](@ref). Selecting it sets the menu's `value` to this item's `value`.

With `checkbox=true` the item toggles a check mark each time it is selected, tracked by `checked`.
Items given a `submenu` open a nested menu; selections there are reported by the top level menu.

# Fields
- `label::Union{String, Hyperscript.Node}` - Item content
- `value::String` - Value reported to the menu when the item is selected
- `checkbox::Bool` - Whether the item is a checkbox item
- `checked::Observable{Bool}` - Observable containing the check state of a checkbox item
- `disabled::Observable{Bool}` - Observable controlling whether the item is disabled
- `loading::Observable{Bool}` - Observable controlling the loading spinner state
- `prefix::Union{String, Hyperscript.Node, Nothing}` - Content placed before the label, such as an `sl_icon`
- `suffix::Union{String, Hyperscript.Node, Nothing}` - Content placed after the label, such as a keyboard shortcut
- `submenu::Vector{Any}` - Items of a nested menu: `SLMenuItem`, `SLMenuLabel` or `sl_divider()`
"""
struct SLMenuItem
    label::Union{String, Hyperscript.Node}
    value::String
    checkbox::Bool
    checked::Observable{Bool}
    disabled::Observable{Bool}
    loading::Observable{Bool}
    prefix::Union{String, Hyperscript.Node, Nothing}
    suffix::Union{String, Hyperscript.Node, Nothing}
    submenu::Vector{Any}
end

SLMenuItem(label::Union{String, Hyperscript.Node}; value::String=(label isa String ? label : ""), checkbox::Bool=false, checked::Bool=false, disabled::Bool=false, prefix=nothing, suffix=nothing, submenu::Vector=[]) =
    SLMenuItem(label, value, checkbox, Observable(checked), Observable(disabled), Observable(false), prefix, suffix, submenu)

function Bonito.jsrender(session::Session, x::SLMenuItem)

    # The menu reports selections, and Shoelace toggles `checked` before it does.  Hand the
    # element our Observable so the menu's handler can sync the new state back to Julia.
    setup = js"""
    function onload(element) {
        element.slwChecked = $(x.checked);
    }
    """

    kwargs = Pair[]
    if x.checkbox
        push!(kwargs, :type => "checkbox")
        if x.checked[]
            push!(kwargs, :checked => true)
        end
    end

    if x.disabled[]
        push!(kwargs, :disabled => true)
    end

    children = Any[x.label]
    if !isnothing(x.prefix)
        push!(children, DOM.span(x.prefix; slot="prefix"))
    end
    if !isnothing(x.suffix)
        push!(children, DOM.span(x.suffix; slot="suffix"))
    end
    if !isempty(x.submenu)
        push!(children, sl_menu(x.submenu...; slot="submenu"))
    end

    dom = sl_menu_item(children...; value=x.value, kwargs...)

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

    update_checked = js"""
        function (value) {
            $(dom).checked = value
        }
    """
    onjs(session, x.checked, update_checked)

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end

"""
    SLMenu(items; style="")

Creates a menu of selectable items with reactive selection tracking.

`items` may hold [`SLMenuItem`](@ref), [`SLMenuLabel`](@ref) and `sl_divider()` in any order.
Selecting an item, including one in a submenu, sets `value` to the item's `value`.  Selecting the
same item again notifies `value` again, so a menu can be used for actions as well as choices.

# Fields
- `items::Observable{Vector{Any}}` - Observable containing the menu contents
- `value::Observable{String}` - Observable containing the value of the last selected item (`""` before any selection)
- `style::String` - Inline CSS style applied to the menu element

# Methods
- `push!(menu, item)` - Add a new item
- `empty!(menu)` - Remove all items
- `popat!(menu, i)` - Remove the item at index i
"""
struct SLMenu
    items::Observable{Vector{Any}}
    value::Observable{String}
    style::String
end

SLMenu(items::Vector; style::String="") = SLMenu(Observable(Vector{Any}(items)), Observable(""), style)

function Base.push!(x::SLMenu, item)
    push!(x.items[], item)
    notify(x.items)
end

function Base.empty!(x::SLMenu)
    empty!(x.items[])
    notify(x.items)
end

function Base.popat!(x::SLMenu, i::Int)
    popat!(x.items[], i)
    notify(x.items)
end

function Bonito.jsrender(session::Session, x::SLMenu)

    # sl-select bubbles, so one listener on the wrapper hears the menu and its submenus, and
    # survives the menu being re-rendered when `items` changes.
    setup = js"""
    function onload(element) {
        function onselect(e) {
            const item = e.detail.item;
            if (item.type === "checkbox" && item.slwChecked) {
                item.slwChecked.notify(item.checked)
            }
            $(x.value).notify(item.value)
        }
        element.addEventListener("sl-select", onselect);
    }
    """

    # Shoelace finds items (for keyboard navigation) among the menu's direct children, so the
    # whole menu is re-rendered rather than nesting an Observable inside it.
    dom = DOM.div(map(items -> sl_menu(items...; style=x.style), x.items))

    Bonito.onload(session, dom, setup)

    return Bonito.jsrender(session, dom)
end


# dialog_manager first: ListManager has a DialogManager field
include("dialog_manager.jl")
include("list_manager.jl")


end # module ShoelaceWidgets
