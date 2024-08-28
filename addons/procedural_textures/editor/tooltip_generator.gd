@tool
extends EditorResourceTooltipPlugin
class_name ProceduralTexturesTooltipPlugin


func _handles(type: String) -> bool:
	return type == "Texture2D" or type == "ShaderTexture"


func _make_tooltip_for_path(path: String, metadata: Dictionary, base: Control) -> Control:
	# Overruling the builtin tooltip generator because we
	# cannot override "get_image" in our ShaderTexture
	var tex = load(path)
	if tex is ShaderTexture:
		base = set_dimensions_label(base, tex)
		base = set_texture_preview(base, tex)

	return base


# Add or modify the Dimensions label
func set_dimensions_label(base: Control, tex: ShaderTexture) -> Control:
	var dimensions_label: Label
	var type_label: Label

	var all_labels = base.find_children("*", "Label", true, false)
	for label: Label in all_labels:
		if label.text.begins_with("Dimensions:"):
			dimensions_label = label
		if label.text.begins_with("Type:"):
			type_label = label

	if not dimensions_label and type_label:
		dimensions_label = Label.new()
		type_label.get_parent_control().add_child(dimensions_label)

	if dimensions_label:
		dimensions_label.text = "Dimensions: {0} × {1}".format([tex.size.x, tex.size.y])

	return base


# Add or modify the preview TextureRect
func set_texture_preview(base: Control, tex: ShaderTexture) -> Control:
	var textrect: TextureRect

	var all_textrect = base.find_children("*", "TextureRect", true, false)
	if all_textrect.size() > 0:
		textrect = all_textrect[0]
	else:
		textrect = TextureRect.new()
		var hbox = HBoxContainer.new()
		hbox.add_child(textrect)
		hbox.add_child(base)
		base = hbox

	textrect.texture = tex
	textrect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textrect.stretch_mode = TextureRect.STRETCH_SCALE
	textrect.custom_minimum_size = Vector2i(128, 128) * EditorInterface.get_editor_scale()

	return base
