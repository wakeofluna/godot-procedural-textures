class_name ProceduralTexturesHelpers


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

static func is_valid_string_character(ord: int, allow_all: bool) -> bool:
	if (ord >= ORD_A and ord <= ORD_Z) or (ord >= ORD_a and ord <= ORD_z) or ord == ORD_UNDERSCORE:
		return true
	if allow_all and ord >= ORD_0 and ord <= ORD_9:
		return true
	return false

static func is_valid_number_character(ord: int, allow_all: bool) -> bool:
	if ord >= ORD_0 and ord <= ORD_9:
		return true
	if allow_all and (ord == ORD_DOT or ord == ORD_f):
		return true
	return false

static func validate_name(value: String) -> String:
	var arr := value.to_ascii_buffer()
	for idx in arr.size():
		if not is_valid_string_character(arr[idx], idx > 0):
			arr[idx] = ORD_UNDERSCORE
	return arr.get_string_from_ascii()
