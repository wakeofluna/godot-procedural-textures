@tool
extends GraphEdit
class_name ProceduralTexturesDesigner


signal title_changed


var design: ProceduralTextureDesign:
	set(new_design):
		if design != new_design:
			if design:
				design.changed.disconnect(_design_changed)
			design = new_design
			if design:
				design.changed.connect(_design_changed)
			_display_design()
			title_changed.emit()


func _iterate_for_files(dir: DirAccess, results: Dictionary) -> void:
	if dir:
		var dirname = dir.get_current_dir()
		if not dirname.ends_with('/'):
			dirname = dirname + '/'

		dir.list_dir_begin()
		while true:
			var fname = dir.get_next()
			if fname.is_empty():
				break
			if fname.begins_with('.'):
				continue
			var fullname = dirname + fname
			if dir.current_is_dir():
				_iterate_for_files(dir.open(fullname), results)
			elif ResourceLoader.exists(fullname, "Shader"):
				var item = ResourceLoader.load(fullname, "Shader", ResourceLoader.CACHE_MODE_REUSE)
				if item is ProceduralShader:
					results[item.name] = item


func _init() -> void:
	grid_pattern = GRID_PATTERN_DOTS
	scroll_offset_changed.connect(_on_scroll_offset_changed)

	var shaders = {}
	_iterate_for_files(DirAccess.open("res://"), shaders)
	print('FOUND SHADERS:')
	for shader_name in shaders:
		print('  - {0} at {1}'.format([shader_name, shaders[shader_name].resource_path]))


func _design_changed() -> void:
	title_changed.emit()


func _display_design() -> void:
	for child in get_children():
		if !child.name.begins_with("_"):
			remove_child(child)

	if design:
		var nodes_data: Array[Dictionary] = design.get_graph_nodes()
		for node_data in nodes_data:
			var node = design.create_graphelement_from_data(node_data)
			if node:
				add_child(node)


func _on_scroll_offset_changed(new_offset: Vector2) -> void:
	if design:
		design.editor_position = new_offset


func get_title() -> String:
	if not design or design.resource_path.is_empty():
		return '[unsaved]'

	var title = design.resource_path.get_file()
	if design.dirty:
		return '{0} (*)'.format([title])
	else:
		return title
