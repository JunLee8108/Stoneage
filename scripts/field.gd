extends Node2D

## 필드: 풀숲 랜덤 인카운터 판정.

signal encounter_triggered

const ENCOUNTER_CHANCE := 0.12

@onready var ground: TileMapLayer = $Ground
@onready var player: CharacterBody2D = $Player
@onready var pet: Node2D = $Pet

var _last_tile := Vector2i(-9999, -9999)

func _ready() -> void:
	player.global_position = GameState.player_field_position
	pet.global_position = player.global_position + Vector2(-36, 0)
	_last_tile = _player_tile()


func _physics_process(_delta: float) -> void:
	var tile := _player_tile()
	if tile == _last_tile:
		return
	_last_tile = tile
	var data := ground.get_cell_tile_data(tile)
	if data == null or not data.get_custom_data("encounter"):
		return
	if randf() < ENCOUNTER_CHANCE:
		_trigger_encounter()


func _player_tile() -> Vector2i:
	return ground.local_to_map(ground.to_local(player.global_position))


func _trigger_encounter() -> void:
	encounter_triggered.emit()
	set_physics_process(false)  # 중복 발동 방지
	GameState.player_field_position = player.global_position
	GameState.begin_wild_battle()
