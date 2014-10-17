/*
#ifndef true
#define true 1
#endif
*/

#define LIST_PUSH(list,element) list.Insert(1,element)

#define LIST_POP(list) list[1];list.Cut(1,2);

#define LIST_ADDFIRST(list,element) LIST_PUSH(list,element)

#define LIST_ADDLAST(list,element) list.Insert(list.len+1 ,element)




/area/proc/getWireNetwork()
	if(wireNetwork ==null)
		wireNetwork = new /datum/wire_network()
		wireNetwork.setName = "Area Wire_Network"
	return wireNetwork


/area
	var/datum/wire_network/wireNetwork = null

/area/proc/use_power(var/powerUsed)
	//na

//#define WIRE_DEBUG world<<"[setName]: ([wireNetworkLoad]/[wireNetworkCurrentSupply]/[wireNetworkMaxPotentialSupply])"
/datum/wire_network




//Note: with this system, extra supply that isn't spent in load is lost.
	var/setName = "Generic Power Network"

	var/wireNetworkMaxPotentialSupply = 0
	var/wireNetworkCurrentSupply = 0
	var/wireNetworkLoad = 0;


	//var/autoRestartLoad = 0;

	//Linked list because of rolling brownouts
//	var/list/brownOutList = list()
//	var/list/autoRestartListOff = list()
	var/list/autoRestartListOn = list()

	var/list/manualRestartListOn = list()




	var/list/processQueue = list()


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

#define ADITONAL_NEEDED (aditonalAmount - (wireNetworkCurrentSupply-wireNetworkLoad))
/datum/wire_network/proc/boolean_reserveAditionalPower(var/aditonalAmount)
//	world << "wirenetwork -> boolean_reserveAditionalPower([aditonalAmount])"

	var/powerWeNeedToGetFromSuppliersRemaining = ADITONAL_NEEDED


	if(powerWeNeedToGetFromSuppliersRemaining<=0)
		return 1



	for(var/datum/power/PowerNode/supply in powerNodesThatCanSupplyPower)

		var/requestAmount = ADITONAL_NEEDED
		//world << "aditonalAmount=[aditonalAmount], maxCanRequest=[maxCanRequest], requestAmount=[requestAmount], powerWeNeedToGetFromSuppliersRemaining=[powerWeNeedToGetFromSuppliersRemaining]"


		if(requestAmount>0)
			if(supply.powerNodeListener != null)
				//world << "supply=[supply], POWEREVENT_ADITIONAL_POWER_REQUEST=[POWEREVENT_ADITIONAL_POWER_REQUEST], requestAmount=[requestAmount]"
				powerWeNeedToGetFromSuppliersRemaining-= supply.powerNodeListener.power_onChangeEvent(supply, POWEREVENT_ADITIONAL_POWER_REQUEST,powerWeNeedToGetFromSuppliersRemaining)
			//	world << "DONE: supply=[supply], POWEREVENT_ADITIONAL_POWER_REQUEST=[POWEREVENT_ADITIONAL_POWER_REQUEST], requestAmount=[requestAmount]"

			else
				if(supply.objListener !=null)
					var/obj/o = supply.objListener

					powerWeNeedToGetFromSuppliersRemaining-= o.power_onChangeEvent(supply, POWEREVENT_ADITIONAL_POWER_REQUEST,powerWeNeedToGetFromSuppliersRemaining)

		if(powerWeNeedToGetFromSuppliersRemaining<=0)
		//	world << "wirenetwork <- boolean_reserveAditionalPower([aditonalAmount]):1"
			return 1

	/***** Process brownouts *****/
	//Cycle through the automatic start list
	var/i = 0
	var/size = autoRestartListOn.len
	while(i<size && ADITONAL_NEEDED  >=0 )
		i++
		var/datum/power/PowerNode/powerNodeThatWeWantToTurnOff = LIST_POP(autoRestartListOn)
		if(powerNodeThatWeWantToTurnOff.setCurrentLoad>0)
			powerNodeThatWeWantToTurnOff.privateForceBrownOut();
		LIST_ADDLAST(processQueue,powerNodeThatWeWantToTurnOff)


	i=0
	size = 	manualRestartListOn.len
	while(i<size && ADITONAL_NEEDED  >=0 )
		i++
		var/datum/power/PowerNode/powerNodeThatWeWantToTurnOff = LIST_POP(manualRestartListOn)
		powerNodeThatWeWantToTurnOff.privateForceBrownOut();
		//We don't auto start manual so they don't get added to a list

	if(ADITONAL_NEEDED >= 0)
		return 1
	else
		return 0

/datum/wire_network/proc/process()

	if(wireNetworkMaxPotentialSupply<0 || wireNetworkCurrentSupply< 0 || wireNetworkLoad<0)
		errorCycle()

	//var/list/moveFromAutoRestartListOnToListOff = list()

//	WIRE_DEBUG

	/***** Process auto starts *****/
	//Process one node per tick
	if(processQueue.len > 0)
		var/datum/power/PowerNode/toProcess = LIST_POP(processQueue)
		//world << "WireNetwork process: [toProcess.setName] (isOn=[toProcess.isOn], setIdleLoad[toProcess.setIdleLoad]<=wireNetworkMaxPotentialSupply=[wireNetworkMaxPotentialSupply]"
		if(toProcess.isOn==0 && toProcess.setIdleLoad<=wireNetworkMaxPotentialSupply)

			if(boolean_reserveAditionalPower(toProcess.setIdleLoad) == 1)
				//world << "WireNetwork process: [toProcess.setName] - Was able to request enough power"
				toProcess.privateRequestPowerOn()
				if(toProcess.isOn==1)
				//	world << "WireNetwork process: [toProcess.setName] - is now on"
					if(toProcess.setCanAutoStartToIdle==1)
						if(toProcess.canSupplyPower==1)
							LIST_ADDLAST(powerNodesThatCanSupplyPower,toProcess)
						else
							LIST_ADDLAST(autoRestartListOn,toProcess)
					else
						LIST_ADDLAST(manualRestartListOn,toProcess)

					//WIRE_DEBUG
					return


		//world << "WireNetwork process: [toProcess.setName] - failed to start"
		LIST_ADDLAST(processQueue,toProcess)


	//WIRE_DEBUG

// Error proc only called if math error is detected, IE if values go negative
/datum/wire_network/proc/errorCycle()
	world << "Math Error: Wirenetwork=[setName] [gridId], reseting network ([wireNetworkLoad]/[wireNetworkCurrentSupply]/[wireNetworkMaxPotentialSupply])"

	//Create a new list with one instance of all nodes
	var/list/newNetworkNodes = list()

	//Search master list (should contain evertything, but there is an error so search all lists)
	for(var/datum/power/PowerNode/powerNode in allNonWiresConnected)
		newNetworkNodes|=powerNode

	for(var/datum/power/PowerNode/powerNode in autoRestartListOn)
		newNetworkNodes|=powerNode

	for(var/datum/power/PowerNode/powerNode in processQueue)
		newNetworkNodes|=powerNode

	//Remove all nodes safely
	for(var/datum/power/PowerNode/powerNode in newNetworkNodes)
		remove(powerNode)

	//Clear lists
	allNonWiresConnected.Cut(0)
	autoRestartListOn.Cut(0)
	processQueue.Cut(0)

	//Clear stats
	wireNetworkMaxPotentialSupply = 0
	wireNetworkCurrentSupply = 0
	wireNetworkLoad = 0;

	//Reinitlize network
	for(var/datum/power/PowerNode/powerNode in newNetworkNodes)
		add(powerNode)
		world << "  -->Ading: Name=[powerNode.setName] [gridId], reseting network ([powerNode.setCurrentLoad]/[powerNode.setCurrentSupply]/[powerNode.setMaxPotentialSupply])"




/datum/wire_network/proc/remove(var/datum/power/PowerNode/powerNode)
	powerNode.privateForceBrownOut()
	powerNode.parentNetwork = null
	processQueue -= powerNode
	autoRestartListOn -= powerNode
	allNonWiresConnected -= powerNode
	return



/datum/wire_network/proc/privateBrownOut(var/datum/power/PowerNode/powerNode)
	remove(powerNode)
	add(powerNode)


/datum/wire_network/proc/add(var/datum/power/PowerNode/powerNode)

	if(powerNode in allNonWiresConnected)
		return

	powerNode.parentNetwork = src
	allNonWiresConnected.Add(powerNode)

	//if(powerNode.canSupplyPower == 1)
	//	powerNodesThatCanSupplyPower.Add(powerNode)

	if( powerNode.setCanAutoStartToIdle == 1 )
		if(powerNode.canSupplyPower == 1)
			LIST_PUSH(processQueue,powerNode)
		else
			LIST_ADDLAST(processQueue,powerNode)



