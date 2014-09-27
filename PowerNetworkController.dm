var/global/list/powerNetworkControllerProcessingLoopList = list()
var/global/list/powerNetworkControllerPowerNodeOnBatteryProcessingLoopList = list()

var/global/powerGridId=0

var/global/list/powerNetworkControllerPowerActivePowerTicks = list()



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


\datum\PowerNetworkController
