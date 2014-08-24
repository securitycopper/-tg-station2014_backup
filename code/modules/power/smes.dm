// the SMES
// stores power

#define SMESRATE 0.05			// rate of internal charge to external power

/obj/machinery/power/smes
	name = "power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit."
	icon_state = "smes"
	density = 1
	anchored = 1
//	use_power = 0
//	var/capacity = 0 //PowerNode: this is kept only to support the orgional map configuration. The value is only checked once
	var/charge = 1e6 //PowerNode: this is kept only to support the orgional map configuration. The value is only checked once

//	var/input_attempt = 0 // 1 = attempting to charge, 0 = not attempting to charge
	//var/inputting = 0 // 1 = actually inputting, 0 = not inputting
	//var/input_level = 50000 // amount of power the SMES attempts to charge by
	var/input_level_max = 200000 // cap on input_level
//	var/input_available = 0 // amount of charge available from input last tick

//	var/output_attempt = 1 // 1 = attempting to output, 0 = not attempting to output
//	var/outputting = 1 // 1 = actually outputting, 0 = not outputting
//	var/output_level = 50000 // amount of power the SMES attempts to output
	//var/output_level_max = 200000 // cap on output_level
//	var/output_used = 0 // amount of power actually outputted. may be less than output_level if the powernet returns excess power

	var/obj/machinery/power/terminal/terminal = null


/obj/machinery/power/smes/New()
	..()

	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = "Smes"
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad = 10
	powerNode.setCurrentLoad = 0
	powerNode.setParentNetworkAttachesOnThisSpace = 0

	//for solar, min and max will match
	powerNode.setMaxPotentialSupply = 0
	powerNode.setCurrentSupply = 0

	//Battery options
	powerNode.setHasBattery=1
	powerNode.setBatteryMaxCapacity=5e6
	powerNode.calculatedBatteryStoredEnergy = 1e6
	powerNode.setBatteryChargeRate=50000
	powerNode.setBatteryMaxDischargeRate=200000


	if(charge!=0)
		powerNode.calculatedBatteryStoredEnergy = charge

	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/smes(null)
	component_parts += new /obj/item/weapon/stock_parts/cell/high(null)
	component_parts += new /obj/item/weapon/stock_parts/cell/high(null)
	component_parts += new /obj/item/weapon/stock_parts/cell/high(null)
	component_parts += new /obj/item/weapon/stock_parts/cell/high(null)
	component_parts += new /obj/item/weapon/stock_parts/cell/high(null)
	component_parts += new /obj/item/weapon/stock_parts/capacitor(null)
	component_parts += new /obj/item/stack/cable_coil(null, 5)
	RefreshParts()
	spawn(5)
		dir_loop:
			for(var/d in cardinal)
				var/turf/T = get_step(src, d)
				for(var/obj/machinery/power/terminal/term in T)
					if(term && term.dir == turn(d, 180))
						terminal = term
						break dir_loop

		if(!terminal)
			stat |= BROKEN
			return
		terminal.master = src
		update_icon()
	return

/obj/machinery/power/smes/RefreshParts()
	var/IO = 0
	var/C = 0
	for(var/obj/item/weapon/stock_parts/capacitor/CP in component_parts)
		IO += CP.rating
	powerNode.setBatteryChargeRate = 200000 * IO
	powerNode.setBatteryMaxDischargeRate = 200000 * IO
	for(var/obj/item/weapon/stock_parts/cell/PC in component_parts)
		C += PC.maxcharge
	powerNode.setBatteryMaxCapacity = C / (15000) * 1e6
	powerNode.update()

/obj/machinery/power/smes/attackby(obj/item/I, mob/user)
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-o", initial(icon_state), I))
		update_icon()
		return

	if(default_change_direction_wrench(user, I))
		terminal = null
		var/turf/T = get_step(src, dir)
		for(var/obj/machinery/power/terminal/term in T)
			if(term && term.dir == turn(dir, 180))
				terminal = term
				terminal.master = src
				user << "<span class='notice'>Terminal found.</span>"
				break
		if(!terminal)
			for(var/obj/structure/cable/C in T)
				if(C.d1 == turn(dir, 180) || C.d2 == turn(dir, 180))
					terminal = C
					user << "<span class='notice'>Cable found.</span>"
					break
		if(!terminal)
			user << "<span class='alert'>No power source found.</span>"
			return
		stat &= ~BROKEN
		update_icon()
		return

	if(exchange_parts(user, I))
		return

	default_deconstruction_crowbar(I)

/obj/machinery/power/smes/Destroy()
	if(ticker && ticker.current_state == GAME_STATE_PLAYING)
		var/area/area = get_area(src)
		message_admins("SMES deleted at (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[x];Y=[y];Z=[z]'>[area.name]</a>)")
		log_game("SMES deleted at ([area.name])")
		investigate_log("<font color='red'>deleted</font> at ([area.name])","singulo")
	if(terminal)
		disconnect_terminal()
	..()

/obj/machinery/power/smes/disconnect_terminal()
	if(terminal)
		terminal.master = null
		terminal = null


/obj/machinery/power/smes/update_icon()
	overlays.Cut()
	if(stat & BROKEN)	return

	if(panel_open)
		return


	overlays += image('icons/obj/power.dmi', "smes-op[powerNode.calculatedCurrentBatteryDistargeRate]")

	if(powerNode.isOn ==1 && powerNode.setBatteryChargeRate>0)
		overlays += image('icons/obj/power.dmi', "smes-oc1")
	else
		if(powerNode.setBatteryChargeRate)
			overlays += image('icons/obj/power.dmi', "smes-oc0")

	var/clevel = chargedisplay()
	if(clevel>0)
		overlays += image('icons/obj/power.dmi', "smes-og[clevel]")
	return


/obj/machinery/power/smes/proc/chargedisplay()
	return round(5.5*powerNode.calculatedBatteryStoredEnergy/powerNode.setBatteryMaxCapacity)

/obj/machinery/power/smes/process()

	if(stat & BROKEN)	return

	//store machine state to see if we need to update the icon overlays
	//var/last_disp = chargedisplay()
	//var/last_chrg = inputting
	//var/last_onln = outputting

	var/datum/wire_network/terminalWireNetwork = powerNode.parentNetwork
/*
	//inputting
	if(terminalWireNetwork && input_attempt)

		input_available = terminalWireNetwork.wireNetworkMaxPotentialSupply - terminalWireNetwork.wireNetworkCurrentSupply

		if(inputting)
			if(input_available > 0 && input_available >= input_level)		// if there's power available, try to charge

				var/load = min((capacity-charge)/SMESRATE, input_level)		// charge at set rate, limited to spare capacity

				charge += load * SMESRATE	// increase the charge

				add_load(load)		// add the load to the terminal side network

			else					// if not enough capcity
				inputting = 0		// stop inputting

		else
			if(input_attempt && input_available > 0 && input_available >= input_level)
				inputting = 1
*/
/*
	//outputting
	if(outputting)
		output_used = min( charge/SMESRATE, output_level)		//limit output to that stored

		charge -= output_used*SMESRATE		// reduce the storage (may be recovered in /restore() if excessive)

		add_avail(output_used)				// add output to powernet (smes side)

		if(output_used < 0.0001)			// either from no charge or set to 0
			outputting = 0
			investigate_log("lost power and turned <font color='red'>off</font>","singulo")
	else if(output_attempt && charge > output_level && output_level > 0)
		outputting = 1
	else
		output_used = 0
*/
	// only update icon if state changed
	if(terminalWireNetwork != null)
		update_icon()



// called after all power processes are finished
// restores charge level to smes if there was excess this ptick
/obj/machinery/power/smes/proc/restore()
	//Only power that is needed is drained from batteries with the PowerNode System so this logic goes away
	/*
	if(stat & BROKEN)
		return

	if(!outputting)
		output_used = 0
		return

	//var/excess = powernet.netexcess		// this was how much wasn't used on the network last ptick, minus any removed by other SMESes

	//excess = min(output_used, excess)				// clamp it to how much was actually output by this SMES last ptick

	//excess = min((capacity-charge)/SMESRATE, excess)	// for safety, also limit recharge by space capacity of SMES (shouldn't happen)

	// now recharge this amount

	var/clev = chargedisplay()

	charge += excess * SMESRATE			// restore unused power
	powernet.netexcess -= excess		// remove the excess from the powernet, so later SMESes don't try to use it

	output_used -= excess

	if(clev != chargedisplay() ) //if needed updates the icons overlay
		update_icon()
		*/
	return


/*/obj/machinery/power/smes/add_load(var/amount)
	if(terminal && terminal.powernet)
		terminal.powernet.load += amount
*/

/obj/machinery/power/smes/attack_ai(mob/user)
	if(stat & BROKEN) return
	ui_interact(user)


/obj/machinery/power/smes/attack_hand(mob/user)
	add_fingerprint(user)
	if(stat & BROKEN) return
	ui_interact(user)


/obj/machinery/power/smes/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null)
	if(!user)
		return

	var/inputAvailable = 0
	if(powerNode.parentNetwork != null)
		inputAvailable = powerNode.parentNetwork.wireNetworkMaxPotentialSupply -powerNode.parentNetwork.wireNetworkLoad
	var/list/data = list(
		"capacityPercent" = round(100.0*powerNode.calculatedBatteryStoredEnergy/powerNode.setBatteryMaxCapacity, 0.1),
		"capacity" = powerNode.setBatteryMaxCapacity,
		"charge" = powerNode.calculatedBatteryStoredEnergy,

		"inputAttempt" = powerNode.setBatteryChargeRate,
		"inputting" = powerNode.setBatteryChargeRate,
		"inputLevel" = powerNode.setBatteryChargeRate,
		"inputLevelMax" = input_level_max,
		"inputAvailable" = inputAvailable,

		"outputAttempt" = powerNode.calculatedCurrentBatteryDistargeRate,
		"outputting" = powerNode.calculatedCurrentBatteryDistargeRate,
		"outputLevel" = min(powerNode.setBatteryMaxDischargeRate, powerNode.calculatedBatteryStoredEnergy),
		"outputLevelMax" = powerNode.setBatteryMaxDischargeRate,
		"outputUsed" = powerNode.calculatedCurrentBatteryDistargeRate
	)

	// update the ui if it exists, returns null if no ui is passed/found
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "smes.tmpl", "SMES - [name]", 350, 560)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()
		// auto update every Master Controller tick
		ui.set_auto_update(1)

/obj/machinery/power/smes/Topic(href, href_list)
//	world << "[href] ; [href_list[href]]"

	if(..())
		return


	else if( href_list["input_attempt"] )
		powerNode.setBatteryChargeRate = text2num(href_list["input_attempt"])
		if(!powerNode.setBatteryChargeRate)
			powerNode.setBatteryChargeRate = 0
		log_smes(usr.ckey)
		update_icon()

	else if( href_list["output_attempt"] )
		powerNode.setBatteryMaxDischargeRate = text2num(href_list["output_attempt"])
		if(!powerNode.setBatteryMaxDischargeRate)
			powerNode.setBatteryMaxDischargeRate = 0
		log_smes(usr.ckey)
		update_icon()

	else if( href_list["set_input_level"] )
		switch(href_list["set_input_level"])
			if("max")
				powerNode.setBatteryChargeRate = input_level_max
			if("custom")
				var/custom = input(usr, "What rate would you like this SMES to attempt to charge at? Max is [input_level_max].") as null|num
				if(isnum(custom))
					href_list["set_input_level"] = custom
					.()
			if("plus")
				powerNode.setBatteryChargeRate += 10000
			if("minus")
				powerNode.setBatteryChargeRate -= 10000
			else
				var/n = text2num(href_list["set_input_level"])
				if(isnum(n))
					powerNode.setBatteryChargeRate = n

		powerNode.setBatteryChargeRate = Clamp(powerNode.setBatteryChargeRate, 0, input_level_max)
		log_smes(usr.ckey)


	else if(href_list["set_output_level"])
		switch(href_list["set_output_level"])
			if("max")
				powerNode.setBatteryMaxDischargeRate = INFINITY
			if("custom")
				var/custom = input(usr, "What rate would you like this SMES to attempt to output at? Max is [INFINITY].") as null|num
				if(isnum(custom))
					href_list["set_output_level"] = custom
					.()
			if("plus")
				powerNode.setBatteryMaxDischargeRate += 10000
			if("minus")
				powerNode.setBatteryMaxDischargeRate -= 10000
			else
				var/n = text2num(href_list["set_output_level"])
				if(isnum(n))
					powerNode.setBatteryMaxDischargeRate = n

		//TODO Folix: Check this logic
		powerNode.setBatteryMaxDischargeRate = Clamp(powerNode.setBatteryMaxDischargeRate, 0, INFINITY)

		log_smes(usr.ckey)

	powerNode.update()
/obj/machinery/power/smes/proc/log_smes(var/user = "")
	investigate_log("input/output; [powerNode.setBatteryChargeRate>powerNode.setBatteryMaxDischargeRate?"<font color='green'>":"<font color='red'>"][powerNode.setBatteryChargeRate]/[powerNode.setBatteryMaxDischargeRate]</font> | Charge: [powerNode.calculatedBatteryStoredEnergy] | Output-mode: [powerNode.setBatteryMaxDischargeRate?"<font color='green'>on</font>":"<font color='red'>off</font>"] | Input-mode: [powerNode.setBatteryChargeRate?"<font color='green'>auto</font>":"<font color='red'>off</font>"] by [user]","singulo")


/obj/machinery/power/smes/emp_act(severity)
	//new emp behavior,

	//Turn off charge
	if(rand(0,1)==0)
		powerNode.setBatteryChargeRate =0


	//Turn off output
	if(rand(0,1)==0)
		powerNode.setBatteryMaxDischargeRate = rand(0, min( powerNode.setBatteryMaxDischargeRate, powerNode.calculatedBatteryStoredEnergy))




	//input_attempt = rand(0,1)




//	inputting = input_attempt
//	output_attempt = rand(0,1)
//	outputting = output_attempt
//	output_level = rand(0, output_level_max)
	powerNode.setBatteryChargeRate = rand(0, input_level_max)
	powerNode.calculatedBatteryStoredEnergy -= 1e6/severity
	if (powerNode.calculatedBatteryStoredEnergy < 0)
		powerNode.calculatedBatteryStoredEnergy = 0

	powerNode.update()
	update_icon()
	log_smes("an emp")
	..()



/obj/machinery/power/smes/magical
	name = "magical power storage unit"
	desc = "A high-capacity superconducting magnetic energy storage (SMES) unit. Magically produces power."
	process()
		powerNode.setBatteryMaxCapacity = INFINITY
		powerNode.calculatedBatteryStoredEnergy = INFINITY
		..()


#undef SMESRATE