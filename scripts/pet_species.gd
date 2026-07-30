class_name PetSpecies
extends Resource

## 펫 종족 정의 데이터. 개체(레벨, 현재 스탯)가 아니라 종족 공통 값만 담는다.

enum Element { EARTH, WATER, FIRE, WIND } # 지·수·화·풍

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
