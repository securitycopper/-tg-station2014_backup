// the power monitoring computer
// for the moment, just report the status of all APCs in the same powernet
/obj/machinery/computer/monitor
	name = "power monitoring console"
	desc = "It monitors power levels across the station."
	icon = 'icons/obj/computer.dmi'
	icon_state = "power"
	density = 1
	anchored = 1


	active_power_usage = 80
	circuit = /obj/item/weapon/circuitboard/powermonitor


//fix for issue 521, by QualityVan.
//someone should really look into why circuits have a powernet var, it's several kinds of retarded.
/obj/machinery/computer/monitor/New()
	..()

	powerNode = new /datum/power/PowerNode()
	//Power Node Behavior
	powerNode.setName = name
	powerNode.setCanAutoStartToIdle = 1
	powerNode.setIdleLoad = active_power_usage
	powerNode.setCurrentLoad = 0

	//for solar, min and max will match
	powerNode.setMaxPotentialSupply = 0
	powerNode.setCurrentSupply = 0

	//Battery options
	powerNode.setHasBattery=0
	powerNode.setBatteryMaxCapacity=0
	powerNode.setBatteryChargeRate=0



	var/obj/structure/cable/attached = null
	var/turf/T = loc
	if(isturf(T))
		attached = locate() in T
	//if(attached)
	//TODO FOLIX: add attach logic
		//powerNode.parentNetwork = attached.powerNode.parentNetwork
		//attached.powerNode.parentNetwork.add(powerNode)
/*
/obj/machinery/computer/monitor/process() //oh shit, somehow we didnt end up with a powernet... lets look for one.
	if(powerNode.parentNetwork != null)
		var/obj/structure/cable/attached = null
		var/turf/T = loc
		if(isturf(T))
			attached = locate() in T
		if(attached)
		//TODO Folix
			//powernet = attached.get_powernet()
	return
*/
/*
/obj/machinery/computer/monitor/attack_hand(mob/user)
	if(..())
		return
	interact(user)
*/

/obj/machinery/computer/monitor/interact(mob/user)
	if ((get_dist(src, user) > 1 ) || (stat & (BROKEN|NOPOWER)) )
		if (!istype(user, /mob/living/silicon))
			user.unset_machine()
			user << browse(null, "window=powcomp")
			return


	user.set_machine(src)
	var/t = ""

	t += "<A href='?src=\ref[src];update=1'>Refresh</A> <A href='?src=\ref[src];close=1'>Close</A><br /><br />"

	if(powerNode.parentNetwork ==null)
		t += "<span class='danger'>No connection.</span>"
	else

		var/list/L = list()
		//TODO FOlix: this logic
		/*
		for(var/obj/machinery/power/terminal/term in powernet.nodes)
			if(istype(term.master, /obj/machinery/power/apc))
				var/obj/machinery/power/apc/A = term.master
				L += A
		*/
		t += "<PRE>Total power: [powerNode.parentNetwork.wireNetworkMaxPotentialSupply-powerNode.parentNetwork.wireNetworkLoad] W<BR>Total load:  [num2text(powerNode.parentNetwork.wireNetworkLoad,10)] W<BR>"

		t += "<FONT SIZE=-1>"

		if(L.len > 0)

			t += "Area                           Eqp./Lgt./Env.  Load   Cell<HR>"

			var/list/S = list(" Off","AOff","  On", " AOn")
			var/list/chg = list("N","C","F")

			for(var/obj/machinery/power/apc/A in L)

				t += copytext(add_tspace("\The [A.area]", 30), 1, 30)
				t += " [S[A.equipment+1]] [S[A.lighting+1]] [S[A.environ+1]] [add_lspace(A.lastused_total, 6)]  [A.powerNode.setHasBattery == 1 ? "[add_lspace(round(A.powerNode.calculatedBatteryStoredEnergy/A.powerNode.setBatteryMaxCapacity), 3)]% [chg[A.charging+1]]" : "  N/C"]<BR>"

		t += "</FONT></PRE>"

	//user << browse(t, "window=powcomp;size=420x900")
	//onclose(user, "powcomp")
	var/datum/browser/popup = new(user, "powcomp", name, 420, 450)
	popup.set_content(t)
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/computer/monitor/Topic(href, href_list)
	if(..())
		return
	if( href_list["close"] )
		usr << browse(null, "window=powcomp")
		usr.unset_machine()
		return
	if( href_list["update"] )
		src.updateDialog()
		return