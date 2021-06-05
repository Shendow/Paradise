/datum/world_topic_handler/round_end
	topic_key = "round_end"
	requires_commskey = TRUE

/datum/world_topic_handler/round_end/execute(list/input, key_valid)
	GLOB.minor_announcement.Announce(input["message"], "News Report")
