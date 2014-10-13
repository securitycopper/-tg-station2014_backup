/*
#ifndef true
#define true 1
#endif
*/

/area/proc/getWireNetwork()
	if(wireNetwork ==null)
		wireNetwork = new /datum/wire_network()
		wireNetwork.setName = "Area Wire_Network"
	return wireNetwork


/area
	var/datum/wire_network/wireNetwork = null

/area/proc/use_power(var/powerUsed)
	//na

/datum/wire_network




//Note: with this system, extra supply that isn't spent in load is lost.
	var/setName = "Generic Power Network"

	var/wireNetworkMaxPotentialSupply = 0
	var/wireNetworkCurrentSupply = 0
	var/wireNetworkLoad = 0;

	//var/autoRestartLoad = 0;

	//Linked list because of rolling brownouts
	var/list/brownOutList = list()
	var/list/autoRestartListOff = list()
	var/list/autoRestartListOn = list()

	var/list/manualRestartList = list()





	var/list/powerNodesThatCanSupplyPower = list()
	var/list/powerNodesThatCanNotSupplyPower = list()

	var/oldwireNetworkMaxPotentialSupply = 0

	var/list/allNonWiresConnected = list()

	var/size = 0;

	var/gridId = 0


/datum/wire_network/proc/Destory()
	//loop though all children and remove this from there parent or child after turning them off.

	//then set lists to nulls
	powerNodesThatCanSupplyPower = null
	powerNodesThatCanNotSupplyPower = null




/datum/wire_network/New()
	powerNetworkControllerProcessingLoopList+=src
	gridId = getUniqueID()


/datum/wire_network/proc/boolean_reserveAditionalPower(var/aditonalAmount)
//	world << "wirenetwork -> boolean_reserveAditionalPower([aditonalAmount])"

	var/powerWeNeedToGetFromSuppliersRemaining = aditonalAmount - (wireNetworkCurrentSupply-wireNetworkLoad)

	if(powerWeNeedToGetFromSuppliersRemaining<=0)
		return 1



	for(var/datum/power/PowerNode/supply in powerNodesThatCanSupplyPower)

		if(supply.powerNodeListener != null)
			powerWeNeedToGetFromSuppliersRemaining-= supply.powerNodeListener.power_onChangeEvent(supply, POWEREVENT_ADITIONAL_POWER_REQUEST,powerWeNeedToGetFromSuppliersRemaining)

		else
			if(supply.objListener !=null)
				var/obj/o = supply.objListener
				powerWeNeedToGetFromSuppliersRemaining-= o.power_onChangeEvent(supply, POWEREVENT_ADITIONAL_POWER_REQUEST,powerWeNeedToGetFromSuppliersRemaining)

		if(powerWeNeedToGetFromSuppliersRemaining<=0)
		//	world << "wirenetwork <- boolean_reserveAditionalPower([aditonalAmount]):1"
			return 1



//	world << "wirenetwork <- boolean_reserveAditionalPower([aditonalAmount]):0"
	return 0


/datum/wire_network/proc/process()
	var/list/moveFromAutoRestartListOnToListOff = list()

	/***** Process brownouts *****/

	for(var/datum/power/PowerNode/powerNodeThatWeWantToTurnOff in autoRestartListOn)
		if(wireNetworkCurrentSupply<wireNetworkLoad)
			powerNodeThatWeWantToTurnOff.privateForceBrownOut();
			moveFromAutoRestartListOnToListOff+=powerNodeThatWeWantToTurnOff
		else
			break

	for(var/datum/power/PowerNode/powerNodeThatWeWantToTurnOff in manualRestartList)
		if(wireNetworkCurrentSupply<wireNetworkLoad)
			powerNodeThatWeWantToTurnOff.privateForceBrownOut();
			moveFromAutoRestartListOnToListOff+=powerNodeThatWeWantToTurnOff
		else
			break


	for(var/datum/power/PowerNode/p in moveFromAutoRestartListOnToListOff)
		autoRestartListOn-=p
		autoRestartListOff+=p


	/***** Process auto starts *****/
	//check to see if current supply is enough for load,
	if(wireNetworkCurrentSupply>=wireNetworkLoad && autoRestartListOff.len ==0)
		return

	var/list/moveFromAutoRestartListOffToListOn = list()


	for(var/datum/power/PowerNode/powerNodeThatWeWantToTurnOn in autoRestartListOff)
		//Note: We already know the node can be started to idle because its in this list

		if(boolean_reserveAditionalPower(powerNodeThatWeWantToTurnOn.setIdleLoad+powerNodeThatWeWantToTurnOn.setBatteryChargeRate)==1)
			/***** Turn on the node because we have enough power *****/
			powerNodeThatWeWantToTurnOn.privateRequestPowerOn()
			if(powerNodeThatWeWantToTurnOn.isOn == 1)
				moveFromAutoRestartListOffToListOn+=powerNodeThatWeWantToTurnOn




	for(var/datum/power/PowerNode/moveNode in moveFromAutoRestartListOffToListOn)
		autoRestartListOff-=moveNode
		autoRestartListOn+=moveNode



/datum/wire_network/proc/remove(var/datum/power/PowerNode/powerNode)
	powerNode.privateForceBrownOut()
	powerNode.parentNetwork = null
	autoRestartListOff -= powerNode
	autoRestartListOn -= powerNode
	allNonWiresConnected -= powerNode
	return




/datum/wire_network/proc/add(var/datum/power/PowerNode/powerNode)

	if(powerNode in allNonWiresConnected)
		return

	powerNode.parentNetwork = src
	allNonWiresConnected.Add(powerNode)

	if(powerNode.canSupplyPower == 1)
		powerNodesThatCanSupplyPower.Add(powerNode)
	else
		powerNodesThatCanNotSupplyPower.Add(powerNode)


	if( powerNode.setCanAutoStartToIdle == 1 )
		if(boolean_reserveAditionalPower(powerNode.setIdleLoad+powerNode.setBatteryChargeRate)==1)
			powerNode.privateRequestPowerOn()
			autoRestartListOn+=powerNode
		else

			autoRestartListOff+=powerNode
	else
		manualRestartList+=powerNode

