#warn TODO: Logging for admins
#warn TODO: Admin actions

/**
  * # Contractor antagonist datum
  *
  * A variant of the Traitor, Contractors rely on kidnapping crew members to earn TC.
  *
  * Contractors are supplied with some unique items
  * and three random low cost contraband items to help kickstart their contracts.
  * A Traitor may become a Contractor if given the chance (random).
  * They will forfeit all their initial TC and receive the above items.
  * The opportunity to become a Contractor goes away after some time or if the traitor spends any initial TC.
  */
/datum/antagonist/traitor/contractor
	name = "Contractor"
	// Settings
	/// How many telecrystals a traitor must forfeit to become a contractor.
	var/tc_cost = 20
	/// How long a traitor's chance to become a contractor lasts before going away. In deciseconds.
	var/offer_duration = 10 MINUTES
	// Variables
	/// The associated contractor uplink. Only present if the offer was accepted.
	var/obj/item/contractor_uplink/uplink = null
	/// world.time at which the offer will expire.
	var/offer_deadline = -1

/datum/antagonist/traitor/contractor/finalize_traitor()
	..()
	// Setup the vars and contractor stuff in the uplink
	var/obj/item/uplink/hidden/U = owner.find_syndicate_uplink()
	if(!U)
		log_runtime(EXCEPTION("Contractor spawned without an uplink!"), src)
		return
	U.contractor = src
	offer_deadline = world.time + offer_duration

	// Greet them with the unique message
	var/greet_text = "Contractors forfeit [tc_cost] telecrystals for the privilege of taking on kidnapping contracts for credit and TC payouts that can add up to more than the normal starting amount of TC.<br>"\
				   + "If you are interested, simply access your hidden uplink and select the \"Contracting Opportunity\" tab for more information.<br>"
	to_chat(owner.current, "<b><font size=4 color=darkred>You have been offered a chance to become a Contractor.</font></b><br>")
	to_chat(owner.current, "<font color=darkred>[greet_text]</font>")
	to_chat(owner.current, "<b><i><font color=darkred>This offer will expire in 10 minutes starting now (expiry time: <u>[station_time_timestamp(time = offer_deadline)]</u>).</font></i></b>")

/**
  * Accepts the offer to be a contractor if possible.
  */
/datum/antagonist/traitor/contractor/proc/become_contractor(mob/living/carbon/human/M, obj/item/uplink/U)
	if(uplink || !istype(M))
		return
	if(U.uses < tc_cost || world.time >= offer_deadline)
		var/reason = (U.uses < tc_cost) ? \
			"you have insufficient telecrystals ([tc_cost] needed in total)" : \
			"the deadline has passed"
		to_chat(M, "<span class='warning'>You can no longer become a contractor as [reason].</span>")
		return

	// Give the kit
	var/obj/item/storage/box/syndie_kit/contractor/B = new(M)
	M.put_in_hands(B)
	uplink = locate(/obj/item/contractor_uplink, B)
	uplink.hub = new(M.mind, uplink)

	// Remove the TC
	U.uses -= tc_cost
