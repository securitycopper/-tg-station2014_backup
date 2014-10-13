var/global/list/powerNetworkControllerProcessingLoopList = list()
var/global/list/powerNetworkControllerPowerNodeOnBatteryProcessingLoopList = list()



var/global/list/powerNetworkControllerPowerActivePowerTicks = list()


var/global/currentUniqueId = 0
proc/global/getUniqueID()
	currentUniqueId++
	return currentUniqueId



/*  ##### Stubed example configuration #####

	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = name
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad = 10
	powerNode.setCurrentLoad = 0
	powerNode.setParentNetworkAttachesOnThisSpace = 1

	//Generator Logic
	powerNode.setMaxPotentialSupply = 0
	powerNode.setCurrentSupply = 0

	//Battery options
	powerNode.setHasBattery=0
	powerNode.setBatteryMaxCapacity=0
	powerNode.calculatedBatteryStoredEnergy = 0
	powerNode.setBatteryChargeRate=0
	powerNode.setBatteryMaxDischargeRate=0

	powerNode.update()



	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = name
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad =
	powerNode.update()



*/


/datum/PowerNetworkController


/datum/PowerNetworkController/proc/processPower()
	//Simulate an iteration
	for(var/datum/power/PowerNode/powerNodeWithBattery in powerNetworkControllerPowerNodeOnBatteryProcessingLoopList)
		powerNodeWithBattery.privatePrcessBattery()

	for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
		wireNetwork.process()
		#if defined(DEBUG_WIRENETWORK_PRINT_TREE)
		//wireNetwork.debugDebugNetwork()
		#endif

	//TODO: Folix, refactor this into an efficent cicular queue that stops when iternation = size
	for(var/datum/power/PowerNode/powerNodeActivePower in powerNetworkControllerPowerActivePowerTicks)
		if( powerNodeActivePower.activePowerTicksRemaining == 0 )
			powerNetworkControllerPowerActivePowerTicks-=powerNodeActivePower
			powerNodeActivePower.setCurrentLoad = powerNodeActivePower.setIdleLoad
		else
			powerNodeActivePower.activePowerTicksRemaining--



