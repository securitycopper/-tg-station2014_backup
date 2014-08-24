
var/global/datum/power/PowerNode/apsForLighting
//#define DEBUG_POWERNODE_BATTERY 1
//#define DEBUG_WIRENETWORK_PROCESS 1
//#define DEBUG_WIRENETWORK_ADD 1
//#define DEBUG_WIRENETWORK_PRINT_TREE 1
client/verb


	Power_Count_Networks()
		world << "[powerNetworkControllerProcessingLoopList.len]"

	Power_PrintGrid()
		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			//wireNetwork.process()
			wireNetwork.debugDebugNetwork()

			#if defined(DEBUG_WIRENETWORK_PRINT_TREE)

			#endif









