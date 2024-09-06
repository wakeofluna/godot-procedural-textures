@tool
@static_unload
extends GraphEdit
class_name ProceduralTextureDesignEditor


signal _popup_result(Variant)


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
		_shader_resources.sort_custom(func(a,b): return a.name > b.name)
		_shader_resources.make_read_only()
	return _shader_resources


func _init(undo_redo: EditorUndoRedoManager) -> void:
	assert(undo_redo)
	self.undo_redo = undo_redo

	# Allow disconnecting things
	right_disconnects = true

	# Allow converting between scalars (usable for constants)
	add_valid_connection_type(TYPE_FLOAT, TYPE_INT)
	add_valid_connection_type(TYPE_INT, TYPE_FLOAT)

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
		# Workaround: the GraphEdit scrollbars min/max are not set until
		# the window resizes the first time. Setting offets are rejected
		# before then since the min/max are not in range.
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

	var nodes: Array[ProceduralTextureDesignNode] = design.get_nodes()
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
	#print('COPY NODES REQUEST')
	pass


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	#print('DELETE NODES REQUEST FOR ', ','.join(nodes))

	var targets: Array[ProceduralTextureDesignEditorNode] = []
	for child in get_children():
		if child.name in nodes:
			targets.append(child)

	undo_redo.create_action("Delete Nodes", UndoRedo.MERGE_DISABLE, design, true)
	for node: ProceduralTextureDesignEditorNode in targets:
		# Remove all incoming connections
		for to_port in node.design_node.connections:
			var conn: Dictionary = node.design_node.connections[to_port]
			var from_node := find_graphnode_for(conn.from_node)
			#undo_redo.add_do_method(node, "remove_connection_to", to_port)
			#undo_redo.add_undo_method(node, "add_connection_to", to_port, conn.from_node, conn.from_port)
			undo_redo.add_do_method(self, "disconnect_node", from_node.name, conn.from_port, node.name, to_port)
			undo_redo.add_undo_method(self, "connect_node", from_node.name, conn.from_port, node.name, to_port)
		# Remove all outgoing connections
		for conn in design.get_outgoing_connections_for(node.design_node):
			var to_node := find_graphnode_for(conn.to_node)
			undo_redo.add_do_method(to_node, "remove_connection_to", conn.to_port)
			undo_redo.add_undo_method(to_node, "add_connection_to", conn.to_port, node.design_node, conn.from_port)
			undo_redo.add_do_method(self, "disconnect_node", node.name, conn.from_port, to_node.name, conn.to_port)
			undo_redo.add_undo_method(self, "connect_node", node.name, conn.from_port, to_node.name, conn.to_port)
		# Remove the node
		undo_redo.add_do_method(design, "remove_design_node", node.design_node)
		undo_redo.add_do_method(self, "remove_child", node)
		undo_redo.add_undo_reference(node)
		undo_redo.add_undo_method(self, "add_child", node)
		undo_redo.add_undo_method(design, "add_new_design_node", node.design_node)

	undo_redo.commit_action()


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
	#print('DUPLICATE NODES REQUEST')
	pass


func _on_node_selected(node: Node) -> void:
	if node is ProceduralTextureDesignEditorNode:
		EditorInterface.edit_resource(node.design_node)


func _on_paste_nodes_request() -> void:
	#print('PASTE NODES REQUEST')
	pass


func _on_popup_request(at_position: Vector2) -> void:
	print_rich('POPUP REQUEST AT ', at_position)

	var result = await show_popup(at_position, -1, -1)
	if result is ProceduralShader:
		var design_node := ProceduralTextureDesignNode.new()
		design_node.shader = result.shader
		design_node.graph_position = at_position + scroll_offset

		var graph_node = create_graphnode_from_data(design_node)

		undo_redo.create_action("Add Design Node", UndoRedo.MERGE_DISABLE, design)
		undo_redo.add_do_reference(graph_node)
		undo_redo.add_do_method(design, "add_new_design_node", design_node)
		undo_redo.add_do_method(self, "add_child", graph_node)
		undo_redo.add_undo_method(self, "remove_child", graph_node)
		undo_redo.add_undo_method(design, "remove_design_node", design_node)
		undo_redo.commit_action()


func create_graphnode_from_data(design_node: ProceduralTextureDesignNode) -> ProceduralTextureDesignEditorNode:
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


func show_popup(position: Vector2, filter_input_type: int, filter_output_type: int) -> Variant:
	var popup := Popup.new()

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = "Add Node"

	var editor_scale = EditorInterface.get_editor_scale()
	var tree := Tree.new()
	tree.hide_root = true
	tree.custom_minimum_size = Vector2(200, 200) * editor_scale
	tree.item_activated.connect(func():
		var selected := tree.get_selected()
		if selected.get_child_count() > 0:
			selected.collapsed = not selected.collapsed
		else:
			_popup_result.emit(selected.get_metadata(0))
		)

	var root := tree.create_item()

	var filters := root.create_child()
	filters.set_text(0, "Filters")
	filters.collapsed = true

	var patterns := root.create_child()
	patterns.set_text(0, "Patterns")
	patterns.collapsed = true

	for shader in get_shader_resources():
		var item := patterns.create_child() if shader.inputs.is_empty() else filters.create_child()
		item.set_text(0, shader.name)
		item.set_metadata(0, shader)

	var vbox := VBoxContainer.new()
	vbox.add_child(label)
	vbox.add_child(HSeparator.new())
	vbox.add_child(tree)
	var panel := PanelContainer.new()
	panel.add_child(vbox)
	popup.add_child(panel)
	popup.exclusive = true
	popup.visibility_changed.connect(func(): if not popup.visible: _popup_result.emit(null))
	popup.close_requested.connect(func(): _popup_result.emit(null))
	var rect := Rect2i(position, Vector2i())
	rect.position += Vector2i(get_screen_position())
	rect.position.x -= 100 * editor_scale
	rect.position.y -= 40 * editor_scale
	popup.popup_exclusive_on_parent(self, rect)

	var result = await _popup_result
	popup.queue_free()
	return result
