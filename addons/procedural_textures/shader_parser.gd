class_name ShaderParser


# Raw tokens
const TOKEN_EOF: StringName = "EOF"
const TOKEN_STRING: StringName = "STRING"
const TOKEN_NUMBER: StringName = "NUMBER"
const TOKEN_OPERATOR: StringName = "OPERATOR"
const TOKEN_NEWLINE: StringName = "NEWLINE"
const TOKEN_BRACE_OPEN: StringName = "BRACE_OPEN"
const TOKEN_BRACE_CLOSE: StringName = "BRACE_CLOSE"
const TOKEN_TOPLEVEL: StringName = "TOPLEVEL"

# Ascii codes
const ORD_NEWLINE = 10
const ORD_QUOTE = 34
const ORD_DOT = 46
const ORD_0 = 48
const ORD_9 = 57
const ORD_A = 65
const ORD_Z = 90
const ORD_UNDERSCORE = 95
const ORD_a = 97
const ORD_f = 102
const ORD_z = 122

static func _is_valid_string_character(ord: int, allow_all: bool) -> bool:
	if (ord >= ORD_A and ord <= ORD_Z) or (ord >= ORD_a and ord <= ORD_z) or ord == ORD_UNDERSCORE:
		return true
	if allow_all and ord >= ORD_0 and ord <= ORD_9:
		return true
	return false

static func _is_valid_number_character(ord: int, allow_all: bool) -> bool:
	if ord >= ORD_0 and ord <= ORD_9:
		return true
	if allow_all and (ord == ORD_DOT or ord == ORD_f):
		return true
	return false

static func _is_brace_open(ord: int) -> bool:
	if ord == 40: return 41
	if ord == 91: return 93
	if ord == 123: return 125
	return 0

static func _is_brace_close(ord: int) -> int:
	if ord == 41: return 40
	if ord == 93: return 91
	if ord == 125: return 123
	return 0

static func _tokenize_shader_code(code: String, callback: Callable) -> void:
	assert(callback)

	var cursor: int = 0
	var cursor_end = code.length()

	while cursor < cursor_end:
		var char = code.unicode_at(cursor)
		if char == ORD_NEWLINE:
			callback.call(TOKEN_NEWLINE, cursor, cursor+1, "")
			cursor += 1
		elif char <= 32:
			cursor += 1
			pass
		elif _is_valid_number_character(char, false):
			var len: int = 1
			while cursor + len < cursor_end:
				char = code.unicode_at(cursor + len)
				if not _is_valid_number_character(char, true):
					break
				len += 1
			var token = code.substr(cursor, len)
			callback.call(TOKEN_NUMBER, cursor, cursor + len, token)
			cursor += len
		elif _is_valid_string_character(char, false):
			var len: int = 1
			while cursor + len < cursor_end:
				char = code.unicode_at(cursor + len)
				if not _is_valid_string_character(char, true):
					break
				len += 1
			var token = code.substr(cursor, len)
			callback.call(TOKEN_STRING, cursor, cursor + len, token)
			cursor += len
		elif _is_brace_open(char):
			callback.call(TOKEN_BRACE_OPEN, cursor, cursor+1, code[cursor])
			cursor += 1
		elif _is_brace_close(char):
			var open_brace = String.chr(_is_brace_close(char))
			callback.call(TOKEN_BRACE_CLOSE, cursor, cursor+1, open_brace)
			cursor += 1
		else:
			callback.call(TOKEN_OPERATOR, cursor, cursor+1, code[cursor])
			cursor += 1

	callback.call(TOKEN_EOF, cursor, cursor, "")


static func tokenize_shader_code(code: String) -> Array:
	var scopes: Array = []
	scopes.append({ type = TOKEN_TOPLEVEL, start = 0, end = 0, token = "", contents = []})

	var cb = func(type: StringName, start: int, end: int, token: String):
		var value = {type = type, start = start, end = end, token = token}

		if type == TOKEN_BRACE_OPEN:
			value.contents = []
			scopes.back().contents.append(value)
			scopes.append(value)

		elif type == TOKEN_BRACE_CLOSE:
			if scopes.back().token == token:
				scopes.back().end = end
				scopes.pop_back()
			else:
				value.type = TOKEN_OPERATOR
				scopes.back().contents.append(value)

		elif type == TOKEN_EOF:
			for scope in scopes:
				scope.end = end
				scope.contents.append(value)

		elif type == TOKEN_OPERATOR:
			var added: bool = false
			if !scopes.back().contents.is_empty():
				var last_token = scopes.back().contents.back()
				if last_token.type == TOKEN_OPERATOR and last_token.end == start:
					var combined_token = last_token.token + token
					if combined_token in ['//', '/*', '*/', '==', '!=', '<=', '>=', '<<', '>>', '&&', '||', '-=', '+=', '/=', '*=']:
						last_token.token = combined_token
						last_token.end = end
						added = true
			if not added:
				scopes.back().contents.append(value)

		else:
			scopes.back().contents.append(value)

	_tokenize_shader_code(code, cb)
	return scopes[0].contents


static func parse_shader(shader: Shader) -> Dictionary:
	var result: Dictionary = {}
	result.name = ""
	result.includes = []
	result.structs = []
	result.functions = []

	if not shader:
		return result

	var code: String = shader.code
	var toplevel: Array = tokenize_shader_code(code)
	var cursor: int = 0
	var cursor_end = toplevel.size()
	var stack: Array = []

	var find_next_token = func(start: int, type: StringName, token: String) -> int:
		var next_cursor: int = start + 1
		while next_cursor < cursor_end:
			var element = toplevel[next_cursor]
			if element.type == type and element.token == token:
				return next_cursor
			next_cursor += 1
		return start

	var merge_string = func(from: int, to: int) -> String:
		if to - from > 1:
			var start = toplevel[from+1].start
			var end = toplevel[to-1].end
			return code.substr(start, end - start)
		return ""

	var had_newline: bool = true

	while cursor < cursor_end:
		var first_token_on_line: bool = had_newline
		had_newline = false

		var element: Dictionary = toplevel[cursor]
		if element.type == TOKEN_OPERATOR:
			if element.token == '//' or element.token == '/*':
				var end: int
				if element.token == '//':
					end = find_next_token.call(cursor, TOKEN_NEWLINE, "")
					had_newline = true
				else:
					end = find_next_token.call(cursor, TOKEN_OPERATOR, "*/")

				var comment: String = merge_string.call(cursor, end)
				#print("COMMENT: {0}".format([comment]))

				if comment.begins_with("NAME:"):
					result.name = comment.substr(5).strip_edges()

				cursor = end + 1
				continue

			elif element.token == '#' and first_token_on_line:
				var end: int = find_next_token.call(cursor, TOKEN_NEWLINE, "")

				var next_token = toplevel[cursor+1]
				if next_token.type == TOKEN_STRING and next_token.token == "include":
					var inc: String = merge_string.call(cursor + 1, end)
					if inc.length() >= 2:
						if inc[0] == '"' and inc[-1] == '"':
							inc = inc.substr(1, inc.length() - 2)
						result.includes.append(inc)

				#var value: String = merge_string.call(cursor - 1, end)
				#print("PREPROCESSOR: {0}".format([value]))

				cursor = end + 1
				had_newline = true
				continue

			elif element.token == ';':
				stack = []

			else:
				#print('{type}: {token}'.format(element))
				stack.append(element)

		elif element.type == TOKEN_BRACE_OPEN:
			#var string: String = code.substr(element.start, element.end - element.start).strip_edges()
			#print("SCOPE: {0}".format([string]))

			if element.token == '{':
				if stack.size() >= 2 and stack[-2].type == TOKEN_STRING and stack[-2].token == 'struct':
					var struct_name = stack[-1].token
					var struct_def = code.substr(element.start, element.end - element.start).strip_edges()
					result.structs.append({ name = struct_name, definition = struct_def })
				elif stack.size() >= 3 and stack[-1].type == TOKEN_BRACE_OPEN and stack[-1].token == '(':
					var ret_type: String = code.substr(stack[0].start, stack[-3].end - stack[0].start).strip_edges()
					var func_name = stack[-2].token
					var func_param: String = code.substr(stack[-1].start, stack[-1].end - stack[-1].start)
					var func_def = element.contents
					result.functions.append({ return_type = ret_type, name = func_name, parameters = func_param, definition = func_def })
				stack = []
			else:
				stack.append(element)

		elif element.type == TOKEN_NEWLINE:
			had_newline = true

		elif element.type == TOKEN_STRING:
			#print('{type}: {token}'.format(element))
			stack.append(element)

		elif element.type == TOKEN_NUMBER:
			#print('{type}: {token}'.format(element))
			stack.append(element)

		elif element.type == TOKEN_EOF:
			break

		else:
			assert(false, "Addon internal error: Unhandled TOKEN_TYPE {0} in ShaderParser parser".format([element.type]))

		cursor += 1

	return result


static func _reconstruct_scope(scope: Array, indent: int, result: String) -> String:
	var last_type = TOKEN_TOPLEVEL

	for x in scope:
		if x.type == TOKEN_EOF:
			break
		elif x.type == TOKEN_NEWLINE:
			result += '\n'
			continue

		if !result.is_empty() and result[-1] == '\n':
			result += '\t\t\t\t\t\t\t\t'.substr(0, indent)

		if x.type == TOKEN_BRACE_OPEN:
			if x.token == '{':
				result += ' '
			result += x.token

			result = _reconstruct_scope(x.contents, indent + 1, result)

			if result[-1] == '\n':
				result += '\t\t\t\t\t\t\t\t'.substr(0, indent)
			if x.token == '{':
				result += '}'
			elif x.token == '(':
				result += ')'
			elif x.token == '[':
				result += ']'
		elif x.type == TOKEN_STRING or x.type == TOKEN_NUMBER:
			if last_type == TOKEN_STRING or last_type == TOKEN_NUMBER:
				result += ' '
			result += x.token
		elif x.type == TOKEN_OPERATOR:
			if x.token not in '.,;':
				result += ' '
			result += x.token
			if x.token not in '.;':
				result += ' '
		else:
			assert(false, "Addon internal error: Unhandled TOKEN_TYPE {0} in ShaderParser reconstructor".format([x.type]))

		last_type = x.type

	return result


static func get_parameter_list(shader: Shader, group_name: String = "", group_prefix: String = "shader/") -> Array[Dictionary]:
	var props: Array[Dictionary] = []

	var uniforms: Array = shader.get_shader_uniform_list(false)
	if !uniforms.is_empty():
		if !group_name.is_empty() and !group_prefix.is_empty():
			var group = {}
			group.name = group_name
			group.class_name = ''
			group.type = TYPE_STRING
			group.hint = PROPERTY_HINT_NONE
			group.hint_string = group_prefix
			group.usage = PROPERTY_USAGE_GROUP
			props.append(group)
		else:
			group_prefix = ''

		for uniform in uniforms:
			uniform.parameter_name = uniform.name
			uniform.default = RenderingServer.shader_get_parameter_default(shader.get_rid(), uniform.name)
			uniform.name = group_prefix + uniform.name
			props.append(uniform)

	return props
