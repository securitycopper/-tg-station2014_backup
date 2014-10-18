// Areas.dm

// Added to fix mech fabs 05/2013 ~Sayu
// This is necessary due to lighting subareas.  If you were to go in assuming that things in
// the same logical /area have the parent /area object... well, you would be mistaken.  If you
// want to find machines, mobs, etc, in the same logical area, you will need to check all the
// related areas.  This returns a master contents list to assist in that.
/proc/area_contents(var/area/A)
	if(!istype(A)) return null
	var/list/contents = list()
	for(var/area/LSA in A.related)
		contents += LSA.contents
	return contents


// ===
/area
	var/global/global_uid = 0
	var/uid
	var/list/ambientsounds = list('sound/ambience/ambigen1.ogg','sound/ambience/ambigen3.ogg',\
									'sound/ambience/ambigen4.ogg','sound/ambience/ambigen5.ogg',\
									'sound/ambience/ambigen6.ogg','sound/ambience/ambigen7.ogg',\
									'sound/ambience/ambigen8.ogg','sound/ambience/ambigen9.ogg',\
									'sound/ambience/ambigen10.ogg','sound/ambience/ambigen11.ogg',\
									'sound/ambience/ambigen12.ogg','sound/ambience/ambigen14.ogg')

/area/New()
	icon_state = ""
	layer = 10
	master = src //moved outside the spawn(1) to avoid runtimes in lighting.dm when it references src.loc.loc.master ~Carn
	uid = ++global_uid
	related = list(src)

	if(requires_power)
		luminosity = 0
	else
		power_light = 0			//rastaf0
		power_equip = 0			//rastaf0
		power_environ = 0		//rastaf0
		luminosity = 1
		lighting_use_dynamic = 0

	..()

//	spawn(15)
	power_change()		// all machines set to current power level, also updates lighting icon
	InitializeLighting()

	blend_mode = BLEND_MULTIPLY // Putting this in the constructure so that it stops the icons being screwed up in the map editor.


/area/proc/poweralert(var/state, var/obj/source as obj)
	if (state != poweralm)
		poweralm = state
		if(istype(source))	//Only report power alarms on the z-level where the source is located.
			var/list/cameras = list()
			for (var/obj/machinery/camera/C in src)
				cameras += C
			for (var/mob/living/silicon/aiPlayer in player_list)
				if(aiPlayer.z == source.z)
					if (state == 1)
						aiPlayer.cancelAlarm("Power", src, source)
					else
						aiPlayer.triggerAlarm("Power", src, cameras, source)
			for(var/obj/machinery/computer/station_alert/a in machines)
				if(a.z == source.z)
					if(state == 1)
						a.cancelAlarm("Power", src, source)
					else
						a.triggerAlarm("Power", src, cameras, source)
			for(var/mob/living/simple_animal/drone/D in mob_list)
				if(D.z == source.z)
					if(state == 1)
						D.cancelAlarm("Power", src, source)
					else
						D.triggerAlarm("Power", src, cameras, source)
	return

/area/proc/atmosalert(danger_level)
//	if(src.type==/area) //No atmos alarms in space
//		return 0 //redudant
	if(danger_level != src.atmosalm)
		//src.updateicon()
		//src.mouse_opacity = 0
		if (danger_level==2)
			var/list/cameras = list()
			for(var/area/RA in src.related)
				//src.updateicon()
				for(var/obj/machinery/camera/C in RA)
					cameras += C
			for(var/mob/living/silicon/aiPlayer in player_list)
				aiPlayer.triggerAlarm("Atmosphere", src, cameras, src)
			for(var/obj/machinery/computer/station_alert/a in machines)
				a.triggerAlarm("Atmosphere", src, cameras, src)
			for(var/mob/living/simple_animal/drone/D in mob_list)
				D.triggerAlarm("Atmosphere", src, cameras, src)
		else if (src.atmosalm == 2)
			for(var/mob/living/silicon/aiPlayer in player_list)
				aiPlayer.cancelAlarm("Atmosphere", src, src)
			for(var/obj/machinery/computer/station_alert/a in machines)
				a.cancelAlarm("Atmosphere", src, src)
			for(var/mob/living/simple_animal/drone/D in mob_list)
				D.cancelAlarm("Atmosphere", src, src)
		src.atmosalm = danger_level
		return 1
	return 0

/area/proc/firealert()
	if(always_unpowered == 1) //no fire alarms in space/asteroid
		return

	var/list/cameras = list()

	for(var/area/RA in related)
		if (!( RA.fire ))
			RA.set_fire_alarm_effect()
			for(var/obj/machinery/door/firedoor/D in RA)
				if(!D.blocked)
					if(D.operating)
						D.nextstate = CLOSED
					else if(!D.density)
						spawn(0)
							D.close()
			for(var/obj/machinery/firealarm/F in RA)
				F.update_icon()
		for (var/obj/machinery/camera/C in RA)
			cameras += C

	for (var/obj/machinery/computer/station_alert/a in machines)
		a.triggerAlarm("Fire", src, cameras, src)
	for (var/mob/living/silicon/aiPlayer in player_list)
		aiPlayer.triggerAlarm("Fire", src, cameras, src)
	for (var/mob/living/simple_animal/drone/D in mob_list)
		D.triggerAlarm("Fire", src, cameras, src)
	return

/area/proc/firereset()
	for(var/area/RA in related)
		if (RA.fire)
			RA.fire = 0
			RA.mouse_opacity = 0
			RA.updateicon()
			for(var/obj/machinery/door/firedoor/D in RA)
				if(!D.blocked)
					if(D.operating)
						D.nextstate = OPEN
					else if(D.density)
						spawn(0)
							D.open()
			for(var/obj/machinery/firealarm/F in RA)
				F.update_icon()

	for (var/mob/living/silicon/aiPlayer in player_list)
		aiPlayer.cancelAlarm("Fire", src, src)
	for (var/obj/machinery/computer/station_alert/a in machines)
		a.cancelAlarm("Fire", src, src)
	for (var/mob/living/simple_animal/drone/D in mob_list)
		D.cancelAlarm("Fire", src, src)
	return

/area/proc/burglaralert(var/obj/trigger)
	if(always_unpowered == 1) //no burglar alarms in space/asteroid
		return

	var/list/cameras = list()

	for(var/area/RA in related)
		//Trigger alarm effect
		RA.set_fire_alarm_effect()
		//Lockdown airlocks
		for(var/obj/machinery/door/airlock/DOOR in RA)
			spawn(0)
				DOOR.close()
				if(DOOR.density)
					DOOR.locked = 1
					DOOR.update_icon()
		for (var/obj/machinery/camera/C in RA)
			cameras += C

	for (var/mob/living/silicon/SILICON in player_list)
		SILICON.triggerAlarm("Burglar", src, cameras, trigger)
	//Cancel silicon alert after 1 minute
	spawn(600)
		for (var/mob/living/silicon/SILICON in player_list)
			SILICON.cancelAlarm("Burglar", src, trigger)

/area/proc/set_fire_alarm_effect()
	fire = 1
	updateicon()
	mouse_opacity = 0

/area/proc/readyalert()
	if(name == "Space")
		return
	if(!eject)
		eject = 1
		updateicon()
	return

/area/proc/readyreset()
	if(eject)
		eject = 0
		updateicon()
	return

/area/proc/partyalert()
	if(src.name == "Space") //no parties in space!!!
		return
	if (!( src.party ))
		src.party = 1
		src.updateicon()
		src.mouse_opacity = 0
	return

/area/proc/partyreset()
	if (src.party)
		src.party = 0
		src.mouse_opacity = 0
		src.updateicon()
		for(var/obj/machinery/door/firedoor/D in src)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = OPEN
				else if(D.density)
					spawn(0)
					D.open()
	return

/area/proc/updateicon()
	if ((fire || eject || party) && (!requires_power||power_environ) && !lighting_space)//If it doesn't require power, can still activate this proc.
		if(fire && !eject && !party)
			icon_state = "blue"
		/*else if(atmosalm && !fire && !eject && !party)
			icon_state = "bluenew"*/
		else if(!fire && eject && !party)
			icon_state = "red"
		else if(party && !fire && !eject)
			icon_state = "party"
		else
			icon_state = "blue-red"
	else
	//	new lighting behaviour with obj lights
		icon_state = null


/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel

	if(!master.requires_power)
		return 1
	if(master.always_unpowered)
		return 0
	if(src.lighting_space)
		return 0 // Nope sorry
	switch(chan)
		if(EQUIP)
			return master.power_equip
		if(LIGHT)
			return master.power_light
		if(ENVIRON)
			return master.power_environ

	return 0

// called when power status changes

/area/proc/power_change()
	for(var/area/RA in related)
		for(var/obj/machinery/M in RA)	// for each machine in the area
			M.power_change()				// reverify power status (to update icons etc.)
		if (fire || eject || party)
			RA.updateicon()

/*
/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += master.used_light
		if(EQUIP)
			used += master.used_equip
		if(ENVIRON)
			used += master.used_environ
		if(TOTAL)
			used += master.used_light + master.used_equip + master.used_environ
		if(STATIC_EQUIP)
			used += master.static_equip
		if(STATIC_LIGHT)
			used += master.static_light
		if(STATIC_ENVIRON)
			used += master.static_environ
	return used

/area/proc/addStaticPower(value, powerchannel)
	switch(powerchannel)
		if(STATIC_EQUIP)
			static_equip += value
		if(STATIC_LIGHT)
			static_light += value
		if(STATIC_ENVIRON)
			static_environ += value


*/
/area/proc/clear_usage()

	master.used_equip = 0
	master.used_light = 0
	master.used_environ = 0

/*
/area/proc/use_power(var/amount, var/chan)

	switch(chan)
		if(EQUIP)
			master.used_equip += amount
		if(LIGHT)
			master.used_light += amount
		if(ENVIRON)
			master.used_environ += amount

*/


/area/Entered(A)
	if(!istype(A,/mob/living))	return

	var/mob/living/L = A
	if(!L.ckey)	return

	if(!L.lastarea)
		L.lastarea = get_area(L.loc)
	var/area/newarea = get_area(L.loc)

	L.lastarea = newarea

	// Ambience goes down here -- make sure to list each area seperately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(!(L && L.client && (L.client.prefs.toggles & SOUND_AMBIENCE)))	return

	if(!L.client.ambience_playing)
		L.client.ambience_playing = 1
		L << sound('sound/ambience/shipambience.ogg', repeat = 1, wait = 0, volume = 35, channel = 2)

	if(prob(35))
		var/sound = pick(ambientsounds)

		if(!L.client.played)
			L << sound(sound, repeat = 0, wait = 0, volume = 25, channel = 1)
			L.client.played = 1
			spawn(600)			//ewww - this is very very bad
				if(L.&& L.client)
					L.client.played = 0

/area/proc/mob_activate(var/mob/living/L)
	return

/proc/has_gravity(atom/AT, turf/T)
	if(!T)
		T = get_turf(AT)
	var/area/A = get_area(T)
	if(istype(T, /turf/space)) // Turf never has gravity
		return 0
	else if(A && A.has_gravity) // Areas which always has gravity
		return 1
	else
		// There's a gravity generator on our z level
		if(T && gravity_generators["[T.z]"] && length(gravity_generators["[T.z]"]))
			return 1
	return 0

/area/proc/clear_docking_area()
	var/list/dstturfs = list()
	var/throwy = world.maxy

	for(var/turf/T in src)
		dstturfs += T
		if(T.y < throwy)
			throwy = T.y

	// hey you, get out of the way!
	for(var/turf/T in dstturfs)
		// find the turf to move things to
		var/turf/D = locate(T.x, throwy - 1, T.z)
		for(var/atom/movable/AM as mob|obj in T)
			//mobs take damage
			if(istype(AM, /mob/living))
				var/mob/living/living_mob = AM
				living_mob.Paralyse(10)
				living_mob.take_organ_damage(80)
				living_mob.anchored = 0 //Unbuckle them so they can be moved
			//Anything not bolted down is moved, everything else is destroyed
			if(!AM.anchored)
				AM.Move(D)
			else
				qdel(AM)
		if(istype(T, /turf/simulated))
			del(T)

	for(var/atom/movable/bug in src) // If someone (or something) is somehow still in the shuttle's docking area...
		qdel(bug)

area/proc/get_apc()
	for(var/area/RA in src.related)
		var/obj/machinery/power/apc/FINDME = locate() in RA
		if (FINDME)
			return FINDME




/area/proc/move_contents_to(var/area/A, var/turftoleave=null, var/direction = null)
	//Takes: Area. Optional: turf type to leave behind.
	//Returns: Nothing.
	//Notes: Attempts to move the contents of one area to another area.
	//       Movement based on lower left corner. Tiles that do not fit
	//		 into the new area will not be moved.

	if(!A || !src) return 0

	var/list/turfs_src = get_area_turfs(src.type)
	var/list/turfs_trg = get_area_turfs(A.type)

	var/src_min_x = 0
	var/src_min_y = 0
	for (var/turf/T in turfs_src)
		if(T.x < src_min_x || !src_min_x) src_min_x	= T.x
		if(T.y < src_min_y || !src_min_y) src_min_y	= T.y

	var/trg_min_x = 0
	var/trg_min_y = 0
	for (var/turf/T in turfs_trg)
		if(T.x < trg_min_x || !trg_min_x) trg_min_x	= T.x
		if(T.y < trg_min_y || !trg_min_y) trg_min_y	= T.y

	var/list/refined_src = new/list()
	for(var/turf/T in turfs_src)
		refined_src += T
		refined_src[T] = new/datum/coords
		var/datum/coords/C = refined_src[T]
		C.x_pos = (T.x - src_min_x)
		C.y_pos = (T.y - src_min_y)

	var/list/refined_trg = new/list()
	for(var/turf/T in turfs_trg)
		refined_trg += T
		refined_trg[T] = new/datum/coords
		var/datum/coords/C = refined_trg[T]
		C.x_pos = (T.x - trg_min_x)
		C.y_pos = (T.y - trg_min_y)

	var/list/fromupdate = new/list()
	var/list/toupdate = new/list()

	moving:
		for (var/turf/T in refined_src)
			var/datum/coords/C_src = refined_src[T]
			for (var/turf/B in refined_trg)
				var/datum/coords/C_trg = refined_trg[B]
				if(C_src.x_pos == C_trg.x_pos && C_src.y_pos == C_trg.y_pos)

					var/old_dir1 = T.dir
					var/old_icon_state1 = T.icon_state
					var/old_icon1 = T.icon

					var/turf/X = new T.type(B)
					X.dir = old_dir1
					X.icon_state = old_icon_state1
					X.icon = old_icon1 //Shuttle floors are in shuttle.dmi while the defaults are floors.dmi


					// Give the new turf our air, if simulated
					if(istype(X, /turf/simulated) && istype(T, /turf/simulated))
						var/turf/simulated/sim = X
						sim.copy_air_with_tile(T)

					/* Quick visual fix for some weird shuttle corner artefacts when on transit space tiles */
					if(direction && findtext(X.icon_state, "swall_s"))

						// Spawn a new shuttle corner object
						var/obj/corner = new()
						corner.loc = X
						corner.density = 1
						corner.anchored = 1
						corner.icon = X.icon
						corner.icon_state = replacetext(X.icon_state, "_s", "_f")
						corner.tag = "delete me"
						corner.name = "wall"

						// Find a new turf to take on the property of
						var/turf/nextturf = get_step(corner, direction)
						if(!nextturf || !istype(nextturf, /turf/space))
							nextturf = get_step(corner, turn(direction, 180))


						// Take on the icon of a neighboring scrolling space icon
						X.icon = nextturf.icon
						X.icon_state = nextturf.icon_state


					for(var/obj/O in T)

						// Reset the shuttle corners
						if(O.tag == "delete me")
							X.icon = 'icons/turf/shuttle.dmi'
							X.icon_state = replacetext(O.icon_state, "_f", "_s") // revert the turf to the old icon_state
							X.name = "wall"
							qdel(O) // prevents multiple shuttle corners from stacking
							continue
						if(!istype(O,/obj)) continue
						O.loc = X
					for(var/mob/M in T)
						if(!M.move_on_shuttle)
							continue
						M.loc = X

//					var/area/AR = X.loc

//					if(AR.lighting_use_dynamic)							//TODO: rewrite this code so it's not messed by lighting ~Carn
//						X.opacity = !X.opacity
//						X.SetOpacity(!X.opacity)

					toupdate += X

					if(turftoleave)
						var/turf/ttl = new turftoleave(T)

//						var/area/AR2 = ttl.loc

//						if(AR2.lighting_use_dynamic)						//TODO: rewrite this code so it's not messed by lighting ~Carn
//							ttl.opacity = !ttl.opacity
//							ttl.sd_SetOpacity(!ttl.opacity)

						fromupdate += ttl

					else
						T.ChangeTurf(/turf/space)

					refined_src -= T
					refined_trg -= B
					continue moving


	if(toupdate.len)
		for(var/turf/simulated/T1 in toupdate)
			air_master.remove_from_active(T1)
			T1.CalculateAdjacentTurfs()
			air_master.add_to_active(T1,1)

	if(fromupdate.len)
		for(var/turf/simulated/T2 in fromupdate)
			air_master.remove_from_active(T2)
			T2.CalculateAdjacentTurfs()
			air_master.add_to_active(T2,1)

/area/proc/copy_contents_to(var/area/A , var/platingRequired = 0 )
	//Takes: Area. Optional: If it should copy to areas that don't have plating
	//Returns: Nothing.
	//Notes: Attempts to move the contents of one area to another area.
	//       Movement based on lower left corner. Tiles that do not fit
	//		 into the new area will not be moved.

	if(!A || !src) return 0

	var/list/turfs_src = get_area_turfs(src.type)
	var/list/turfs_trg = get_area_turfs(A.type)

	var/src_min_x = 0
	var/src_min_y = 0
	for (var/turf/T in turfs_src)
		if(T.x < src_min_x || !src_min_x) src_min_x	= T.x
		if(T.y < src_min_y || !src_min_y) src_min_y	= T.y

	var/trg_min_x = 0
	var/trg_min_y = 0
	for (var/turf/T in turfs_trg)
		if(T.x < trg_min_x || !trg_min_x) trg_min_x	= T.x
		if(T.y < trg_min_y || !trg_min_y) trg_min_y	= T.y

	var/list/refined_src = new/list()
	for(var/turf/T in turfs_src)
		refined_src += T
		refined_src[T] = new/datum/coords
		var/datum/coords/C = refined_src[T]
		C.x_pos = (T.x - src_min_x)
		C.y_pos = (T.y - src_min_y)

	var/list/refined_trg = new/list()
	for(var/turf/T in turfs_trg)
		refined_trg += T
		refined_trg[T] = new/datum/coords
		var/datum/coords/C = refined_trg[T]
		C.x_pos = (T.x - trg_min_x)
		C.y_pos = (T.y - trg_min_y)

	var/list/toupdate = new/list()

	var/copiedobjs = list()


	moving:
		for (var/turf/T in refined_src)
			var/datum/coords/C_src = refined_src[T]
			for (var/turf/B in refined_trg)
				var/datum/coords/C_trg = refined_trg[B]
				if(C_src.x_pos == C_trg.x_pos && C_src.y_pos == C_trg.y_pos)

					var/old_dir1 = T.dir
					var/old_icon_state1 = T.icon_state
					var/old_icon1 = T.icon

					if(platingRequired)
						if(istype(B, /turf/space))
							continue moving

					var/turf/X = new T.type(B)
					X.dir = old_dir1
					X.icon_state = old_icon_state1
					X.icon = old_icon1 //Shuttle floors are in shuttle.dmi while the defaults are floors.dmi


					var/list/objs = new/list()
					var/list/newobjs = new/list()
					var/list/mobs = new/list()
					var/list/newmobs = new/list()

					for(var/obj/O in T)

						if(!istype(O,/obj))
							continue

						objs += O


					for(var/obj/O in objs)
						newobjs += DuplicateObject(O , 1)


					for(var/obj/O in newobjs)
						O.loc = X

					for(var/mob/M in T)
						if(!M.move_on_shuttle)
							continue
						mobs += M

					for(var/mob/M in mobs)
						newmobs += DuplicateObject(M , 1)

					for(var/mob/M in newmobs)
						M.loc = X

					copiedobjs += newobjs
					copiedobjs += newmobs



					for(var/V in T.vars)
						if(!(V in list("type","loc","locs","vars", "parent", "parent_type","verbs","ckey","key","x","y","z","contents", "luminosity")))
							X.vars[V] = T.vars[V]

//					var/area/AR = X.loc

//					if(AR.lighting_use_dynamic)
//						X.opacity = !X.opacity
//						X.sd_SetOpacity(!X.opacity)			//TODO: rewrite this code so it's not messed by lighting ~Carn

					toupdate += X

					refined_src -= T
					refined_trg -= B
					continue moving


	if(toupdate.len)
		for(var/turf/simulated/T1 in toupdate)
			T1.CalculateAdjacentTurfs()
			air_master.add_to_active(T1,1)


	return copiedobjs
