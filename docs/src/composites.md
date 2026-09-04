# Composite Controls

Most widgets in ShoelaceWidgets map one-to-one onto a Shoelace element. The two on this page do not:
they assemble several widgets into a single control with its own behaviour.

- [`ListManager`](@ref) — an [`SLList`](@ref) plus add, delete, clear, edit and reorder buttons,
  managing a `Vector{T}` for any `T`.
- [`DialogManager`](@ref) — a modal dialog with OK and Cancel buttons that cannot be dismissed any
  other way.

```@example composites
using ShoelaceWidgets
using Bonito
nothing # hide
```

## ListManager

### A simple list

The list is seeded from a vector, and `add_function` is called with the active session each time the
add button is clicked. Whatever it returns is appended; returning `nothing` cancels the add.

```@example composites
manager = ListManager(["alpha", "beta"];
                      label = "Items",
                      add_function = session -> "item $(length(manager) + 1)")

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(manager)
    )
end
```

Read the contents back at any time with `get_values`:

```@example composites
ShoelaceWidgets.get_values(manager)
```

The list itself is the source of truth, not the vector you passed in — that vector is never mutated.
Mutate the control instead, with `push!`, `append!`, `deleteat!`, `empty!` and `moveat!`:

```@example composites
push!(manager, "gamma")
ShoelaceWidgets.get_values(manager)
```

### Rows holding live widgets

`item_function` maps `(manager, value)` to the [`SLListItem`](@ref) that displays it, and
`get_function` maps `(manager, item)` back to a value. Because rows can contain any widget, an item
can hold its own editor — `get_values` then reflects whatever the user typed.

```@example composites
function item_function(manager, value)
    input = SLInput(value)
    return SLListItem(DOM.div(input); object = input)
end

get_function(manager, item::SLListItem) = item.object.value[]

editable = ListManager(["alpha", "beta"];
                       label = "Editable items",
                       add_function = session -> "new",
                       item_function,
                       get_function)

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(editable)
    )
end
```

Reordering moves rows without rebuilding them, so each row keeps its own live editor and whatever
was typed into it survives the move.

### Building a composite value in a dialog

For a type with several fields, a single click cannot produce a value — the user has to fill it in.
Setting `add_mode` to `DialogAdd` changes `add_function`'s contract from `add_function(session)` to
`add_function(manager, action)`, where `action` is an
[`OpenOKCancel`](@ref ShoelaceWidgets.OpenOKCancel). The add button then
opens an OK/Cancel dialog whose body is `add_content`.

Initialize the editors on `Open`, and assemble the value and `push!` it on `OK`. `Cancel` needs no
branch, because nothing is appended until the `OK` branch runs.

```@example composites
struct Point
    x::Float64
    y::Float64
end

xin = SLInput(0.0; label = "x")
yin = SLInput(0.0; label = "y")

function add_point(manager, action)
    if action == ShoelaceWidgets.Open
        xin.value[] = 0.0
        yin.value[] = 0.0
    elseif action == ShoelaceWidgets.OK
        push!(manager, Point(xin.value[], yin.value[]))
    end
end

points = ListManager(Point[];
                     label = "Points",
                     add_mode = ShoelaceWidgets.DialogAdd,
                     add_function = add_point,
                     add_content = DOM.div(xin, yin),
                     add_label = "Add point",
                     item_function = (manager, p) -> SLListItem("($(p.x), $(p.y))"; object = p))

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(points)
    )
end
```

### Editing the selected item

`edit_function` adds a pencil button, disabled until something is selected, that opens a second
dialog with body `edit_content`. It takes the same `(manager, action)` contract. Seed the editors
from the selection on `Open`, and commit with `replace_selected!` on `OK`.

```@example composites
ex = SLInput(0.0; label = "x")
ey = SLInput(0.0; label = "y")

function edit_point(manager, action)
    if action == ShoelaceWidgets.Open
        p = manager.list.object
        ex.value[] = p.x
        ey.value[] = p.y
    elseif action == ShoelaceWidgets.OK
        ShoelaceWidgets.replace_selected!(manager, Point(ex.value[], ey.value[]))
    end
end

editable_points = ListManager([Point(1.0, 2.0), Point(3.0, 4.0)];
                              label = "Points",
                              edit_function = edit_point,
                              edit_content = DOM.div(ex, ey),
                              dialog_label = "Edit point",
                              item_function = (manager, p) -> SLListItem("($(p.x), $(p.y))"; object = p))

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(editable_points)
    )
end
```

Note that no add button behaviour was supplied here, so it is disabled — a button that provably does
nothing is not left looking clickable.

### Button states

Buttons disable themselves whenever they do not apply, so the control never offers an action that
would silently do nothing:

| Button | Disabled when |
|---|---|
| add | no `add_function` was supplied |
| delete, edit | nothing is selected |
| clear | the list is empty |
| move up | the first item is selected |
| move down | the last item is selected |

Deleting and clearing drop the selection. Moving carries it along, so repeated clicks walk the same
item to either end of the list.

### Suppressing buttons

A button that should not appear at all, rather than appear disabled, is suppressed by a mode. Setting
`add_mode = ShoelaceWidgets.NoAdd` drops the add button, and `edit_mode = ShoelaceWidgets.NoEdit`
drops the edit button and its dialog, whether or not the matching function was supplied.
`edit_mode = ShoelaceWidgets.NoEditDeleteClearOrder` drops the delete, clear, move up and move down
buttons as well, so only the add button is left under the list; combine it with `NoAdd` for a list
with no buttons at all. The corresponding fields are then `nothing` instead of a button.

```@example composites
display_only = ListManager(["alpha", "beta", "gamma"];
                           label = "Read-only",
                           add_mode = ShoelaceWidgets.NoAdd,
                           edit_mode = ShoelaceWidgets.NoEditDeleteClearOrder)

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(display_only)
    )
end
```

Only the buttons go away. `push!`, `deleteat!`, `empty!`, `moveat!` and the rest still work, so a
list with no buttons can still be driven entirely from code.

## DialogManager

A [`DialogManager`](@ref) is a modal dialog with OK and Cancel in its footer. Unlike a bare
[`SLDialog`](@ref) it refuses every other way out — the overlay, the escape key, and the header close
button, which is hidden rather than left as a control that does nothing. Exactly one `OK` or `Cancel`
therefore follows every `Open`, which is what makes the callback contract reliable.

The body is passed at construction and holds the editing widgets. `dialog_function` seeds them on
`Open` and reads them on `OK`.

```@example composites
name = Observable("alpha")
editor = SLInput(""; label = "Name")

function edit_name(d, action)
    if action == ShoelaceWidgets.Open
        editor.value[] = name[]
    elseif action == ShoelaceWidgets.OK
        name[] = editor.value[]
    end
end

dialog = DialogManager(DOM.div(editor), edit_name; label = "Edit name")

open_button = SLButton("edit"; variant = "primary")
on(open_button.value) do session
    isnothing(session) || ShoelaceWidgets.open!(dialog)
end

app = App() do session
    DOM.html(
        DOM.head(get_shoelace()...),
        DOM.body(open_button, dialog)
    )
end
```

Both the trigger and the dialog have to be rendered — a dialog that is not in the document has
nothing to show.

Cancel is a no-op by construction rather than by undo: since `name` is only written in the `OK`
branch, rejecting the dialog leaves it untouched. Nothing is snapshotted or restored automatically,
so a `dialog_function` that writes its value during `Open` is responsible for its own undo.

The three actions can also be driven from Julia, which is how the behaviour is tested without a
browser:

```@example composites
ShoelaceWidgets.open!(dialog)     # runs the Open action and shows the dialog
editor.value[] = "beta"
ShoelaceWidgets.accept!(dialog)   # runs OK and closes
name[]
```

```@example composites
ShoelaceWidgets.open!(dialog)
editor.value[] = "discarded"
ShoelaceWidgets.reject!(dialog)   # runs Cancel and closes
name[]                            # unchanged
```
