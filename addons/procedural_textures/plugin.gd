@tool
extends EditorPlugin


const FILE_NEW = 1
const FILE_CLOSE = 2


var proc_text_editor_inspector: EditorInspectorPlugin
var proc_text_preview_gen: EditorResourcePreviewGenerator
var proc_text_tooltip_gen: EditorResourceTooltipPlugin
var designer_button: Button
var designer_manager: Control


func _enter_tree() -> void:
	proc_text_editor_inspector = preload("editor/editor_inspector.gd").new()
	add_inspector_plugin(proc_text_editor_inspector)

	var previewer = EditorInterface.get_resource_previewer()
	if previewer:
		proc_text_preview_gen = preload("editor/preview_generator.gd").new()
		previewer.add_preview_generator(proc_text_preview_gen)

	var filedock = EditorInterface.get_file_system_dock()
	if filedock:
		proc_text_tooltip_gen = preload("editor/tooltip_generator.gd").new()
		filedock.add_resource_tooltip_plugin(proc_text_tooltip_gen)

	designer_manager = _build_designer_manager()
	designer_button = add_control_to_bottom_panel(designer_manager, "Procedural Texture Editor")
	designer_button.visible = false


func _exit_tree() -> void:
	if proc_text_editor_inspector:
		remove_inspector_plugin(proc_text_editor_inspector)
		proc_text_editor_inspector = null

	if proc_text_preview_gen:
		var previewer = EditorInterface.get_resource_previewer()
		if previewer:
			previewer.remove_preview_generator(proc_text_preview_gen)
		proc_text_preview_gen = null

	if proc_text_tooltip_gen:
		var filedock = EditorInterface.get_file_system_dock()
		if filedock:
			filedock.remove_resource_tooltip_plugin(proc_text_tooltip_gen)
		proc_text_tooltip_gen = null

	if designer_manager:
		remove_control_from_bottom_panel(designer_manager)
		designer_manager.queue_free()
		designer_manager = null


func _handles(object: Object) -> bool:
	return object is ProceduralTexture


func _make_visible(visible: bool) -> void:
	if designer_button:
		designer_button.visible = visible
	if visible and designer_manager:
		make_bottom_panel_item_visible(designer_manager)


func _build_designer_manager() -> Control:
	var main_split = HSplitContainer.new()

	var vbox_left = VBoxContainer.new()
	vbox_left.custom_minimum_size = Vector2(200, 300) * EditorInterface.get_editor_scale()
	main_split.add_child(vbox_left)

	var menu_bar = HBoxContainer.new()
	vbox_left.add_child(menu_bar)

	var menu = MenuButton.new()
	menu.text = "File"
	menu.get_popup().add_item("New Texture ...", FILE_NEW)
	menu.get_popup().add_item("Close File", FILE_CLOSE)
	menu_bar.add_child(menu)

	var item_list = ItemList.new()
	item_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_left.add_child(item_list)

	var tabs = TabContainer.new()
	tabs.tabs_visible = false
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.add_child(tabs)

	var empty_style = StyleBoxEmpty.new()
	tabs.add_theme_stylebox_override("panel", empty_style)

	return main_split
