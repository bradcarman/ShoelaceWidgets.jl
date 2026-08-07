# ----------------------------------------
# List Manager
# ----------------------------------------

# Matches Shoelace's own form control labels, so the label rendered above the
# bordered list looks native next to every other widget's label.

"""
    AddMode

Selects how a [`ListManager`](@ref) interprets its `add_function`:

- `FunctionMode` - `add_function(session)` returns the value to append
- `DialogMode` - `add_function(manager, action)` drives an OK/Cancel dialog

Named `FunctionMode` rather than `Function` because a bare `Function` would collide with
`Base.Function`, which this module uses throughout in type annotations.
"""
@enum AddMode FunctionMode DialogMode


"""
    ListManager(values::Vector{T}; add_function=nothing, add_mode=FunctionMode, label="", help="", item_function=default_item, get_function=default_get, style="")

Creates a composite control that pairs an [`SLList`](@ref) with add, delete, clear and reorder
buttons, managing a list of arbitrary Julia values.

`values` seeds the list; each element is turned into an `SLListItem` by `item_function`. The list
itself is the source of truth from then on, so an item may hold live sub-widgets (an [`SLInput`](@ref)
for inline editing, for example). Call [`get_values`](@ref) to read the current values back out;
it applies `get_function` to every item and returns a `Vector{T}`.

`add_function` drives the add button, and `add_mode` (an [`AddMode`](@ref)) decides how it is called:

- `FunctionMode` (the default) calls `add_function(session)` with the active `Bonito.Session` when
  the button is clicked. It returns the value to append, or `nothing` to cancel. Good for values
  needing no input.
- `DialogMode` instead opens an OK/Cancel dialog whose body is the `add_content` node, for building
  a composite value field by field, and calls `add_function(manager, action)` with an
  [`OpenOKCancel`](@ref): on `Open` initialize your editors (nothing is seeded, since a new value has
  no prior state), and on `OK` assemble the value and `push!(manager, value)` yourself. `Cancel`
  normally needs no branch, as nothing was appended.

Leaving `add_function` as `nothing` disables the add button, since clicking it would do nothing.

The move up and move down buttons reorder the list, and the selection follows the item as it moves,
so the same item can be walked to either end with repeated clicks.

Passing `edit_function` adds a pencil button that edits the selected item through a
[`DialogManager`](@ref) owned by the manager, whose body is the `edit_content` node. It is called as
`edit_function(manager, action)` with an [`OpenOKCancel`](@ref):

- `Open` when the button is clicked. `manager.dialog.value[]` has already been seeded with the
  selected item's value, so this seeds the editors in `edit_content` from it.
- `OK` when the user accepts. Commit the editors, typically with
  [`replace_selected!`](@ref).
- `Cancel` when the user rejects. Nothing has been committed, so this normally needs no branch.

Because the dialog cannot be dismissed by the overlay, escape, or a close button, exactly one `OK` or
`Cancel` follows every `Open`.

Leaving `edit_function` as `nothing` means no edit button and no dialog are created at all, and both
the `edit` and `dialog` fields are `nothing`.

Buttons disable themselves when they do not apply: delete and edit while no item is selected, clear
while the list is empty, and the two moves at the corresponding end of the list. Deleting or clearing
drops the selection.

# Fields
- `list::SLList` - The underlying list; use `list.index` and `list.object` to inspect the selection
- `label::String` - Label text, rendered above the bordered list rather than inside it
- `add::SLButton` - The add button
- `delete::SLButton` - The delete button
- `clear::SLButton` - The clear button
- `edit::Union{SLButton, Nothing}` - The edit button, an `sl_icon` pencil, or `nothing`
- `move_up::SLButton` - The move up button, an `sl_icon` arrow
- `move_down::SLButton` - The move down button, an `sl_icon` arrow
- `dialog::Union{DialogManager, Nothing}` - The OK/Cancel edit dialog, or `nothing`
- `add_dialog::Union{DialogManager, Nothing}` - The OK/Cancel add dialog, or `nothing` in `FunctionMode`
- `add_function::Union{Function, Nothing}` - Called per `add_mode`, or `nothing` to disable adding
- `add_mode::AddMode` - `FunctionMode` or `DialogMode`
- `item_function::Function` - Maps a value to the `SLListItem` used to display it
- `get_function::Function` - Maps an `SLListItem` back to its value, the inverse of `item_function`
- `edit_function::Union{Function, Nothing}` - Called as `edit_function(manager, action)`
- `style::String` - Inline CSS style applied to the wrapping element
- `list_style::String` - Inline CSS style for the bordered, scrolling box around the items

# Methods
- `get_values(manager)` - Read the current values as a `Vector{T}`
- `push!(manager, value)` - Append a value
- `append!(manager, values)` - Append several values
- `deleteat!(manager, i)` - Remove the item at index i
- `empty!(manager)` - Remove all items
- `moveat!(manager, from, to)` - Move the item at `from` to position `to`
- `open_editor!(manager)` - Open the edit dialog for the selected item
- `open_adder!(manager)` - Open the add dialog
- `replace_selected!(manager, value)` - Replace the selected item, for an `OK` branch
"""
@kwdef struct ListManager{T}
    list::SLList
    label::String
    add::SLButton
    delete::SLButton
    clear::SLButton
    edit::Union{SLButton, Nothing}
    move_up::SLButton
    move_down::SLButton

    add_function::Union{Function, Nothing}
    add_dialog::Union{DialogManager, Nothing}
    add_mode::AddMode

    item_function::Function
    get_function::Function

    edit_function::Union{Function, Nothing}
    edit_dialog::Union{DialogManager, Nothing}

    style::String
    list_style::String
end

"""
    default_item(value)

Default `item_function` for [`ListManager`](@ref): displays `string(value)` and keeps `value` as the
item's `object`. Pairs with [`default_get`](@ref).
"""
default_item(value) = SLListItem(string(value); object=value)

"""
    default_get(item::SLListItem)

Default `get_function` for [`ListManager`](@ref): returns the item's `object`, which is where
[`default_item`](@ref) stashed the original value.
"""
default_get(item::SLListItem) = item.object

function ListManager(values::Vector{T};
                     label::String="",
                     help::String="",
                     add_mode::AddMode=FunctionMode,
                     add_function::Union{Function, Nothing}=nothing, #add_function(session)::T or add_function(manager, action) on Open ::Hyperscript.Node, on OK ::T
                     item_function::Function=default_item,
                     get_function::Function=default_get,
                     edit_function::Union{Function, Nothing}=nothing, #edit_function(manager, action)
                     edit_content::Hyperscript.Node=DOM.div(),
                     add_content::Hyperscript.Node=DOM.div(),
                     dialog_label::String="Edit",
                     add_label::String="Add",
                     style::String="",
                     dialog_style="--width: 75vw;",
                     list_style="height: 40vh; overflow-y: auto; padding: 5px; border: 1px solid lightgray;") where T

    # the dialog callback needs the manager, which does not exist yet
    manager = Ref{Any}(nothing)

    # no edit_function means no edit button and no dialog at all
    edit = isnothing(edit_function) ? nothing :
           SLButton(sl_icon(; name="pencil"); variant="text", size="small", disabled=true)

    edit_dialog = isnothing(edit_function) ? nothing :
             DialogManager(edit_content,
                           function (d::DialogManager, action)
                               m = manager[]
                               m.edit_function(m, action)
                           end;
                           label=dialog_label, style=dialog_style)

    # the add dialog builds a brand new value, so there is nothing to seed from;
    # initializing the editors is the callback's job
    add_dialog = (add_mode != DialogMode || isnothing(add_function)) ? nothing :
                 DialogManager(add_content,
                               function (d, action)
                                   m = manager[]
                                   m.add_function(m, action)
                               end;
                               label=add_label, style=dialog_style)

    # the label is rendered above the bordered list rather than passed to SLList,
    # which would place it inside the border
    x = ListManager{T}(;
                list = SLList(SLListItem[]; help),
                label,
                add = SLButton(sl_icon(; name="plus-circle"); variant="text", size="small"),
                delete = SLButton(sl_icon(; name="dash-circle"); variant="text", size="small", disabled=true), # nothing is selected yet
                clear = SLButton(sl_icon(; name="x-circle"); variant="text", size="small", disabled=true),  # populated by append! below
                edit,
                move_up = SLButton(sl_icon(; name="arrow-up"); variant="text", size="small", disabled=true),
                move_down = SLButton(sl_icon(; name="arrow-down"); variant="text", size="small", disabled=true),
                
                add_dialog,
                add_function,
                add_mode,
                       
                item_function,
                get_function,
                
                edit_function,
                edit_dialog,
                       
                style,
                list_style)

    manager[] = x

    # nothing is wired to the add button, so do not leave it looking clickable.
    # Set it back to false yourself if you are wiring `add.value` by hand.
    if isnothing(add_function)
        x.add.disabled[] = true
    end

    # delete only applies to a selection, which deleting or clearing drops
    on(x.list.value) do _
        update_buttons!(x)
    end

    # add_mode decides how add_function is called
    on(x.add.value) do session
        isnothing(session) && return
        isnothing(x.add_function) && return
        if x.add_mode == DialogMode
            open_adder!(x)
        else
            value = x.add_function(session)
            isnothing(value) || push!(x, value)
        end
    end

    on(x.delete.value) do session
        isnothing(session) && return
        delete_selected!(x)
    end

    on(x.clear.value) do session
        isnothing(session) && return
        empty!(x)
    end

    on(x.move_up.value) do session
        isnothing(session) && return
        move_up!(x)
    end

    on(x.move_down.value) do session
        isnothing(session) && return
        move_down!(x)
    end

    # the DialogManager routes OK and Cancel to edit_function itself
    isnothing(x.edit) || on(x.edit.value) do session
        isnothing(session) && return
        open_editor!(x)
    end

    append!(x, values)

    return x
end

"""
    get_values(x::ListManager{T}) -> Vector{T}

Returns the current values by applying `x.get_function` to every displayed item. When items hold
live sub-widgets this reads whatever the user last entered in the browser.
"""
get_values(x::ListManager{T}) where T = T[x.get_function(item) for item in x.list.values[]]

"""
    selected_index(x::ListManager)

Returns the selected index, or `nothing` when there is no valid selection.
"""
function selected_index(x::ListManager)
    i = x.list.index
    if isnothing(i) || (i < 1) || (i > length(x))
        return nothing
    end
    return i
end

function selected_value(x::ListManager)
    i = selected_index(x)
    if !isnothing(i)
        return x.list.object #TODO: there is got to be a better field then object, should be value
    end
end

"""
    delete_selected!(x::ListManager)

Removes the selected item. Does nothing when there is no selection.
"""
function delete_selected!(x::ListManager)
    i = selected_index(x)
    isnothing(i) || deleteat!(x, i)
    return x
end

"""
    moveat!(x::ListManager, from::Int, to::Int)

Moves the item at position `from` to position `to`, carrying the selection with it. Does nothing when
either position is out of range, which is what makes the move buttons no-ops at the ends of the list.
"""
function moveat!(x::ListManager, from::Int, to::Int)
    items = x.list.values[]
    n = length(items)
    ((from < 1) || (from > n) || (to < 1) || (to > n) || (from == to)) && return x

    insert!(items, to, popat!(items, from))
    for (i, item) in enumerate(items)
        item.index = i
    end

    # set the selection before notifying, matching how SLList's own popat! resets it
    
    
    notify(x.list.values)
    update_buttons!(x)

    x.list.value[] = "0" # do this first to ensure control updates
    x.list.value[] = string(to)
    return x
end

"""
    move_up!(x::ListManager)

Moves the selected item one position towards the front. Does nothing when there is no selection or
the first item is selected.
"""
function move_up!(x::ListManager)
    i = selected_index(x)
    isnothing(i) || moveat!(x, i, i - 1)
    return x
end

"""
    move_down!(x::ListManager)

Moves the selected item one position towards the back. Does nothing when there is no selection or
the last item is selected.
"""
function move_down!(x::ListManager)
    i = selected_index(x)
    isnothing(i) || moveat!(x, i, i + 1)
    return x
end

"""
    open_editor!(x::ListManager)

Opens the edit dialog, which seeds `x.dialog.value` from the selected item and then runs
`x.edit_function(x, Open)`. Does nothing when no `edit_function` was supplied or nothing is selected.
"""
function open_editor!(x::ListManager)
    isnothing(x.edit_dialog) && return x
    isnothing(selected_index(x)) && return x
    open!(x.edit_dialog)
    return x
end

"""
    open_adder!(x::ListManager)

Opens the add dialog, which runs `x.add_dialog_function(x, Open)`. Unlike the editor this needs no
selection. Does nothing when no `add_dialog_function` was supplied.
"""
function open_adder!(x::ListManager)
    isnothing(x.add_dialog) && return x
    open!(x.add_dialog)
    return x
end

"""
    replace_selected!(x::ListManager, value)

Replaces the selected item with `x.item_function(value)`, keeping its position and the selection.
This is what an `edit_function` calls in its `OK` branch to commit an edit. Does nothing when there
is no selection.
"""
function replace_selected!(x::ListManager, value)
    i = selected_index(x)
    isnothing(i) && return x
    item = x.item_function(value)
    item.index = i
    x.list.values[][i] = item
    notify(x.list.values)
    return x
end

"""
    update_buttons!(x::ListManager)

Syncs the delete, clear, edit and reorder buttons with the current selection and list length.
"""
function update_buttons!(x::ListManager)
    i = selected_index(x)
    x.delete.disabled[] = isnothing(i)
    x.clear.disabled[] = isempty(x)
    x.move_up.disabled[] = isnothing(i) || (i == 1)
    x.move_down.disabled[] = isnothing(i) || (i == length(x))
    isnothing(x.edit) || (x.edit.disabled[] = isnothing(i))
    return x
end

function Base.push!(x::ListManager, value)
    push!(x.list, x.item_function(value))  # SLList assigns the item index
    update_buttons!(x)
    return x
end

function Base.append!(x::ListManager, values)
    for value in values
        push!(x.list, x.item_function(value))
    end
    update_buttons!(x)
    return x
end

function Base.deleteat!(x::ListManager, i::Int)
    popat!(x.list, i)  # SLList re-indexes the remaining items and drops the selection
    update_buttons!(x)
    return x
end

function Base.empty!(x::ListManager)
    empty!(x.list)
    update_buttons!(x)
    return x
end

Base.length(x::ListManager) = length(x.list.values[])
Base.isempty(x::ListManager) = isempty(x.list.values[])

function Bonito.jsrender(session::Session, x::ListManager)
    # NOTE: Shoelace tooltips do not fire on disabled elements, so these only show when enabled
    buttons = [sl_tooltip(x.add; content="add"), sl_tooltip(x.delete; content="remove"), sl_tooltip(x.clear; content="clear")]
    isnothing(x.edit) || push!(buttons, sl_tooltip(x.edit; content="edit"))
    push!(buttons, sl_tooltip(x.move_up; content="move up"))
    push!(buttons, sl_tooltip(x.move_down; content="move down"))

    # the border belongs to this wrapper, so the label goes above it rather than
    # inside the sl-radio-group
    scroll = DOM.div(x.list; style=x.list_style)

    children = Any[]
    isempty(x.label) || push!(children, DOM.div(x.label; style=LABEL_STYLE))
    push!(children, scroll)
    push!(children, DOM.div(buttons...))

    # the dialogs have to be in the document for them to be shown
    isnothing(x.edit_dialog) || push!(children, x.edit_dialog)
    isnothing(x.add_dialog) || push!(children, x.add_dialog)

    return Bonito.jsrender(session, DOM.div(children...; style=x.style))
end
