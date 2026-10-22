using Test
using Bonito
using ShoelaceWidgets

value = Observable("clipboard contents")

data = [
    (name="Alice", age=25, score=95.5),
    (name="Bob", age=30, score=87.2),
]

table = Observable(Bonito.Table(data))

app = App() do session
    DOM.div(
        sl_copy_button(;value),
        table
    )
end


data = [
    (name="Alice", age=25, score=95.5),
    (name="Bob", age=30, score=87.2),
    (name="Charlie", age=22, score=92.8)
]

table[] = Bonito.Table(data)