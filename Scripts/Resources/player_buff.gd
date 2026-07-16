class_name PlayerBuff extends Resource


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

enum HowVisible {
	INVISIBLE,
	SHROUDED,
	DESCRIBED,
	FULLY_VISIBLE
}


@export var button_name: String
@export var description: String
@export var buff_type: BuffType
@export var strength: float
@export var prereq_buffs: Array[PlayerBuff]
@export var cost_minor: int
@export var cost_major: int


func has() -> bool:
	return PlayerStats.has_buff(self)


func can_be_bought() -> bool:
	assert(buff_type != BuffType.UNDEFINED)
	if PlayerStats.has_buff(self):
		return false
	if not PlayerStats.can_afford(cost_minor, cost_major):
		return false
	for prereq: PlayerBuff in prereq_buffs:
		if not PlayerStats.has_buff(prereq):
			return false
	return true


func can_see() -> HowVisible:
	if PlayerStats.has_buff(self):
		return HowVisible.FULLY_VISIBLE
	var missing_prereqs: int = 0
	var gained_prereqs: int = 0
	for prereq: PlayerBuff in prereq_buffs:
		if PlayerStats.has_buff(prereq):
			gained_prereqs += 1
		else:
			var pr_visibility: HowVisible = prereq.can_see()
			if pr_visibility == HowVisible.SHROUDED or pr_visibility == HowVisible.INVISIBLE:
				return HowVisible.INVISIBLE
			missing_prereqs += 1
	if gained_prereqs > 0:
		if missing_prereqs == 0:
			return HowVisible.FULLY_VISIBLE
		elif missing_prereqs <= gained_prereqs:
			return HowVisible.DESCRIBED
		else:
			return HowVisible.SHROUDED
	elif missing_prereqs == 0:
		return HowVisible.DESCRIBED
	else:
		return HowVisible.SHROUDED
