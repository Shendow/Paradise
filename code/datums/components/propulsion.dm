/**
  * # Propulsion component
  *
  * Makes the parent [/atom/movable] move towards a direction with a given speed and other parameters.
  */
/datum/component/propulsion
	/// The direction of the propulsion.
	var/direction = NONE
	/// The speed of the propulsion in arbitrary units.
	var/speed = 0
	/// The friction of the propulsion in arbitrary units, aka how much speed it will shed over time.
	var/friction = 0
	/// The current velocity of the propulsion.
	var/velocity = 0
	/// How many cycles before processing again.
	var/remaining_cycles = 0

/datum/component/propulsion/Initialize(_speed = 0, _direction = NONE, _friction = 0.5)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

	speed = _speed
	direction = _direction
	friction = 1 - _friction
	START_PROCESSING(SSfastprocess, src)

/datum/component/propulsion/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/datum/component/propulsion/process(wait)
	if(speed + velocity < 1) // If we can't muster enough velocity to move a tile, we're done
		qdel(src)
		return PROCESS_KILL
	if(remaining_cycles > 0)
		remaining_cycles--
		return

	velocity += speed * (world.tick_lag * wait)
	if(velocity >= 1)
		velocity--
		remaining_cycles = max(0, CEILING(1 / friction, 1) - velocity * friction)
		step(parent, direction)
	speed *= friction
