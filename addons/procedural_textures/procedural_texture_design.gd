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


const shader_type_string = {
	TYPE_BOOL: 'bool',
	TYPE_INT: 'int',
	TYPE_FLOAT:  'float',
	TYPE_VECTOR2: 'vec2',
	TYPE_VECTOR3: 'vec3',
	TYPE_VECTOR4: 'vec4',
	TYPE_COLOR: 'vec4',
}


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


func _gather_shader_data_for_node(node: ProceduralTextureDesignNode, data: Dictionary) -> void:
	if node in data.node_map:
		return

	for incoming in node.connections:
		var inc_node = node.connections[incoming].from_node
		_gather_shader_data_for_node(inc_node, data)

	data.counter += 1
	var postfix = '_{0}'.format([data.counter])

	match node.get_mode():
		ProceduralTextureDesignNode.Mode.SHADER:
			var shader := node.proc_shader
			if shader not in data.procedural_shader_map:
				var last_func: String = ''
				for x in shader.includes:
					if x not in data.includes:
						data.includes.append(x)
				for x in shader.structs:
					var definition = ShaderParser.reconstruct_string(x.definition)
					data.structs.append('struct {0} {{1}};'.format([x.name, definition]))
				for x in shader.functions:
					if x.name in ['vertex','fragment']: continue
					var return_type = ShaderParser.reconstruct_string(x.return_type)
					var func_name = x.name
					var func_params = ShaderParser.reconstruct_string(x.parameters)
					var func_def = ShaderParser.reconstruct_string(x.definition)
					# TODO replace texture() calls
					if func_name == 'process':
						func_name = 'process_' + shader.name
					data.functions.append('{0} {1}({2}) {{3}}'.format([return_type, func_name, func_params, func_def]))
					last_func = func_name
				data.procedural_shader_map[shader] = last_func

			var node_func_name: String = 'node_{0}{1}'.format([shader.name, postfix])
			var param_list: Array[String] = ['uv']
			for idx in shader.uniforms.size():
				var uniform := shader.uniforms[idx]
				var to_port: int = shader.inputs.size() + idx
				var connection: Dictionary = node.connections.get(to_port, {})
				var from_node = connection.get('from_node')
				if from_node is ProceduralTextureDesignNode:
					var converted = _convert_type_from_to(data.node_map[from_node], from_node.get_output_type(), uniform.type)
					param_list.append(converted)
				else:
					var value = node.shader_params.get(uniform.name) if node.shader_params.has(uniform.name) else shader.defaults.get(uniform.name)
					param_list.append(_format_immediate(value))

			var write_func: Array[String] = []
			write_func.append('{0} {1}(vec2 uv) {'.format([shader_type_string[shader.output_type], node_func_name]))
			write_func.append('\treturn {0}({1});'.format([data.procedural_shader_map[shader], ', '.join(param_list)]))
			write_func.append('}')
			data.functions.append('\n'.join(write_func))
			data.node_map[node] = node_func_name
		ProceduralTextureDesignNode.Mode.CONSTANT:
			var item_name = node.output_name + postfix
			data.variables.append('const {0} {1} = {2};'.format([shader_type_string[typeof(node.output_value)], item_name, _format_immediate(node.output_value)]))
			data.node_map[node] = item_name
		ProceduralTextureDesignNode.Mode.VARIABLE:
			var item_name = node.output_name + postfix
			data.variables.append('uniform {0} {1} = {2};'.format([shader_type_string[typeof(node.output_value)], item_name, _format_immediate(node.output_value)]))
			data.node_map[node] = item_name


func _build_shader_code_for_node(node: ProceduralTextureDesignNode) -> String:
	var mode := node.get_mode()
	if mode == ProceduralTextureDesignNode.Mode.OUTPUT:
		if node.connections.is_empty():
			return ''
		else:
			return _build_shader_code_for_node(node.connections[0].from_node)

	if mode != ProceduralTextureDesignNode.Mode.SHADER:
		return ''

	var data = {}
	data.counter = 0
	data.includes = []
	data.variables = []
	data.structs = []
	data.functions = []
	data.node_map = {}
	data.procedural_shader_map = {}

	_gather_shader_data_for_node(node, data)
	#print_rich('GATHERED DATA:', data)

	var arr: Array[String] = []

	arr.append('shader_type canvas_item;')
	arr.append('render_mode unshaded;')

	if not data.variables.is_empty():
		arr.append('')
		for x in data.variables:
			arr.append(x)

	for x in data.structs:
		arr.append('')
		arr.append(x)

	for x in data.functions:
		arr.append('')
		arr.append(x)

	var fragment_call = data.node_map[node] + '(UV)'
	arr.append('')
	arr.append('void fragment() {')
	arr.append('\tCOLOR = {0};'.format([_convert_type_from_to(fragment_call, node.proc_shader.output_type + 1000, TYPE_VECTOR4 + 1000)]))
	arr.append('}')

	var shader_code: String = '\n'.join(arr)
	print('SHADER CODE=\n', shader_code)
	return shader_code


static func _convert_type_from_to(value: String, from: int, to: int) -> String:
	if from == TYPE_INT and to == TYPE_FLOAT:
		return 'float({0})'.format([value])
	if from == TYPE_FLOAT and to == TYPE_INT:
		return 'int({0})'.format([value])
	if from == TYPE_FLOAT + 1000:
		if to == TYPE_VECTOR2 + 1000:
			return 'vec2({0}, 1.0)'.format([value])
		if to == TYPE_VECTOR3 + 1000:
			return 'vec3({0})'.format([value])
		if to == TYPE_VECTOR4 + 1000:
			return 'vec4(vec3({0}), 1.0)'.format([value])
	if from == TYPE_VECTOR2 + 1000:
		if to == TYPE_FLOAT + 1000:
			return '{0}.x'.format([value])
		if to == TYPE_VECTOR4 + 1000:
			return '{0}.xxxy'.format([value])
	if from == TYPE_VECTOR3 + 1000:
		if to == TYPE_VECTOR4 + 1000:
			return 'vec4({0}, 1.0)'.format([value])
	if from == TYPE_VECTOR4 + 1000:
		if to == TYPE_VECTOR3 + 1000:
			return '{0}.xyz'.format([value])
	return value


static func _format_float(value: float) -> String:
	var s = String.num(value, 3)
	if not '.' in s:
		s += '.0'
	return s


static func _format_immediate(value: Variant) -> String:
	if value is String:
		return value
	elif value is bool:
		return 'true' if value else 'false'
	elif value is int:
		return String.num(value)
	elif value is float:
		return _format_float(value)
	elif value is Vector2:
		return 'vec2({0}, {1})'.format([_format_float(value.x), _format_float(value.y)])
	elif value is Vector3:
		return 'vec3({0}, {1}, {2})'.format([_format_float(value.x), _format_float(value.y), _format_float(value.z)])
	elif value is Vector4:
		return 'vec4({0}, {1}, {2}, {3})'.format([_format_float(value.x), _format_float(value.y), _format_float(value.z), _format_float(value.w)])
	elif value is Color:
		return 'vec4({0}, {1}, {2}, {3})'.format([_format_float(value.r), _format_float(value.g), _format_float(value.b), _format_float(value.a)])

	assert(false, 'Unhandled variant type in _format_immediate')
	return var_to_str(value)


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
