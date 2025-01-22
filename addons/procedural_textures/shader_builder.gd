@tool
class_name ShaderBuilder


const shader_type_string = {
	TYPE_BOOL: 'bool',
	TYPE_INT: 'int',
	TYPE_FLOAT:  'float',
	TYPE_VECTOR2: 'vec2',
	TYPE_VECTOR3: 'vec3',
	TYPE_VECTOR4: 'vec4',
	TYPE_COLOR: 'vec4',
}


static func build_shader_code_for_node(node: ProceduralTextureDesignNode) -> String:
	var mode := node.get_mode()
	if mode == ProceduralTextureDesignNode.Mode.OUTPUT:
		if node.connections.is_empty():
			return ''
		else:
			return build_shader_code_for_node(node.connections[0].from_node)

	if mode != ProceduralTextureDesignNode.Mode.SHADER:
		return ''

	var data = {}
	data.counter = 0
	data.includes = []
	data.variables = []
	data.structs = []
	data.functions = []
	data.function_names = []
	data.procedural_shader_map = {}
	data.node_map = {}

	if not _gather_shader_data_for_node(node, data):
		return ''

	var arr: Array[String] = []

	arr.append('shader_type canvas_item;')
	arr.append('render_mode unshaded;')

	if not data.includes.is_empty():
		arr.append('')
		for x in data.includes:
			arr.append('#include "{0}"'.format([x]))

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
	#print('SHADER CODE=\n', shader_code)
	return shader_code


static func _gather_shader_data_for_node(node: ProceduralTextureDesignNode, data: Dictionary) -> bool:
	if node in data.node_map:
		return true

	if not node.all_required_inputs_are_connected():
		return false

	for incoming in node.connections:
		var inc_node = node.connections[incoming].from_node
		if not _gather_shader_data_for_node(inc_node, data):
			return false

	data.counter += 1
	var postfix = '_{0}'.format([data.counter])

	match node.get_mode():
		ProceduralTextureDesignNode.Mode.SHADER:
			var shader := node.proc_shader
			var shader_name := _format_name(shader.name)

			var input_mapping = {}
			for idx in shader.inputs.size():
				var inp = shader.inputs[idx]
				var from_node = node.connections[idx].from_node
				input_mapping['sample_' + inp.name] = {
					'new_name': data.node_map[from_node],
					'format': _convert_type_from_to_format(from_node.get_output_type() + 1000, inp.type + 1000)
				}

			if shader not in data.procedural_shader_map:
				for x in shader.includes:
					if x not in data.includes:
						data.includes.append(x)

				for x in shader.structs:
					var definition = ShaderParser.reconstruct_string(x.definition)
					data.structs.append('struct {0} {{1}};'.format([x.name, definition]))

				var do_functions: Array
				var do_proc_func: Dictionary
				if input_mapping.is_empty():
					do_functions = shader.functions.duplicate()
					do_proc_func = shader.process_function.duplicate()
					do_proc_func.name = 'process_' + shader_name
					do_functions.append(do_proc_func)
				else:
					do_functions = shader.functions

				for x in do_functions:
					if x.name in data.function_names:
						continue
					var return_type = ShaderParser.reconstruct_string(x.return_type)
					var func_params = ShaderParser.reconstruct_string(x.parameters)
					var func_def = ShaderParser.reconstruct_string(x.definition)
					data.functions.append('{0} {1}({2}) {{3}}'.format([return_type, x.name, func_params, func_def]))
					data.function_names.append(x.name)

				data.procedural_shader_map[shader] = do_proc_func.get('name', '')

			var process_func_name: String
			if input_mapping.is_empty():
				process_func_name = data.procedural_shader_map[shader]
			else:
				var return_type = ShaderParser.reconstruct_string(shader.process_function.return_type)
				process_func_name = 'process_' + shader_name + postfix
				var func_params = ShaderParser.reconstruct_string(shader.process_function.parameters)
				var func_def = ShaderParser.reconstruct_string(shader.process_function.definition, input_mapping)
				data.functions.append('{0} {1}({2}) {{3}}'.format([return_type, process_func_name, func_params, func_def]))


			var node_func_name: String = 'node_{0}{1}'.format([shader_name, postfix])
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
			write_func.append('\treturn {0}({1});'.format([process_func_name, ', '.join(param_list)]))
			write_func.append('}')
			data.functions.append('\n'.join(write_func))
			data.node_map[node] = node_func_name
		ProceduralTextureDesignNode.Mode.CONSTANT:
			var item_name = _format_name(node.output_name) + postfix
			data.variables.append('const {0} {1} = {2};'.format([shader_type_string[typeof(node.output_value)], item_name, _format_immediate(node.output_value)]))
			data.node_map[node] = item_name
		ProceduralTextureDesignNode.Mode.VARIABLE:
			var item_name = _format_name(node.output_name) + postfix
			data.variables.append('uniform {0} {1} = {2};'.format([shader_type_string[typeof(node.output_value)], item_name, _format_immediate(node.output_value)]))
			data.node_map[node] = item_name
		ProceduralTextureDesignNode.Mode.INPUT:
			var item_name = _format_name(node.output_name)
			data.variables.append('uniform sampler2D {0};'.format([item_name]))
			var node_func_name: String = 'texture_{0}'.format([item_name])
			var write_func: Array[String] = []
			write_func.append('vec4 {0}(vec2 uv) {'.format([node_func_name]))
			write_func.append('\treturn texture({0}, uv);'.format([item_name]))
			write_func.append('}')
			data.functions.append('\n'.join(write_func))
			data.node_map[node] = node_func_name

	return true


static func _convert_type_from_to_format(from: int, to: int) -> String:
	from = from % 1000
	to = to % 1000

	if from == TYPE_INT and to == TYPE_FLOAT:
		return 'float({0})'
	if from == TYPE_FLOAT and to == TYPE_INT:
		return 'int({0})'
	if from == TYPE_FLOAT:
		if to == TYPE_VECTOR2:
			return 'vec2({0}, 1.0)'
		if to == TYPE_VECTOR3:
			return 'vec3({0})'
		if to == TYPE_VECTOR4:
			return 'vec4(vec3({0}), 1.0)'
	if from == TYPE_VECTOR2:
		if to == TYPE_FLOAT:
			return '{0}.x'
		if to == TYPE_VECTOR3:
			return '{0}.xxx'
		if to == TYPE_VECTOR4:
			return '{0}.xxxy'
	if from == TYPE_VECTOR3:
		if to == TYPE_FLOAT:
			return '{0}.x'
		if to == TYPE_VECTOR2:
			return 'vec2({0}.x, 1.0)'
		if to == TYPE_VECTOR4:
			return 'vec4({0}, 1.0)'
	if from == TYPE_VECTOR4:
		if to == TYPE_FLOAT:
			return '{0}.x'
		if to == TYPE_VECTOR2:
			return '{0}.xw'
		if to == TYPE_VECTOR3:
			return '{0}.xyz'

	return '{0}'


static func _convert_type_from_to(value: String, from: int, to: int) -> String:
	return _convert_type_from_to_format(from, to).format([value])


static func _format_name(value: String) -> String:
	return ProceduralTexturesHelpers.validate_name(value)


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
		return String.num(value, 0)
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
