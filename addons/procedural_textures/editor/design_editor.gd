@tool
extends GraphEdit
class_name ProceduralTextureDesignEditor


static var _shader_resources: Array[ProceduralShader] = []

var design: ProceduralTextureDesign
var undo_redo: EditorUndoRedoManager
var scroll_offset_applied: bool = false

var resource_path: String:
	get():
		return design.resource_path if design else ''

var resource_owner: String:
	get():
		var path = design.resource_path if design else ''
		return path.get_slice('::', 0)

var resource_sub_path: String:
	get():
		var path = design.resource_path if design else ''
		return path.get_slice('::', 1) if path.contains('::') else ''

var is_sub_resource: bool:
	get():
		var path = design.resource_path if design else ''
		return path.contains('::')


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
				if item is Shader:
					results.append(ProceduralShader.new(item as Shader))


static func get_shader_resources(force_scan: bool = false) -> Array[ProceduralShader]:
	if _shader_resources.is_empty() or force_scan:
		_shader_resources = []
		_search_for_shaders(DirAccess.open("res://"), _shader_resources)
		_shader_resources.make_read_only()
	return _shader_resources


func dump_children(obj: Object, indent: int = 0) -> void:
	if obj:
		var ind = '                '.substr(0, indent)
		if obj is ScrollBar:
			print('{0}{1} # {2}'.format([ind, obj.get_class(), obj.get_instance_id()]))
			print('{0}  min={1} max={2} page={3} value={4}'.format([ind, obj.min_value, obj.max_value, obj.page, obj.value]))
		for child in obj.get_children(true):
			dump_children(child, indent + 2)

func print_scrollbars() -> void:
	dump_children(self)


func _init(undo_redo: EditorUndoRedoManager) -> void:
	assert(undo_redo)
	self.undo_redo = undo_redo


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not scroll_offset_applied:
			scroll_offset_applied = true
			scroll_offset = design.editor_position


func setup_design(design: ProceduralTextureDesign) -> void:
	assert(design)
	self.design = design

	var shaders = get_shader_resources()
	print('FOUND SHADERS:')
	for shader in shaders:
		print('  - {0} at {1}'.format([shader.name if !shader.name.is_empty() else "(noname)", shader.resource_path]))

	var nodes: Array[ProceduralTextureDesignNode] = design.get_graph_nodes()
	for node in nodes:
		var element = create_graphelement_from_data(node)
		add_child(element)

	grid_pattern = GRID_PATTERN_DOTS
	panning_scheme = PanningScheme.SCROLL_PANS
	minimap_enabled = design.editor_minimap
	zoom = design.editor_zoom


func _apply_changes() -> void:
	design.editor_position = scroll_offset
	design.editor_minimap = minimap_enabled
	design.editor_zoom = zoom


func _on_node_position_changed(graph_node: GraphElement, design_node: ProceduralTextureDesignNode):
	if design_node.graph_position != graph_node.position_offset:
		var name = 'Move Node ' + String.num_uint64(graph_node.get_instance_id())
		undo_redo.create_action(name, UndoRedo.MERGE_ENDS)
		undo_redo.add_do_property(design_node, 'graph_position', graph_node.position_offset)
		undo_redo.add_undo_property(design_node, 'graph_position', design_node.graph_position)
		undo_redo.add_undo_property(graph_node, 'position_offset', design_node.graph_position)
		undo_redo.commit_action()


func create_graphelement_from_data(design_node: ProceduralTextureDesignNode) -> GraphElement:
	var graph_node = GraphNode.new()
	if design_node.title.is_empty():
		graph_node.title = design_node.proc_shader.name
	else:
		graph_node.title = '{0} ({1})'.format([design_node.title, design_node.proc_shader.name])
	graph_node.position_offset = design_node.graph_position
	graph_node.position_offset_changed.connect(_on_node_position_changed.bind(graph_node, design_node))
	return graph_node


func get_title() -> String:
	if not design or design.resource_path.is_empty():
		return '[unsaved]'

	return design.resource_path.get_file()
