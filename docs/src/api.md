# API Reference

## Header Functions

```@docs
get_shoelace
```

## Input Components

### Input

```@docs
SLInput
```

### Select

```@docs
SLSelect
```

### Button

```@docs
SLButton
```

### Checkbox

```@docs
SLCheckbox
```

### Radio

```@docs
SLRadio
SLRadioGroup
```

### List

The same control with list styling instead of radio buttons.

```@docs
SLList
SLListItem
```

### Dialog

```@docs
SLDialog
```

### Details

```@docs
SLDetails
```

### Tree
NOTE: SLTree needs more work to be done properly, will remove for now

### Textarea

```@docs
SLTextarea
```

### Progress Bar

```@docs
SLProgressBar
```

### Alert

```@docs
SLAlert
```

## Composite Components

Controls assembled from several widgets. See the
[Composite Controls](composites.md) page for worked examples.

```@docs
ListManager
DialogManager
ShoelaceWidgets.AddMode
ShoelaceWidgets.EditMode
ShoelaceWidgets.OpenOKCancel
```

## UI Element Functions

### Tab Components

```@docs
sl_tab_group
sl_tab
sl_tab_panel
```

### Utility Components

```@docs
sl_tag
sl_format_date
sl_spinner
sl_icon
sl_card
sl_checkbox
sl_tooltip
sl_copy_button
```

## Internals

These are not exported. Reach them as `ShoelaceWidgets.get_values(...)` and so on.

### Reading and mutating a ListManager

```@docs
ShoelaceWidgets.get_values
ShoelaceWidgets.selected_index
ShoelaceWidgets.replace_selected!
ShoelaceWidgets.delete_selected!
ShoelaceWidgets.moveat!
ShoelaceWidgets.move_up!
ShoelaceWidgets.move_down!
ShoelaceWidgets.open_adder!
ShoelaceWidgets.open_editor!
ShoelaceWidgets.default_item
ShoelaceWidgets.default_get
ShoelaceWidgets.update_buttons!
```

### Driving a DialogManager

```@docs
ShoelaceWidgets.open!
ShoelaceWidgets.accept!
ShoelaceWidgets.reject!
ShoelaceWidgets.prevent_close_js
```