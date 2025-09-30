using Test
using Bonito
using ShoelaceWidgets

# Test old constructor still works
item = SLTreeItem("1")

tree = SLTree([
                    SLTreeItem("A",[
                        SLTreeItem("1")
                        SLTreeItem("2")
                        SLTreeItem("3")
                    ])
                    SLTreeItem("B",[
                        SLTreeItem("1")
                        SLTreeItem("2")
                        SLTreeItem("3")
                    ])
                ])

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            tree
        )
    )
end

# Test new simplified constructor
items = [
   "Deciduous" => [
      "Birch",
      "Maple" => ["Field", "Red", "Sugar"],
      "Oak"
   ],
   "Coniferous" => [
      "Cedar",
      "Pine",
      "Spruce"
   ]
]

tree = SLTree(items)

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            tree
        )
    )
end

@test length(tree.values) == 2
@test tree.values[1].value == "Deciduous"
@test length(tree.values[1].values) == 3
@test tree.values[1].values[2].value == "Maple"
@test length(tree.values[1].values[2].values) == 3
@test tree.values[1].values[2].values[1].value == "Field"

items = [
   "1",
   "2",
   "3"
]

tree = SLTree(items)

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            tree
        )
    )
end

tree.value[] = "2"

@test tree.value[] == "2"

# NOTE: diaglog does not show well in VS Code, use browser to see correctly
# port = 80
# url = "0.0.0.0"
# server = Bonito.Server(app, url, port)

