/datum/world_topic_handler/reload_admins
	topic_key = "reload_admins"
	requires_commskey = TRUE

/datum/world_topic_handler/reload_admins/execute(list/input, key_valid)
	message_admins("<span class='boldannounce'>Admin reload request received from a peer server, please wait. If you lose your access, please notify the host immediately.")
	load_admins(TRUE)
