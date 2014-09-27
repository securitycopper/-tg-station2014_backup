
//Add define for % battery used
//powerNode.calculatedBatteryStoredEnergy / powerNode.setBatteryMaxCapacity

#define POWER_BACKWORDS_COMPATIBLITY

//############# Power Events ##############
#define POWEREVENT_ON 1
#define POWEREVENT_OFF 2


/obj/proc/power_onChangeEvent(var/powerEvent)


/datum/power/PowerNode

	var/obj/machinery/setCallBackEvents


	/*
		Anything can create a PowerNode. The object that uses it needs to
		check if its powered to see if

		An example assuming we are in the process() of the object that contains a powerNode
			Assume: PowerNode is defined as powerNode

			if(powerNode.isOn==1)
				Change graphic to on state

			else
				change grapic to off state



	*/

	var/setName="Generic Power Node"

	//Configuration: call PowerNode.update() after making changes
	var/setCanAutoStartToIdle = 0
	var/setIdleLoad = 0

	//used with terminal logic
	var/setParentNetworkAttachesOnThisSpace = 1

	//Default uses apc power;. This takes piority
	var/setDrawPowerFromArea = 1


	//load used by this machine, Note: child network will be added to this to dirive total load
	var/setCurrentLoad = 0


	var/setMaxPotentialSupply=0
	var/setCurrentSupply=0


	//By setting this, current load will change based on child network needs
	//Child network will be supplied power from your battery if your not receiving power from supply
	var/datum/wire_network/childNetwork

	var/datum/wire_network/parentNetwork



	//Note if it has a battery, it will be added to the tick processing queue
	// because its values can change every tick
	var/setHasBattery = 0
	var/setBatteryMaxCapacity=0
	var/setBatteryChargeRate=0
	var/setBatteryMaxDischargeRate=0 //For logic reasons, i always want battery discharge to be equal to current energy stored, but smes wants to set this value so am preserving it



	//after setting these values, call PowerNode.update()
	var/calculatedBatteryStoredEnergy = 0

	var/calculatedChildNetworkLoad = 0


	var/calculatedTotalLoad = 0

	//replaced with  calculatedBatteryStoredEnergy  var/calculatedChildCurrentPotentialSupply = 0
	var/calculatedCurrentBatteryDistargeRate = 0

	var/oldCalculatedPotentialSupply=0
	var/oldcalculatedChildCurrentPotentialSupply=0
	var/oldCalculatedLoadOnParentNetwork=0;
	//var/oldcalculatedBatteryDischargeRate

	var/oldCalculatedSupply = 0;

	//readable values

	var/isOn = 0
	//Is the powerNode registered to a Wire_network
	var/isConnected = 0
	//Is a brownoutEffecting this node. Not enough power is being supplied to node
	var/isBrownOut = 0

	var/isCharging = 0;

	var/runningOnGridOrBattery = 0 //0-Grid, 1-Battery
	//var/isRunningOnBattery = 0



	//##### private variables that only PowerNode Utils should access #####
	var/list/storedObjects = list()

	var/activePowerTicksRemaining = 0
	//var/activePowerActiveUsage = 0

	var/gridId = 0


	var/oldIsOn = 0

/datum/power/PowerNode/proc/prcessBattery()
	/*
		Notes:
		Battery Load is battery drain from childNetwork.
		TOOD: have wire network notify suppliers that there is extra energy

	*/
	if(isOn == 0)
		#if defined(DEBUG_POWERNODE_BATTERY)
		world<< "DEBUG: [setName] power is off so battery can't be processed"
		#endif
		//powerNetworkControllerPowerNodeOnBatteryProcessingLoopList-=src
		return

	#if defined(DEBUG_POWERNODE_BATTERY)
	world<< "DEBUG: [setName] prcessBattery()"
	#endif


	////Charging logic
//	if (runningOnGridOrBattery ==0)

	var/chargeDiff = 0

	//If running on battery, see if we can now switch to running on grid
	if(runningOnGridOrBattery == 1 && parentNetwork!=null && (parentNetwork.wireNetworkMaxPotentialSupply - parentNetwork.wireNetworkLoad)>=calculatedCurrentBatteryDistargeRate+setCurrentLoad)
		isOn = 0
		update()
		runningOnGridOrBattery = 0
		requestPowerOn()



	//Grid
	if(runningOnGridOrBattery == 0)
		chargeDiff = setBatteryChargeRate-calculatedCurrentBatteryDistargeRate - setCurrentLoad
	else
		chargeDiff = -calculatedCurrentBatteryDistargeRate - setCurrentLoad


	if(chargeDiff+calculatedBatteryStoredEnergy > setBatteryMaxCapacity)
		calculatedBatteryStoredEnergy=setBatteryMaxCapacity
		var/extraCharge = chargeDiff+calculatedBatteryStoredEnergy-setBatteryMaxCapacity
		setBatteryChargeRate = max(setBatteryChargeRate-extraCharge,calculatedCurrentBatteryDistargeRate)
		update()
	else
		calculatedBatteryStoredEnergy+=chargeDiff

	if(	calculatedBatteryStoredEnergy<0)
		//Out of power, notify child network
		calculatedBatteryStoredEnergy=0
		runningOnGridOrBattery = 0
		isOn=0


	if(childNetwork!=null)
		var/diff = calculatedBatteryStoredEnergy-oldcalculatedChildCurrentPotentialSupply
		oldcalculatedChildCurrentPotentialSupply=calculatedBatteryStoredEnergy
		//ajust child potential supply
		childNetwork.wireNetworkMaxPotentialSupply +=diff;
		if(calculatedBatteryStoredEnergy<=0)
			//Battery Depleated
			childNetwork.wireNetworkCurrentSupply-=calculatedCurrentBatteryDistargeRate
			calculatedCurrentBatteryDistargeRate = 0







		//Now check to switch over to main power if able

	//private powerNode managment settings that shouldn't be changed outside of this class
	//var/last



//Utility function called from PowerNodeUtils. This will remove the machine from the network, then reregister it.
//This process is far simplier then doing alot of checks with adding and removing from the networks
/datum/power/PowerNode/proc/cycle()

/datum/power/PowerNode/proc/Destory()
	//TODO: write a destory block
	isOn=0
	update()
	parentNetwork=null
	setCallBackEvents=null
	childNetwork=null

/datum/power/PowerNode/proc/update(var/area/area)

	/*
	Connection logic for when no parent network
	1. Connect to wire network if attached by wire
	2. Connect to area if allowed to
	*/

	if(oldIsOn == 1 && isOn == 0)
		// turn off power
		oldIsOn = 0
		setCurrentLoad = 0

		if(parentNetwork!=null)
			//remove supply and load from parent
			parentNetwork.wireNetworkMaxPotentialSupply-= setMaxPotentialSupply
			parentNetwork.wireNetworkCurrentSupply-=setCurrentSupply
			//TODO review if i need to remove current load from grid if on grid

		//remove supply from child
		if( setHasBattery && childNetwork != null)
			childNetwork.wireNetworkMaxPotentialSupply-=calculatedBatteryStoredEnergy
			childNetwork.wireNetworkCurrentSupply-=calculatedCurrentBatteryDistargeRate
			calculatedCurrentBatteryDistargeRate=0


	//If parent network is null and is a wireless node, then connect to area network
	if(parentNetwork == null && setParentNetworkAttachesOnThisSpace ==1)
		//Attempt to connect to wired network
		//TODO Folix this logic

	if(parentNetwork == null && setDrawPowerFromArea == 1 && area != null)
		//Attempt to connect to area network
		parentNetwork = area.getWireNetwork()
		parentNetwork.add(src)


	if(parentNetwork !=null && isOn ==1)
		//Calculate diffs

		var/calculatedLoadDiff = 0


		if(runningOnGridOrBattery == 0)
			//Grid
			calculatedLoadDiff =(setCurrentLoad + setBatteryChargeRate) - oldCalculatedLoadOnParentNetwork
		else
			calculatedLoadDiff = 0 - oldCalculatedLoadOnParentNetwork




		//var/oldIsOn
		var/calculatedSupplyDiff = setCurrentSupply - oldCalculatedSupply
		var/calculatedPotentialSupplyDiff = setMaxPotentialSupply - oldCalculatedSupply


		oldCalculatedLoadOnParentNetwork+=calculatedLoadDiff
		oldCalculatedSupply+=calculatedSupplyDiff
		oldCalculatedPotentialSupply+=calculatedPotentialSupplyDiff





		//update parent
		parentNetwork.wireNetworkLoad+=calculatedLoadDiff
		parentNetwork.wireNetworkCurrentSupply += calculatedSupplyDiff
		parentNetwork.wireNetworkMaxPotentialSupply+=calculatedPotentialSupplyDiff




/datum/power/PowerNode/proc/aditionalPowerRequest(var/datum/wire_network/networkRequestingIncrease, var/diffAmount)
	#if defined(DEBUG_POWERNODE_BATTERY)
	world<< "DEBUG: [setName] aditionalPowerRequest(): [networkRequestingIncrease.setName] is requesting [diffAmount] more power"
	#endif
	if(networkRequestingIncrease==parentNetwork)
		#if defined(DEBUG_POWERNODE_BATTERY)
		world<< "DEBUG: [setName] Supply request from parent"
		#endif
		//Parent network wants more power, this use case is mainly for generators that run on fuel
		//For now generators give there parents all they have so we will only handle the battery case here
	else if(networkRequestingIncrease==childNetwork)
		#if defined(DEBUG_POWERNODE_BATTERY)
		world<< "DEBUG: [setName] Supply request from child"
		#endif
		//var/newLoad = diffAmount+calculatedTotalLoad
		//calculatedTotalLoad = newLoad

		//All power goes through battery
		if(calculatedCurrentBatteryDistargeRate +diffAmount < calculatedBatteryStoredEnergy)
			//Increase by the diff and take the rest off of battery power if it exists

			childNetwork.wireNetworkCurrentSupply+= diffAmount
			calculatedCurrentBatteryDistargeRate+=diffAmount




/datum/power/PowerNode/proc/forceBrownOut()
	if(isOn == 1)
		isBrownOut=1
		//Check if there is a battery, if so, switch to it
		if(setHasBattery==1)
			runningOnGridOrBattery=1
			powerNetworkControllerPowerNodeOnBatteryProcessingLoopList|=src
			//Process battery will turn off node if not enough power
		else
			//No power, no battery, remove load from parent
			isOn=0

		//parentNetwork.wireNetworkLoad -=calculatedTotalLoad
		//setCurrentLoad=0
			parentNetwork.autoRestartListOff+=src

	update()
	if(setCallBackEvents!=null && isOn == 0)
		setCallBackEvents.power_onChangeEvent( POWEREVENT_OFF)
		#if defined(POWER_BACKWORDS_COMPATIBLITY)
		setCallBackEvents.power_change()
		#endif


/*
			//Ok now we know we have a battery
			if(calculatedTotalLoad<calculatedBatteryStoredEnergy )
				//Now we know we have enough energy stored to meet demand
				runningOnGridOrBattery = 1
				//TODO: Add self to tick to subtract battery capacity
				parentNetwork.wireNetworkLoad -=calculatedTotalLoad

				//Add self to processing battery loop
				powerNetworkControllerPowerNodeOnBatteryProcessingLoopList+=src
			else
				isOn = 0
				//We don't have enough power, if we are suppying power to a child node, stop supplying that power
//				if(childNetwork != null)
//					childNetwork.wireNetworkMaxPotentialSupply-=calculatedChildCurrentPotentialSupply
//					childNetwork.wireNetworkCurrentSupply-=setCurrentSupply

				setCurrentLoad=0

*/


/datum/power/PowerNode/proc/remove(var/datum/power/PowerNode/toRemove)
	//TODO: remove logic
	return



/datum/power/PowerNode/proc/requestPowerOn()
	//TODO: testing something, remove this if when done
	//if(setCallBackEvents!=null )
	//setCallBackEvents.power_onChangeEvent()
	//	setCallBackEvents.power_change()


	if(isOn == 1)
		return

	if(setHasBattery == 1)
	//TODO: This should only happen once but will be called each time. add in a check to see if it has been already added
		powerNetworkControllerPowerNodeOnBatteryProcessingLoopList.Add(src)



	if(parentNetwork != null && parentNetwork.wireNetworkMaxPotentialSupply-parentNetwork.wireNetworkLoad >= setIdleLoad)
		isOn = 1
		oldIsOn = 1

		setCurrentLoad = setIdleLoad
		update()

	//TODO< check if on battery and switch over all load to grid
	else if(setHasBattery == 1 && setIdleLoad <= calculatedBatteryStoredEnergy)
		isOn = 1
		oldIsOn = 1
		runningOnGridOrBattery = 1
		setCurrentLoad = setIdleLoad
		//the battery process loop will apply power to child nextwork on next tick




	if(setCallBackEvents!=null && isOn == 1)
		setCallBackEvents.power_onChangeEvent( POWEREVENT_ON)

		#if defined(POWER_BACKWORDS_COMPATIBLITY)
		setCallBackEvents.power_change()
		#endif







/*


obj/structure/cable/proc/add_avail(var/amount)
	if(wireNetwork)
		powernet.newavail += amount

obj/structure/cable/proc/add_load(var/amount)
	if(powernet)
		powernet.load += amount

obj/structure/cable/proc/surplus()
	if(powernet)
		return powernet.avail-powernet.load
	else
		return 0

obj/structure/cable/proc/avail()
	if(powernet)
		return powernet.avail
	else
		return 0


/obj/machinery/power/proc/aditionalPowerRequest(var/aditionalAmountNeeded)
	//TODO: batteries will have to evaluate this

/obj/machinery/power/proc/forcePowerOff()
	add_avail(0)
	stat|=NOPOWER

/obj/machinery/power/proc/requestPowerOn()
	if(idle_power_usage<wireNetwork.wireNetworkSupply - wireNetwork.wireNetworkLoad)
		add_avail(-idle_power_usage)
		stat&=~NOPOWER //TODO: Double check this is the correct byte wise operation

// common helper procs for all power machines
/obj/machinery/power/proc/add_avail(var/amount)
	var/diff = amount - power_oldEnergyOutput
	wireNetwork.wireNetworkSupply += diff

/obj/machinery/power/proc/add_load(var/amount)
	var/diff = amount - power_oldEnergyOutput
	wireNetwork.wireNetworkSupply += diff
	//depercated: this would add load to the powernet

/obj/machinery/power/proc/surplus()
	//depercated. this would return surplus, now returns 0
	return wireNetwork.wireNetworkSupply - wireNetwork.wireNetworkLoad

/obj/machinery/power/proc/avail()
	return wireNetwork.wireNetworkSupply - wireNetwork.wireNetworkLoad


/obj/machinery/power/proc/disconnect_terminal() // machines without a terminal will just return, no harm no fowl.
	return
*/