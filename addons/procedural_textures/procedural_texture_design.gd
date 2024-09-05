@tool
extends Resource
class_name ProceduralTextureDesign


@export var nodes : Array[ProceduralTextureDesignNode] = []

@export_storage var editor_position: Vector2
@export_storage var editor_zoom: float = 1.0
@export_storage var editor_minimap: bool = false


func get_nr_outputs() -> int:
	return 0


func get_graph_nodes() -> Array[ProceduralTextureDesignNode]:
	if nodes.is_empty():
		var node: ProceduralTextureDesignNode

		node = ProceduralTextureDesignNode.new()
		node.shader = preload("res://addons/procedural_textures/shaders/pattern_bricks.gdshader")
		node.graph_position = Vector2i(20, 20)
		nodes.append(node)

		node = ProceduralTextureDesignNode.new()
		node.shader = preload("res://addons/procedural_textures/shaders/filter_emboss.gdshader")
		node.graph_position = Vector2i(20, 100)
		nodes.append(node)

		notify_property_list_changed()

	return nodes
