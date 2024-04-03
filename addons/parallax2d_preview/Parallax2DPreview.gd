@tool
extends EditorPlugin

enum { PREVIEW_DISABLED, PREVIEW_ACCURATE, PREVIEW_BASIC, REFRESH_PREVIEW }

var preview_button: MenuButton
var button_popup: Popup
var preview_node: Node

func _enter_tree() -> void:
	preview_button = MenuButton.new()
	preview_button.text = "Parallax2D Preview"
	preview_button.icon = preload("res://addons/parallax2d_preview/Icon.png")
	preview_button.hide()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, preview_button)
	
	var menu := preview_button.get_popup()
	menu.id_pressed.connect(on_menu_selected)
	
	menu.add_radio_check_item("Preview Disabled", PREVIEW_DISABLED)
	menu.add_radio_check_item("Accurate Preview", PREVIEW_ACCURATE)
	menu.add_radio_check_item("Basic Preview", PREVIEW_BASIC)
	menu.add_separator()
	menu.add_item("Refresh Preview", REFRESH_PREVIEW)
	on_menu_selected(PREVIEW_DISABLED)
	
	scene_changed.connect(func(s): on_menu_selected(PREVIEW_DISABLED))
	EditorInterface.get_selection().selection_changed.connect(update_button)

func _exit_tree() -> void:
	on_menu_selected(PREVIEW_DISABLED)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, preview_button)
	preview_button.queue_free()

func update_button():
	var make_visible: bool
	
	var selection := EditorInterface.get_selection().get_selected_nodes()
	if selection.size() == 1:
		make_visible = selection[0] is CanvasItem
	
	preview_button.visible = make_visible

func on_menu_selected(id: int):
	match id:
		PREVIEW_DISABLED:
			if preview_node:
				preview_node.queue_free()
				preview_node = null
		
		PREVIEW_ACCURATE:
			if preview_node:
				preview_node.accurate_preview = true
			else:
				make_node(true)
		
		PREVIEW_BASIC:
			if preview_node:
				preview_node.accurate_preview = false
			else:
				make_node(false)
		
		REFRESH_PREVIEW:
			if not preview_node:
				return
			
			var accurate: bool = preview_node.accurate_preview
			preview_node.free()
			make_node(accurate)
	
	var menu := preview_button.get_popup()
	if id < REFRESH_PREVIEW:
		for i in REFRESH_PREVIEW:
			menu.set_item_checked(i, id == i)
	
	menu.set_item_disabled(menu.get_item_index(REFRESH_PREVIEW), preview_node == null)

func make_node(accurate_preview: bool):
	if not EditorInterface.get_edited_scene_root():
		return
	
	preview_node = preload("res://addons/parallax2d_preview/PreviewNode.gd").new()
	preview_node.accurate_preview = accurate_preview
	EditorInterface.get_edited_scene_root().add_child(preview_node)
