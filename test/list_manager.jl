using Test
using Bonito
using ShoelaceWidgets
using ShoelaceWidgets: get_values, delete_selected!, selected_index, move_up!, move_down!, moveat!,
                       open_editor!, open_adder!, replace_selected!, accept!, reject!,
                       OpenOKCancel, Open, OK, Cancel, AddMode, FunctionMode, DialogMode

# ----------------------------------
# TEST 1: default item_function/get_function
# ----------------------------------
names = ["alpha", "beta"]


# function item_function(value::String)

#     edit = SLInput(value)
   
#     return SLListItem(DOM.div(edit); object=edit)
# end

# function get_function(item::SLListItem)  
#     return item.object.value[]
# end

manager = ListManager(names; 
                    add_function = session -> "item $(length(manager) + 1)", 
                    label="Items", collapsible=true) #, item_function, get_function)


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
ordered = ListManager(["a", "b", "c"]; add_function = session -> "x", label="Ordered")

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

manager = ListManager(names; add_function = session -> "item $(length(manager) + 1)", label="Items", item_function, get_function)

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

points = ListManager(Point[]; add_function = session -> Point(1.0, 2.0),
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
@test isnothing(points.edit_dialog)
@test isnothing(points.edit_function)
# NOTE: "sl-dialog" alone appears in the stylesheet, so match the opening tag
@test !occursin("<sl-dialog", html)
@test !occursin("pencil", html)

# open_editor! is a harmless no-op without an edit_function
points.list.index = 1
open_editor!(points)
@test isnothing(points.edit_dialog)


# ----------------------------------
# TEST 5: edit button and DialogManager
# ----------------------------------
calls = Tuple{OpenOKCancel, Union{Int, Nothing}}[]
edit_input = SLInput(""; label="Value")

function edit_fn(m::ListManager, action)
    push!(calls, (action, selected_index(m)))
    if action == Open
        edit_input.value[] = ShoelaceWidgets.selected_value(m)
    elseif action == OK
        ShoelaceWidgets.replace_selected!(m, edit_input.value[])
    end
end

editable = ListManager(["a", "b", "c"]; 
                    add_function = session -> "x",
                    label="Editable",
                    edit_function=edit_fn,
                    edit_content=DOM.div(edit_input))

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
@test editable.edit_dialog isa DialogManager
@test editable.edit_function === edit_fn

# edit is selection scoped, like delete
@test editable.edit.disabled[] == true
@test isempty(calls)

editable.list.index = 2
@test editable.edit.disabled[] == false

# opening seeds dialog.value from the selection, then runs the Open action
open_editor!(editable)
@test calls == [(Open, 2)]
@test editable.edit_dialog.open[] == true
@test edit_input.value[] == "b"

# OK commits through replace_selected! and closes
edit_input.value[] = "BEE"
accept!(editable.edit_dialog)
@test calls == [(Open, 2), (OK, 2)]
@test get_values(editable) == ["a", "BEE", "c"]
@test editable.edit_dialog.open[] == false
@test selected_index(editable) == 2                   # the selection survives the commit
@test [item.index for item in editable.list.values[]] == [1, 2, 3]

# Cancel discards the edit
open_editor!(editable)
edit_input.value[] = "discarded"
reject!(editable.edit_dialog)
@test calls == [(Open, 2), (OK, 2), (Open, 2), (Cancel, 2)]
@test get_values(editable) == ["a", "BEE", "c"]
@test editable.edit_dialog.open[] == false

# no selection: the button disables and open_editor! is a no-op
editable.list.index = 0
@test isnothing(selected_index(editable))
@test editable.edit.disabled[] == true
open_editor!(editable)
@test length(calls) == 4
@test editable.edit_dialog.open[] == false

# replace_selected! is a no-op without a selection
replace_selected!(editable, "ignored")
@test get_values(editable) == ["a", "BEE", "c"]

# deleting drops the selection, which disables edit again
editable.list.index = 1
@test editable.edit.disabled[] == false
delete_selected!(editable)
@test get_values(editable) == ["BEE", "c"]
@test editable.edit.disabled[] == true

# ----------------------------------
# TEST 6: add dialog for a composite type
# ----------------------------------
add_calls = OpenOKCancel[]
xin = SLInput(0.0; label="x", select_on_focus=true)
yin = SLInput(0.0; label="y", select_on_focus=true)

function add_dialog_function(m, action)
    push!(add_calls, action)
    if action == Open
        xin.value[] = 0.0
        yin.value[] = 0.0
    elseif action == OK
        push!(m, Point(xin.value[], yin.value[]))
    end
end

composite = ListManager(Point[];
                        label="Points",
                        add_function = add_dialog_function,
                        add_mode = DialogMode,
                        add_content=DOM.div(xin, yin),
                        add_label="Add point",
                        item_function = p -> SLListItem("($(p.x), $(p.y))"; object=p))


app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            composite
        )
    )
end





@test composite.add_dialog isa DialogManager
@test composite.add_mode == DialogMode
@test isnothing(composite.edit_dialog)                 # no edit_function given
@test composite.add_function === add_dialog_function
@test composite.add.disabled[] == false           # add_function wires the button
@test isempty(add_calls)
@test isempty(composite)

# opening does not need a selection, unlike the editor
open_adder!(composite)
@test add_calls == [Open]
@test composite.add_dialog.open[] == true
@test xin.value[] == 0.0

# OK appends whatever the callback assembled
xin.value[] = 3.0
yin.value[] = 4.0
accept!(composite.add_dialog)
@test add_calls == [Open, OK]
@test get_values(composite) == [Point(3.0, 4.0)]
@test composite.add_dialog.open[] == false

# the editors are reinitialized on the next open, not left holding the last value
open_adder!(composite)
@test xin.value[] == 0.0

# Cancel appends nothing
xin.value[] = 9.0
yin.value[] = 9.0
reject!(composite.add_dialog)
@test add_calls == [Open, OK, Open, Cancel]
@test get_values(composite) == [Point(3.0, 4.0)]

# a second add appends rather than replacing
open_adder!(composite)
xin.value[] = 5.0
yin.value[] = 6.0
accept!(composite.add_dialog)
@test get_values(composite) == [Point(3.0, 4.0), Point(5.0, 6.0)]
@test [item.index for item in composite.list.values[]] == [1, 2]

# the add dialog renders alongside the list
html = render_html(composite)
@test occursin("<sl-dialog label=\"Add point\"", html)
@test occursin("name=\"plus-circle\"", html)

# with no add_function the add button is disabled and no dialog is built
inert = ListManager(["a"]; label="Inert")
@test isnothing(inert.add_dialog)
@test isnothing(inert.add_function)
@test inert.add_mode == FunctionMode              # the default
@test inert.add.disabled[] == true
open_adder!(inert)                                # harmless no-op
@test get_values(inert) == ["a"]

# DialogMode with no add_function builds no dialog either
no_fn = ListManager(["a"]; add_mode=DialogMode, add_content=DOM.div())
@test isnothing(no_fn.add_dialog)
@test no_fn.add.disabled[] == true

# FunctionMode never builds a dialog, even with add_content supplied
fn_mode = ListManager(String[];
                      add_function = session -> "from add_function",
                      add_content = DOM.div())
@test isnothing(fn_mode.add_dialog)
@test fn_mode.add_mode == FunctionMode
open_adder!(fn_mode)                              # no dialog to open
@test isempty(fn_mode)
@test !occursin("<sl-dialog", render_html(fn_mode))
