/client/proc/cmd_global_say(msg as text)
	set category = "Admin"
	set name = "Gsay"
	set hidden = TRUE

	if(!check_rights(R_ADMIN))
		return

	msg = sanitize(copytext(msg, 1, MAX_MESSAGE_LEN))
	if(!msg)
		return

	world.msg_peers("gsay", list("ckey" = ckey, "message" = msg, "from" = config.server_name))
	do_global_say(ckey, msg, config.server_name)
	log_globalsay(msg, src)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Gsay")

/proc/do_global_say(ckey, msg, from)
	for(var/client/C in GLOB.admins)
		if(!(R_ADMIN & C.holder.rights))
			continue
		// Lets see if this admin was pinged in the gsay message
		if(findtext(msg, "@[C.ckey]") || findtext(msg, "@[C.key]")) // Check ckey and key, so you can type @AffectedArc07 or @affectedarc07
			SEND_SOUND(C, sound('sound/misc/ping.ogg'))
			msg = replacetext(msg, "@[C.ckey]", "<font color='red'>@[C.ckey]</font>")
			msg = replacetext(msg, "@[C.key]", "<font color='red'>@[C.key]</font>") // Same applies here. key and ckey.

		msg = "<span class='emoji_enabled'>[msg]</span>"
		to_chat(C, "<span class='global_channel'>GLOBAL: <span class='name'>[ckey] ([from]):</span> <span class='message'>[msg]</span></span>")

