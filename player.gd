extends CharacterBody2D

## 필드 이동 속도 (픽셀/초). 16px 타일 기준 초당 5칸.
const SPEED := 80.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
