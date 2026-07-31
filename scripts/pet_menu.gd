extends CanvasLayer

## 보유 펫 목록 / 출전 펫 교체 메뉴. 열리는 동안 게임은 일시정지된다.

signal active_changed

@onready var rows_box: VBoxContainer = $Panel/Margin/VBox/Rows


func open() -> void:
	_rebuild()
	visible = true
	get_tree().paused = true
	if rows_box.get_child_count() > 0:
		(rows_box.get_child(0) as Button).grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("open_pets") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	for child in rows_box.get_children():
		rows_box.remove_child(child)
		child.queue_free()
	for i in GameState.pets.size():
		var pet: PetInstance = GameState.pets[i]
		var row := Button.new()
		row.custom_minimum_size = Vector2(340, 30)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var marker := "[출전] " if i == GameState.active_pet_index else "       "
		row.text = "%s%s  Lv.%d  HP %d/%d  (%s)" % [
			marker, pet.display_name(), pet.level,
			pet.current_hp, pet.max_hp(),
			PetSpecies.element_name(pet.species.element),
		]
		row.pressed.connect(_on_row_pressed.bind(i))
		rows_box.add_child(row)


func _on_row_pressed(index: int) -> void:
	if GameState.active_pet_index != index:
		GameState.active_pet_index = index
		GameState.save_game()
		active_changed.emit()
	_rebuild()
	if index < rows_box.get_child_count():
		(rows_box.get_child(index) as Button).grab_focus()
