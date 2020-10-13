/**
  * # Syndicate Hub
  *
  * Describes and manages the contracts and rewards for a single contractor.
  */
/datum/contractor_hub
	// Settings
	/// The number of contracts to generate initially.
	var/num_contracts = 6
	/// How much Contractor Rep to earn per contract completion.
	var/rep_per_completion = 2
	/// Completing every contract at a given difficulty will always result in a sum of TC greater or equal than the difficulty's threshold.
	/// Structure: EXTRACTION_DIFFICULTY_(EASY|MEDIUM|HARD) => number
	var/difficulty_tc_thresholds = list(
		EXTRACTION_DIFFICULTY_EASY = 30,
		EXTRACTION_DIFFICULTY_MEDIUM = 40,
		EXTRACTION_DIFFICULTY_HARD = 50,
	)
	/// Maximum variation a single contract's TC reward can have upon generation.
	/// In other words: final_reward = CEILING((tc_threshold / num_contracts) * (1 + (rand(-100, 100) / 100) * tc_variation), 1)
	var/tc_variation = 0.25
	/// TC reward multiplier if the target was extracted DEAD. Should be a penalty so between 0 and 1.
	/// The final amount is rounded up.
	var/dead_penalty = 0.2
	#warn: TODO: Rep items
	// Variables
	/// The contractor associated to this hub.
	var/datum/mind/owner = null
	/// The uplink associated to this hub.
	var/obj/item/contractor_uplink/uplink = null
	/// The current contract in progress.
	var/datum/syndicate_contract/current_contract = null
	/// The contracts offered by the hub.
	var/list/datum/syndicate_contract/contracts = null
	/// List of targets from each contract in [/datum/contractor_hub/var/contracts].
	/// Used to make sure two contracts from the same hub don't have the same target.
	var/list/datum/mind/targets = null
	/// Amount of telecrystals available for redeeming.
	var/reward_tc_available = 0
	/// Total amount of paid out telecrystals since the start.
	var/reward_tc_paid_out = 0
	/// The number of completed contracts.
	var/completed_contracts = 0
	/// Amount of Contractor Rep available for spending.
	var/rep = 0
	/// The TGUI module associated with this hub.
	var/datum/tgui_module/contractor_uplink/tgui = null

/datum/contractor_hub/New(datum/mind/O, obj/item/contractor_uplink/U)
	owner = O
	uplink = U
	tgui = new(U)
	tgui.hub = src
	generate_contracts()

/datum/contractor_hub/tgui_interact(mob/user)
	return tgui.tgui_interact(user)

/**
  * Regenerates a list of contracts for the contractor to take up.
  */
/datum/contractor_hub/proc/generate_contracts()
	contracts = list()
	targets = list()

	var/num_to_generate = min(num_contracts, length(GLOB.data_core.locked))
	if(num_to_generate <= 0) // ?
		return

	// Contract generation
	var/total_earnable_tc = list(0, 0, 0)
	for(var/i in 1 to num_to_generate)
		var/datum/syndicate_contract/C = new(src, owner, targets)
		// Calculate TC reward for each difficulty
		C.reward_tc = list(null, null, null)
		for(var/difficulty in EXTRACTION_DIFFICULTY_EASY to EXTRACTION_DIFFICULTY_HARD)
			var/amount_tc = calculate_tc_reward(num_to_generate, difficulty)
			C.reward_tc[difficulty] = amount_tc
			total_earnable_tc[difficulty] += amount_tc
		// Add to lists
		contracts += C
		targets += C.contract.target

	// Fill the gap if a difficulty doesn't meet the TC threshold
	for(var/difficulty in EXTRACTION_DIFFICULTY_EASY to EXTRACTION_DIFFICULTY_HARD)
		var/total = total_earnable_tc[difficulty]
		var/missing = difficulty_tc_thresholds[difficulty] - total
		if(missing <= 0)
			continue
		// Just add the missing TC to a random contract
		var/datum/syndicate_contract/C = pick(contracts)
		C?.reward_tc[difficulty] += missing

/**
  * Generates an amount of TC to be used as a contract reward for the given difficulty.
  *
  * Arguments:
  * * total_contracts - The number of contracts being generated.
  * * difficulty - The difficulty to base the threshold from.
  */
/datum/contractor_hub/proc/calculate_tc_reward(total_contracts, difficulty = EXTRACTION_DIFFICULTY_EASY)
	ASSERT(total_contracts > 0)
	return CEILING((difficulty_tc_thresholds[difficulty] / total_contracts) * (1 + (rand(-100, 100) / 100) * tc_variation), 1)

/**
  * Gives any unclaimed TC to the given mob.
  *
  * Arguments:
  * * M - The mob to give the TC to.
  */
/datum/contractor_hub/proc/claim_tc(mob/living/M)
	if(reward_tc_available <= 0)
		return

	// Spawn the crystals
	var/obj/item/stack/telecrystal/TC = new(get_turf(M), reward_tc_available)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.put_in_hands(TC))
			to_chat(H, "<span class='notice'>Your payment materializes into your hands!</span>")
		else
			to_chat(M, "<span class='notice'>Your payment materializes on the floor.</span>")
	// Update info
	reward_tc_paid_out += reward_tc_available
	reward_tc_available = 0
