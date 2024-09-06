@tool
extends Resource
class_name ProceduralTextureDesign


@export_storage var nodes : Array[ProceduralTextureDesignNode] = []
@export_storage var editor_position: Vector2
@export_storage var editor_zoom: float = 1.0
@export_storage var editor_minimap: bool = false


func add_new_design_node(new_node: ProceduralTextureDesignNode) -> void:
	assert(not nodes.has(new_node), "Attempted to add a design node twice")
	nodes.append(new_node)
	emit_changed()


func remove_design_node(old_node: ProceduralTextureDesignNode) -> void:
	var found := nodes.find(old_node)
	assert(found >= 0, "Attempted to remove an unowned design node")
	nodes.remove_at(found)
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


func get_nr_outputs() -> int:
	return 0


func get_nodes() -> Array[ProceduralTextureDesignNode]:
	return nodes
