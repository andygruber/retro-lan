// Bots (the CS bots built into ReGameDLL)
//
// Bots fill the teams up to lan_bots_quota players and leave again when
// humans join. They only join once a human is on the server.
//
// say /bots, amx_botmenu or amxmodmenu > Bots: admin menu
//
// Defaults: configs/plugins/lan_bots.cfg (executed once per server start, so
// changes made in the menu last until the server restarts).
// Mode cfgs (configs/modes/*.cfg) can set lan_bots_allowed 0 to have no bots
// in that mode.

#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "LAN Bots"
#define VERSION "1.0"
#define AUTHOR  "cs16-srv"

#define ACCESS ADMIN_CVAR
#define TASK_APPLY 51400

new const PREFIX[] = "^4[Bots]^1";

new const DIFFICULTY[][] = { "Easy", "Normal", "Hard", "Expert" };
new const WEAPONS[][] = { "All weapons", "Pistols only", "Snipers only", "Knives only" };
new const WEAPON_CMDS[][] = { "bot_all_weapons", "bot_pistols_only", "bot_snipers_only", "bot_knives_only" };
new const CHATTER[][] = { "normal", "minimal", "radio", "off" };

new g_pEnabled, g_pQuota, g_pDifficulty, g_pWeapons, g_pChatter, g_pAllowed, g_pLoaded;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pEnabled = create_cvar("lan_bots_enabled", "1", _, "Bots on (1) or off (0)", true, 0.0, true, 1.0);
	g_pQuota = create_cvar("lan_bots_quota", "10", _, "Bots fill up to this many players (humans + bots)", true, 0.0, true, 32.0);
	g_pDifficulty = create_cvar("lan_bots_difficulty", "1", _, "0 easy, 1 normal, 2 hard, 3 expert", true, 0.0, true, 3.0);
	g_pWeapons = create_cvar("lan_bots_weapons", "0", _, "0 all, 1 pistols only, 2 snipers only, 3 knives only", true, 0.0, true, 3.0);
	g_pChatter = create_cvar("lan_bots_chatter", "0", _, "Radio chatter: 0 normal, 1 minimal, 2 radio only, 3 off", true, 0.0, true, 3.0);
	g_pAllowed = create_cvar("lan_bots_allowed", "1", _, "Set by the mode cfgs: 0 = no bots in this mode", true, 0.0, true, 1.0);
	g_pLoaded = create_cvar("lan_bots_loaded", "0", FCVAR_PROTECTED, "Internal: defaults executed");

	new const cvars[][] = { "lan_bots_enabled", "lan_bots_quota", "lan_bots_difficulty", "lan_bots_weapons", "lan_bots_chatter", "lan_bots_allowed" };
	for (new i = 0; i < sizeof(cvars); i++)
		hook_cvar_change(get_cvar_pointer(cvars[i]), "OnCvarChange");

	register_concmd("amx_botmenu", "CmdBotMenu", ACCESS, "- bot settings menu");
	register_clcmd("say /bots", "CmdSayBots");
	register_clcmd("say_team /bots", "CmdSayBots");

	AddMenuItem("Bots", "amx_botmenu", ACCESS, PLUGIN);
}

public plugin_cfg()
{
	// cvars survive map changes, so the defaults only once per server start
	if (!get_pcvar_num(g_pLoaded))
	{
		new path[PLATFORM_MAX_PATH];
		get_configsdir(path, charsmax(path));
		add(path, charsmax(path), "/plugins/lan_bots.cfg");
		if (file_exists(path))
		{
			server_cmd("exec ^"%s^"", path);
			server_exec();
		}
		set_pcvar_num(g_pLoaded, 1);
	}

	// after the mode cfg (lan_modes runs it after 1 s)
	QueueApply(2.0);
}

public OnCvarChange(pcvar, const oldValue[], const newValue[])
{
	QueueApply(0.1);
}

QueueApply(Float:delay)
{
	remove_task(TASK_APPLY);
	set_task(delay, "Apply", TASK_APPLY);
}

public Apply()
{
	new quota = 0;
	if (get_pcvar_num(g_pEnabled) && get_pcvar_num(g_pAllowed))
		quota = min(get_pcvar_num(g_pQuota), get_maxplayers());

	server_cmd("bot_quota_mode fill");
	server_cmd("bot_difficulty %d", get_pcvar_num(g_pDifficulty));
	server_cmd("bot_chatter %s", CHATTER[get_pcvar_num(g_pChatter)]);
	server_cmd("%s", WEAPON_CMDS[get_pcvar_num(g_pWeapons)]);
	server_cmd("bot_quota %d", quota);
}

public CmdBotMenu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
		ShowMenu(id);
	return PLUGIN_HANDLED;
}

public CmdSayBots(id)
{
	if (access(id, ACCESS))
		ShowMenu(id);
	else
		client_print_color(id, print_team_default, "%s Bots fill up to ^4%d^1 players. Only admins can change that.", PREFIX, get_pcvar_num(g_pQuota));
	return PLUGIN_HANDLED;
}

ShowMenu(id, page = 0)
{
	new menu = menu_create("\yBots^n\dfill the teams until enough humans are there", "MenuHandler");
	new text[96];

	if (!get_pcvar_num(g_pAllowed))
		formatex(text, charsmax(text), "Bots: \d%s (off in this game mode)", get_pcvar_num(g_pEnabled) ? "on" : "off");
	else
		formatex(text, charsmax(text), "Bots: \y%s", get_pcvar_num(g_pEnabled) ? "on" : "off");
	menu_additem(menu, text);

	formatex(text, charsmax(text), "Fill up to: \y%d players", get_pcvar_num(g_pQuota));
	menu_additem(menu, text);

	formatex(text, charsmax(text), "Difficulty: \y%s", DIFFICULTY[get_pcvar_num(g_pDifficulty)]);
	menu_additem(menu, text);

	formatex(text, charsmax(text), "Weapons: \y%s", WEAPONS[get_pcvar_num(g_pWeapons)]);
	menu_additem(menu, text);

	formatex(text, charsmax(text), "Radio chatter: \y%s", CHATTER[get_pcvar_num(g_pChatter)]);
	menu_additem(menu, text);

	menu_additem(menu, "Kick all bots now \d(they rejoin)");

	menu_display(id, menu, page);
}

public MenuHandler(id, menu, item)
{
	menu_destroy(menu);
	if (item < 0 || !access(id, ACCESS))
		return PLUGIN_HANDLED;

	new name[32];
	get_user_name(id, name, charsmax(name));

	switch (item)
	{
		case 0:
		{
			new on = !get_pcvar_num(g_pEnabled);
			set_pcvar_num(g_pEnabled, on);
			client_print_color(0, id, "%s ^3%s^1 turned the bots ^4%s^1.", PREFIX, name, on ? "on" : "off");
		}
		case 1:
		{
			// 2, 4, ... max players, then back to 2
			new quota = get_pcvar_num(g_pQuota) + 2;
			if (quota > get_maxplayers())
				quota = 2;
			quota -= quota % 2;
			set_pcvar_num(g_pQuota, quota);
			client_print_color(0, id, "%s ^3%s^1: bots fill up to ^4%d^1 players.", PREFIX, name, quota);
		}
		case 2:
		{
			new difficulty = (get_pcvar_num(g_pDifficulty) + 1) % sizeof(DIFFICULTY);
			set_pcvar_num(g_pDifficulty, difficulty);
			// bot_difficulty only applies to new bots
			KickBots();
			client_print_color(0, id, "%s ^3%s^1: bot difficulty ^4%s^1.", PREFIX, name, DIFFICULTY[difficulty]);
		}
		case 3:
		{
			new weapons = (get_pcvar_num(g_pWeapons) + 1) % sizeof(WEAPONS);
			set_pcvar_num(g_pWeapons, weapons);
			client_print_color(0, id, "%s ^3%s^1: bots use ^4%s^1.", PREFIX, name, WEAPONS[weapons]);
		}
		case 4:
		{
			set_pcvar_num(g_pChatter, (get_pcvar_num(g_pChatter) + 1) % sizeof(CHATTER));
		}
		case 5:
		{
			KickBots();
			client_print_color(0, id, "%s ^3%s^1 kicked all bots.", PREFIX, name);
		}
	}

	ShowMenu(id);
	return PLUGIN_HANDLED;
}

KickBots()
{
	// bot_kick also sets bot_quota 0, Apply sets it again
	server_cmd("bot_kick");
	QueueApply(1.0);
}
