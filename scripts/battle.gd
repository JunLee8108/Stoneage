extends Control

## 야생 펫과의 1:1 턴제 전투. 커맨드: 공격 / 스킬 / 포획 / 도망.

signal battle_finished(result: StringName)

const LOG_DELAY := 0.7
const SKILL_NAME := "송곳니 박기"
const SKILL_MULT := 1.5
const SKILL_USES_MAX := 3
const EXP_PER_WIN := 10

var ally: PetInstance
var enemy: PetInstance
var busy := true
var skill_uses := SKILL_USES_MAX
var log_delay := LOG_DELAY   # 테스트에서 짧게 조정 가능

@onready var ally_sprite: AnimatedSprite2D = $AllySprite
@onready var enemy_sprite: AnimatedSprite2D = $EnemySprite
@onready var ally_name: Label = $AllyPanel/Margin/VBox/AllyName
@onready var ally_hp_bar: ProgressBar = $AllyPanel/Margin/VBox/AllyHP
@onready var ally_hp_text: Label = $AllyPanel/Margin/VBox/AllyHPText
@onready var enemy_name: Label = $EnemyPanel/Margin/VBox/EnemyName
@onready var enemy_hp_bar: ProgressBar = $EnemyPanel/Margin/VBox/EnemyHP
@onready var log_label: Label = $BottomPanel/Margin/VBox/LogLabel
@onready var attack_button: Button = $BottomPanel/Margin/VBox/Commands/AttackButton
@onready var skill_button: Button = $BottomPanel/Margin/VBox/Commands/SkillButton
@onready var capture_button: Button = $BottomPanel/Margin/VBox/Commands/CaptureButton
@onready var flee_button: Button = $BottomPanel/Margin/VBox/Commands/FleeButton


func _ready() -> void:
	ally = GameState.active_pet()
	enemy = GameState.pending_wild
	if enemy == null:  # 씬 단독 실행(F6) 대비
		enemy = PetInstance.new(ally.species, 2)

	ally_sprite.sprite_frames = ally.species.walk_frames
	ally_sprite.play("walk_right")
	enemy_sprite.sprite_frames = enemy.species.walk_frames
	enemy_sprite.play("walk_left")

	ally_name.text = "%s Lv.%d" % [ally.display_name(), ally.level]
	enemy_name.text = "%s Lv.%d" % [_name_of(enemy), enemy.level]
	ally_hp_bar.max_value = ally.max_hp()
	enemy_hp_bar.max_value = enemy.max_hp()

	attack_button.pressed.connect(_on_attack)
	skill_button.pressed.connect(_on_skill)
	capture_button.pressed.connect(_on_capture)
	flee_button.pressed.connect(_on_flee)

	_update_hud()
	_set_commands(false)
	_log("야생 %s이(가) 나타났다!" % enemy.display_name())
	await _delay()
	_open_command_phase()


func _name_of(pet: PetInstance) -> String:
	return ("야생 " + pet.display_name()) if pet == enemy else pet.display_name()


# --- 커맨드 ---

func _on_attack() -> void:
	if busy:
		return
	_run_round(&"attack")


func _on_skill() -> void:
	if busy or skill_uses <= 0:
		return
	skill_uses -= 1
	_run_round(&"skill")


func _on_capture() -> void:
	if busy:
		return
	busy = true
	_set_commands(false)
	_log("돌 포획틀을 던졌다!")
	await _delay()
	if randf() < capture_chance(enemy.hp_ratio()):
		_log("야생 %s을(를) 포획했다! 동료가 되었다!" % enemy.display_name())
		await _finish(&"capture")
		return
	_log("포획 실패! 야생 %s이(가) 빠져나왔다!" % enemy.display_name())
	await _delay()
	await _perform_attack(enemy, ally, 1.0)
	if ally.current_hp <= 0:
		await _handle_lose()
		return
	_open_command_phase()


func _on_flee() -> void:
	if busy:
		return
	busy = true
	_set_commands(false)
	var chance := flee_chance(ally.agility(), enemy.agility())
	if randf() < chance:
		_log("무사히 도망쳤다!")
		await _finish(&"flee")
		return
	_log("도망칠 수 없었다!")
	await _delay()
	await _perform_attack(enemy, ally, 1.0)
	if ally.current_hp <= 0:
		await _handle_lose()
		return
	_open_command_phase()


# --- 턴 진행 ---

func _run_round(player_action: StringName) -> void:
	busy = true
	_set_commands(false)
	var steps: Array = [[ally, enemy, player_action], [enemy, ally, &"attack"]]
	if enemy.agility() > ally.agility():
		steps.reverse()
	for step in steps:
		var is_skill: bool = step[2] == &"skill"
		await _perform_attack(step[0], step[1], SKILL_MULT if is_skill else 1.0)
		if enemy.current_hp <= 0:
			await _handle_win()
			return
		if ally.current_hp <= 0:
			await _handle_lose()
			return
	_open_command_phase()


func _perform_attack(attacker: PetInstance, defender: PetInstance, mult: float) -> void:
	var dmg := calc_damage(attacker, defender, mult)
	defender.current_hp = maxi(0, defender.current_hp - dmg)
	if mult > 1.0:
		_log("%s의 %s! %s에게 %d 데미지!" % [_name_of(attacker), SKILL_NAME, _name_of(defender), dmg])
	else:
		_log("%s의 공격! %s에게 %d 데미지!" % [_name_of(attacker), _name_of(defender), dmg])
	_update_hud()
	await _delay()


func _handle_win() -> void:
	_log("야생 %s을(를) 쓰러뜨렸다!" % enemy.display_name())
	await _delay()
	var before_level := ally.level
	ally.gain_exp(EXP_PER_WIN)
	_log("%s은(는) 경험치 %d을(를) 얻었다!" % [ally.display_name(), EXP_PER_WIN])
	if ally.level > before_level:
		await _delay()
		_update_hud_full()
		_log("%s은(는) 레벨 %d이(가) 되었다!" % [ally.display_name(), ally.level])
	await _finish(&"win")


func _handle_lose() -> void:
	_log("%s이(가) 쓰러졌다... 눈앞이 캄캄해졌다!" % ally.display_name())
	await _finish(&"lose")


func _finish(result: StringName) -> void:
	await _delay()
	battle_finished.emit(result)
	GameState.finish_battle(result)


# --- 규칙 (테스트에서 직접 검증) ---

static func calc_damage(attacker: PetInstance, defender: PetInstance, mult: float) -> int:
	var raw := float(attacker.attack()) * randf_range(0.85, 1.15) * mult \
		- float(defender.defense()) * 0.5
	return maxi(1, int(raw))


static func flee_chance(my_agility: int, enemy_agility: int) -> float:
	return clampf(0.5 + float(my_agility - enemy_agility) * 0.04, 0.25, 0.9)


## 남은 HP 비율이 낮을수록 잡기 쉽다. 풀피 약 21%, 빈사 최대 85%.
static func capture_chance(hp_ratio: float) -> float:
	return clampf(0.85 * (1.0 - 0.75 * hp_ratio), 0.05, 0.95)


# --- UI ---

func _open_command_phase() -> void:
	busy = false
	_set_commands(true)
	attack_button.grab_focus()


func _set_commands(enabled: bool) -> void:
	attack_button.disabled = not enabled
	skill_button.disabled = not enabled or skill_uses <= 0
	capture_button.disabled = not enabled
	flee_button.disabled = not enabled
	skill_button.text = "스킬 (%d)" % skill_uses


func _update_hud() -> void:
	ally_hp_bar.value = ally.current_hp
	enemy_hp_bar.value = enemy.current_hp
	ally_hp_text.text = "%d / %d" % [ally.current_hp, ally.max_hp()]


## 레벨업 등으로 최대치가 변했을 때 전체 갱신.
func _update_hud_full() -> void:
	ally_name.text = "%s Lv.%d" % [ally.display_name(), ally.level]
	ally_hp_bar.max_value = ally.max_hp()
	_update_hud()


func _log(text: String) -> void:
	log_label.text = text


func _delay() -> void:
	await get_tree().create_timer(log_delay).timeout
