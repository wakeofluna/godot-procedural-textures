@tool
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
const ORD_NEWLINE = ProceduralTexturesHelpers.ORD_NEWLINE
const ORD_QUOTE = ProceduralTexturesHelpers.ORD_QUOTE

static func _is_valid_string_character(ord: int, allow_all: bool) -> bool:
	return ProceduralTexturesHelpers.is_valid_string_character(ord, allow_all)

static func _is_valid_number_character(ord: int, allow_all: bool) -> bool:
	return ProceduralTexturesHelpers.is_valid_number_character(ord, allow_all)

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
	var seen_whitespace = false

	while cursor < cursor_end:
		var char = code.unicode_at(cursor)
		if char == ORD_NEWLINE:
			callback.call(TOKEN_NEWLINE, "", false)
			seen_whitespace = false
			cursor += 1
		elif char <= 32:
			seen_whitespace = true
			cursor += 1
		elif _is_valid_number_character(char, false):
			var len: int = 1
			while cursor + len < cursor_end:
				char = code.unicode_at(cursor + len)
				if not _is_valid_number_character(char, true):
					break
				len += 1
			var token = code.substr(cursor, len)
			callback.call(TOKEN_NUMBER, token, seen_whitespace)
			seen_whitespace = false
			cursor += len
		elif _is_valid_string_character(char, false):
			var len: int = 1
			while cursor + len < cursor_end:
				char = code.unicode_at(cursor + len)
				if not _is_valid_string_character(char, true):
					break
				len += 1
			var token = code.substr(cursor, len)
			callback.call(TOKEN_STRING, token, seen_whitespace)
			seen_whitespace = false
			cursor += len
		elif _is_brace_open(char):
			callback.call(TOKEN_BRACE_OPEN, code[cursor], seen_whitespace)
			seen_whitespace = false
			cursor += 1
		elif _is_brace_close(char):
			var open_brace = String.chr(_is_brace_close(char))
			callback.call(TOKEN_BRACE_CLOSE, open_brace, seen_whitespace)
			seen_whitespace = false
			cursor += 1
		else:
			callback.call(TOKEN_OPERATOR, code[cursor], seen_whitespace)
			seen_whitespace = false
			cursor += 1

	callback.call(TOKEN_EOF, "", false)


static func tokenize_shader_code(code: String) -> Array:
	var scopes: Array = []
	scopes.append({ "type" = TOKEN_TOPLEVEL, "token" = "", "seen_whitespace" = false, "contents" = []})

	var cb = func(type: StringName, token: String, seen_whitespace: bool):
		var value = {"type" = type, "token" = token, "seen_whitespace" = seen_whitespace}

		if type == TOKEN_BRACE_OPEN:
			value.contents = []
			scopes.back().contents.append(value)
			scopes.append(value)

		elif type == TOKEN_BRACE_CLOSE:
			if scopes.back().token == token:
				scopes.pop_back()
			else:
				value.type = TOKEN_OPERATOR
				scopes.back().contents.append(value)

		elif type == TOKEN_EOF:
			pass

		elif type == TOKEN_OPERATOR:
			var added: bool = false
			if not seen_whitespace and not scopes.back().contents.is_empty():
				var last_token = scopes.back().contents.back()
				if last_token.type == TOKEN_OPERATOR:
					var combined_token = last_token.token + token
					if combined_token in ['//', '/*', '*/', '==', '!=', '<=', '>=', '<<', '>>', '&&', '||', '-=', '+=', '/=', '*=']:
						last_token.token = combined_token
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
	var element_idx: int = 0
	var element_idx_end = toplevel.size()
	var stack: Array = []

	var find_next_token = func(start_element: int, type: StringName, token: String) -> int:
		var next_element: int = start_element + 1
		while next_element < element_idx_end:
			var element = toplevel[next_element]
			if (element.type == type and element.token == token) or element.type == TOKEN_EOF:
				return next_element
			next_element += 1
		return start_element

	var had_newline: bool = true
	while element_idx < element_idx_end:
		var first_token_on_line: bool = had_newline
		had_newline = false

		var element: Dictionary = toplevel[element_idx]
		if element.type == TOKEN_OPERATOR:
			if element.token == '//' or element.token == '/*':
				var end: int
				if element.token == '//':
					end = find_next_token.call(element_idx, TOKEN_NEWLINE, "")
					had_newline = true
				else:
					end = find_next_token.call(element_idx, TOKEN_OPERATOR, "*/")

				if end > element_idx + 1:
					var comment: String = reconstruct_string(toplevel.slice(element_idx + 1, end)).strip_edges()
					#print("COMMENT: {0}".format([comment]))
					if comment.begins_with("NAME:"):
						result.name = comment.substr(5).strip_edges()

				element_idx = end + 1
				continue

			elif element.token == '#' and first_token_on_line:
				var end: int = find_next_token.call(element_idx, TOKEN_NEWLINE, "")

				if end > element_idx + 2:
					var next_token = toplevel[element_idx + 1]
					if next_token.type == TOKEN_STRING and next_token.token == "include":
						var inc: String = reconstruct_string(toplevel.slice(element_idx + 2, end)).strip_edges()
						if inc.length() >= 2:
							if inc[0] == '"' and inc[-1] == '"':
								inc = inc.substr(1, inc.length() - 2)
							result.includes.append(inc)

				#if end > element_idx + 1:
				#	var value: String = reconstruct_string(toplevel.slice(element_idx + 1, end)).strip_edges()
				#	print("PREPROCESSOR: {0}".format([value]))

				element_idx = end + 1
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
					var struct_def = element.contents
					result.structs.append({ name = struct_name, definition = struct_def })
				elif stack.size() >= 3 and stack[-1].type == TOKEN_BRACE_OPEN and stack[-1].token == '(':
					var ret_type = stack.slice(0, -2)
					var func_name = stack[-2].token
					var func_param = stack[-1].contents
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

		element_idx += 1

	return result


static func _reconstruct_scope(scope: Array, call_replacements: Dictionary, indent: int, result: String) -> String:
	var last_type = TOKEN_TOPLEVEL

	var max_idx : int = scope.size() - 1
	var idx : int = -1

	while idx < max_idx:
		idx += 1

		var x: Dictionary = scope[idx]
		if x.type == TOKEN_EOF:
			break
		elif x.type == TOKEN_NEWLINE:
			result += '\n'
			last_type = x.type
			continue

		if not result.is_empty() and result[-1] == '\n':
			result += '\t\t\t\t\t\t\t\t'.substr(0, indent)

		if x.type == TOKEN_BRACE_OPEN:
			if x.seen_whitespace and last_type != TOKEN_NEWLINE:
				result += ' '
			result += x.token

			result = _reconstruct_scope(x.contents, call_replacements, indent + 1, result)

			if result[-1] == '\n':
				result += '\t\t\t\t\t\t\t\t'.substr(0, indent)
			if x.token == '{':
				result += '}'
			elif x.token == '(':
				result += ')'
			elif x.token == '[':
				result += ']'
		elif x.type == TOKEN_STRING and idx+1 < max_idx and scope[idx+1].type == TOKEN_BRACE_OPEN and scope[idx+1].token == '(':
			if x.seen_whitespace and last_type != TOKEN_NEWLINE:
				result += ' '
			var replacement: Dictionary = call_replacements.get(x.token, {})
			if replacement.is_empty():
				result += x.token
			else:
				var call_parameters: String = _reconstruct_scope(scope[idx+1].contents, call_replacements, indent + 1, '')
				var new_call = '{0}({1})'.format([replacement.new_name, call_parameters])
				result += replacement.format.format([new_call])
				idx += 1
		else:
			if x.seen_whitespace and last_type != TOKEN_NEWLINE:
				result += ' '
			result += x.token

		last_type = x.type

	return result


static func reconstruct_string(scope: Array, call_replacements: Dictionary = {}) -> String:
	return _reconstruct_scope(scope, call_replacements, 1, '')


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
