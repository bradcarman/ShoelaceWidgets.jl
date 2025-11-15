using Test
using Bonito
using ShoelaceWidgets


# Test basic progress bar
progress = SLProgressBar(50.0; label="Loading")

app = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress
        )
    )
end

# Test updating progress value
progress.value[] = 75.0


# Test progress bar with custom height
progress_custom = SLProgressBar(25.0; height="30px", label="Upload progress")

app2 = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress_custom
        )
    )
end


# Test indeterminate progress bar
progress_indeterminate = SLProgressBar(; indeterminate=true, label="Processing")

app3 = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress_indeterminate
        )
    )
end

# Toggle indeterminate state
progress_indeterminate.indeterminate[] = false


# Test progress bar with hidden value
progress_hidden = SLProgressBar(60.0; show_value=false, label="Background task")

app4 = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress_hidden
        )
    )
end


# Test progress bar visibility control
progress_visible = SLProgressBar(40.0; label="Visible test")

app5 = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress_visible
        )
    )
end

# Hide the progress bar
progress_visible.visible[] = false

# Show it again
progress_visible.visible[] = true


# Test creating initially hidden progress bar
progress_initially_hidden = SLProgressBar(30.0; visible=false, label="Initially hidden")

app6 = App() do session
    DOM.html(
        DOM.head(
            get_shoelace()...
        ),
        DOM.body(
            progress_initially_hidden
        )
    )
end

# Show it
progress_initially_hidden.visible[] = true


@test true
