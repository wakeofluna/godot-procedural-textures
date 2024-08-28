@tool
extends Resource
class_name ProceduralTextureDesign


var nodes : Array[Dictionary] = []

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR + PROPERTY_USAGE_READ_ONLY) var dirty : bool = false:
	set(new_dirty):
		if dirty != new_dirty or new_dirty:
			dirty = new_dirty
			emit_changed()

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_READ_ONLY) var editor_position: Vector2i


func create_graphelement_from_data(data: Dictionary) -> GraphElement:
	var node = GraphNode.new()
	if data.title.is_empty():
		node.title = data.shader_name
	else:
		node.title = '{0} ({1})'.format([data.title, data.shader_name])
	node.position_offset = data.position
	node.position_offset_changed.connect(_node_position_changed.bind(node, data))
	return node


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var prop: Dictionary

	for index in nodes.size():

		prop = {}
		prop.name = "nodes/{0}/title".format([index])
		prop.class_name = ""
		prop.type = TYPE_STRING
		prop.hint = PROPERTY_HINT_NONE
		prop.hint_string = ""
		prop.usage = PROPERTY_USAGE_DEFAULT
		props.append(prop)

		prop = {}
		prop.name = "nodes/{0}/shader_name".format([index])
		prop.class_name = ""
		prop.type = TYPE_STRING
		prop.hint = PROPERTY_HINT_NONE
		prop.hint_string = ""
		prop.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		props.append(prop)

		prop = {}
		prop.name = "nodes/{0}/position".format([index])
		prop.class_name = ""
		prop.type = TYPE_VECTOR2I
		prop.hint = PROPERTY_HINT_NONE
		prop.hint_string = ""
		prop.usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY
		props.append(prop)

	return props


func _get(property: StringName) -> Variant:
	if property.begins_with("nodes/"):
		var index_str = property.get_slice('/', 1)
		if index_str.is_valid_int():
			var index = index_str.to_int()
			if index >= 0 and index < nodes.size():
				var node = nodes[index]
				var element = property.get_slice('/', 2)
				return node.get(element)
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with("nodes/"):
		var index_str = property.get_slice('/', 1)
		if index_str.is_valid_int():
			var index = index_str.to_int()
			if index == nodes.size():
				nodes.append({})
			if index >= 0 and index < nodes.size():
				var node = nodes[index]
				var element = property.get_slice('/', 2)
				node[element] = value
				return true
	return false


func _node_position_changed(node: GraphNode, data: Dictionary):
	data.position = node.position_offset
	dirty = true


func get_nr_outputs() -> int:
	return 0


func get_graph_nodes() -> Array[Dictionary]:
	if nodes.is_empty():
		var data = {}
		data.title = ''
		data.shader_name = "Bricks"
		data.position = Vector2i(20, 20)
		nodes.append(data)

		data = {}
		data.title = ''
		data.shader_name = "Emboss"
		data.position = Vector2i(20, 100)
		nodes.append(data)

		notify_property_list_changed()

	return nodes
