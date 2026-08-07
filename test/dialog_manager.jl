using Test
using Bonito
using ShoelaceWidgets
using ShoelaceWidgets: open!, accept!, reject!, OpenOKCancel, Open, OK, Cancel

# ----------------------------------
# TEST 1: the Open / OK / Cancel contract
# ----------------------------------
actions = OpenOKCancel[]
editor = SLInput("alpha"; label="Name")

function dialog_function(x::DialogManager, action)
    push!(actions, action)
    if action == Open
        editor.value[] = ""
    elseif action == OK
        println(editor.value[])
    end
end

d = DialogManager(DOM.div(editor), dialog_function; label="Edit name")
b = SLButton("open")
on(b.value) do x
    open!(d)
end

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            DOM.div(b; style="height:500px; border:1px solid gray;"),
            d
        )
    )
end

@test d.open[] == false
@test isempty(actions)

# opening seeds the editor from the value
open!(d)
@test actions == [Open]
@test d.open[] == true
@test editor.value[] == ""

# OK commits and closes
editor.value[] = "ALPHA"
accept!(d)
@test actions == [Open, OK]
@test d.open[] == false

# Cancel closes without committing
open!(d)
@test editor.value[] == ""     
editor.value[] = "discarded"
reject!(d)
@test actions == [Open, OK, Open, Cancel]
@test d.open[] == false

# setting the Observable directly also runs the Open action
d.open[] = true
@test actions[end] == Open
@test d.open[] == true
reject!(d)
@test d.open[] == false

# closing does not run Open
empty!(actions)
d.open[] = false
@test isempty(actions)

# the buttons are guarded against the initial `nothing` session
d.ok.value[] = nothing
d.cancel.value[] = nothing
@test isempty(actions)


# ----------------------------------
# TEST 2: arbitrary value type
# ----------------------------------
count_editor = SLInput(0)

counter = DialogManager(DOM.div(count_editor),
                        function (x, action)
                            action == OK && (count_editor.value[] += 1)
                        end; label="Count")


open!(counter)
@test count_editor.value[] == 0
accept!(counter)
@test count_editor.value[] == 1


