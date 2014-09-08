
var/global/datum/power/PowerNodeUtils/powerUtils = new /datum/power/PowerNodeUtils()



/datum/power/PowerNodeUtils

//The goal of this file is to add additional customization logic to the tg code base without
//adding tg code to the core files. This allowes the power network rewrite to be ported to other ss13 projects




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