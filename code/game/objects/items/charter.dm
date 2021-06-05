#define CUSTOM_STATION_NAME_MAXLEN 50
#define STATION_RENAME_TIME_LIMIT 5 MINUTES

/obj/item/station_charter
	name = "station charter"
	desc = "An official document entrusting the governance of the station and surrounding space to the Captain."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll2"
	// Settings
	/// Whether the charter can only be used once.
	var/one_use = TRUE
	/// Whether the charter can only be used within round start.
	var/has_time_limit = TRUE
	/// How long should the approval timer last, in seconds.
	var/approval_time = 60 SECONDS
	// Variables
	/// Whether the charter was used.
	var/used = FALSE
	/// The current timer handle for admin verification, before automatically declining.
	var/approval_timer = null
	/// The current mob who submitted a name proposal.
	var/mob/proposal_user = null
	/// The current name proposal pending approval.
	var/proposed_name = null
	/// Regex that checks if names can be automatically approved.
	var/static/regex/standard_station_regex

/obj/item/station_charter/Initialize()
	. = ..()
	if(!standard_station_regex)
		var/prefixes = jointext(strings(STATION_NAME_STRINGS, "prefix"), "|")
		var/names = jointext(strings(STATION_NAME_STRINGS, "name"), "|")
		var/suffixes = jointext(strings(STATION_NAME_STRINGS, "suffix"), "|")
		var/list/temp = GLOB.greek_letters + GLOB.phonetic_alphabet + GLOB.numbers_as_words
		for(var/i in 1 to 99)
			temp.Add("[i]", "\Roman[i]")
		var/numerals = jointext(temp, "|")

		var/regexstr = "^(([prefixes]) )?(([names]) ?)([suffixes]) ([numerals])$"
		standard_station_regex = new(regexstr)

/obj/item/station_charter/examine(mob/user)
	. = ..()

	if(one_use && used)
		. += "<span class='notice'>It has already been used.</span>"
	else if(has_time_limit && (world.time - SSticker.round_start_time > STATION_RENAME_TIME_LIMIT))
		. += "<span class='notice'>Now no longer seems like a good time to use it.</span>"
	else if(proposed_name)
		. += "<span class='notice'>A proposal for <b>[proposed_name]</b> is currently under consideration.</span>"
	else if(has_time_limit)
		. += "<span class='notice'>It will expire in <b>[seconds_to_clock((SSticker.round_start_time + STATION_RENAME_TIME_LIMIT - world.time) / 10)]</b>.</span>"
	else
		. += "<span class='notice'>It is available for use.</span>"

/obj/item/station_charter/attack_self(mob/user)
	if(one_use && used)
		to_chat(user, "<span class='warning'>The station has already been named!</span>")
		return
	if(has_time_limit && (world.time - SSticker.round_start_time > STATION_RENAME_TIME_LIMIT))
		to_chat(user, "<span class='warning'>The crew has already settled into the shift. It probably wouldn't be good to rename the station right now.</span>")
		return
	if(approval_timer)
		to_chat(user, "<span class='warning'>You're still waiting for approval from Central Command about your proposed name change, it'd be best to wait for now.</span>")
		return

	var/new_name = stripped_input(user, "What name would you like to give to the station? \
                                         Keep in mind, low quality names may be rejected by Central Command, \
                                         while names following the standard format will automatically be accepted.", "Custom Station Name", max_length = CUSTOM_STATION_NAME_MAXLEN)
	if(!new_name)
		return

	log_game("[key_name(user)] has proposed to name the station as [new_name]")
	proposal_user = user
	proposed_name = new_name

	// Name fits the template, auto-accept
	if(standard_station_regex.Find(new_name))
		to_chat(user, "<span class='notice'>Your station name has been automatically approved.</span>")
		approve_rename(TRUE)
		return

	// Custom names should be vetted
	approval_timer = addtimer(CALLBACK(src, .proc/reject_rename), approval_time, TIMER_STOPPABLE)
	to_chat(user, "<span class='notice'>Your station name has been sent to Central Command for approval.</span>")

	message_admins("<span class='orangeb'>[key_name_admin(user)] wants to rename the station to '[new_name]' (<a href='?src=[UID()];approve=1'>Approve</a>|<a href='?src=[UID()];reject=1'>Reject</a>|<a href='?_src_=holder;CentcommReply=[user.UID()]'>Reply</a>)</span>")
	for(var/client/C in GLOB.admins)
		if(C.prefs.toggles & SOUND_ADMINHELP)
			window_flash(C)
			SEND_SOUND(C, sound('sound/ambience/alarm4.ogg'))

/obj/item/station_charter/Topic(href, href_list)
	if(..())
		return

	if(href_list["approve"])
		approve_rename()
	else if(href_list["reject"])
		reject_rename()

/**
  * Approves the current proposal.
  *
  * Arguments:
  * * user - The mob responsible for the approval.
  * * auto - Whether this is an automatic approval.
  */
/obj/item/station_charter/proc/approve_rename(mob/user, auto = FALSE)
	if(!proposed_name)
		return
	if(user && !(user.client?.holder?.rights & R_ADMIN))
		return

	set_station_name(proposed_name)
	GLOB.captain_announcement.Announce(proposal_user ? "[proposal_user] has designated the station as [proposed_name]." : "The station is now designated as [proposed_name].", new_title = "Captain's Charter")
	log_and_message_admins("has approved the proposed station name '[proposed_name]'[auto ? " (auto-approved)" : ""]")

	name = "station charter for [proposed_name]"
	desc = "An official document entrusting the governance of [proposed_name] and surrounding space to the Captain."
	used = TRUE
	SSblackbox.record_feedback("text", "station_renames", 1, proposed_name)

	cleanup()

/**
  * Rejects the current proposal.
  *
  * Arguments:
  * * user - The mob responsible for the rejection.
  */
/obj/item/station_charter/proc/reject_rename(mob/user)
	if(!proposed_name)
		return
	if(user && !(user.client?.holder?.rights & R_ADMIN))
		return

	visible_message("<span class='warning'>The proposed changes disappear from [src]; it looks like they've been rejected.</span>")
	log_and_message_admins(usr ? "has rejected the proposed station name '[proposed_name]'" : "Proposed station name '[proposed_name]' automatically rejected")

	cleanup()

/**
  * Cleans up the approval variables.
  */
/obj/item/station_charter/proc/cleanup()
	deltimer(approval_timer)
	approval_timer = null
	proposal_user = null
	proposed_name = null

/obj/item/station_charter/unlimited
	one_use = FALSE
	has_time_limit = FALSE

#undef CUSTOM_STATION_NAME_MAXLEN
#undef STATION_RENAME_TIME_LIMIT
