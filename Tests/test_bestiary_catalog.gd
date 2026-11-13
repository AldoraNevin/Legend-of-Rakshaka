extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1080, 608)
	player_data.init_system()
	player_data.discovered_enemies = ["Leak", "kuntilanak"]
	player_data.discovered_artifacts = ["kujang_pusaka"]
	var catalog = load("res://Scenes/Interactables/bestiary_catalog.tscn").instantiate()
	var enemy_card = catalog.get_node("EnemyPage/Book/EntryGrid/Entry_leak")
	var artifact_card = catalog.get_node("ArtifactPage/Book/EntryGrid/Entry_kujang_pusaka")
	check(enemy_card.has_node("Portrait") and artifact_card.has_node("NameLabel"), "Each category must contain permanent content nodes")
	# Simulate edits made in Inspector before the scene runs.
	enemy_card.get_node("NameLabel").text = "Leak Edit"
	enemy_card.description = "Deskripsi dari Inspector"
	var edited_texture: Texture2D = artifact_card.get_node("Portrait").texture
	enemy_card.get_node("Portrait").texture = edited_texture
	var card_id: int = enemy_card.get_instance_id()
	root.add_child(catalog)
	await process_frame
	catalog.open_book()
	var enemies = catalog.enemy_page
	var artifacts = catalog.artifact_page
	check(paused and enemies.visible and not artifacts.visible, "Lobby opens enemy tab and pauses")
	check(enemies.entries.size() == enemies.grid.get_child_count(), "Every enemy must have its own permanent card")
	enemies.search.text = "Leak Edit"
	enemies.search.text_changed.emit(enemies.search.text)
	check(enemies.filtered.size() == 1, "Search must use the authored name")
	check(enemies.title_label.text == "LEAK EDIT", "Runtime must use edited card name")
	check(enemies.details.get_parsed_text().contains("Deskripsi dari Inspector"), "Runtime must use authored description")
	check(enemies.portrait.texture == edited_texture, "Runtime must use authored texture")
	enemies.search.text = ""
	enemies._filter()
	enemies._turn(1)
	check(enemy_card.get_instance_id() == card_id, "Paging must never replace authored cards")
	catalog._set_category(true)
	check(artifacts.visible and not enemies.visible, "Artifact tab switches to its independent scene")
	check(artifacts.entries.size() == artifacts.grid.get_child_count(), "Every artifact must have its own card")
	check(artifacts.entries.size() == player_data.bestiary_master.artifacts.size(), "All original artifacts must be migrated")
	artifacts.search.text = "Kujang"
	artifacts._filter()
	check(artifacts.filtered.size() == 1 and artifacts.selected.name == "Kujang Pusaka", "Artifact data must remain available")
	catalog.close_book()
	check(not paused, "Closing catalogue resumes gameplay")
	catalog.open_book(true)
	check(artifacts.visible, "Reopening can directly select artifacts")
	catalog.close_book()
	catalog.queue_free()
	await process_frame
	# Running a tab directly is the F6 preview; no save data is changed.
	change_scene_to_file("res://Scenes/Interactables/bestiary_artifacts_tab.tscn")
	await scene_changed
	await process_frame
	var tab = current_scene
	check(tab.preview_mode, "F6 must show authored contents without save locks")
	check(tab.selected.is_unlocked and not tab.entries.is_empty(), "F6 details must match editor preview")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	tab.queue_free()
	await process_frame
	# F6 of the container must respect the same editor tab/page/entry choices.
	var preview = load("res://Scenes/Interactables/bestiary_catalog.tscn").instantiate()
	preview.initial_tab = 1
	preview.get_node("ArtifactPage").preview_entry = 13
	var expected: Dictionary = preview.get_node("ArtifactPage/Book/EntryGrid").get_child(13).get_entry()
	root.add_child(preview)
	current_scene = preview
	await process_frame
	await process_frame
	check(preview.active_page == preview.artifact_page, "F6 must open editor Initial Tab")
	check(preview.artifact_page.page == 1, "F6 must preserve editor preview page")
	check(preview.artifact_page.selected.entity_id == expected.entity_id, "F6 must preserve editor Preview Entry")
	check(preview.artifact_page.selected.is_unlocked, "F6 preview must not apply save locks")
	check(preview.artifact_page.cards[13].button_pressed, "F6 card highlight must match selected detail")
	preview.queue_free()
	await process_frame
	print("BESTIARY TEST: %d failures" % failures)
	quit(1 if failures else 0)
