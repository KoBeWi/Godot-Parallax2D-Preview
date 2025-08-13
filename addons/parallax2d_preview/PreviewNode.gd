@tool
extends Node

var parallax_list: Array[Parallax2D]
var accurate_preview: bool:
	set = update_preview
var window_size: Vector2

var last_viewport_pos: Vector2 = Vector2.INF
var line_helper: Node2D

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			if parallax_list.is_empty():
				find_parallax(get_tree().edited_scene_root)
				window_size = Vector2(
					ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width"),
					ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
				)
				
				if parallax_list.is_empty():
					push_warning("No Parallax2D nodes found in the current scene.")
			
			update_preview()
			_process.call_deferred(0)
		
		NOTIFICATION_EXIT_TREE:
			for parallax in parallax_list:
				parallax.screen_offset = Vector2()
			
			if line_helper:
				line_helper.queue_free()
		
		NOTIFICATION_EDITOR_PRE_SAVE:
			for parallax in parallax_list:
				parallax.screen_offset = Vector2()
		
		NOTIFICATION_EDITOR_POST_SAVE:
			last_viewport_pos = Vector2.INF

func find_parallax(parent: Node):
	for child in parent.get_children():
		if child is Parallax2D:
			parallax_list.append(child)
		
		find_parallax(child)

func update_preview(new: bool = accurate_preview):
	accurate_preview = new
	
	if not is_inside_tree():
		return
	
	if accurate_preview:
		if not line_helper:
			line_helper = Node2D.new()
			line_helper.z_index = 4096
			line_helper.top_level = true
			line_helper.draw.connect(draw_outline)
			get_tree().edited_scene_root.add_child(line_helper)
	else:
		if line_helper:
			line_helper.queue_free()
			line_helper = null
	
	last_viewport_pos = Vector2.INF

func _process(delta: float) -> void:
	var viewport_pos := get_viewport().global_canvas_transform.origin
	
	if viewport_pos != last_viewport_pos:
		last_viewport_pos = viewport_pos
		
		var position: Vector2
		if accurate_preview:
			position = get_editor_view_rect().position
		else:
			position = -viewport_pos / get_viewport().global_canvas_transform.get_scale()
		
		for parallax in parallax_list:
			parallax.screen_offset = position
		
		if accurate_preview:
			line_helper.queue_redraw()

func get_editor_view_rect() -> Rect2:
	var viewport_scale := get_viewport().global_canvas_transform.get_scale()
	var viewport_pos := get_viewport().global_canvas_transform.origin / viewport_scale
	var view_rect := Rect2(-viewport_pos, Vector2(get_viewport().size) / viewport_scale)
	return Rect2(view_rect.position + view_rect.size * 0.5 - window_size * 0.5, window_size)

func draw_outline() -> void:
	if Engine.is_editor_hint():
		var rect := get_editor_view_rect()
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0))
		draw_line(rect.position, rect.position + Vector2(0, rect.size.y))
		draw_line(rect.position + Vector2(rect.size.x, 0), rect.end)
		draw_line(rect.position + Vector2(0, rect.size.y), rect.end)

func draw_line(from: Vector2, to: Vector2):
	line_helper.draw_dashed_line(from, to, Color.YELLOW, -1, 4, false)
	line_helper.draw_dashed_line(from + from.direction_to(to) * 4, to, Color.BLACK, -1, 4, false)
