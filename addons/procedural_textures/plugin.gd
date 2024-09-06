@tool
extends EditorPlugin


var proc_text_editor_inspector: EditorInspectorPlugin
var proc_text_preview_gen: EditorResourcePreviewGenerator
var proc_text_tooltip_gen: EditorResourceTooltipPlugin

var designer_button: Button
var designer_manager: Control
var designs_list: ItemList
var designs_tabs: TabContainer


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


func _edit(object: Object) -> void:
	if not designer_manager:
		return

	var design: ProceduralTextureDesign = object
	if design:
		for idx in designs_tabs.get_tab_count():
			if designs_tabs.get_child(idx).design == design:
				designs_list.select(idx)
				switch_to_selected_design()
				return
		var new_editor = _build_new_editor(design)
		designs_list.select(designs_list.item_count - 1)
		switch_to_selected_design()


func _get_window_layout(configuration: ConfigFile) -> void:
	configuration.set_value('main', 'visible', designer_manager.is_visible_in_tree())

	# Rebuild all settings for all open scenes
	var active_designs: Dictionary = {}
	for editor: ProceduralTextureDesignEditor in designs_tabs.get_children():
		var section: String
		var key: String

		if editor.is_sub_resource:
			section = editor.resource_owner
			key = editor.resource_sub_path
		else:
			section = 'root'
			key = editor.resource_path

		if not active_designs.has(section):
			active_designs[section] = PackedStringArray()
		active_designs[section].append(key)

	if not active_designs.has('root') and configuration.has_section_key('editors', 'root'):
		configuration.erase_section_key('editors', 'root')
	for section in active_designs:
		configuration.set_value('editors', section, active_designs[section])

	# Restore edited resources here since _set_state does not behave
	var scenes = EditorInterface.get_open_scenes()

	# Close editors from scenes that are closed
	for idx in range(designs_tabs.get_tab_count() - 1, -1, -1):
		var editor: ProceduralTextureDesignEditor = designs_tabs.get_child(idx)
		if editor.is_sub_resource and scenes.find(editor.resource_owner) == -1:
			unlist_editor_idx(idx)

	# Open editors for scenes that are open
	for scene in scenes:
		if configuration.has_section_key('editors', scene):
			var sub_paths = configuration.get_value('editors', scene)
			for sub_path in sub_paths:
				var full_path = '{0}::{1}'.format([scene, sub_path])
				if ResourceLoader.exists(full_path):
					var design = ResourceLoader.load(full_path, "ProceduralTextureDesign", ResourceLoader.CACHE_MODE_REUSE)
					if design and not find_editor_for_design(design):
						_build_new_editor(design)


func _handles(object: Object) -> bool:
	return object is ProceduralTextureDesign


func _make_visible(visible: bool) -> void:
	if visible and designer_button:
		designer_button.visible = true
		make_bottom_panel_item_visible(designer_manager)


func _apply_changes() -> void:
	for editor: ProceduralTextureDesignEditor in designs_tabs.get_children():
		editor._apply_changes()


func _set_window_layout(configuration: ConfigFile) -> void:
	if configuration.has_section_key('editors', 'root'):
		var paths = configuration.get_value('editors', 'root')
		for path in paths:
			if ResourceLoader.exists(path):
				var design = ResourceLoader.load(path, "ProceduralTextureDesign", ResourceLoader.CACHE_MODE_REUSE)
				if design and not find_editor_for_design(design):
					_build_new_editor(design)

	var is_visible = configuration.get_value('main', 'visible', false)
	if is_visible and designs_list.item_count > 0:
		make_bottom_panel_item_visible(designer_manager)


func find_editor_for_design(design: ProceduralTextureDesign) -> ProceduralTextureDesignEditor:
	for editor: ProceduralTextureDesignEditor in designs_tabs.get_children():
		if editor and editor.design == design:
			return editor
	return null


func switch_to_selected_design() -> void:
	var selected_items = designs_list.get_selected_items()
	if selected_items.is_empty():
		designs_tabs.current_tab = -1
		return

	var selected = selected_items[0]
	designs_tabs.current_tab = selected


func unlist_editor_idx(index: int) -> void:
	if designs_list.is_selected(index):
		designs_list.deselect_all()
		switch_to_selected_design()

	var editor = designs_tabs.get_child(index)
	designs_tabs.remove_child(editor)
	editor.queue_free()

	designs_list.remove_item(index)

	if designs_list.item_count == 0:
		designer_button.visible = false
		if designer_manager.is_visible_in_tree():
			hide_bottom_panel()


func _build_designer_manager() -> Control:
	var main_split = HSplitContainer.new()

	designs_list = ItemList.new()
	designs_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	designs_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	designs_list.allow_reselect = true
	designs_list.item_clicked.connect(_on_designs_list_clicked)
	designs_list.item_selected.connect(_on_designs_list_selected)
	designs_list.custom_minimum_size = Vector2(200, 300) * EditorInterface.get_editor_scale()
	main_split.add_child(designs_list)

	designs_tabs = TabContainer.new()
	designs_tabs.tabs_visible = false
	designs_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	designs_tabs.deselect_enabled = true
	main_split.add_child(designs_tabs)

	var empty_style = StyleBoxEmpty.new()
	designs_tabs.add_theme_stylebox_override("panel", empty_style)

	return main_split


func _build_new_editor(design: ProceduralTextureDesign) -> ProceduralTextureDesignEditor:
	var new_editor := ProceduralTextureDesignEditor.new(get_undo_redo())
	new_editor.setup_design(design)
	designs_tabs.add_child(new_editor)
	designs_list.add_item(new_editor.get_title())
	if designs_list.item_count == 1:
		designs_list.select(0)
	designer_button.visible = true
	return new_editor


func _on_designs_list_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == 3:
		unlist_editor_idx(index)


func _on_designs_list_selected(index: int) -> void:
	EditorInterface.edit_resource(designs_tabs.get_child(index).design)


func _on_editor_title_changed(editor) -> void:
	for idx in designs_tabs.get_child_count():
		if editor == designs_tabs.get_child(idx):
			var title = editor.get_title()
			designs_list.set_item_text(idx, title)
			break
