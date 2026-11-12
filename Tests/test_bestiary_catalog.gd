extends SceneTree
## Run with --headless --path . --script res://Tests/test_bestiary_catalog.gd.
## Optional -- --capture=absolute/path.png uses a graphical renderer for visual QA.
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1080, 608)
	# In-memory discovery only: never modify the player's save file.
	player_data.init_system()
	player_data.discovered_enemies = ["leak", "kuntilanak", "genderuwo", "jerangkong", "banaspati", "sarpakenaka", "rangda"]
	player_data.discovered_artifacts = ["kujang_pusaka"]
	var catalog = load("res://Scenes/Interactables/bestiary_catalog.tscn").instantiate()
	# These visuals must exist before _ready, including nested card children.
	check(catalog.has_node("Book/Background"), "Book background must be saved in the scene")
	check(catalog.has_node("Book/EntryGrid/Card01/Portrait"), "Card portrait must be saved in the scene")
	var authored_position: Vector2 = catalog.get_node("Book/SearchInput").position + Vector2(3, 2)
	catalog.get_node("Book/SearchInput").position = authored_position
	var first_card_id: int = catalog.get_node("Book/EntryGrid/Card01").get_instance_id()
	root.add_child(catalog)
	await process_frame
	catalog.open_book()
	check(catalog.search.position == authored_position, "Runtime must preserve edited positions")
	check(paused and catalog.visible, "Book must pause the game when opened")
	check(catalog.grid.get_child_count() == 12, "First page must contain 12 cards")
	catalog._turn(1)
	check(catalog.grid.get_child(0).get_instance_id() == first_card_id, "Pagination must reuse permanent cards")
	check(catalog.page == 1, "Next page must advance")
	catalog.search.text = "LEAK"
	catalog.search.text_changed.emit(catalog.search.text)
	check(catalog.filtered.size() == 1, "Search must ignore letter case")
	check(catalog.title_label.text == "LEAK", "Search result must populate details")
	catalog._set_detail(true)
	check(not catalog.details.get_parsed_text().is_empty(), "History must display existing lore")
	catalog.search.text = "no-such-entry"
	catalog.search.text_changed.emit(catalog.search.text)
	check(catalog.filtered.is_empty() and catalog.selected.is_empty(), "Empty search must clear stale details")
	catalog.search.text = ""
	catalog.search.text_changed.emit(catalog.search.text)
	catalog.discovered.button_pressed = true
	check(catalog.filtered.size() == 7, "Discovered filter must honor save state")
	for index in range(catalog.region.item_count):
		if catalog.region.get_item_text(index) == "Bali":
			catalog.region.select(index)
	catalog._filter()
	check(not catalog.filtered.is_empty(), "Bali region must have a result")
	for entry in catalog.filtered:
		check(entry.get("region") == "Bali", "Region filter must exclude other regions")
	catalog._set_category(true)
	check(catalog.entries.size() == player_data.bestiary_master.artifacts.size(), "Artifact tab must load artifacts")
	catalog.close_book()
	check(not paused and not catalog.visible, "Close must restore gameplay")
	paused = true
	catalog.open_book()
	catalog.close_book()
	check(paused, "Close must preserve an already paused game")
	paused = false
	catalog.open_book()
	catalog.search.text = "leak"
	catalog.search.text_changed.emit(catalog.search.text)
	catalog.search.text = ""
	catalog.search.text_changed.emit(catalog.search.text)
	for entry in catalog.filtered:
		if entry.get("entity_id") == "leak":
			catalog._select(entry)
			catalog.grid.get_child(catalog.filtered.find(entry)).button_pressed = true
	await process_frame
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			var result := root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
			check(result == OK, "Screenshot must save")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	catalog._input(cancel)
	check(not paused and not catalog.visible, "Escape must close the book and unpause")
	catalog.queue_free()
	await process_frame
	print("BESTIARY TEST: %d failures" % failures)
	quit(1 if failures else 0)

