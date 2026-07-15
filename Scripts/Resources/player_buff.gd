class_name PlayerBuff extends Resource

@export var button_name: String
@export var description: String
@export var buff_type: BuffType
@export var strength: float
@export var prereq_buffs: Array[PlayerBuff]
@export var cost_minor: int
@export var cost_major: int

enum BuffType {
	UNDEFINED,
	DRONE_COUNT,
	DRONE_FIRE_RATE,
	BUNKER_WIDTH,
	BUNKER_DEFENSE,
	AMMO_PIERCING_POWER,
	AMMO_PIERCING_COOLDOWN,
	AMMO_SHOTGUN_AMOUNT,
	AMMO_SHOTGUN_COOLDOWN,
	AMMO_EXPLOSIVE_COOLDOWN,
	AMMO_EXPLOSIVE_RADIUS,
	AMMO_SEEKER_COOLDOWN,
	GUN_RATE_OF_FIRE,
	GUN_BULLET_SPEED,
	LIVES_HIGHER_MAX,
	LIVES_RESTORE_PER_WAVE,
	RESPEC,
}
