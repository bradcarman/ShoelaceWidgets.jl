using Test
using Bonito
using ShoelaceWidgets
using ShoelaceWidgets: get_values, delete_selected!, selected_index, move_up!, move_down!, moveat!,
                       open_editor!, replace_selected!, accept!, reject!

# ----------------------------------
# TEST 1: default item_function/get_function
# ----------------------------------
names = ["alpha", "beta"]
manager = ListManager(names, session -> "item $(length(manager) + 1)"; label="Items")

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            manager
        )
    )
end

@test get_values(manager) == names
@test get_values(manager) isa Vector{String}
@test length(manager) == 2
@test length(manager.list.values[]) == 2
@test [item.index for item in manager.list.values[]] == [1, 2]

# nothing selected initially: delete disabled, clear enabled
@test manager.delete.disabled[] == true
@test manager.clear.disabled[] == false
@test isnothing(selected_index(manager))

# selecting enables delete
manager.list.index = 2
@test selected_index(manager) == 2
@test manager.delete.disabled[] == false
@test manager.list.object == "beta"

# delete removes the selection and drops it
delete_selected!(manager)
@test get_values(manager) == ["alpha"]
@test isnothing(selected_index(manager))
@test manager.delete.disabled[] == true

# no selection: delete_selected! is a no-op
delete_selected!(manager)
@test get_values(manager) == ["alpha"]

# an out of range selection is not a valid selection
manager.list.index = 5
@test isnothing(selected_index(manager))
@test manager.delete.disabled[] == true

# push! keeps the item indices sequential
push!(manager, "gamma")
@test get_values(manager) == ["alpha", "gamma"]
@test [item.index for item in manager.list.values[]] == [1, 2]

append!(manager, ["delta", "epsilon"])
@test get_values(manager) == ["alpha", "gamma", "delta", "epsilon"]
@test [item.index for item in manager.list.values[]] == [1, 2, 3, 4]

# deleting from the middle re-indexes the rest
deleteat!(manager, 2)
@test get_values(manager) == ["alpha", "delta", "epsilon"]
@test [item.index for item in manager.list.values[]] == [1, 2, 3]

# empty! disables clear
empty!(manager)
@test isempty(manager)
@test get_values(manager) == String[]
@test manager.clear.disabled[] == true

# the seed vector is never mutated
@test names == ["alpha", "beta"]

# the add button is guarded against the initial `nothing` session
manager.add.value[] = nothing
@test isempty(manager)


# ----------------------------------
# TEST 1b: reordering
# ----------------------------------
ordered = ListManager(["a", "b", "c"], session -> "x"; label="Ordered")

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            ordered
        )
    )
end

# nothing selected: both moves disabled
@test ordered.move_up.disabled[] == true
@test ordered.move_down.disabled[] == true

# the last item can move up but not down
ordered.list.index = 3
@test ordered.move_up.disabled[] == false
@test ordered.move_down.disabled[] == true

# the selection follows the item, so repeated clicks walk it to the top
move_up!(ordered)
@test get_values(ordered) == ["a", "c", "b"]
@test selected_index(ordered) == 2
@test [item.index for item in ordered.list.values[]] == [1, 2, 3]
@test ordered.move_up.disabled[] == false
@test ordered.move_down.disabled[] == false

move_up!(ordered)
@test get_values(ordered) == ["c", "a", "b"]
@test selected_index(ordered) == 1
@test ordered.move_up.disabled[] == true

# no-op at the top, selection untouched
move_up!(ordered)
@test get_values(ordered) == ["c", "a", "b"]
@test selected_index(ordered) == 1

move_down!(ordered)
@test get_values(ordered) == ["a", "c", "b"]
@test selected_index(ordered) == 2

# walk it back to the bottom
move_down!(ordered)
@test get_values(ordered) == ["a", "b", "c"]
@test selected_index(ordered) == 3
@test ordered.move_down.disabled[] == true

# no-op at the bottom
move_down!(ordered)
@test get_values(ordered) == ["a", "b", "c"]
@test selected_index(ordered) == 3

# non-adjacent moves
moveat!(ordered, 1, 3)
@test get_values(ordered) == ["b", "c", "a"]
@test selected_index(ordered) == 3
@test [item.index for item in ordered.list.values[]] == [1, 2, 3]

# out of range and no-change moves leave the list alone
moveat!(ordered, 1, 0)
moveat!(ordered, 4, 1)
moveat!(ordered, 2, 2)
@test get_values(ordered) == ["b", "c", "a"]

# an emptied list disables the moves
empty!(ordered)
@test ordered.move_up.disabled[] == true
@test ordered.move_down.disabled[] == true


# ----------------------------------
# TEST 2: inline SLInput editor
# ----------------------------------

function item_function(value)
    input = SLInput(value)
    item = SLListItem(DOM.div(input); object=input)
    return item
end

function get_function(item::SLListItem)
    input::SLInput = item.object
    return input.value[]
end

manager = ListManager(names, session -> "item $(length(manager) + 1)"; label="Items", item_function, get_function)

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            manager
        )
    )
end

@test get_values(manager) == names

# editing an input in the browser is reflected by get_values
manager.list.values[][1].object.value[] = "ALPHA"
@test get_values(manager) == ["ALPHA", "beta"]

# added items get their own editor
push!(manager, "gamma")
@test get_values(manager) == ["ALPHA", "beta", "gamma"]
manager.list.values[][3].object.value[] = "GAMMA"
@test get_values(manager) == ["ALPHA", "beta", "GAMMA"]

# deleting removes the right editor
deleteat!(manager, 2)
@test get_values(manager) == ["ALPHA", "GAMMA"]

# a move reorders the rows without rebuilding them: the same SLInput object
# travels with its row, so whatever the user typed survives the move
alpha_input = manager.list.values[][1].object
manager.list.index = 1
move_down!(manager)
@test get_values(manager) == ["GAMMA", "ALPHA"]
@test selected_index(manager) == 2
@test manager.list.values[][2].object === alpha_input

# and that editor still drives get_values from its new position
alpha_input.value[] = "alpha again"
@test get_values(manager) == ["GAMMA", "alpha again"]


# ----------------------------------
# TEST 3: arbitrary element type
# ----------------------------------
struct Point
    x::Float64
    y::Float64
end

points = ListManager(Point[], session -> Point(1.0, 2.0);
                     label="Points",
                     item_function = p -> SLListItem(DOM.div("($(p.x), $(p.y))"); object=p))

@test isempty(points)
@test get_values(points) isa Vector{Point}
@test points.clear.disabled[] == true
@test points.delete.disabled[] == true

push!(points, Point(3.0, 4.0))
@test get_values(points) == [Point(3.0, 4.0)]
@test points.clear.disabled[] == false

points.list.index = 1
@test points.list.object == Point(3.0, 4.0)
@test points.delete.disabled[] == false

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            points
        )
    )
end

@test !isnothing(app)


# ----------------------------------
# TEST 4: rendered markup
# ----------------------------------
# App() is lazy, so render to HTML to actually exercise Bonito.jsrender
render_html(x) = sprint(show, MIME"text/html"(),
                        App(session -> DOM.html(DOM.head(get_shoelace()...), DOM.body(x))))

html = render_html(points)
@test occursin("sl-radio-group", html)
@test occursin("arrow-up", html)    # move up icon
@test occursin("arrow-down", html)  # move down icon
@test occursin("sl-tooltip", html)
@test occursin("move up", html)
@test occursin("move down", html)

# the inline editor variant renders an SLInput per row
@test occursin("sl-input", render_html(manager))

# with no edit_function there is no edit button and no dialog
@test isnothing(points.edit)
@test isnothing(points.dialog)
@test isnothing(points.edit_function)
# NOTE: "sl-dialog" alone appears in the stylesheet, so match the opening tag
@test !occursin("<sl-dialog", html)
@test !occursin("pencil", html)

# open_editor! is a harmless no-op without an edit_function
points.list.index = 1
open_editor!(points)
@test isnothing(points.dialog)


# ----------------------------------
# TEST 5: edit button and DialogManager
# ----------------------------------
calls = Tuple{OpenOKCancel, Union{Int, Nothing}}[]
edit_input = SLInput(""; label="Value")

function edit_fn(m, action)
    push!(calls, (action, selected_index(m)))
    if action == Open
        edit_input.value[] = m.dialog.value[]         # seeded from the selection
    elseif action == OK
        replace_selected!(m, edit_input.value[])
    end
end

editable = ListManager(["a", "b", "c"], session -> "x";
                       label="Editable",
                       edit_function=edit_fn,
                       edit_content=DOM.div(edit_input),
                       dialog_label="Edit item")

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            editable
        )
    )
end

@test !isnothing(editable.edit)
@test editable.dialog isa DialogManager
@test editable.edit_function === edit_fn

# edit is selection scoped, like delete
@test editable.edit.disabled[] == true
@test isempty(calls)

editable.list.index = 2
@test editable.edit.disabled[] == false

# opening seeds dialog.value from the selection, then runs the Open action
open_editor!(editable)
@test calls == [(Open, 2)]
@test editable.dialog.open[] == true
@test editable.dialog.value[] == "b"
@test edit_input.value[] == "b"

# OK commits through replace_selected! and closes
edit_input.value[] = "BEE"
accept!(editable.dialog)
@test calls == [(Open, 2), (OK, 2)]
@test get_values(editable) == ["a", "BEE", "c"]
@test editable.dialog.open[] == false
@test selected_index(editable) == 2                   # the selection survives the commit
@test [item.index for item in editable.list.values[]] == [1, 2, 3]

# Cancel discards the edit
open_editor!(editable)
@test editable.dialog.value[] == "BEE"
edit_input.value[] = "discarded"
reject!(editable.dialog)
@test calls == [(Open, 2), (OK, 2), (Open, 2), (Cancel, 2)]
@test get_values(editable) == ["a", "BEE", "c"]
@test editable.dialog.open[] == false

# no selection: the button disables and open_editor! is a no-op
editable.list.index = 0
@test isnothing(selected_index(editable))
@test editable.edit.disabled[] == true
open_editor!(editable)
@test length(calls) == 4
@test editable.dialog.open[] == false

# replace_selected! is a no-op without a selection
replace_selected!(editable, "ignored")
@test get_values(editable) == ["a", "BEE", "c"]

# deleting drops the selection, which disables edit again
editable.list.index = 1
@test editable.edit.disabled[] == false
delete_selected!(editable)
@test get_values(editable) == ["BEE", "c"]
@test editable.edit.disabled[] == true

# the dialog, its OK/Cancel footer and the pencil icon are rendered
html = render_html(editable)
@test occursin("<sl-dialog label=\"Edit item\"", html)
@test occursin("class=\"dialog-manager\"", html)
@test occursin("slot=\"footer\"", html)
@test occursin("<sl-tooltip content=\"edit\"", html)
@test occursin("name=\"pencil\"", html)

# the edit button sits between clear and the arrows
@test first(findfirst("name=\"pencil\"", html)) < first(findfirst("name=\"arrow-up\"", html))
