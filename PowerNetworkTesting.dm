
var/global/datum/power/PowerNode/apsForLighting
#define DEBUG_POWERNODE_BATTERY 1
#define DEBUG_WIRENETWORK_PROCESS 1
#define DEBUG_WIRENETWORK_ADD 1
#define DEBUG_WIRENETWORK_PRINT_TREE 1

var/datum/PowerNetworkController/powerController = new /datum/PowerNetworkController()

var/datum/wire_network/smesNetwork = new /datum/wire_network()

/datum/globalNull


/datum/globalNull/proc/runtimeError()
var/global/datum/globalNull/globalNull=null

#define true 1
#define false 0

#define assertTrue(actual) if(actual!=1)	globalNull.runtimeError();

#define assertEquals(expected, actual) if(expected!=actual)	world<<"Expected=[expected], actual=[actual]";if(expected!=actual)	globalNull.runtimeError();

client/verb

	test()

		powerNetworkControllerProcessingLoopList = list()
		assertEquals(0,powerNetworkControllerProcessingLoopList.len)


		var/area/kitchenArea = new /area()
		var/datum/wire_network/kitchenWireNetwork = kitchenArea.getWireNetwork();

		kitchenWireNetwork.setName = "Kitchen Area"

		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 2
		kitchenLight.init(kitchenArea)

		//At this point the parent network hasn't started the child item yet


		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenLight.isOn)

		kitchenWireNetwork.process()

		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenLight.isOn)




		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()
		kitchenApc.initApcConfiguration(kitchenArea)
		var/datum/power/PowerNode/kitchenApcOutputNode = kitchenApc.outputNode
		kitchenApc.setBattery(40,13,13,40)
		kitchenApc.update()

		smesNetwork.add(kitchenApc)

		assertEquals(0, kitchenLight.isOn)
		assertEquals(0, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(0, kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(0, kitchenWireNetwork.wireNetworkMaxPotentialSupply)


		assertEquals(0, kitchenApc.isOn)

		assertEquals(0, kitchenApcOutputNode.isOn)


		//kitchenApc.privatePrcessBattery()

		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		kitchenWireNetwork.process()
		kitchenWireNetwork.process()
		kitchenWireNetwork.process()

		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0, kitchenApc.isOn)
		kitchenApc.privatePrcessBattery()
		assertEquals(0, kitchenApc.isOn)
		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(13, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		kitchenWireNetwork.process()

		assertEquals(1, kitchenLight.isOn)


		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(13, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(13,kitchenWireNetwork.wireNetworkMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)

		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(11,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(11, kitchenApcOutputNode.setMaxPotentialSupply)


		kitchenWireNetwork.process() // No effect


		assertEquals(1, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)

		assertEquals(2, kitchenApcOutputNode.setCurrentSupply)
		assertEquals(2, kitchenWireNetwork.wireNetworkLoad)
		assertEquals(2,kitchenWireNetwork.wireNetworkCurrentSupply)
		assertEquals(11,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(11, kitchenApcOutputNode.setMaxPotentialSupply)


		kitchenApc.privatePrcessBattery()

		assertEquals(9,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(9, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(7,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(7, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(5,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(5, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()

		assertEquals(3,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(3, kitchenApcOutputNode.setMaxPotentialSupply)

		kitchenApc.privatePrcessBattery()


		assertEquals(1,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(1, kitchenApcOutputNode.setMaxPotentialSupply)

		/***********************************************/
		kitchenApc.privatePrcessBattery()

		// Now out of power the apc will be off
		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)

		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(1, kitchenLight.isOn)

		/*******************************************/
		//Battery allready depleated and isn't charging so this call won't do anything.
		kitchenApc.privatePrcessBattery()
				// Now out of power the apc will be off
		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)

		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(1, kitchenLight.isOn)


		/*******************************************/
		//Process the wire network. This will cause the apc output to turn back on (with 0 supply) and will turn the light off
		kitchenWireNetwork.process()

		assertEquals(0, kitchenApcOutputNode.isOn)
		assertEquals(0, kitchenApcOutputNode.setCurrentLoad)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setCurrentSupply)

		assertEquals(0,kitchenWireNetwork.wireNetworkMaxPotentialSupply)
		assertEquals(0, kitchenApcOutputNode.setMaxPotentialSupply)


		//Kitchen light is still on because the network hasn't been processed yet
		assertEquals(0, kitchenLight.isOn)




		//Now process the network. The light will draw power and apc load will match power drain of 2



		world << "Test Passed"
		/*

		smesNetwork.setName = "SMES Network"






		var/datum/power/PowerNode/kitchenApc = new /datum/power/PowerNode()



		kitchenApc.initApcConfiguration(kitchenArea)

		smesNetwork.add(kitchenApc)

		world << "Constructed wirenetwork "




		assertEquals(1,1)
		assertEquals(1,2)
*/

	processWireNetwork()
		powerController.processPower()

		world << null
		world << null

		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			//wireNetwork.process()
			wireNetwork.debugDebugNetwork()

	MagicInjectPower()
		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			wireNetwork.wireNetworkCurrentSupply+=90000
			wireNetwork.wireNetworkMaxPotentialSupply+=90000


	ConstructLargeLoadNetwork()
		var/datum/wire_network/kitchenWireNetwork = new /datum/wire_network()


		var/datum/power/PowerNode/kitchenLight = new /datum/power/PowerNode()
		kitchenLight.setName = "obj/machinery/light"
		kitchenLight.setCanAutoStartToIdle = 1
		kitchenLight.setIdleLoad = 400000


		kitchenWireNetwork.add(kitchenLight)


		var/datum/power/PowerNode/terminalPowerNode = new /datum/power/PowerNode()
		terminalPowerNode.initSmesConfiguration()
		var/datum/power/smesOutput = terminalPowerNode.outputNode
		kitchenWireNetwork.add(smesOutput)






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



