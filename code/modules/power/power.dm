//////////////////////////////
// POWER MACHINERY BASE CLASS
//////////////////////////////

/////////////////////////////
// Definitions
/////////////////////////////

/obj/machinery/power
	name = null
	icon = 'icons/obj/power.dmi'
	anchored = 1.0
	//var/datum/powernet/powernet = null
	use_power = 0
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/power/Destroy()
	disconnect_from_network()
	..()

///////////////////////////////
// General procedures
//////////////////////////////



/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return

// returns true if the area has power on given channel (or doesn't require power).
// defaults to power_channel
/obj/machinery/proc/powered(var/chan = -1) // defaults to power_channel

	if(!src.loc)
		return 0

	if(!use_power)
		return 1

	var/area/A = src.loc.loc		// make sure it's in an area
	if(!A || !isarea(A) || !A.master)
		return 0					// if not, then not powered
	if(chan == -1)
		chan = power_channel
	return A.master.powered(chan)	// return power status of the area

// increment the power usage stats for an area
/obj/machinery/proc/use_power(var/amount, var/chan = -1) // defaults to power_channel
	var/area/A = get_area(src)		// make sure it's in an area
	if(!A || !isarea(A) || !A.master)
		return
	if(chan == -1)
		chan = power_channel
	A.master.use_power(amount, chan)

/obj/machinery/proc/addStaticPower(value, powerchannel)
	var/area/A = get_area(src)
	if(!A || !A.master)
		return
	A.master.addStaticPower(value, powerchannel)

/obj/machinery/proc/removeStaticPower(value, powerchannel)
	addStaticPower(-value, powerchannel)

/obj/machinery/proc/power_change()		// called whenever the power settings of the containing area change
										// by default, check equipment channel & set flag
										// can override if needed
	if(powered(power_channel))
		stat &= ~NOPOWER
	else

		stat |= NOPOWER
	return

// connect the machine to a powernet if a node cable is present on the turf
/obj/machinery/power/proc/connect_to_network()
	var/turf/T = src.loc
	if(!T || !istype(T))
		return 0

	var/obj/structure/cable/cableOnTurf = T.get_cable_node() //check if we have a node cable on the machine turf, the first found is picked
	if(cableOnTurf==null || cableOnTurf.parentNetwork==null)
		return 0

	cableOnTurf.parentNetwork.add(src)
	return 1

// remove and disconnect the machine from its current powernet
/obj/machinery/power/proc/disconnect_from_network()
	if(powerNode.parentNetwork==null)
		return 0
	powerNode.parentNetwork.remove(powerNode)
	return 1

// attach a wire to a power machine - leads from the turf you are standing on
//almost never called, overwritten by all power machines but terminal and generator
/obj/machinery/power/attackby(obj/item/weapon/W, mob/user)

	if(istype(W, /obj/item/stack/cable_coil))

		var/obj/item/stack/cable_coil/coil = W

		var/turf/T = user.loc

		if(T.intact || !istype(T, /turf/simulated/floor))
			return

		if(get_dist(src, user) > 1)
			return

		coil.turf_place(T, user)
		return
	else
		..()
	return

///////////////////////////////////////////
// Powernet handling helpers
//////////////////////////////////////////

//returns all the cables WITHOUT a powernet in neighbors turfs,
//pointing towards the turf the machine is located at
/obj/machinery/power/proc/get_connections()

	. = list()

	var/cdir
	var/turf/T

	for(var/card in cardinal)
		T = get_step(loc,card)
		cdir = get_dir(T,loc)

		for(var/obj/structure/cable/C in T)
			if(C.parentNetwork !=null)
				continue
			if(C.d1 == cdir || C.d2 == cdir)
				. += C
	return .

//returns all the cables in neighbors turfs,
//pointing towards the turf the machine is located at
/obj/machinery/power/proc/get_marked_connections()

	. = list()

	var/cdir
	var/turf/T

	for(var/card in cardinal)
		T = get_step(loc,card)
		cdir = get_dir(T,loc)

		for(var/obj/structure/cable/C in T)
			if(C.d1 == cdir || C.d2 == cdir)
				. += C
	return .

//returns all the NODES (O-X) cables WITHOUT a powernet in the turf the machine is located at
/obj/machinery/power/proc/get_indirect_connections()
	. = list()
	for(var/obj/structure/cable/C in loc)
		if(C.parentNetwork !=null)
			continue
		if(C.d1 == 0) // the cable is a node cable
			. += C
	return .

///////////////////////////////////////////
// GLOBAL PROCS for powernets handling
//////////////////////////////////////////


// returns a list of all power-related objects (nodes, cable, junctions) in turf,
// excluding source, that match the direction d
// if unmarked==1, only return those with no powernet
/proc/power_list(var/turf/T, var/source, var/d, var/unmarked=0, var/cable_only = 0)
	. = list()
	//var/fdir = (!d)? 0 : turn(d, 180)			// the opposite direction to d (or 0 if d==0)

	for(var/AM in T)
		if(AM == source)	continue			//we don't want to return source

		if(!cable_only && istype(AM,/obj/machinery/power))
			var/obj/machinery/power/P = AM


			if(!unmarked || !P.powerNode.parentNetwork)		//if unmarked=1 we only return things with no powernet
				if(d == 0)
					. += P

		else if(istype(AM,/obj/structure/cable))
			var/obj/structure/cable/C = AM

			if(!unmarked || C.parentNetwork !=null)
				if(C.d1 == d || C.d2 == d)
					. += C
	return .


// rebuild all power networks from scratch - only called at world creation or by the admin verb
/proc/makepowernets()

	for(var/obj/structure/cable/currentCableNode in cable_list)
		if(currentCableNode.parentNetwork == null)
			var/datum/wire_network/newWireNetwork = new /datum/wire_network
			propagate_network(currentCableNode,newWireNetwork,null)


//remove the old powernet and replace it with a new one throughout the network.
/*
	Propagate network along wires


*/
/proc/propagate_network(var/obj/structure/cable/powerNodeSpaceWithoutNetowrk
, var/datum/wire_network/toPropagate, var/datum/wire_network/toReplace)
	//world.log << "propagating new network"


	//This contains a list of objects that have a parentNode var
	var/list/toProcessCable = list()

	toProcessCable+=toPropagate;

	//Propagate along wires
	while(toProcessCable.len >0)
		//Pop first element
		var/obj/structure/cable/currentNode = toProcessCable.Cut(1,2)

		if(currentNode.parentNetwork==toReplace)
			currentNode.parentNetwork = toPropagate

			//This gets adjacent dables and adds them to the queue
			var/cdir
			var/turf/T
			for(var/card in cardinal)
				T = get_step(currentNode.loc,card)
				cdir = get_dir(T,currentNode.loc)
				for(var/obj/structure/cable/C in T)
					if(C.d1 == cdir || C.d2 == cdir)
						toProcessCable+= C

			//Attach any machines if found on this space
			for(var/obj/machinery/machine in src)
				var/datum/power/PowerNode/machinepowerNode = machine.powerNode
				if(machinepowerNode!=null && machine.anchored && machinepowerNode.parentNetwork == toReplace)
					//remove machine from existing network and add to new one
					var/datum/wire_network/machineparentNetwork = machinepowerNode.parentNetwork
					if(machineparentNetwork!=null)
					 	//The machine is currently atached to a network, remove it
						machineparentNetwork.remove(machinepowerNode)

					//now add machine to new network if one exists. it should, but to suppor the off case where one
					// would want to propagate null for what ever reason. I'll put a check in.
					if(toPropagate!=null)
						machinepowerNode.parentNetwork = toPropagate
						world << "power connecting machine [machinepowerNode.setName]"
						toPropagate.add(machinepowerNode)




//Merge two powernets, the bigger (in cable length term) absorbing the other
/proc/merge_powernets(var/datum/powernet/net1, var/datum/powernet/net2)
	/*

	TODO Folix: Write merge logic
	*/

	return

	/*
	if(!net1 || !net2) //if one of the powernet doesn't exist, return
		return

	if(net1 == net2) //don't merge same powernets
		return

	//We assume net1 is larger. If net2 is in fact larger we are just going to make them switch places to reduce on code.
	if(net1.cables.len < net2.cables.len)	//net2 is larger than net1. Let's switch them around
		var/temp = net1
		net1 = net2
		net2 = temp

	//merge net2 into net1
	for(var/obj/structure/cable/Cable in net2.cables) //merge cables
		net1.add_cable(Cable)

	for(var/obj/machinery/power/Node in net2.nodes) //merge power machines
		if(!Node.connect_to_network())
			Node.disconnect_from_network() //if somehow we can't connect the machine to the new powernet, disconnect it from the old nonetheless

	return net1
*/
//Determines how strong could be shock, deals damage to mob, uses power.
//M is a mob who touched wire/whatever
//power_source is a source of electricity, can be powercell, area, apc, cable, powernet or null
//source is an object caused electrocuting (airlock, grille, etc)
//No animations will be performed by this proc.
/proc/electrocute_mob(mob/living/carbon/M as mob, var/power_source, var/obj/source, var/siemens_coeff = 1.0)
/* TODO FOLIX: this logic


	if(istype(M.loc,/obj/mecha))	return 0	//feckin mechs are dumb
	if(istype(M,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.siemens_coefficient == 0)	return 0		//to avoid spamming with insulated glvoes on

	var/area/source_area
	if(istype(power_source,/area))
		source_area = power_source
		power_source = source_area.get_apc()
	if(istype(power_source,/obj/structure/cable))
		var/obj/structure/cable/Cable = power_source
		power_source = Cable.powernet

	var/datum/powernet/PN
	var/obj/item/weapon/stock_parts/cell/cell

	if(istype(power_source,/datum/powernet))
		PN = power_source
	else if(istype(power_source,/obj/item/weapon/stock_parts/cell))
		cell = power_source
	else if(istype(power_source,/obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = power_source
		cell = apc.cell
		if (apc.terminal)
			PN = apc.terminal.powernet
	else if (!power_source)
		return 0
	else
		log_admin("ERROR: /proc/electrocute_mob([M], [power_source], [source]): wrong power_source")
		return 0
	if (!cell && !PN)
		return 0
	var/PN_damage = 0
	var/cell_damage = 0
	if (PN)
		PN_damage = PN.get_electrocute_damage()
	if (cell)
		cell_damage = cell.get_electrocute_damage()
	var/shock_damage = 0
	if (PN_damage>=cell_damage)
		power_source = PN
		shock_damage = PN_damage
	else
		power_source = cell
		shock_damage = cell_damage
	var/drained_hp = M.electrocute_act(shock_damage, source, siemens_coeff) //zzzzzzap!
	var/drained_energy = drained_hp*20

	if (source_area)
		source_area.use_power(drained_energy/CELLRATE)
	else if (istype(power_source,/datum/powernet))
		var/drained_power = drained_energy/CELLRATE //convert from "joules" to "watts"
		PN.load+=drained_power
	else if (istype(power_source, /obj/item/weapon/stock_parts/cell))
		cell.use(drained_energy)
	return drained_energy
*/
////////////////////////////////////////////
// POWERNET DATUM PROCS
// each contiguous network of cables & nodes
////////////////////////////////////////////

/datum/powernet/New()
	powernets += src

/datum/powernet/Destroy()
	powernets -= src
/*
/datum/powernet/proc/is_empty()
	return !cables.len && !nodes.len

//remove a cable from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/remove_cable(var/obj/structure/cable/C)
	cables -= C
	C.parentNetwork = null
	if(is_empty())//the powernet is now empty...
		qdel(src)///... delete it


//add a cable to the current powernet
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/add_cable(var/obj/structure/cable/C)
	if(C.parentNetwork != null)// if C already has a powernet...
		if(C.parentNetwork == src.parentNetwork)
			return
		else
			C.parentNetwork = null //..remove it
	C.parentNetwork = src.powerNode.parentNetwork
	cables +=C

//remove a power machine from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/remove_machine(var/obj/machinery/power/M)
	nodes -=M
	M.powernet = null
	if(is_empty())//the powernet is now empty...
		qdel(src)///... delete it


//add a power machine to the current powernet
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/add_machine(var/datum/power/PowerNode/M)
	if(M.parentNetwork)// if M already has a powernet...
		if(M.parentNetwork == powerNode.ParentNetwork)
			return
		else
			M.disconnect_from_network()//..remove it
	powerNode.parentNetwork.add(M)
	nodes[M] = M

//handles the power changes in the powernet
//called every ticks by the powernet controller
/datum/powernet/proc/reset()

	//see if there's a surplus of power remaining in the powernet and stores unused power in the SMES
	netexcess = avail - load

	if(netexcess > 100 && nodes && nodes.len)		// if there was excess power last cycle
		for(var/obj/machinery/power/smes/S in nodes)	// find the SMESes in the network
			S.restore()				// and restore some of the power that was used

	//updates the viewed load (as seen on power computers)
	viewload = 0.8*viewload + 0.2*load
	viewload = round(viewload)

	//reset the powernet
	load = 0
	avail = newavail
	newavail = 0

/datum/powernet/proc/get_electrocute_damage()
	switch(avail)/*
		if (1300000 to INFINITY)
			return min(rand(70,150),rand(70,150))
		if (750000 to 1300000)
			return min(rand(50,115),rand(50,115))
		if (100000 to 750000-1)
			return min(rand(35,101),rand(35,101))
		if (75000 to 100000-1)
			return min(rand(30,95),rand(30,95))
		if (50000 to 75000-1)
			return min(rand(25,80),rand(25,80))
		if (25000 to 50000-1)
			return min(rand(20,70),rand(20,70))
		if (10000 to 25000-1)
			return min(rand(20,65),rand(20,65))
		if (1000 to 10000-1)
			return min(rand(10,20),rand(10,20))*/
		if (1000000 to INFINITY)
			return min(rand(50,160),rand(50,160))
		if (200000 to 1000000)
			return min(rand(25,80),rand(25,80))
		if (100000 to 200000)//Ave powernet
			return min(rand(20,60),rand(20,60))
		if (50000 to 100000)
			return min(rand(15,40),rand(15,40))
		if (1000 to 50000)
			return min(rand(10,20),rand(10,20))
		else
			return 0
*/
////////////////////////////////////////////////
// Misc.
///////////////////////////////////////////////


// return a knot cable (O-X) if one is present in the turf
// null if there's none
/turf/proc/get_cable_node()
	if(!istype(src, /turf/simulated/floor))
		return null
	for(var/obj/structure/cable/C in src)
		if(C.d1 == 0)
			return C
	return null

/area/proc/get_apc()
	for(var/area/RA in src.related)
		var/obj/machinery/power/apc/FINDME = locate() in RA
		if (FINDME)
			return FINDME