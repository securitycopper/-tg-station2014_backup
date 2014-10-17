
var/global/datum/power/PowerNodeUtils/powerUtils = new /datum/power/PowerNodeUtils()

#define LIST_PUSH(list,element) list.Insert(1,element)

#define LIST_POP(list) list[1];list.Cut(1,2);

/datum/power/PowerNode





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




/datum/power/PowerNodeUtils/proc/use_power(var/datum/power/PowerNode/powerNode, var/amount, var/numOfTicks)
/* Disabled
	powerNode.activePowerTicksRemaining=numOfTicks
	powerNode.setCurrentLoad = amount
	powerNetworkControllerPowerActivePowerTicks|=powerNode
*/



/datum/power/PowerNodeUtils/proc/blob_act(var/datum/power/PowerNode/powerNode)
/datum/power/PowerNodeUtils/proc/emp_act(var/datum/power/PowerNode/powerNode, severity)
/datum/power/PowerNodeUtils/proc/ex_act(var/datum/power/PowerNode/powerNode, severity)
	//TODO: Add logic for explosion damage against cells



//Returns the cell removed
/datum/power/PowerNodeUtils/proc/removeCell(var/datum/power/PowerNode/powerNode)
	//TODO: Folix: add remove logic

/datum/power/PowerNodeUtils/proc/addCell(var/datum/power/PowerNode/powerNode, var/obj/item/weapon/stock_parts/cell/cell)
/* Disabled
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
*/

//TODO Folix: add remove cell logic


/*
	Propagate network along wires
*/
/proc/propagate_network(var/obj/structure/cable/powerNodeSpaceWithoutNetowrk
, var/datum/wire_network/toPropagate, var/datum/wire_network/toReplace)
	//world.log << "propagating new network"


	//This contains a list of objects that have a parentNode var
	//TODO Folix: replace this with normal list after this is working

	var/list/toProcessCable = list()

//	var/list/toProcessCable = list()

	LIST_PUSH(toProcessCable,powerNodeSpaceWithoutNetowrk)

	//Propagate along wires
	while(toProcessCable.len >0)
		//Pop first element
		var/obj/structure/cable/currentNode = LIST_POP(toProcessCable)

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
						LIST_PUSH(toProcessCable,C)

			//Attach any machines if found on this space
			for(var/obj/machinery/machine in currentNode.loc)

				/*** Terminal Logic get and set powerNode from master ***/

				//For terminals, we need to get the terminal node from the master
				if(istype(machine,/obj/machinery/power/terminal))
					var/obj/machinery/power/terminal/terminal = machine
					var/obj/machinery/terminalMaster = terminal.master
					terminal.powerNode = terminalMaster.terminalPowerNode

				var/datum/power/PowerNode/machinepowerNode = machine.powerNode

/*
			//START HERE	zxsc



				//Terminal Logic
				if(istype(machine,/obj/machinery/power/terminal))
					var/obj/machinery/power/terminal/terminal = machine
					var/datum/power/PowerNode/terminalMasterPowerNode = terminal.master.powerNode
					if(terminal.master!=null)
						//Now we either will set the child or parent network

						if(istype(terminal.master, /obj/machinery/power/apc)


						//TODO Folix: add logic to remove from network if one exists
						if(terminalMasterPowerNode.setParentNetworkAttachesOnThisSpace==1)
							if(terminalMasterPowerNode.parentNetwork == toReplace)
								terminalMasterPowerNode.parentNetwork = toPropagate

								//logic for apc
								if(terminalMasterPowerNode.outputNode!=null && terminalMasterPowerNode.outputNode.parentNetwork==null)


						else
							//smes
							if(terminalMasterPowerNode.outputNode != null && terminalMasterPowerNode.outputNode.parentNetwork == toReplace)
								terminalMasterPowerNode.outputNode.parentNetwork = toPropagate


						//apc logic for adding to power area as child network
						if(istype(terminal.master, /obj/machinery/power/apc))
							var/area/area = get_area(terminal.master)
							terminalMasterPowerNode.outputNode.parentNetwork = area.getWireNetwork()
							terminalMasterPowerNode.outputNode.parentNetwork.add(terminalMasterPowerNode)
					toPropagate.add(terminal.master.powerNode)

*/
				//Normal machine logic
				if(machinepowerNode!=null && machine.anchored )
					if(machinepowerNode.parentNetwork == toReplace)

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
/*
					var/datum/power/PowerNode/machineOutputNode = machinepowerNode.outputNode
					if(machinepowerNode.setParentNetworkAttachesOnThisSpace == 0 && machineOutputNode != null && machineOutputNode.parentNetwork == toReplace)

						//remove machine from existing network and add to new one
						var/datum/wire_network/machinechildNetwork = machinepowerNode.outputNode.parentNetwork
						if(machinechildNetwork!=null)
						 	//The machine is currently atached to a network, remove it
							machinechildNetwork.remove(machinepowerNode)

						//now add machine to new network if one exists. it should, but to suppor the off case where one
						// would want to propagate null for what ever reason. I'll put a check in.
						if(toPropagate!=null)
							machinepowerNode.outputNode.parentNetwork = toPropagate
							world << "power connecting machine [machinepowerNode.setName]"
							toPropagate.add(machinepowerNode.outputNode)

*/