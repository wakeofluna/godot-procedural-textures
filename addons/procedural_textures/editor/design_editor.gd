@tool
extends GraphEdit
class_name ProceduralTexturesEditor


static var _shader_resources: Array[ProceduralShader] = []

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

@export_custom(PROPERTY_HINT_NONE, '', PROPERTY_USAGE_READ_ONLY) var resource_path: String:
	get():
		return design.resource_path if design else ''

@export_custom(PROPERTY_HINT_NONE, '', PROPERTY_USAGE_READ_ONLY) var resource_owner: String:
	get():
		var path = design.resource_path if design else ''
		return path.get_slice('::', 0)

@export_custom(PROPERTY_HINT_NONE, '', PROPERTY_USAGE_READ_ONLY) var resource_sub_path: String:
	get():
		var path = design.resource_path if design else ''
		return path.get_slice('::', 1) if path.contains('::') else ''

@export_custom(PROPERTY_HINT_NONE, '', PROPERTY_USAGE_READ_ONLY) var is_sub_resource: bool:
	get():
		var path = design.resource_path if design else ''
		return path.contains('::')


signal title_changed


static func _search_for_shaders(dir: DirAccess, results: Array[ProceduralShader]) -> void:
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
				_search_for_shaders(dir.open(fullname), results)
			elif ResourceLoader.exists(fullname, "Shader"):
				var item = ResourceLoader.load(fullname, "Shader", ResourceLoader.CACHE_MODE_REUSE)
				var ps: ProceduralShader = ProceduralShader.create_from_object(item)
				if ps:
					results.append(ps)


static func get_shader_resources(force_scan: bool = false) -> Array[ProceduralShader]:
	if _shader_resources.is_empty() or force_scan:
		_shader_resources = []
		_search_for_shaders(DirAccess.open("res://"), _shader_resources)
		_shader_resources.make_read_only()
	return _shader_resources


func _init() -> void:
	grid_pattern = GRID_PATTERN_DOTS
	scroll_offset_changed.connect(_on_scroll_offset_changed)

	var shaders = get_shader_resources()
	print('FOUND SHADERS:')
	for shader in shaders:
		print('  - {0} at {1}'.format([shader.name if !shader.name.is_empty() else "(noname)", shader.resource_path]))


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
