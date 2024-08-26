@tool
extends EditorResourceTooltipPlugin


func _handles(type: String) -> bool:
	return type == "Texture2D"


func _make_tooltip_for_path(path: String, metadata: Dictionary, base: Control) -> Control:
	# Overruling the builtin tooltip generator because we
	# cannot override "get_image" in our ProceduralTexture
	var tex = load(path)
	if tex is ProceduralTexture:
		var hbox: HBoxContainer = base
		var hbox_children = hbox.get_children()
		var textrect: TextureRect = hbox_children[0]
		var vbox: VBoxContainer = hbox_children[1]
		var vbox_children = vbox.get_children()
		vbox.remove_child(vbox_children.back())
		var lbl: Label = Label.new()
		lbl.text = "Dimensions: {0} × {1}".format([tex.size.x, tex.size.y])
		vbox.add_child(lbl)
		textrect.texture = tex
		textrect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textrect.stretch_mode = TextureRect.STRETCH_SCALE
		textrect.custom_minimum_size = Vector2i(128, 128) * EditorInterface.get_editor_scale()

	return base
