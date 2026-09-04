module ShoelaceWidgets
using Bonito: m, @js_str
using Bonito
using Hyperscript
using Dates

# header
export get_shoelace

# controls
export SLInput, SLSelect, SLButton, SLRadio, SLRadioGroup, SLDialog, SLList, SLListItem, SLCheckbox, SLTextarea, SLProgressBar, SLAlert, SLDetails

# composite controls
export ListManager, DialogManager

# tags
export sl_tab_group, sl_tab, sl_tab_panel, sl_tag, sl_format_date, sl_spinner, sl_icon, sl_card, sl_checkbox, sl_tooltip, sl_copy_button


const LABEL_STYLE = "display: inline-block; color: var(--sl-input-label-color); font-size: var(--sl-input-label-font-size-medium); margin-bottom: var(--sl-spacing-3x-small);"

# ----------------------------------------
const STYLE_CSS = """
    /* ---------------------------------------------------
       Shoelace themes only define tokens, they never style
       the page itself, so a dark theme leaves the document
       on the browser default background. Follow the tokens
       the way shoelace.style does. `:where` keeps these at
       zero specificity so any application CSS wins.
       --------------------------------------------------- */
    :where(body) {
      background-color: var(--sl-color-neutral-0);
      color: var(--sl-color-neutral-900);
    }

    /* ---------------------------------------------------
       `sl-details` paints a background on its base but never
       sets a color, so the summary inherits from the page.
       On a dark page that is light text on the still light
       panel, and the summary disappears. Pin it to the same
       token the body uses.
       --------------------------------------------------- */
    sl-details::part(base) {
      color: var(--sl-color-neutral-900);
    }

    /* ---------------------------------------------------
       Shoelace ships `.radio { align-items: top }`, which is
       not a valid align-items value, so it is dropped and the
       circle falls back to stretch (pinned to the top). That
       is invisible for one line of text because the label
       carries `line-height: var(--toggle-size)`, but any block
       content (a div holding another widget) leaves the circle
       stranded at the top. Center it, and drop the single-line
       line-height so block content is not distorted.
       --------------------------------------------------- */
    sl-radio::part(base) {
      align-items: center;
    }

    sl-radio::part(label) {
      line-height: normal;
    }

    /* ---------------------------------------------------
       Core CSS to make sl-radio look like sl-tree-item
       --------------------------------------------------- */

    /* Force the host element to be block level so it stacks properly */
    sl-radio.tree-style {
      display: block;
      margin-bottom: 2px;
    }

    /* 1. Base styling for the "row" */
    sl-radio.tree-style::part(base) {
      padding: var(--sl-spacing-x-small) var(--sl-spacing-small);
      border-radius: var(--sl-border-radius-medium);
      transition: background-color 150ms ease, color 150ms ease;
      width: 100%; /* Makes it stretch like a tree node */
      box-sizing: border-box;
      cursor: pointer;
    }

    /* 2. Hover effect */
    sl-radio.tree-style:hover::part(base) {
      background-color: var(--sl-color-neutral-100);
    }

    /* 3. The "Selected" state highlight */
    sl-radio.tree-style[checked]::part(base),
    sl-radio.tree-style[aria-checked="true"]::part(base) {
      background-color: var(--sl-color-primary-100);
      color: var(--sl-color-primary-700);
    }

    /* Hide the little radio circle completely */
    sl-radio.tree-style-hidden-circle::part(control) {
      display: none;
    }

    /* Remove the gap between the hidden circle and the label */
    sl-radio.tree-style-hidden-circle::part(base) {
      gap: 0;
      /* Make the left side flat for the bar, keep right side rounded */
      border-radius: 0 var(--sl-border-radius-medium) var(--sl-border-radius-medium) 0;
      /* Invisible border to prevent text shifting on selection */
      border-left: 4px solid transparent; 
    }

    /* Add the blue bar indicator when checked */
    sl-radio.tree-style-hidden-circle[checked]::part(base),
    sl-radio.tree-style-hidden-circle[aria-checked="true"]::part(base) {
      border-left-color: var(--sl-color-primary-600);
    }

    /* Ensure no stray padding exists on the label */
    sl-radio.tree-style-hidden-circle::part(label) {
      padding-inline-start: 0;
      /* Make the label take up full width for a bigger click target */
      width: 100%;
    }

    /* ---------------------------------------------------
       DialogManager: OK and Cancel are the only way out, so
       remove the header close button rather than leave a
       control that does nothing
       --------------------------------------------------- */
    sl-dialog.dialog-manager::part(close-button) {
      display: none;
    }
"""

const SHOELACE_CDN = "https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn"

theme_href(name) = "$SHOELACE_CDN/themes/$name.css"

"""
    get_shoelace(charset="UTF-8"; theme=:auto)

Returns an array of DOM elements (link and script tags) needed to load the Shoelace web component library from CDN.
This should be included in the document head of your Bonito application.  The `charset` is also included which is not
specifically required by Shoelace.style but is defaulted to UTF-8 to ensure Julia Unicode is rendered correctly in browsers.

Splat the result into your document head: `DOM.head(get_shoelace()...)`.

# Themes
- `:auto` (default) - Follows the browser/OS setting.  Both themes are loaded, each gated on
  `prefers-color-scheme`, so switching the system theme reskins a running page without a reload.
- `:light` - Always the light theme.
- `:dark` - Always the dark theme.

The dark theme tokens are scoped to `.sl-theme-dark`, so `:auto` and `:dark` also emit a script that
adds that class to the `<html>` element.  Under `:auto` the class is always present and the media
query on the stylesheet decides which set of tokens applies.
"""
function get_shoelace(charset="UTF-8"; theme=:auto)
    theme in (:auto, :light, :dark) || throw(ArgumentError("theme must be :auto, :light or :dark, got :$theme"))

    head = Any[DOM.meta(;charset)]

    if theme === :auto
        push!(head, DOM.link(;rel="stylesheet", media="(prefers-color-scheme: light)", href=theme_href("light")))
        push!(head, DOM.link(;rel="stylesheet", media="(prefers-color-scheme: dark)", href=theme_href("dark")))
    else
        push!(head, DOM.link(;rel="stylesheet", href=theme_href(theme)))
    end

    if theme !== :light
        push!(head, DOM.script("document.documentElement.classList.add('sl-theme-dark');"))
    end

    push!(head, DOM.script(;type="module", src="$SHOELACE_CDN/shoelace-autoloader.js"))
    push!(head, DOM.style(STYLE_CSS))

    return head
end

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
    sl_tooltip(args...; kw...)

Creates a Shoelace tooltip component. Use the `content` keyword to set the tooltip contents.
"""
sl_tooltip(args...; kw...) = m("sl-tooltip", args...; kw...)

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

"""
    sl_card(args...; kw...)

Creates a Shoelace card component. Cards provide a container for grouping related content.
"""
sl_card(args...; kw...) = m("sl-card", args...; kw...)

"""
    sl_checkbox(args...; kw...)

Creates a Shoelace checkbox component. Checkboxes allow users to toggle an option on or off.
"""
sl_checkbox(args...; kw...) = m("sl-checkbox", args...; kw...)

"""
    sl_copy_button(args...; kw...)

Creates a Shoelace copy button component, contents passed to the `value` keyword are sent to the clipboard.
"""
sl_copy_button(args...; kw...) = m("sl-copy-button", args...; kw...)


# ----------------------------------------
# Input
# ----------------------------------------
sl_input(args...; kw...) = m("sl-input", args...; kw...)

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
sl_option(args...; kw...) = m("sl-option", args...; kw...)
sl_select(args...; kw...) = m("sl-select", args...; kw...)

"""
    SLSelect(values; label="", index=0, help="", style="")

Creates a dropdown select widget with reactive selection tracking.

# Fields
- `label::String` - Label text displayed above the dropdown
- `options::Observable{Vector{Hyperscript.Node}}` - Observable containing the option elements
- `values::Vector{T}` - Array of selectable values
- `index::Observable{Int}` - Observable containing the currently selected index (1-based)
- `value` - Computed property returning `values[index[]]` (the currently selected value)
- `style::String` - Inline CSS style applied to the select element

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
    # value from getproperty
end

function get_options(values::Vector)
    options = Hyperscript.Node[]
    for (i,x) in enumerate(values)
        push!(options, sl_option(x; value=i))
    end
    return options
end

function SLSelect(values::Vector{T}; label::String="", index=0, help::String="", style::String="") where T
    return SLSelect(label, Observable(get_options(values)), values, Observable(index), help, style)
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
    }
    """

    dom = sl_select(x.options, DOM.div(Bonito.HTML(x.help); slot="help-text"); label=x.label, value=string(x.index[]), style=x.style)
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
sl_textarea(args...; kw...) = m("sl-textarea", args...; kw...)

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

sl_radio_group(args...; kw...) = m("sl-radio-group", args...; kw...)
sl_radio(args...; kw...) = m("sl-radio", args...; kw...)

sl_list(args...; kw...) = m("sl-radio-group", args...; kw...)
sl_list_item(args...; kw...) = m("sl-radio", args...; class="tree-style tree-style-hidden-circle", kw...)

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
    SLListItem(value; disabled=false, object=nothing)

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
"""
mutable struct SLListItem <: SLRadioLike
    value::Union{String, Hyperscript.Node}
    disabled::Bool
    object::Any
    index::Int
end
SLListItem(value::Union{String, Hyperscript.Node}; disabled=false, object=nothing) = SLListItem(value, disabled, object, 0)

function Bonito.jsrender(session::Session, x::SLRadioLike)
    kwargs = x.disabled ? [:disabled => true] : []
    f = if x isa SLRadio
        sl_radio
    elseif x isa SLListItem
        sl_list_item
    end
    dom = f(x.value; value=string(x.index), kwargs...)
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
sl_dialog(args...; kw...) = m("sl-dialog", args...; kw...)

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
# Details
# ----------------------------------------
sl_details(args...; kw...) = m("sl-details", args...; kw...)


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
# sl_tree(args...; kw...) = m("sl-tree", args...; kw...)
# sl_tree_item(args...; kw...) = m("sl-tree-item", args...; kw...)

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
sl_progress_bar(args...; kw...) = m("sl-progress-bar", args...; kw...)

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
sl_alert(args...; kw...) = m("sl-alert", args...; kw...)

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


# dialog_manager first: ListManager has a DialogManager field
include("dialog_manager.jl")
include("list_manager.jl")


end # module ShoelaceWidgets
