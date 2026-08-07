# ----------------------------------------
# Dialog Manager
# ----------------------------------------

"""
    OpenOKCancel

The action passed to a [`DialogManager`](@ref)'s `dialog_function`:

- `Open` - the dialog is being shown; seed the editors from `x.value`
- `OK` - the user accepted; commit the editors into `x.value`
- `Cancel` - the user dismissed; `x.value` is left alone unless you change it
"""
@enum OpenOKCancel Open OK Cancel

"""
    DialogManager(value::Observable{T}, content, dialog_function; label="", ok_label="OK", cancel_label="Cancel", style="")

Creates a modal dialog with OK and Cancel buttons in its footer, wrapped around `content`.

Unlike a bare [`SLDialog`](@ref), this dialog cannot be dismissed by clicking the overlay, pressing
escape, or via the header close button (which is hidden, since it would otherwise be a control that
does nothing). Clicking OK or Cancel is the only way out, so `dialog_function` is guaranteed to see
exactly one `OK` or `Cancel` for every `Open`.

`content` is built once at construction and holds the live editing widgets. `dialog_function` is
called as `dialog_function(manager, action)` where `action` is an [`OpenOKCancel`](@ref), and is
where `manager.value` is read and written:

```julia
function dialog_function(x, action)
    if action == Open
        editor.value[] = x.value[]   # seed the editor
    elseif action == OK
        x.value[] = editor.value[]   # commit
    end
    # Cancel needs no branch: nothing was committed, so there is nothing to undo
end
```

Because a commit only happens in the `OK` branch, `Cancel` is naturally a no-op. Nothing is
snapshotted or restored automatically; if your function edits `value` live, undoing that is its own
responsibility.

# Fields
- `value::Observable{T}` - The value the dialog edits
- `content::Hyperscript.Node` - The dialog body, holding the editing widgets
- `ok::SLButton` - The OK button
- `cancel::SLButton` - The Cancel button
- `open::Observable{Bool}` - Visibility; setting it to `true` runs the `Open` action
- `label::String` - Dialog title text
- `dialog_function::Function` - Called as `dialog_function(manager, action)`
- `style::String` - Inline CSS style applied to the dialog element

# Methods
- `open!(manager)` - Show the dialog, running the `Open` action
- `accept!(manager)` - Run the `OK` action and close, as the OK button does
- `reject!(manager)` - Run the `Cancel` action and close, as the Cancel button does

# Examples
```julia
editor = SLInput(""; label="Name")
value = Observable("alpha")

function dialog_function(x, action)
    if action == Open
        editor.value[] = x.value[]
    elseif action == OK
        x.value[] = editor.value[]
    end
end

d = DialogManager(value, DOM.div(editor), dialog_function; label="Edit name")

# Show it from a button
btn = SLButton("edit")
on(btn.value) do session
    isnothing(session) || ShoelaceWidgets.open!(d)
end

# React to an accepted edit
on(value) do v
    println("committed: ", v)
end

# Both the manager and the dialog must be rendered
app = App() do session
    DOM.html(DOM.head(get_shoelace()...), DOM.body(btn, d))
end
```
"""
struct DialogManager
    value::Observable{Hyperscript.Node}
    ok::SLButton
    cancel::SLButton
    open::Observable{Bool}
    dialog_function::Function
    label::String
    style::String
end

function DialogManager(value::Hyperscript.Node, dialog_function::Function;
                       label::String="",
                       ok_label::String="OK",
                       cancel_label::String="Cancel",
                       style::String="")

    x = DialogManager(  
                        Observable(value),
                        SLButton(ok_label; variant="primary"),
                        SLButton(cancel_label),
                        Observable(false),
                        dialog_function,
                        label,
                        style
                        )

    # opening runs the Open action, whether through open! or by setting the Observable directly
    on(x.open) do isopen
        isopen && x.dialog_function(x, Open)
    end

    on(x.ok.value) do session
        isnothing(session) && return
        accept!(x)
    end

    on(x.cancel.value) do session
        isnothing(session) && return
        reject!(x)
    end

    return x
end

# DialogManager(value::T, content::Hyperscript.Node, dialog_function::Function; kw...) where T =
#     DialogManager(Observable(value), content, dialog_function; kw...)

"""
    open!(x::DialogManager)

Shows the dialog, which runs the `Open` action.
"""
function open!(x::DialogManager)
    x.open[] = true
    return x
end

"""
    accept!(x::DialogManager)

Runs the `OK` action and closes the dialog, exactly as the OK button does.
"""
function accept!(x::DialogManager)
    x.dialog_function(x, OK)
    x.open[] = false
    return x
end

"""
    reject!(x::DialogManager)

Runs the `Cancel` action and closes the dialog, exactly as the Cancel button does.
"""
function reject!(x::DialogManager)
    x.dialog_function(x, Cancel)
    x.open[] = false
    return x
end

"""
    prevent_close_js()

The listener that makes OK and Cancel the only ways out of a [`DialogManager`](@ref): the overlay,
the escape key and the header close button all arrive as `sl-request-close`, and all are refused.
Named so the behavior can be asserted without a browser.
"""
prevent_close_js() = js"""
    function onload(element) {
        element.addEventListener("sl-request-close", function (event) {
            event.preventDefault();
        });
    }
    """

function Bonito.jsrender(session::Session, x::DialogManager)

    dom = sl_dialog(x.value[],
                    DOM.div(x.cancel, x.ok;
                            slot="footer",
                            style="display: flex; gap: var(--sl-spacing-x-small); justify-content: flex-end");
                    label=x.label,
                    class="dialog-manager",
                    style=x.style)

    open_close = js"""
        function (value) {
            if (value) {
                $(dom).show();
            } else {
                $(dom).hide();
            }
        }
    """
    onjs(session, x.open, open_close)

    Bonito.onload(session, dom, prevent_close_js())

    return Bonito.jsrender(session, dom)
end
