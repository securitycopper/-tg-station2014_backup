
var/global/datum/power/PowerNodeUtils/powerUtils = new /datum/power/PowerNodeUtils()



/datum/power/PowerNodeUtils

//The goal of this file is to add additional customization logic to the tg code base without
//adding tg code to the core files. This allowes the power network rewrite to be ported to other ss13 projects




/*
For cases when you just want one tick worth of drain from the node, you can call this.
Normally you would change current load and call update on the powerNode, but if you
don't have a way to reset to idel load, this is a way of doing it.


Depercated: This is support some old power net logic

*/


/obj/machinery/proc/use_power(var/powerUsed)
	if(powerNode !=null)
		powerUtils.use_power(powerNode,powerUsed,1)
	else
		world << "[name] isn't set up on the new power system yet"

/area
	var/datum/wire_network/wireNetwork = null

/area/proc/use_power(var/powerUsed)
	//na

/area/proc/getWireNetwork()
	if(wireNetwork ==null)
		wireNetwork = new /datum/wire_network()
		wireNetwork.setName = "Area Wire_Network"
	return wireNetwork

/datum/power/PowerNodeUtils/proc/use_power(var/datum/power/PowerNode/powerNode, var/amount, var/numOfTicks)
	powerNode.activePowerTicksRemaining=numOfTicks
	powerNode.setCurrentLoad = amount
	powerNetworkControllerPowerActivePowerTicks|=powerNode




/datum/power/PowerNodeUtils/proc/blob_act(var/datum/power/PowerNode/powerNode)
/datum/power/PowerNodeUtils/proc/emp_act(var/datum/power/PowerNode/powerNode, severity)
/datum/power/PowerNodeUtils/proc/ex_act(var/datum/power/PowerNode/powerNode, severity)
	//TODO: Add logic for explosion damage against cells



//Returns the cell removed
/datum/power/PowerNodeUtils/proc/removeCell(var/datum/power/PowerNode/powerNode)
	//TODO: Folix: add remove logic

/datum/power/PowerNodeUtils/proc/addCell(var/datum/power/PowerNode/powerNode, var/obj/item/weapon/stock_parts/cell/cell)

	//I'm remapping the vars here because it will make it easier to follow
	var/cellCapacity = cell.maxcharge
	var/cellStoredEnergy = cell.charge


	if( powerNode.setHasBattery == 0 )
		//Add battery logic, add to battery
		powerNode.setHasBattery = 1
		powerNode.calculatedBatteryStoredEnergy+=cellStoredEnergy
		cell.charge = 0
		powerNode.setBatteryMaxCapacity+=cellCapacity


		powerNode.cycle();


	powerNode.storedObjects.Add(cell)

//TODO Folix: add remove cell logic


/*
	Propagate network along wires
*/
/proc/propagate_network(var/obj/structure/cable/powerNodeSpaceWithoutNetowrk
, var/datum/wire_network/toPropagate, var/datum/wire_network/toReplace)
	//world.log << "propagating new network"


	//This contains a list of objects that have a parentNode var
	//TODO Folix: replace this with normal list after this is working

	var/datum/datastructures/LinkedList/toProcessCable = new /datum/datastructures/LinkedList()

//	var/list/toProcessCable = list()

	toProcessCable.push(powerNodeSpaceWithoutNetowrk);

	//Propagate along wires
	while(toProcessCable.size >0)
		//Pop first element
		var/obj/structure/cable/currentNode = toProcessCable.pop()
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
						toProcessCable.push(C)

			//Attach any machines if found on this space
			for(var/obj/machinery/machine in currentNode.loc)

				var/datum/power/PowerNode/machinepowerNode = machine.powerNode


				//Terminal Logic
				if(istype(machine,/obj/machinery/power/terminal))
					var/obj/machinery/power/terminal/terminal = machine
					var/datum/power/PowerNode/terminalMasterPowerNode = terminal.master.powerNode
					if(terminal.master!=null)
						//Now we either will set the child or parent network

						//TODO Folix: add logic to remove from network if one exists
						if(terminalMasterPowerNode.setParentNetworkAttachesOnThisSpace==1)
							if(terminalMasterPowerNode.parentNetwork == toReplace)
								terminalMasterPowerNode.parentNetwork = toPropagate

								//logic for apc
								if(terminalMasterPowerNode.childNetwork==null)

								//TODO Folix add logic to remove if exists and needs to be updated

									var/area/area = get_area(terminal.master)




						else
							//smes
							if(terminalMasterPowerNode.childNetwork == toReplace)
								terminalMasterPowerNode.childNetwork = toPropagate


						//apc logic for adding to power area as child network
						if(istype(terminal.master, /obj/machinery/power/apc))
							var/area/area = get_area(terminal.master)
							terminalMasterPowerNode.childNetwork = area.getWireNetwork()
							terminalMasterPowerNode.childNetwork.add(terminalMasterPowerNode)
					toPropagate.add(terminal.master.powerNode)


				//Normal machine logic
				if(machinepowerNode!=null && machine.anchored && !istype(machine,/obj/machinery/power/terminal))
					if(machinepowerNode.setParentNetworkAttachesOnThisSpace == 1 && machinepowerNode.parentNetwork == toReplace)

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

					if(machinepowerNode.setParentNetworkAttachesOnThisSpace == 0 && machinepowerNode.childNetwork == toReplace)

						//remove machine from existing network and add to new one
						var/datum/wire_network/machinechildNetwork = machinepowerNode.childNetwork
						if(machinechildNetwork!=null)
						 	//The machine is currently atached to a network, remove it
							machinechildNetwork.remove(machinepowerNode)

						//now add machine to new network if one exists. it should, but to suppor the off case where one
						// would want to propagate null for what ever reason. I'll put a check in.
						if(toPropagate!=null)
							machinepowerNode.childNetwork = toPropagate
							world << "power connecting machine [machinepowerNode.setName]"
							toPropagate.add(machinepowerNode)

