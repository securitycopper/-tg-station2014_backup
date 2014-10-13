
var/global/datum/power/PowerNode/apsForLighting
#define DEBUG_POWERNODE_BATTERY 1
#define DEBUG_WIRENETWORK_PROCESS 1
#define DEBUG_WIRENETWORK_ADD 1
#define DEBUG_WIRENETWORK_PRINT_TREE 1

var/datum/PowerNetworkController/powerController = new /datum/PowerNetworkController()

var/datum/wire_network/smesNetwork = new /datum/wire_network()


client/verb

	processWireNetwork()
		powerController.processPower()

		world << null
		world << null

		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			//wireNetwork.process()
			wireNetwork.debugDebugNetwork()

	ConstructWireNetwork()

		var/area/kitchenArea = new /area()
		var/datum/wire_network/kitchenWireNetwork = kitchenArea.getWireNetwork();

		kitchenWireNetwork.setName = "Kitchen Area"

		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 1
		kitchenLight.init(kitchenArea)




		smesNetwork.setName = "SMES Network"





		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()



		kitchenApc.initApcConfiguration(kitchenArea)

		smesNetwork.add(kitchenApc)

		world << "Constructed wirenetwork "


	Power_Count_Networks()
		world << "[powerNetworkControllerProcessingLoopList.len]"

	addSMESWith300Energy()
		var/datum/power/PowerNode/terminalPowerNode = new /datum/power/PowerNode()
		terminalPowerNode.initSmesConfiguration()
		var/datum/power/smesOutput = terminalPowerNode.outputNode
		smesNetwork.add(smesOutput)





/datum/wire_network/proc/debugDebugNetwork()
	world << "[setName] - #[gridId] Current Load([wireNetworkLoad]/[wireNetworkCurrentSupply]) Max Potential Supply = [wireNetworkMaxPotentialSupply], "

	for(var/datum/power/PowerNode/node in powerNodesThatCanSupplyPower)
		world << "--> Supply: [node.setName] - #[node.gridId] isOn = [node.isOn], Load=[node.setCurrentLoad], Supply([node.setCurrentSupply]/[node.setMaxPotentialSupply])"
	for(var/datum/power/PowerNode/node in powerNodesThatCanNotSupplyPower)
		world << "--> Consumer: [node.setName] - #[node.gridId] isOn = [node.isOn] Load=[node.setCurrentLoad],Battery([node.calculatedBatteryStoredEnergy]/[node.setBatteryMaxCapacity]+[node.setBatteryChargeRate]-[node.calculatedCurrentBatteryDistargeRate])"



