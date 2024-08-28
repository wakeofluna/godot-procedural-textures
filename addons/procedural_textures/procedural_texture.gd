@tool
extends Texture2D
class_name ProceduralTexture

const pink = Color(1.0, 0.0, 1.0)
const black = Color(0.0, 0.0, 0.0)

var rid : RID
var update_queued : bool = false
var size_changed : bool = true

var tmp_viewport : RID
var tmp_canvas : RID
var tmp_canvas_item : RID
var tmp_material : RID

var shader_params: Dictionary
var shader_defaults: Dictionary


@export var design : ProceduralTextureDesign:
	set(new_design):
		if design != new_design:
			if design:
				design.disconnect("changed", _design_changed)
			design = new_design
			if design:
				design.connect("changed", _design_changed)
			_design_changed()

@export_custom(PROPERTY_HINT_LINK, "") var size : Vector2i = Vector2i(512, 512):
	set(new_size):
		if size != new_size:
			size = new_size
			size_changed = true
			_queue_update()


func _init() -> void:
	rid = RenderingServer.texture_2d_placeholder_create()


func _notification(what : int) -> void:
	if what == NOTIFICATION_PREDELETE:
		update_queued = false
		for x in [tmp_viewport, tmp_canvas, tmp_canvas_item, tmp_material, rid]:
			if x.is_valid():
				RenderingServer.free_rid(x)


func _get_width() -> int:
	return size.x

func _get_height() -> int:
	return size.y

func _get_rid() -> RID:
	return rid


func _design_changed():
	_get_design_uniforms()
	_queue_update()


func _shader_param_changed():
	_queue_update()


func _get_design_uniforms():
	pass


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	return props


func _get(property: StringName) -> Variant:
	return null


func _set(property: StringName, value: Variant) -> bool:
	return false


func _property_can_revert(property: StringName) -> bool:
	return false


func _property_get_revert(property: StringName) -> Variant:
	return null


func _queue_update() -> void:
	if !update_queued:
		update_queued = true
		_update_texture.call_deferred()


func _generate_image(img_size: Vector2i) -> Image:
	var img: Image

	if design:
		pass

	return img


func _update_texture() -> void:
	if not update_queued:
		return

	var local_size_changed = size_changed
	update_queued = false
	size_changed = false

	var img: Image = await _generate_image(size)

	if not img or img.is_empty():
		img = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGB8)
		img.fill(pink)

	if local_size_changed:
		var new_tex = RenderingServer.texture_2d_create(img)
		RenderingServer.texture_replace(rid, new_tex)
		RenderingServer.free_rid(new_tex)
	else:
		RenderingServer.texture_2d_update(rid, img, 0)

	emit_changed()
