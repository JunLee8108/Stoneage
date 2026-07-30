extends Node2D

## 필드에서 플레이어를 따라다니는 동행 펫.

const FOLLOW_DISTANCE := 28.0   # 이 거리 안이면 멈춘다
const SPEED := 90.0             # 플레이어(80)보다 살짝 빨라야 안 뒤처진다

@export var species: PetSpecies
@export var target: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"

func _ready() -> void:
	if species and species.walk_frames:
		sprite.sprite_frames = species.walk_frames


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance <= FOLLOW_DISTANCE:
		sprite.pause()
		sprite.frame = 0
		return
	var dir := to_target / distance
	global_position += dir * minf(SPEED * delta, distance - FOLLOW_DISTANCE)
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0.0 else "left"
	else:
		facing = "down" if dir.y > 0.0 else "up"
	sprite.play("walk_" + facing)
