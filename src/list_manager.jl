# ----------------------------------------
# List Manager
# ----------------------------------------

"""
    ListManager(values::Vector{T}, add_function; label="", help="", item_function=default_item, get_function=default_get, style="")

Creates a composite control that pairs an [`SLList`](@ref) with add, delete, clear and reorder
buttons, managing a list of arbitrary Julia values.

`values` seeds the list; each element is turned into an `SLListItem` by `item_function`. The list
itself is the source of truth from then on, so an item may hold live sub-widgets (an [`SLInput`](@ref)
for inline editing, for example). Call [`get_values`](@ref) to read the current values back out;
it applies `get_function` to every item and returns a `Vector{T}`.

`add_function` is called with the active `Bonito.Session` when the add button is clicked and should
return the new value to append. Returning `nothing` cancels the add, which is useful when the add
flow is driven by an [`SLDialog`](@ref) the user may dismiss.

The move up and move down buttons reorder the list, and the selection follows the item as it moves,
so the same item can be walked to either end with repeated clicks.

Buttons disable themselves when they do not apply: delete while no item is selected, clear while the
list is empty, and the two moves at the corresponding end of the list. Deleting or clearing drops the
selection.

# Fields
- `list::SLList` - The underlying list; use `list.index` and `list.object` to inspect the selection
- `add::SLButton` - The add button
- `delete::SLButton` - The delete button
- `clear::SLButton` - The clear button
- `move_up::SLButton` - The move up button, an `sl_icon` arrow
- `move_down::SLButton` - The move down button, an `sl_icon` arrow
- `add_function::Function` - Called as `add_function(session)`, returns a new value or `nothing`
- `item_function::Function` - Maps a value to the `SLListItem` used to display it
- `get_function::Function` - Maps an `SLListItem` back to its value, the inverse of `item_function`
- `move_up_tooltip::String` - Tooltip text for the move up button
- `move_down_tooltip::String` - Tooltip text for the move down button
- `style::String` - Inline CSS style applied to the wrapping element

# Methods
- `get_values(manager)` - Read the current values as a `Vector{T}`
- `push!(manager, value)` - Append a value
- `append!(manager, values)` - Append several values
- `deleteat!(manager, i)` - Remove the item at index i
- `empty!(manager)` - Remove all items
- `moveat!(manager, from, to)` - Move the item at `from` to position `to`

# Examples
```julia
# Read-only list of strings, adding a numbered entry on each click
manager = ListManager(["alpha", "beta"], session -> "new item"; label="Items")
ShoelaceWidgets.get_values(manager)  # ["alpha", "beta"]

# Editable list: each item renders an SLInput, and get_function reads it back
item_function(value) = SLListItem(DOM.div(SLInput(value)); object=SLInput(value))
manager = ListManager(["alpha", "beta"], session -> "";
                      label="Items",
                      item_function = value -> (input = SLInput(value);
                                                SLListItem(DOM.div(input); object=input)),
                      get_function = item -> item.object.value[])

# After the user edits the inputs in the browser
ShoelaceWidgets.get_values(manager)  # reflects whatever was typed

# Any element type works
struct Point; x::Float64; y::Float64; end
manager = ListManager(Point[], session -> Point(rand(), rand());
                      label="Points",
                      item_function = p -> SLListItem(sl_tag("(\$(p.x), \$(p.y))"); object=p))

# Inspect the selection
manager.list.index   # selected index, or nothing
manager.list.object  # the selected item's object

# Cancel an add by returning nothing
manager = ListManager(String[], session -> nothing)
```
"""
struct ListManager{T}
    list::SLList
    add::SLButton
    delete::SLButton
    clear::SLButton
    move_up::SLButton
    move_down::SLButton
    add_function::Function
    item_function::Function
    get_function::Function
    move_up_tooltip::String
    move_down_tooltip::String
    style::String
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

function ListManager(values::Vector{T}, add_function::Function;
                     label::String="",
                     help::String="",
                     item_function::Function=default_item,
                     get_function::Function=default_get,
                     add_label::String="add",
                     delete_label::String="delete",
                     clear_label::String="clear",
                     move_up_tooltip::String="move up",
                     move_down_tooltip::String="move down",
                     style::String="") where T

    x = ListManager{T}(SLList(SLListItem[]; label, help),
                       SLButton(add_label; variant="text", size="small"),
                       SLButton(delete_label; variant="text", size="small", disabled=true), # nothing is selected yet
                       SLButton(clear_label; variant="text", size="small", disabled=true),  # populated by append! below
                       SLButton(sl_icon(; name="arrow-up"); variant="text", size="small", disabled=true),
                       SLButton(sl_icon(; name="arrow-down"); variant="text", size="small", disabled=true),
                       add_function,
                       item_function,
                       get_function,
                       move_up_tooltip,
                       move_down_tooltip,
                       style)

    # delete only applies to a selection, which deleting or clearing drops
    on(x.list.value) do _
        update_buttons!(x)
    end

    on(x.add.value) do session
        isnothing(session) && return
        value = x.add_function(session)
        isnothing(value) || push!(x, value)
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
    update_buttons!(x::ListManager)

Syncs the delete, clear and reorder buttons with the current selection and list length.
"""
function update_buttons!(x::ListManager)
    i = selected_index(x)
    x.delete.disabled[] = isnothing(i)
    x.clear.disabled[] = isempty(x)
    x.move_up.disabled[] = isnothing(i) || (i == 1)
    x.move_down.disabled[] = isnothing(i) || (i == length(x))
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
    buttons = DOM.div(x.add, x.delete, x.clear,
                      sl_tooltip(x.move_up; content=x.move_up_tooltip),
                      sl_tooltip(x.move_down; content=x.move_down_tooltip))
    return Bonito.jsrender(session, DOM.div(x.list, buttons; style=x.style))
end
