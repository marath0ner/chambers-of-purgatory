extends Resource
class_name Loot

enum Rarity {COMMON, UNCOMMON, RARE, LEGENDARY, EXOTIC}
enum Type {WEAPON, ARMOR, ACCESSORY, MAGIC}

@export var name : String
@export var type : Type
@export var rarity : Rarity
@export var description : String
@export var model : PackedScene
@export var texture : Texture2D
@export var attack_damage : int
@export var attack_speed : float
