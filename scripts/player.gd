extends CharacterBody2D

## 필드 이동 속도 (픽셀/초). 16px 타일 기준 초당 5칸.
const SPEED := 80.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		sprite.pause()
		sprite.frame = 0
		return
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "down" if direction.y > 0.0 else "up"
	sprite.play("walk_" + facing)
