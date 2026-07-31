class_name PetSpecies
extends Resource

## 펫 종족 정의 데이터. 개체(레벨, 현재 스탯)가 아니라 종족 공통 값만 담는다.

enum Element { EARTH, WATER, FIRE, WIND } # 지·수·화·풍

const ELEMENT_NAMES := {
	Element.EARTH: "지",
	Element.WATER: "수",
	Element.FIRE: "화",
	Element.WIND: "풍",
}

## 순환 상성: 지→수→화→풍→지 (앞이 뒤를 이긴다)
const ELEMENT_BEATS := {
	Element.EARTH: Element.WATER,
	Element.WATER: Element.FIRE,
	Element.FIRE: Element.WIND,
	Element.WIND: Element.EARTH,
}

const ELEMENT_MULT_ADVANTAGE := 1.5
const ELEMENT_MULT_DISADVANTAGE := 0.75

@export var id: StringName
@export var display_name: String
@export var element: Element = Element.EARTH

@export_group("기본 스탯 (1레벨 기준)")
@export var base_hp: int = 50
@export var base_attack: int = 10
@export var base_defense: int = 10
@export var base_agility: int = 10

@export_group("레벨당 성장치")
@export var growth_hp: float = 5.0
@export var growth_attack: float = 1.0
@export var growth_defense: float = 1.0
@export var growth_agility: float = 1.0

@export_group("표시")
@export var walk_frames: SpriteFrames


func stat_at_level(base: int, growth: float, level: int) -> int:
	return base + int(growth * float(level - 1))


static func element_name(element_value: Element) -> String:
	return ELEMENT_NAMES.get(element_value, "?")


## 공격 속성이 유리하면 1.5, 불리하면 0.75, 그 외 1.0.
static func element_multiplier(attacker_element: Element, defender_element: Element) -> float:
	if ELEMENT_BEATS[attacker_element] == defender_element:
		return ELEMENT_MULT_ADVANTAGE
	if ELEMENT_BEATS[defender_element] == attacker_element:
		return ELEMENT_MULT_DISADVANTAGE
	return 1.0
