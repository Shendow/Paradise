/particles/welding_sparks
	width = 96
	height = 96
	count = 32
	spawning = 3
	bound1 = list(-48, -48, -1000)
	bound2 = list(48, 48, 1000)
	lifespan = 1 SECONDS
	fade = 1 SECONDS
	gradient = list("#FF0000", "#FFFF00", "#FFFFFF")
	color = generator("num", 0, 1)
	velocity = generator("box", list(-8, -8, 0), list(-16, 16, 0))
	gravity = list(0, -3.2)
	friction = 0.2
	drift = generator("sphere", 0, 2)

/obj/effect/particle_system/welding_spark
	layer = FLY_LAYER
	var/obj/effect/welding_dot/dot = null
	var/obj/effect/dummy/lighting_obj/light_obj = null
	var/start_time = -1
	var/end_time = -1
	var/xdif = 0
	var/ydif = 0

/obj/effect/particle_system/welding_spark/New(atom/loc, turf/source, length)
	. = ..()
	var/particles/welding_sparks/P = new
	particles = P
	xdif = (loc.x - source.x) * 32
	ydif = (loc.y - source.y) * 32
	// dot
	dot = new /obj/effect/welding_dot(loc)
	// light
	light_obj = new(src, "#FFFF99", 2, 1)
	// particle direction
	if(loc != source)
		var/_atan = arctan(source.x - loc.x, source.y - loc.y)
		var/_cos = cos(_atan) * 8
		var/_sin = sin(_atan)
		P.gravity = list(0, -1.6 + 1.6 * _sin)
		_sin *= 8
		var/x_vary = (source.x - loc.x) ? 0 : 4
		P.velocity = generator("box", list(_cos - x_vary, _sin, 0), list(_cos * 2 + x_vary, _sin + 8, 0))
	// position
	P.position = list(xdif, ydif, 0)
	src.loc = source // Prevents seeing the particles from the other side - we have to compensate the particles position above
	// animate
	start_time = world.time
	end_time = world.time + length
	INVOKE_ASYNC(src, .proc/do_animation)

/obj/effect/particle_system/welding_spark/proc/do_animation()
	while(world.time < end_time)
		if(QDELETED(src))
			break
		var/progress = 1 - (end_time - world.time) / (end_time - start_time)
		dot?.update(progress)
		var/particles/welding_sparks/P = particles
		P.position = list(xdif, ydif + 16 - progress * 32)
		//
		sleep(1)

/obj/effect/particle_system/welding_spark/Destroy()
	. = ..()
	QDEL_NULL(dot)
	QDEL_NULL(light_obj)

/obj/effect/welding_dot
	layer = FLY_LAYER
	var/static/icon/yellow_dot = null
	var/image/dot_overlay = null
	var/image/trail_overlay = null

/obj/effect/welding_dot/New(atom/loc)
	. = ..()
	// dot
	if(!yellow_dot)
		yellow_dot = icon('icons/effects/effects.dmi', "impact_laser")
		yellow_dot.GrayScale()
		yellow_dot.Blend("#FFFF33", ICON_MULTIPLY)
	dot_overlay = image(yellow_dot)
	dot_overlay.transform *= 0.5
	dot_overlay.pixel_y = 16
	add_overlay(dot_overlay)
	// trail
	trail_overlay = image('icons/effects/effects.dmi', src, "thermite")
	trail_overlay.color = "#333333"

/obj/effect/welding_dot/proc/update(progress)
	cut_overlays()
	// trail
	var/matrix/M = matrix()
	M.Scale(6 / 32, progress)
	M.Translate(0, 16 * (1 - progress))
	trail_overlay.transform = M
	add_overlay(trail_overlay)
	// dot
	dot_overlay.pixel_y = 16 - 32 * progress
	add_overlay(dot_overlay)
