
//Add define for % battery used
//powerNode.calculatedBatteryStoredEnergy / powerNode.setBatteryMaxCapacity

#define POWER_BACKWORDS_COMPATIBLITY

//############# Power Events ##############
#define POWEREVENT_ON 1
#define POWEREVENT_OFF 2
#define POWEREVENT_ADITIONAL_POWER_REQUEST 3
#define POWEREVENT_SWITCHED_TO_BATTERY_POWER 3


#define POWER_STATE_OFF 0
#define POWER_STATE_ON 1
#define POWER_STATE_BATTERY 2


/datum/power/PowerNode



	var/canSupplyPower=0

	var/setName="Generic Power Node"

	//Configuration: call PowerNode.update() after making changes
	var/setCanAutoStartToIdle = 0
	var/setIdleLoad = 0




	var/setCurrentLoad = 0


	var/setMaxPotentialSupply=0
	var/setCurrentSupply=0





	/******* init configuration Variables *********/

	//Default uses apc power;. This takes piority
	var/setDrawPowerFromArea = 1


	//Note if it has a battery, it will be added to the tick processing queue
	// because its values can change every tick
	var/setHasBattery = 0
	var/setBatteryMaxCapacity=0
	var/setBatteryChargeRate=0
	var/setBatteryMaxDischargeRate=0 //For logic reasons, i always want battery discharge to be equal to current energy stored, but smes wants to set this value so am preserving it







	/******* Read Only Variables *********/
	//When (isOn==1) the PowerNode is currently running at set load
	var/isOn = 0
	//Used to identify unique instances of PowerNode and wire_network
	var/gridId = 0



	//##### private variables t #####
	var/list/storedObjects = list()

	var/activePowerTicksRemaining = 0

	var/privateSetParentNetworkAttachesOnThisSpace = 1



	var/datum/power/PowerNode/outputNode

	var/calculatedBatteryStoredEnergy = 0


	//replaced with  calculatedBatteryStoredEnergy  var/calculatedChildCurrentPotentialSupply = 0
	var/calculatedCurrentBatteryDistargeRate = 0

	var/oldCalculatedPotentialSupply=0

	var/oldCalculatedLoadOnParentNetwork=0;
	//var/oldcalculatedBatteryDischargeRate

	var/oldCalculatedSupply = 0;


	var/datum/wire_network/parentNetwork


	//listener logic
	var/obj/objListener
	var/datum/power/PowerNode/powerNodeListener





/**************************************** initiation procs ***************************************************/
/datum/power/PowerNode/New()
	gridId = getUniqueID()

/datum/power/PowerNode/proc/init(var/area/area, var/idleLoad)
	if(parentNetwork == null && setDrawPowerFromArea == 1 && area != null)
		if(idleLoad!=null && idleLoad != 0)
			setCanAutoStartToIdle = 1
			setIdleLoad = idleLoad

		//Attempt to connect to area network
		parentNetwork = area.getWireNetwork()
		parentNetwork.add(src)
		update()


/*
SMES Code
	var/datum/power/PowerNode/terminalPowerNode = new /datum/power/PowerNode()
	terminalPowerNode.initSmesConfiguration()
	terminalPowerNode.setBattery(chargeRate,intialCharge,capacity)
	powerNode = terminalPowerNode.outputNode
*/
/datum/power/PowerNode/proc/initSmesConfiguration()
	setDrawPowerFromArea = 0
	setCanAutoStartToIdle = 1

	setBattery(6000,5e6,5e6,200000)


	setName = "SMES Terminal #[gridId]"

	outputNode = new /datum/power/PowerNode()
	outputNode.gridId = gridId
	outputNode.setName = "SMES Output #[gridId]"
	outputNode.setDrawPowerFromArea = 0
	outputNode.canSupplyPower = 1
	outputNode.setCanAutoStartToIdle = 1
	outputNode.setIdleLoad = 0
	outputNode.setListener(src)
	outputNode.update()


/*
APC Code
	powerNode = new /datum/power/PowerNode()
	powerNode.initApcConfiguration(ObjectLocation)
	powerNode.setBattery(chargeRate,intialCharge,capacity)

*/
/datum/power/PowerNode/proc/initApcConfiguration(var/area/area)
	setCanAutoStartToIdle = 1


	//Battery options
	setBattery(200,5,2500);


	setDrawPowerFromArea = 0


	var/datum/wire_network/areaNetwork  = area.getWireNetwork()
	outputNode = new /datum/power/PowerNode()
	outputNode.gridId = gridId
	outputNode.setName = "WirelessAPC #[gridId]"
	outputNode.setDrawPowerFromArea = 0
	outputNode.canSupplyPower = 1
	outputNode.setCanAutoStartToIdle = 1
	outputNode.setIdleLoad = 0
	outputNode.setListener(src)
	areaNetwork.add(outputNode)
	outputNode.update()





/**************************************** public  procs ***************************************************/

/datum/power/PowerNode/proc/setBattery(var/chargeRate, var/initCapacity, var/maxCapacity, var/maxDischarge)
	//TODO: max discharge logic


	setHasBattery=1
	setBatteryMaxCapacity=maxCapacity
	setBatteryChargeRate=chargeRate
	calculatedBatteryStoredEnergy = initCapacity
	powerNetworkControllerPowerNodeOnBatteryProcessingLoopList|=src



/datum/power/PowerNode/proc/setListener(var/listener)
	if(istype(listener, /datum/power/PowerNode))
		powerNodeListener = listener
	if(istype(listener, /obj))
		objListener = listener






/datum/power/PowerNode/proc/update()

	if(setHasBattery==1 && outputNode!=null && outputNode.isOn == POWER_STATE_ON)
		outputNode.setMaxPotentialSupply = calculatedBatteryStoredEnergy
		outputNode.setCurrentSupply = min(calculatedBatteryStoredEnergy,outputNode.setCurrentSupply)
		outputNode.update()



	if(parentNetwork !=null && isOn ==POWER_STATE_ON)
		//Calculate diffs

		var/calculatedLoadDiff = 0

		if(isOn == 1)
			//Grid
			calculatedLoadDiff =(setCurrentLoad + setBatteryChargeRate) - oldCalculatedLoadOnParentNetwork
		else
			calculatedLoadDiff = 0 - oldCalculatedLoadOnParentNetwork

		oldCalculatedLoadOnParentNetwork+=calculatedLoadDiff



		var/calculatedSupplyDiff = setCurrentSupply - oldCalculatedSupply
		oldCalculatedSupply=setCurrentSupply


		var/calculatedPotentialSupplyDiff = setMaxPotentialSupply - oldCalculatedPotentialSupply
		oldCalculatedPotentialSupply=setMaxPotentialSupply







		//update parent
		parentNetwork.wireNetworkLoad+=calculatedLoadDiff
		parentNetwork.wireNetworkCurrentSupply += calculatedSupplyDiff
		parentNetwork.wireNetworkMaxPotentialSupply+=calculatedPotentialSupplyDiff




/datum/power/PowerNode/proc/publicTurnOff()
		// turn off power






/datum/power/PowerNode/proc/publicTurnOn()


//Utility function called from PowerNodeUtils. This will remove the machine from the network, then reregister it.
//This process is far simplier then doing alot of checks with adding and removing from the networks
/datum/power/PowerNode/proc/cycle()

/datum/power/PowerNode/proc/Destory()
	publicTurnOff()
	parentNetwork=null
	powerNodeListener=null
	objListener=null
	if(outputNode != null)
		outputNode.Destory()
		outputNode=null


/**************************************** extendable procs ***************************************************/
/obj/proc/power_onChangeEvent(var/datum/power/PowerNode/powerNode, var/powerEvent,var/diffAmount)





/**************************************** private procs ***************************************************/


/**
  * This doesn't turn on the node, it only manages the math and turns off the node if its out of power
  * Switching over to grid is managed from the requestPowerOn of this node.
  * We know if we are running on grid because isOn == 1
  */

/datum/power/PowerNode/proc/privatePrcessBattery()
	//world << "PowerNode #[gridId] -> privatePrcessBattery()"
	if(isOn == 0 && outputNode !=null && outputNode.isOn==0)
	//	world << "PowerNode <- privatePrcessBattery(1)"
		return


	var/chargeDiff = 0




	//Grid
	if(isOn == POWER_STATE_ON)
		//world << "privatePrcessBattery #[gridId] POWER_STATE_ON"
		chargeDiff = setBatteryChargeRate-calculatedCurrentBatteryDistargeRate - setCurrentLoad

	if(isOn == POWER_STATE_OFF && (outputNode!=null && outputNode.isOn == POWER_STATE_ON))
	//	world << "privatePrcessBattery #[gridId] POWER_STATE_BATTERY"
		chargeDiff = -calculatedCurrentBatteryDistargeRate - setCurrentLoad

//	world << "privatePrcessBattery #[gridId] isOn=[isOn], setBatteryChargeRate=[setBatteryChargeRate], calculatedCurrentBatteryDistargeRate=[calculatedCurrentBatteryDistargeRate], setCurrentLoad=[setCurrentLoad],chargeDiff=[chargeDiff]"

	if(calculatedBatteryStoredEnergy + chargeDiff > setBatteryMaxCapacity)
		calculatedBatteryStoredEnergy=setBatteryMaxCapacity
		var/extraCharge = chargeDiff+calculatedBatteryStoredEnergy-setBatteryMaxCapacity
		setBatteryChargeRate = max(setBatteryChargeRate-extraCharge,calculatedCurrentBatteryDistargeRate)

	else
		calculatedBatteryStoredEnergy+=chargeDiff

	if(	calculatedBatteryStoredEnergy<0)
		//Out of power, notify child network
		calculatedBatteryStoredEnergy=0

		privateForceBrownOut()

	update()




//	world << "PowerNode #[gridId] <- privatePrcessBattery(2)"


/datum/power/PowerNode/proc/boolean_privateSwitchToBattery()

	if(calculatedBatteryStoredEnergy>=setCurrentLoad)
		powerNetworkControllerPowerNodeOnBatteryProcessingLoopList|=src
		isOn = POWER_STATE_BATTERY
	else
		if(setCanAutoStartToIdle==1)
			parentNetwork.autoRestartListOn-=src
			parentNetwork.autoRestartListOff+=src

	return 0

/datum/power/PowerNode/proc/privateForceBrownOut()
	if(isOn == 1)
		if(boolean_privateSwitchToBattery()==1)
			return

		if(parentNetwork!=null)
			//remove supply and load from parent
			parentNetwork.wireNetworkLoad-=setCurrentLoad
			parentNetwork.wireNetworkMaxPotentialSupply-= setMaxPotentialSupply
			parentNetwork.wireNetworkCurrentSupply-=setCurrentSupply

				//TODO review if i need to remove current load from grid if on grid
		isOn=0;


		if(objListener!=null)
			objListener.power_onChangeEvent(src,  POWEREVENT_OFF, null)
			#if defined(POWER_BACKWORDS_COMPATIBLITY)
			//setCallBackEvents.power_change()
			#endif



/datum/power/PowerNode/proc/privateRequestPowerOn()


	if(isOn == 1)
		return



	if(isOn == POWER_STATE_BATTERY && parentNetwork!=null && parentNetwork.boolean_reserveAditionalPower(setCurrentLoad)==1)
		parentNetwork.wireNetworkLoad+=setCurrentLoad
		parentNetwork.wireNetworkMaxPotentialSupply+= setMaxPotentialSupply
		parentNetwork.wireNetworkCurrentSupply+=setCurrentSupply
		isOn = POWER_STATE_ON
		return;
		//parent network has enough power, switch to parent network







	//world << "[setName] PowerNode -> privateRequestPowerOn(), hasbattery=[setHasBattery]"


	if(setHasBattery == 1)
	//TODO: This should only happen once but will be called each time. add in a check to see if it has been already added
		powerNetworkControllerPowerNodeOnBatteryProcessingLoopList|=src
		//world << "[setName] privateRequestPowerOn() -> Adding battery"



	if(parentNetwork != null && parentNetwork.wireNetworkMaxPotentialSupply-parentNetwork.wireNetworkLoad >= setIdleLoad)
		isOn = 1


		setCurrentLoad = setIdleLoad


	//TODO< check if on battery and switch over all load to grid
	else if(setHasBattery == 1 && setIdleLoad <= calculatedBatteryStoredEnergy)
		isOn = 1

		setCurrentLoad = setIdleLoad
		//the battery process loop will apply power to child nextwork on next tick




	if(objListener!=null && isOn == 1)
		objListener.power_onChangeEvent( src, POWEREVENT_ON, 0)

		#if defined(POWER_BACKWORDS_COMPATIBLITY)
		//setCallBackEvents.power_change()
		#endif


	update()
	//world << "[setName] is now [isOn]"


/************************  Power Node APC Logic *****************************************/

/*  This can only be called from childNode ***/
/datum/power/PowerNode/proc/power_onChangeEvent(var/datum/power/PowerNode/powerNode, var/powerEvent,var/diffAmount)
	switch(powerEvent)
		if(POWEREVENT_ADITIONAL_POWER_REQUEST)
			if(calculatedCurrentBatteryDistargeRate +diffAmount < calculatedBatteryStoredEnergy)
			//Increase by the diff and take the rest off of battery power if it exists
				calculatedCurrentBatteryDistargeRate+=diffAmount


				powerNode.setCurrentSupply+=diffAmount
				powerNode.update()
				return diffAmount

