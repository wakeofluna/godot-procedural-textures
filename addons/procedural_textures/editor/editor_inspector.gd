@tool
extends EditorInspectorPlugin
class_name ProceduralTexturesInspectorPlugin


func _can_handle(object: Object) -> bool:
	return object is ShaderTexture


func _parse_begin(object: Object) -> void:
	var tex: ShaderTexture = object
	if tex:
		var rect: TextureRect = TextureRect.new()
		rect.custom_minimum_size = Vector2(128, 128) * EditorInterface.get_editor_scale()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.texture = tex
		add_custom_control(rect)
