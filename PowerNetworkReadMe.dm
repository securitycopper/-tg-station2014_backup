/*

This file discusses the power network rewrite







#################    Requirments  #################

Terms:

Fully Portable - Matthew Cummings wrote the full power rewrite and has given his permission for the code to be
					used with other SS13 versions. Please don't modify the standard files and report bugs
					to mcdreamware@gmail.com

WireNetwork - Complete rewrite of the old power_network concept.
				They exist for every area that has something drawing power from the area.
				They replace the old area power logic
				They connect to diffrent areas based on wire connections

Power Node - This replaces all the custom machine power logic with a machine power configuration
				The machine lisens to diffrent events rather then checking every time to see if it has power
				Battery logic, SMES, and APC logic are all now standardized within PowerNode

PowerNetworkController - Contains lists of all existing PowerNodes with batteries and WireNetworks.
							These will be processed during the main controller processing loop

PowerNodeConsts - This contains a list of #define statments that each machine uses for its power.
					The goal with this was to abstract the power usage to a seperate file that
					can be later tweaked to reblance the powerusage across the machines.

PowerNodeUtils - Contains depercated/custom logic that supports some backwords compatiblity
					with the old method calls from machines that I haven't converted over yet.
					Logic that ties the system to a code base like tg is placed here


----- Standardized Logic ------
Old batteries still use the add/remove power. PowerNodeUtils has a proc for simulating adding a
battery to a power node.

APC, SMES, and every Machine use the same power logic.
Every machine 'could' if programed to have a battery.

Machines knotted to wires will draw power from the wire vs the area network if they are configured
for area power.



----- Less CPU usage then the old network -----
The Old:
The old power network had alot of hidden time.
For example, most of the power callculation was hidden within the tic time of the machine loop.
Adding some of the machine loop time with the power network loop time would be the real time
Every time the machine would use power it would subtract it from the grid during its loop

The New system works on diffrences.  A machine creates a PowerNode and configures it for its use.
The machine only updates the PowerNode configuration when the power levels change.
This means that the processing loop for the new system is around 200 as of 9/27/2014 to account
for every PowerNetwork and PowerNode that has a battery.  If the machine doesn't have a battery,
then it won't be in the processing loop.

To avoid the checks during the machine loop to determine if the machine is connected and running still,
the machine implements a power_onChangeEvent(var/event) that notifies the machine of what changed.
This means you can write a swith that turns your machine 'on' when the power is on to the machine.


PowerNodes only output power to make up the diffrence of the network.
If you have multiple SMESs on the same WireNetwork


#############  API  ######################

----- Power Nodes -----





*/