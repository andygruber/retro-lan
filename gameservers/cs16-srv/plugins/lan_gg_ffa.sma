// Starts ReGG (GunGame) in free-for-all mode. Used instead of
// regg_controller.amxx by the gungame_ffa mode, because regg_controller reads
// regg_mode at map start, before the mode cfg can set it.

#include <amxmodx>
#include <regg>

public plugin_init()
{
	register_plugin("LAN GunGame FFA", "1.0", "cs16-srv");
}

public plugin_cfg()
{
	ReGG_Start(ReGG_ModeFFA);
}
