@tool
extends Resource
class_name ProceduralTextureDesignNode

@export var title: String

@export var shader: Shader:
	set(new_shader):
		if shader != new_shader:
			if proc_shader:
				proc_shader.changed.disconnect(_shader_changed)
				proc_shader.property_list_changed.disconnect(notify_property_list_changed)
			proc_shader = ProceduralShader.new(new_shader) if new_shader else null
			if proc_shader:
				proc_shader.changed.connect(_shader_changed)
				proc_shader.property_list_changed.connect(notify_property_list_changed)
			shader = new_shader
			_shader_changed()

@export var graph_position: Vector2 = Vector2(0,0)

var proc_shader: ProceduralShader


func _shader_changed():
	notify_property_list_changed()


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary]
	if proc_shader:
		props = proc_shader._get_property_list()
	else:
		props = []
	return props

func _get(property: StringName) -> Variant:
	return proc_shader._get(property) if proc_shader else null

func _set(property: StringName, value: Variant) -> bool:
	return proc_shader._set(property, value) if proc_shader else false

func _property_can_revert(property: StringName) -> bool:
	return proc_shader._property_can_revert(property) if proc_shader else false

func _property_get_revert(property: StringName) -> Variant:
	return proc_shader._property_get_revert(property) if proc_shader else null
