/datum/world_topic_handler/ckey_connected
	topic_key = "ckey_connected"
	requires_commskey = TRUE

/datum/world_topic_handler/ckey_connected/execute(list/input, key_valid)
	var/ckey = input["ckey"]
	var/client/C = GLOB.directory[ckey]

	return json_encode(list("connected" = !isnull(C)))
