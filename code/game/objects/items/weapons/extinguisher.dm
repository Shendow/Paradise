#define EXTINGUISHER_FIRE_COOLDOWN 2 SECONDS

/obj/item/extinguisher
	name = "fire extinguisher"
	desc = "A traditional red fire extinguisher."
	icon = 'icons/obj/items.dmi'
	icon_state = "fire_extinguisher0"
	item_state = "fire_extinguisher"
	container_type = AMOUNT_VISIBLE
	flags = CONDUCT
	resistance_flags = FIRE_PROOF
	materials = list(MAT_METAL = 90)
	dog_fashion = /datum/dog_fashion/back
	force = 10
	throwforce = 10
	hitsound = 'sound/weapons/smash.ogg'
	attack_verb = list("slammed", "whacked", "bashed", "thunked", "battered", "bludgeoned", "thrashed")
	// Settings
	/// How much water reagent units the extinguisher can contain.
	var/water_capacity = 50
	/// Whether the extinguisher is guaranteed to hit all turfs.
	var/precision = FALSE
	/// The base icon state, to use on icon update (safety toggle).
	var/base_icon_state = "fire_extinguisher"
	/// Propulsion speed.
	var/propulsion_speed = 5
	/// Propulsion friction.
	var/propulsion_friction = 0.5
	// Variables
	/// The world.time at which the extinguisher was last fired.
	var/last_use = 0
	/// Whether the extinguisher's safety is engaged, meaning it cannot be fired.
	var/safety = TRUE

/obj/item/extinguisher/Initialize(mapload)
	. = ..()
	create_reagents(water_capacity)
	reagents.add_reagent("water", water_capacity)

/obj/item/extinguisher/update_icon()
	..()
	icon_state = "[base_icon_state][safety]"

/obj/item/extinguisher/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The safety is [safety ? "on" : "off"].</span>"

/obj/item/extinguisher/attack_self(mob/user)
	safety = !safety
	to_chat(user, "<span class='notice'>You toggle the safety [safety ? "on" : "off"].</span>")
	update_icon()

/obj/item/extinguisher/attack_obj(obj/O, mob/living/user, params)
	if(istype(O, /obj/structure/reagent_dispensers/watertank) && user.Adjacent(O))
		. = TRUE
		if(reagents.holder_full())
			to_chat(user, "<span class='warning'>[src] is already full!</span>")
			return

		var/transferred = O.reagents.trans_to(src, water_capacity)
		if(transferred)
			user.visible_message("<span class='notice'>[user] refills [src] using [O].</span>", \
								 "<span class='notice'>You refill [src] by [transferred] unit\s.</span>")
			playsound(src, 'sound/effects/refill.ogg', 50, TRUE, -6)
		else
			to_chat(user, "<span class='warning'>[O] is empty!</span>")
		return
	return ..()

/obj/item/extinguisher/afterattack(atom/target, mob/user, proximity, params)
	..()
	if(safety)
		return
	if(!reagents.total_volume)
		to_chat(user, "<span class='danger'>[src] is empty!</span>")
		return
	if(last_use + EXTINGUISHER_FIRE_COOLDOWN > world.time)
		return

	last_use = world.time
	playsound(src, 'sound/effects/extinguish.ogg', 75, TRUE, -3)
	if(reagents.chem_temp > 300 || reagents.chem_temp < 280)
		add_attack_logs(user, target, "Sprayed with superheated or cooled fire extinguisher at Temperature [reagents.chem_temp]K")

	var/direction = get_dir(src, target)
	var/opposite_direction = turn(direction, 180)

	// Extinguishers, the future of PROPULSION
	if(!QDELETED(user.buckled) && !user.buckled.anchored)
		user.buckled.AddComponent(/datum/component/propulsion, propulsion_speed, opposite_direction, propulsion_friction)
	else
		user.newtonian_move(opposite_direction)

	// var/turf/T = get_turf(target)
	// var/turf/T1 = get_step(T,turn(direction, 90))
	// var/turf/T2 = get_step(T,turn(direction, -90))
	// var/list/the_targets = list(T,T1,T2)
	// if(precision)
	// 	var/turf/T3 = get_step(T1, turn(direction, 90))
	// 	var/turf/T4 = get_step(T2,turn(direction, -90))
	// 	the_targets = list(T,T1,T2,T3,T4)

	// for(var/a=0, a<5, a++)
	// 	spawn(0)
	// 		var/obj/effect/particle_effect/water/W = new /obj/effect/particle_effect/water( get_turf(src) )
	// 		var/turf/my_target = pick(the_targets)
	// 		if(precision)
	// 			the_targets -= my_target
	// 		var/datum/reagents/R = new/datum/reagents(5)
	// 		if(!W) return
	// 		W.reagents = R
	// 		R.my_atom = W
	// 		if(!W || !src) return
	// 		src.reagents.trans_to(W,1)
	// 		for(var/b=0, b<5, b++)
	// 			step_towards(W,my_target)
	// 			if(!W || !W.reagents) return
	// 			W.reagents.reaction(get_turf(W))
	// 			for(var/atom/atm in get_turf(W))
	// 				if(!W) return
	// 				W.reagents.reaction(atm)
	// 				if(isliving(atm)) //For extinguishing mobs on fire
	// 					var/mob/living/M = atm
	// 					M.ExtinguishMob()

	// 			if(W.loc == my_target) break
	// 			sleep(2)

/obj/item/extinguisher/cyborg_recharge(coeff, emagged)
	reagents.check_and_add("water", water_capacity, 5 * coeff)

/obj/item/extinguisher/mini
	name = "pocket fire extinguisher"
	desc = "A light and compact fibreglass-framed model fire extinguisher."
	icon_state = "miniFE0"
	item_state = "miniFE"
	w_class = WEIGHT_CLASS_SMALL
	flags = null
	materials = list()
	dog_fashion = null

	force = 3
	throwforce = 2
	hitsound = null

	water_capacity = 30
	base_icon_state = "miniFE"

#undef EXTINGUISHER_FIRE_COOLDOWN
