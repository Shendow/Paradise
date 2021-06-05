/datum/world_topic_handler/gsay
	topic_key = "gsay"
	requires_commskey = TRUE

/datum/world_topic_handler/gsay/execute(list/input, key_valid)
	do_global_say(input["ckey"], input["message"], input["from"])
