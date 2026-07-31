extends Node

## 게임 전역 상태 (autoload). 보유 펫, 필드 위치, 세이브/로드, 전투 진입/복귀.

const SAVE_PATH := "user://save.json"
const SPECIES_DIR := "res://data/pets"
const FIELD_SCENE := "res://field.tscn"
const BATTLE_SCENE := "res://battle.tscn"
const DEFAULT_SPAWN := Vector2(320, 176)

var species_registry: Dictionary = {}       # StringName -> PetSpecies
var pets: Array[PetInstance] = []
var active_pet_index: int = 0
var player_field_position := DEFAULT_SPAWN
var pending_wild: PetInstance = null        # 전투 씬에 넘길 야생 개체

## 테스트/연출용: false면 씬 전환 없이 상태만 바꾼다.
var scene_transitions_enabled := true


func _ready() -> void:
	_load_species_registry()
	if not load_game():
		new_game()


func _load_species_registry() -> void:
	species_registry.clear()
	var dir := DirAccess.open(SPECIES_DIR)
	if dir == null:
		push_error("펫 데이터 폴더를 열 수 없음: " + SPECIES_DIR)
		return
	for file in dir.get_files():
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var res := load(SPECIES_DIR + "/" + name) as PetSpecies
		if res:
			species_registry[res.id] = res


func new_game() -> void:
	pets.clear()
	pets.append(PetInstance.new(species_registry.get(&"verga"), 1))
	active_pet_index = 0
	player_field_position = DEFAULT_SPAWN


func active_pet() -> PetInstance:
	if pets.is_empty():
		return null
	return pets[clampi(active_pet_index, 0, pets.size() - 1)]


func begin_wild_battle() -> void:
	var ids := species_registry.keys()
	var species: PetSpecies = species_registry[ids[randi() % ids.size()]]
	pending_wild = PetInstance.new(species, randi_range(2, 4))
	if scene_transitions_enabled:
		get_tree().change_scene_to_file(BATTLE_SCENE)


## result: &"win" | &"lose" | &"capture" | &"flee"
func finish_battle(result: StringName) -> void:
	match result:
		&"capture":
			if pending_wild:
				pets.append(pending_wild)
		&"lose":
			var pet := active_pet()
			if pet:
				pet.current_hp = 1
	pending_wild = null
	save_game()
	if scene_transitions_enabled:
		get_tree().change_scene_to_file(FIELD_SCENE)


func save_game() -> void:
	var pet_dicts: Array = []
	for pet in pets:
		pet_dicts.append(pet.to_dict())
	var data := {
		"version": 1,
		"player": {"x": player_field_position.x, "y": player_field_position.y},
		"active_pet": active_pet_index,
		"pets": pet_dicts,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("세이브 실패: " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	var player_data: Dictionary = data.get("player", {})
	player_field_position = Vector2(
		float(player_data.get("x", DEFAULT_SPAWN.x)),
		float(player_data.get("y", DEFAULT_SPAWN.y))
	)
	pets.clear()
	for entry in data.get("pets", []):
		if typeof(entry) == TYPE_DICTIONARY:
			var pet := PetInstance.from_dict(entry, species_registry)
			if pet:
				pets.append(pet)
	if pets.is_empty():
		return false
	active_pet_index = clampi(int(data.get("active_pet", 0)), 0, pets.size() - 1)
	return true
