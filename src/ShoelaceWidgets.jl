module ShoelaceWidgets
using Bonito: m, @js_str
using Bonito
using Hyperscript

# header
export get_shoelace

# controls
export SLInput, SLSelect, SLButton

# tags
export sl_tab_group, sl_tab, sl_tab_panel, sl_tag, sl_format_date, sl_spinner, sl_icon



# ----------------------------------------

get_shoelace() = [
    DOM.link(;rel="stylesheet", href="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/themes/light.css"),
    DOM.script(;type="module", src="https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2.20.1/cdn/shoelace-autoloader.js")  
]

sl_tab_group(args...; kw...) = m("sl-tab-group", args...; kw...)
sl_tab(args...; kw...) = m("sl-tab", args...; kw...)
sl_tab_panel(args...; kw...) = m("sl-tab-panel", args...; kw...)

sl_tag(args...; kw...) = m("sl-tag", args...; kw...)
sl_format_date(args...; kw...) = m("sl-format-date", args...; kw...)
sl_spinner(args...; kw...) = m("sl-spinner", args...; kw...)
sl_icon(args...; kw...) = m("sl-icon", args...; kw...)

# ----------------------------------------
# Input
# ----------------------------------------
sl_input(args...; kw...) = m("sl-input", args...; kw...)

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

function Bonito.jsrender(session::Session, x::SLInput{T}) where T

    setup = js"""
    function onload(element) {
        function onchange(e) {
            if ($(x.type) == "number"){
                $(x.value).notify(Number(element.value))
            } else {
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

struct SLSelect{T}
    label::String
    options::Observable{Vector{Hyperscript.Node}}
    values::Vector{T}
    index::Observable{Int}
    # value from getproperty
end

function SLSelect(values::Vector{T}; label::String = "", index=0) where T 
    options = Hyperscript.Node[]
    for (i,x) in enumerate(values)
        push!(options, sl_option(x; value=i))
    end
    return SLSelect(label, Observable(options), values, Observable(index))
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

struct SLButton
    value::Observable{Bool}
    disabled::Observable{Bool}
    label::String
end

SLButton(label::String; disabled::Bool = false) = SLButton(Observable(true), Observable(disabled), label)

function Bonito.jsrender(session::Session, x::SLButton)

    click = js"""
        function (value) { 
            $(x.value).notify(true)
        } 
    """

    dom = if x.disabled[]
        sl_button(x.label; onclick=click, disabled=true)
    else
        sl_button(x.label; onclick=click)
    end
    
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

    return Bonito.jsrender(session, dom)
end



end # module ShoelaceWidgets
