@tool
@static_unload
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
					results.append(ProceduralShader.from_shader(item as Shader))


static func get_shader_resources(force_scan: bool = false) -> Array[ProceduralShader]:
	if _shader_resources.is_empty() or force_scan:
		_shader_resources = []
		_search_for_shaders(DirAccess.open("res://"), _shader_resources)
		_shader_resources.make_read_only()
	return _shader_resources


func _init(undo_redo: EditorUndoRedoManager) -> void:
	assert(undo_redo)
	self.undo_redo = undo_redo

	# Allow disconnecting things
	right_disconnects = true
	# Allow connecting float outputs to vector inputs
	# vec2 = (float, 1.0)
	add_valid_connection_type(TYPE_FLOAT + 1000, TYPE_VECTOR2 + 1000)
	# vec3 = (float, float, float)
	add_valid_connection_type(TYPE_FLOAT + 1000, TYPE_VECTOR3 + 1000)
	# vec4 = (float, float, float, 1.0)
	add_valid_connection_type(TYPE_FLOAT + 1000, TYPE_VECTOR4 + 1000)
	# float = vec2.x
	add_valid_connection_type(TYPE_VECTOR2 + 1000, TYPE_FLOAT + 1000)
	# vec4 = (vec2.x, vec2.x, vec2.x, vec2.y)
	add_valid_connection_type(TYPE_VECTOR2 + 1000, TYPE_VECTOR4 + 1000)
	# vec4 = (vec3.x, vec3.y, vec3.z, 1.0)
	add_valid_connection_type(TYPE_VECTOR3 + 1000, TYPE_VECTOR4 + 1000)
	# vec3 = (vec4.x, vec4.y, vec4.z)
	add_valid_connection_type(TYPE_VECTOR4 + 1000, TYPE_VECTOR3 + 1000)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not scroll_offset_applied:
			scroll_offset_applied = true
			scroll_offset = design.editor_position


func setup_design(design: ProceduralTextureDesign) -> void:
	assert(design)
	self.design = design

	#var shaders = get_shader_resources()
	#print('FOUND SHADERS:')
	#for shader in shaders:
	#	print('  - {0} at {1}'.format([shader.name if !shader.name.is_empty() else "(noname)", shader.resource_path]))

	clear_connections()
	for idx in range(get_child_count() -1, -1, -1):
		var child = get_child(idx) as ProceduralTextureDesignEditorNode
		if child:
			remove_child(child)

	var nodes: Array[ProceduralTextureDesignNode] = design.get_graph_nodes()
	for node in nodes:
		var element = create_graphnode_from_data(node)
		add_child(element)

	for node in nodes:
		var to_node = find_graphnode_for(node)
		for to_port in node.connections:
			var connection = node.connections[to_port]
			var from_node = find_graphnode_for(connection.from_node)
			var from_port = connection.from_port
			if from_node and to_node:
				connect_node(from_node.name, from_port, to_node.name, to_port)

	grid_pattern = GRID_PATTERN_DOTS
	panning_scheme = PanningScheme.SCROLL_PANS
	minimap_enabled = design.editor_minimap
	zoom = design.editor_zoom

	connection_from_empty.connect(_on_connection_from_empty)
	connection_to_empty.connect(_on_connection_to_empty)
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	copy_nodes_request.connect(_on_copy_nodes_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	duplicate_nodes_request.connect(_on_duplicate_nodes_request)
	node_selected.connect(_on_node_selected)
	paste_nodes_request.connect(_on_paste_nodes_request)
	popup_request.connect(_on_popup_request)


func _apply_changes() -> void:
	design.editor_position = scroll_offset
	design.editor_minimap = minimap_enabled
	design.editor_zoom = zoom


func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	print_rich('CONNECTION FROM EMPTY TO ', to_node, ':', to_port, " AT LOCATION ", release_position)


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	print_rich('CONNECTION TO EMPTY FROM ', from_node, ':', from_port, " AT LOCATION ", release_position)


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	#print('CONNECTION REQUEST FROM ', from_node, ':', from_port, " TO ", to_node, ':', to_port)
	var from: ProceduralTextureDesignEditorNode
	var to: ProceduralTextureDesignEditorNode
	for child in get_children():
		if child.name == from_node:
			from = child
		if child.name == to_node:
			to = child
	if not from or not to:
		return
	if to.detect_circular_reference(from.design_node):
		printerr("Attempted to create a circular reference, connection denied")
		return

	undo_redo.create_action('Add Design Node Connection', UndoRedo.MERGE_DISABLE, design, true)
	var existing_connection = to.get_connection_to(to_port)
	if not existing_connection.is_empty():
		var other_node = find_graphnode_for(existing_connection.from_node).name
		undo_redo.add_do_method(to, "remove_connection_to", to_port)
		undo_redo.add_do_method(self, "disconnect_node", other_node, existing_connection.from_port, to_node, to_port)
		undo_redo.add_undo_method(to, "add_connection_to", to_port, existing_connection.from_node, existing_connection.from_port)
		undo_redo.add_undo_method(self, "connect_node", other_node, existing_connection.from_port, to_node, to_port)
	undo_redo.add_do_method(to, "add_connection_to", to_port, from.design_node, from_port)
	undo_redo.add_undo_method(to, "remove_connection_to", to_port)
	undo_redo.add_do_method(self, "connect_node", from_node, from_port, to_node, to_port)
	undo_redo.add_undo_method(self, "disconnect_node", from_node, from_port, to_node, to_port)
	undo_redo.commit_action()


func _on_copy_nodes_request() -> void:
	print('COPY NODES REQUEST')


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	print('DELETE NODES REQUEST FOR ', ','.join(nodes))


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	#print('DISCONNECT REQUEST FROM ', from_node, ':', from_port, " TO ", to_node, ':', to_port)
	var to: ProceduralTextureDesignEditorNode
	for child in get_children():
		if child.name == to_node:
			to = child
	if not to:
		return

	var existing_connection = to.get_connection_to(to_port)
	if not existing_connection.is_empty():
		undo_redo.create_action('Remove Design Node Connection', UndoRedo.MERGE_DISABLE, design, true)
		undo_redo.add_do_method(to, "remove_connection_to", to_port)
		undo_redo.add_undo_method(to, "add_connection_to", to_port, existing_connection.from_node, existing_connection.from_port)
		undo_redo.add_do_method(self, "disconnect_node", from_node, from_port, to_node, to_port)
		undo_redo.add_undo_method(self, "connect_node", from_node, from_port, to_node, to_port)
		undo_redo.commit_action()


func _on_duplicate_nodes_request() -> void:
	print('DUPLICATE NODES REQUEST')


func _on_node_selected(node: Node) -> void:
	if node is ProceduralTextureDesignEditorNode:
		EditorInterface.edit_resource(node.design_node)


func _on_paste_nodes_request() -> void:
	print('PASTE NODES REQUEST')


func _on_popup_request(at_position: Vector2) -> void:
	print_rich('POPUP REQUEST AT ', at_position)


func create_graphnode_from_data(design_node: ProceduralTextureDesignNode) -> GraphElement:
	var graph_node = ProceduralTextureDesignEditorNode.new()
	graph_node.setup_design_node(undo_redo, design_node)
	return graph_node


func find_graphnode_for(design_node: ProceduralTextureDesignNode) -> ProceduralTextureDesignEditorNode:
	for child in get_children():
		if child is ProceduralTextureDesignEditorNode:
			if child.design_node == design_node:
				return child
	return null


func get_title() -> String:
	if not design or design.resource_path.is_empty():
		return '[unsaved]'

	return design.resource_path.get_file()
