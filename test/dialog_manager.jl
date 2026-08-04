using Test
using Bonito
using ShoelaceWidgets
using ShoelaceWidgets: open!, accept!, reject!, OpenOKCancel, Open, OK, Cancel

# ----------------------------------
# TEST 1: the Open / OK / Cancel contract
# ----------------------------------
actions = OpenOKCancel[]
editor = SLInput(""; label="Name")
value = Observable("alpha")

function dialog_function(x, action)
    push!(actions, action)
    if action == Open
        editor.value[] = x.value[]
    elseif action == OK
        x.value[] = editor.value[]
    end
end

d = DialogManager(value, DOM.div(editor), dialog_function; label="Edit name")
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
            b,
            d
        )
    )
end


@test d.value === value
@test d.open[] == false
@test isempty(actions)

# opening seeds the editor from the value
open!(d)
@test actions == [Open]
@test d.open[] == true
@test editor.value[] == "alpha"

# OK commits and closes
editor.value[] = "ALPHA"
accept!(d)
@test actions == [Open, OK]
@test value[] == "ALPHA"
@test d.open[] == false

# Cancel closes without committing
open!(d)
@test editor.value[] == "ALPHA"     # reseeded from the committed value
editor.value[] = "discarded"
reject!(d)
@test actions == [Open, OK, Open, Cancel]
@test value[] == "ALPHA"            # untouched
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
count_value = Observable(0)
count_editor = SLInput(0)

counter = DialogManager(count_value, DOM.div(count_editor),
                        function (x, action)
                            action == Open && (count_editor.value[] = x.value[])
                            action == OK && (x.value[] = count_editor.value[])
                        end; label="Count")

@test counter isa DialogManager{Int}

open!(counter)
@test count_editor.value[] == 0
count_editor.value[] = 42
accept!(counter)
@test count_value[] == 42

# a plain value is wrapped in an Observable
plain = DialogManager("hello", DOM.div(), (x, action) -> nothing; label="Plain")
@test plain isa DialogManager{String}
@test plain.value[] == "hello"


# ----------------------------------
# TEST 3: rendered markup
# ----------------------------------
render_html(x) = sprint(show, MIME"text/html"(),
                        App(session -> DOM.html(DOM.head(get_shoelace()...), DOM.body(x))))

html = render_html(d)

# the dialog itself
@test occursin("<sl-dialog", html)
@test occursin("label=\"Edit name\"", html)

# OK and Cancel live in the footer slot
@test occursin("slot=\"footer\"", html)

# the header close button is hidden by the stylesheet, and the class that targets it is applied
@test occursin("class=\"dialog-manager\"", html)
@test occursin("sl-dialog.dialog-manager::part(close-button)", html)

# Every dismissal route is blocked. Bonito serializes onload JS into its binary
# asset bundle rather than inline HTML, so assert on the listener source itself.
prevent_close = string(ShoelaceWidgets.prevent_close_js())
@test occursin("sl-request-close", prevent_close)
@test occursin("preventDefault", prevent_close)
