class_name PetInstance
extends RefCounted

## 펫 "개체" 데이터. 종족(PetSpecies) 공통 값에 레벨/경험치/현재 HP를 얹는다.

var species: PetSpecies
var nickname: String = ""
var level: int = 1
var exp: int = 0
var current_hp: int = 1


func _init(p_species: PetSpecies = null, p_level: int = 1, p_nickname: String = "") -> void:
	species = p_species
	level = maxi(1, p_level)
	nickname = p_nickname
	if species:
		current_hp = max_hp()


func display_name() -> String:
	if nickname != "":
		return nickname
	return species.display_name if species else "???"


func max_hp() -> int:
	return species.stat_at_level(species.base_hp, species.growth_hp, level)


func attack() -> int:
	return species.stat_at_level(species.base_attack, species.growth_attack, level)


func defense() -> int:
	return species.stat_at_level(species.base_defense, species.growth_defense, level)


func agility() -> int:
	return species.stat_at_level(species.base_agility, species.growth_agility, level)


func hp_ratio() -> float:
	return float(current_hp) / float(max_hp())


func exp_to_next() -> int:
	return level * 20


## 경험치를 더하고, 레벨업했으면 true. 레벨업 시 HP 전체 회복.
func gain_exp(amount: int) -> bool:
	exp += amount
	var leveled := false
	while exp >= exp_to_next():
		exp -= exp_to_next()
		level += 1
		leveled = true
	if leveled:
		current_hp = max_hp()
	return leveled


func to_dict() -> Dictionary:
	return {
		"species": String(species.id),
		"nickname": nickname,
		"level": level,
		"exp": exp,
		"hp": current_hp,
	}


static func from_dict(data: Dictionary, registry: Dictionary) -> PetInstance:
	var sp: PetSpecies = registry.get(StringName(String(data.get("species", ""))))
	if sp == null:
		return null
	var pet := PetInstance.new(sp, int(data.get("level", 1)), String(data.get("nickname", "")))
	pet.exp = maxi(0, int(data.get("exp", 0)))
	pet.current_hp = clampi(int(data.get("hp", pet.current_hp)), 1, pet.max_hp())
	return pet
