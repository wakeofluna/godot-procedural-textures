@tool
extends EditorResourcePreviewGenerator
class_name ProceduralTexturesPreviewGenerator


func _handles(type: String) -> bool:
	return type == "ShaderTexture"


func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	var tex: ShaderTexture = resource
	if tex:
		metadata.dimensions = tex.size
		var img = await tex._generate_image(size)
		if img:
			return ImageTexture.create_from_image(img)
	return null


func _generate_small_preview_automatically() -> bool:
	return false


func _can_generate_small_preview() -> bool:
	return true
