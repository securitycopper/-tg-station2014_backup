/obj/machinery/igniter
	name = "igniter"
	desc = "It's useful for igniting plasma."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "igniter1"
	var/id = null
	var/on = 1.0
	anchored = 1.0


/obj/machinery/igniter/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/igniter/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/igniter/attack_hand(mob/user as mob)
	if(..())
		return
	add_fingerprint(user)

	src.on = !( src.on )
	src.icon_state = text("igniter[]", src.on)
	return

/obj/machinery/igniter/process()	//ugh why is this even in process()?
	if (src.on && !(stat & NOPOWER) )
		var/turf/location = src.loc
		if (isturf(location))
			location.hotspot_expose(1000,500,1)
	return 1

/obj/machinery/igniter/New()
	..()

	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = name
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad = POWERNODECONSTS_IGNITER_CONSTANT_LOAD
	powerNode.update(loc)

	icon_state = "igniter[on]"

/obj/machinery/igniter/power_change()
	if(!( stat & NOPOWER) )
		icon_state = "igniter[src.on]"
	else
		icon_state = "igniter0"

// Wall mounted remote-control igniter.

/obj/machinery/sparker
	name = "mounted igniter"
	desc = "A wall-mounted ignition device."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "migniter"
	var/id = null
	var/disable = 0
	var/last_spark = 0
	var/base_state = "migniter"
	anchored = 1

/obj/machinery/sparker/New()
	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = name
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad = POWERNODECONSTS_IGNITER_IDLE_LOAD


	powerNode.update(loc)


	..()

/obj/machinery/sparker/power_change()
	if ( powered() && disable == 0 )
		stat &= ~NOPOWER
		icon_state = "[base_state]"
//		src.sd_SetLuminosity(2)
	else
		stat |= ~NOPOWER
		icon_state = "[base_state]-p"
//		src.sd_SetLuminosity(0)

/obj/machinery/sparker/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/device/detective_scanner))
		return
	if (istype(W, /obj/item/weapon/screwdriver))
		add_fingerprint(user)
		src.disable = !src.disable
		if (src.disable)
			user.visible_message("<span class='danger'>[user] has disabled the [src]!</span>", "<span class='danger'>You disable the connection to the [src].</span>")
			icon_state = "[base_state]-d"
		if (!src.disable)
			user.visible_message("<span class='danger'>[user] has reconnected the [src]!</span>", "<span class='danger'>You fix the connection to the [src].</span>")
			if(src.powered())
				icon_state = "[base_state]"
			else
				icon_state = "[base_state]-p"

/obj/machinery/sparker/attack_ai()
	if (src.anchored)
		return src.ignite()
	else
		return

/obj/machinery/sparker/proc/ignite()
	if (!(powered()))
		return

	if ((src.disable) || (src.last_spark && world.time < src.last_spark + 50))
		return


	flick("[base_state]-spark", src)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(2, 1, src)
	s.start()
	src.last_spark = world.time
	powerUtils.use_power(powerNode,POWERNODECONSTS_IGNITER_ACTIVE_LOAD,POWERNODECONSTS_IGNITER_ACTIVE_TICKS)
	var/turf/location = src.loc
	if (isturf(location))
		location.hotspot_expose(1000,500,1)
	return 1

/obj/machinery/sparker/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	ignite()
	..(severity)

/obj/machinery/ignition_switch/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/ignition_switch/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/ignition_switch/attackby(obj/item/weapon/W, mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/ignition_switch/attack_hand(mob/user as mob)

	if(stat & (NOPOWER|BROKEN))
		return
	if(active)
		return


	active = 1
	icon_state = "launcheract"

	for(var/obj/machinery/sparker/M in world)
		if (M.id == src.id)
			spawn( 0 )
				M.ignite()

	for(var/obj/machinery/igniter/M in world)
		if(M.id == src.id)
			powerUtils.use_power(powerNode,POWERNODECONSTS_IGNITER_ACTIVE_LOAD_HAND_USE,POWERNODECONSTS_IGNITER_ACTIVE_TICKS)
			M.on = !( M.on )
			M.icon_state = text("igniter[]", M.on)

	sleep(50)

	icon_state = "launcherbtt"
	active = 0

	return