extends RefCounted

static func apply(target: Node, bleed: bool, stun: bool) -> void:
	if bleed:
		target.set_meta("bleed_left", 3.0)
		if not target.has_meta("bleed_tick"):
			target.set_meta("bleed_tick", 1.0)
	if stun and not target.get("countering"):
		target.set_meta("stun_left", 1.0)

static func tick(target: Node, delta: float) -> bool:
	var remaining: float = target.get_meta("bleed_left", 0.0)
	if remaining > 0.0:
		var timer: float = target.get_meta("bleed_tick", 1.0)
		timer -= minf(delta, remaining)
		if timer <= 0.00001:
			target.take_damage(1)
			timer += 1.0
		target.set_meta("bleed_tick", timer)
		target.set_meta("bleed_left", maxf(0.0, remaining - delta))
	var stun: float = target.get_meta("stun_left", 0.0)
	target.set_meta("stun_left", maxf(0.0, stun - delta))
	var animation := target.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation != null:
		var dead: bool = target.get("is_dead") == true or target.get("health") <= 0
		animation.speed_scale = 0.0 if stun > 0.0 and not dead else 1.0
	return stun > 0.0 and target.get("health") > 0
