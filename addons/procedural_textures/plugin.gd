@tool
extends EditorPlugin


const FILE_NEW = 1
const FILE_CLOSE = 2


var proc_text_editor_inspector: EditorInspectorPlugin
var proc_text_preview_gen: EditorResourcePreviewGenerator
var proc_text_tooltip_gen: EditorResourceTooltipPlugin
var designer_button: Button
var designer_manager: Control
var designs_list: ItemList
var designs_tabs: TabContainer
var active_editors: Array[ProceduralTexturesDesigner] = []
var designs_to_be_saved: Array[ProceduralTextureDesign] = []


func _get_plugin_name() -> String:
	return "ProceduralTexturesAddon"


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
	return object is ProceduralTextureDesign


func _make_visible(visible: bool) -> void:
	if visible and designer_button:
		designer_button.visible = true
		make_bottom_panel_item_visible(designer_manager)


func _edit(object: Object) -> void:
	if not designer_manager:
		return

	var design: ProceduralTextureDesign = object
	if design:
		for idx in active_editors.size():
			if active_editors[idx].design == design:
				designs_list.select(idx)
				_switch_to_selected_design()
				return
		var new_editor = preload("editor/design_editor.gd").new()
		new_editor.design = design
		new_editor.title_changed.connect(_editor_title_changed.bind(new_editor))
		active_editors.append(new_editor)
		designs_tabs.add_child(new_editor)
		designs_list.add_item(new_editor.get_title())
		designs_list.select(active_editors.size() - 1)
		_switch_to_selected_design()


func _apply_changes() -> void:
	print("APPLY CHANGES REQUEST")
	if EditorInterface.get_edited_scene_root():
		print('   SCENE ROOT={0}'.format([EditorInterface.get_edited_scene_root().scene_file_path]))


func _build() -> bool:
	print("BUILD REQUEST")
	return true


func _clear() -> void:
	print('CLEAR REQUEST')
	for idx in range(active_editors.size() - 1, -1, -1):
		if active_editors[idx].design.resource_path.contains('::'):
			_unlist_designer(idx)


func _get_state() -> Dictionary:
	print('GET STATE REQUEST')
	print('   SCENE ROOT={0}'.format([EditorInterface.get_edited_scene_root().scene_file_path]))
	return {}


func _get_unsaved_status(for_scene: String) -> String:
	print('GET UNSAVED STATUS REQUEST FOR {0}'.format([for_scene]))
	if EditorInterface.get_edited_scene_root():
		print('   SCENE ROOT={0}'.format([EditorInterface.get_edited_scene_root().scene_file_path]))
	designs_to_be_saved = []
	for editor in active_editors:
		if not editor.design.dirty:
			continue
		var res_path: String = editor.design.resource_path
		var res_slice = res_path.get_slice("::", 0)
		if for_scene == res_slice or for_scene.is_empty():
			designs_to_be_saved.append(editor.design)

	var num_dirty = designs_to_be_saved.size()
	if num_dirty == 0:
		return ""
	else:
		return "ProceduralTexture: save {0} modified resources?".format([num_dirty])


func _get_window_layout(configuration: ConfigFile) -> void:
	print('GET WINDOW LAYOUT REQUEST')


func _save_external_data() -> void:
	print('SAVE EXTERNAL DATA REQUEST')


func _set_state(state: Dictionary) -> void:
	print('SET STATE REQUEST')
	print('   SCENE ROOT={0}'.format([EditorInterface.get_edited_scene_root().scene_file_path]))


func _set_window_layout(configuration: ConfigFile) -> void:
	print('SET WINDOW LAYOUT REQUEST')



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

	designs_list = ItemList.new()
	designs_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	designs_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	designs_list.item_clicked.connect(_designs_list_clicked)
	designs_list.item_selected.connect(_designs_list_selected)
	vbox_left.add_child(designs_list)

	designs_tabs = TabContainer.new()
	designs_tabs.tabs_visible = false
	designs_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	designs_tabs.deselect_enabled = true
	main_split.add_child(designs_tabs)

	var empty_style = StyleBoxEmpty.new()
	designs_tabs.add_theme_stylebox_override("panel", empty_style)

	return main_split


func _designs_list_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 3:
		_unlist_designer(index)
		if active_editors.is_empty():
			hide_bottom_panel()
			designer_button.visible = false


func _unlist_designer(index: int) -> void:
	if designs_list.is_selected(index):
		designs_list.deselect_all()
		_switch_to_selected_design()
	designs_list.remove_item(index)
	designs_tabs.remove_child(designs_tabs.get_child(index))
	active_editors[index].queue_free()
	active_editors.remove_at(index)



func _designs_list_selected(index: int) -> void:
	EditorInterface.edit_resource(active_editors[index].design)


func _switch_to_selected_design() -> void:
	var selected_items = designs_list.get_selected_items()
	if selected_items.is_empty():
		designs_tabs.current_tab = -1
		return

	var selected = selected_items[0]
	designs_tabs.current_tab = selected


func _editor_title_changed(editor) -> void:
	for idx in active_editors.size():
		if editor == active_editors[idx]:
			var title = editor.get_title()
			designs_list.set_item_text(idx, title)
			return
