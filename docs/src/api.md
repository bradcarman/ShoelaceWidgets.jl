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

Also exists as `SLListItem` and `SLList`, providing a different selection styling.

### List

```@docs
SLList
```



### Dialog

```@docs
SLDialog
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

```@docs
DialogManager
ListManager
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
```@docs
ShoelaceWidgets.reject! 
ShoelaceWidgets.default_get 
ShoelaceWidgets.open_editor! 
ShoelaceWidgets.move_up! 
ShoelaceWidgets.accept! 
ShoelaceWidgets.default_item 
ShoelaceWidgets.update_buttons! 
ShoelaceWidgets.prevent_close_js 
ShoelaceWidgets.open! 
ShoelaceWidgets.OpenOKCancel
ShoelaceWidgets.replace_selected! 
ShoelaceWidgets.delete_selected! 
ShoelaceWidgets.moveat! 
ShoelaceWidgets.selected_index 
ShoelaceWidgets.move_down! 
ShoelaceWidgets.get_values 
```