@tool
extends Resource
class_name ProceduralTextureDesign


@export_storage var nodes : Array[ProceduralTextureDesignNode] = []:
	set(new_nodes):
		for node in nodes:
			node.changed.disconnect(_on_node_changed)
		nodes = new_nodes
		for node in new_nodes:
			node.changed.connect(_on_node_changed.bind(node))
		emit_changed()

@export_storage var editor_position: Vector2
@export_storage var editor_zoom: float = 1.0
@export_storage var editor_minimap: bool = false


var shader_cache: Dictionary = {}


func add_new_design_node(new_node: ProceduralTextureDesignNode) -> void:
	assert(not nodes.has(new_node), "Attempted to add a design node twice")
	nodes.append(new_node)
	new_node.changed.connect(_on_node_changed.bind(new_node))
	emit_changed()


func remove_design_node(old_node: ProceduralTextureDesignNode) -> void:
	var found := nodes.find(old_node)
	assert(found >= 0, "Attempted to remove an unowned design node")
	old_node.changed.disconnect(_on_node_changed)
	nodes.remove_at(found)
	shader_cache.erase(old_node)
	emit_changed()


func get_outgoing_connections_for(node: ProceduralTextureDesignNode) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for other in nodes:
		for to_port in other.connections:
			var conn = other.connections[to_port]
			if conn.from_node == node:
				var item = {}
				item.from_port = conn.from_port
				item.to_node = other
				item.to_port = to_port
				result.append(item)
	return result


func get_nodes() -> Array[ProceduralTextureDesignNode]:
	return nodes


func get_output(name: String) -> ProceduralTextureDesignNode:
	for node in nodes:
		if node.get_mode() == ProceduralTextureDesignNode.Mode.OUTPUT and node.output_name == name:
			return node
	return null


func get_outputs() -> Array[ProceduralTextureDesignNode]:
	var result: Array[ProceduralTextureDesignNode] = []
	for node in nodes:
		if node.get_mode() == ProceduralTextureDesignNode.Mode.OUTPUT:
			result.append(node)
	return result


func get_output_names() -> Array[String]:
	var result: Array[String]
	for node in nodes:
		if node.get_mode() == ProceduralTextureDesignNode.Mode.OUTPUT:
			result.append(node.output_name)
	return result


func get_shader_for_node(node: ProceduralTextureDesignNode) -> Shader:
	var shader_ref: WeakRef = shader_cache.get(node)
	var shader: Shader = shader_ref.get_ref() if shader_ref else null
	if not shader:
		shader = Shader.new()
		shader.code = _build_shader_code_for_node(node)
		shader_cache[node] = weakref(shader)
	return shader


func _build_shader_code_for_node(node: ProceduralTextureDesignNode) -> String:
	return ''


func _on_node_changed(node: ProceduralTextureDesignNode) -> void:
	var shader_ref: WeakRef = shader_cache.get(node)
	var shader: Shader = shader_ref.get_ref() if shader_ref else null
	if shader:
		var new_code = _build_shader_code_for_node(node)
		if shader.code == new_code:
			return
		shader.code = new_code

	var handled = []
	for ref in get_outgoing_connections_for(node):
		if ref.to_node not in handled:
			handled.append(ref.to_node)
			_on_node_changed(ref.to_node)
