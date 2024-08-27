@tool
extends Texture2D
class_name ShaderTexture

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


@export_custom(PROPERTY_HINT_LINK, "") var size : Vector2i = Vector2i(512, 512):
	set(new_size):
		if size != new_size:
			size = new_size
			size_changed = true
			_queue_update()


@export var shader : Shader:
	set(new_shader):
		if shader != new_shader:
			if shader:
				shader.disconnect("changed", _shader_changed)
			shader = new_shader
			if shader:
				shader.connect("changed", _shader_changed)
			_shader_changed()


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


func _shader_changed():
	_get_shader_uniforms()
	_queue_update()


func _shader_param_changed():
	_queue_update()


func _get_shader_uniforms():
	shader_defaults = {}
	if shader:
		var shader_rid = shader.get_rid()
		var uniforms = shader.get_shader_uniform_list(true)
		for uniform in uniforms:
			var deflt = RenderingServer.shader_get_parameter_default(shader_rid, uniform.name)
			shader_defaults[uniform.name] = deflt
	notify_property_list_changed()


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []

	if shader:
		var group = {}
		group.name = 'Shader Parameters'
		group.class_name = ''
		group.type = TYPE_STRING
		group.hint = PROPERTY_HINT_NONE
		group.hint_string = "shader/"
		group.usage = PROPERTY_USAGE_GROUP
		props.append(group)

		var uniforms = shader.get_shader_uniform_list(true)
		for uniform in uniforms:
			uniform.name = 'shader/' + uniform.name
			props.append(uniform)

	return props


func _get(property: StringName) -> Variant:
	if not property.begins_with("shader/"):
		return null
	property = property.substr(7)
	if shader_params.has(property):
		return shader_params.get(property)
	else:
		return shader_defaults.get(property)


func _set(property: StringName, value: Variant) -> bool:
	if not property.begins_with("shader/"):
		return false
	property = property.substr(7)
	if not shader_defaults.has(property):
		return false

	var old_value = shader_params.get(property)
	if old_value == value:
		return true
	if old_value is Resource:
		old_value.changed.disconnect(_shader_param_changed)

	var deflt = shader_defaults.get(property)
	if value == deflt:
		if shader_params.has(property):
			shader_params.erase(property)
	else:
		shader_params[property] = value
		if value is Resource:
			value.changed.connect(_shader_param_changed)

	_queue_update()
	return true


func _property_can_revert(property: StringName) -> bool:
	if not property.begins_with("shader/"):
		return false
	property = property.substr(7)
	return shader_defaults.has(property)


func _property_get_revert(property: StringName) -> Variant:
	if not property.begins_with("shader/"):
		return null
	property = property.substr(7)
	return shader_defaults.get(property)


func _queue_update() -> void:
	if !update_queued:
		update_queued = true
		_update_texture.call_deferred()


func _generate_image(img_size: Vector2i) -> Image:
	var img: Image

	if shader:
		tmp_material = RenderingServer.material_create()
		tmp_canvas = RenderingServer.canvas_create()
		tmp_canvas_item = RenderingServer.canvas_item_create()
		tmp_viewport = RenderingServer.viewport_create()

		RenderingServer.material_set_shader(tmp_material, shader.get_rid())
		for uniform in shader_params.keys():
			var value = shader_params[uniform]
			if value is Texture:
				RenderingServer.material_set_param(tmp_material, uniform, value.get_rid())
			else:
				RenderingServer.material_set_param(tmp_material, uniform, value)
		RenderingServer.canvas_item_set_parent(tmp_canvas_item, tmp_canvas)
		RenderingServer.canvas_item_set_material(tmp_canvas_item, tmp_material)
		RenderingServer.canvas_item_add_texture_rect(tmp_canvas_item, Rect2(0, 0, img_size.x, img_size.y), rid)
		RenderingServer.viewport_set_size(tmp_viewport, img_size.x, img_size.y)
		RenderingServer.viewport_attach_canvas(tmp_viewport, tmp_canvas)
		RenderingServer.viewport_set_update_mode(tmp_viewport, RenderingServer.VIEWPORT_UPDATE_ONCE)
		RenderingServer.viewport_set_active(tmp_viewport, true)
		await RenderingServer.frame_post_draw

		# The builtin Godot preview generator aborts here!
		# So the free_rids will be delayed...

		var tex = RenderingServer.viewport_get_texture(tmp_viewport)
		img = RenderingServer.texture_2d_get(tex)

		for x in [tmp_viewport, tmp_canvas, tmp_canvas_item, tmp_material]:
			if x.is_valid():
				RenderingServer.free_rid(x)
		tmp_viewport = RID()
		tmp_canvas = RID()
		tmp_canvas_item = RID()
		tmp_material = RID()

	return img


func _update_texture() -> void:
	if not update_queued:
		return

	var local_size_changed = size_changed
	update_queued = false
	size_changed = false

	var img: Image = await _generate_image(size)

	if !img or img.is_empty():
		img = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGB8)
		img.fill(pink)

	if local_size_changed:
		var new_tex = RenderingServer.texture_2d_create(img)
		RenderingServer.texture_replace(rid, new_tex)
		RenderingServer.free_rid(new_tex)
	else:
		RenderingServer.texture_2d_update(rid, img, 0)

	emit_changed()
