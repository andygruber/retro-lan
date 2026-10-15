// Player menu: one entry point for votes and info
//
// say /menu  or console "lanmenu" (bindable: bind F3 lanmenu)
// Admins also get "Start map vote" (here and in amxmodmenu), bots and the
// admin menu.

#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "LAN Menu"
#define VERSION "1.0"
#define AUTHOR  "cs16-srv"

// text shown, chat command it runs for the player
new const ITEMS[][][] = {
	{ "Rock the vote (change map)", "rtv" },
	{ "Nominate a map",             "/maps" },
	{ "Vote game mode",             "/votemode" },
	{ "Vote kick a player",         "/votekick" },
	{ "Time left",                  "timeleft" },
	{ "Next map",                   "nextmap" }
};

new g_pAdvert;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pAdvert = create_cvar("lan_menu_advert", "240", _, "Seconds between chat hints about /menu (0 = off)", true, 0.0);

	register_clcmd("say /menu", "CmdMenu");
	register_clcmd("say menu", "CmdMenu");
	register_clcmd("say !menu", "CmdMenu");
	register_clcmd("say_team /menu", "CmdMenu");
	register_clcmd("lanmenu", "CmdMenu");

	AddMenuItem("Start Map Vote", "mapm_start_vote", ADMIN_MAP, PLUGIN);
}

public plugin_cfg()
{
	new Float:interval = get_pcvar_float(g_pAdvert);
	if (interval > 0.0)
		set_task(interval, "Advert", _, _, _, "b");
}

public Advert()
{
	client_print_color(0, print_team_default, "^4[LAN]^1 Type ^4/menu^1 for map votes, game modes and vote kick.");
}

public CmdMenu(id)
{
	new menu = menu_create("\yLAN Server Menu", "MenuHandler");
	new info[32];
	for (new i = 0; i < sizeof(ITEMS); i++)
	{
		formatex(info, charsmax(info), "say %s", ITEMS[i][1]);
		menu_additem(menu, ITEMS[i][0], info);
	}

	if (access(id, ADMIN_MAP))
		menu_additem(menu, "\rStart map vote", "cmd mapm_start_vote");
	if (access(id, ADMIN_CVAR))
		menu_additem(menu, "\rBots", "cmd amx_botmenu");
	if (access(id, ADMIN_MENU))
		menu_additem(menu, "\rAdmin menu", "cmd amxmodmenu");

	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public MenuHandler(id, menu, item)
{
	if (item < 0)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new info[32], access_, callback;
	menu_item_getinfo(menu, item, access_, info, charsmax(info), _, _, callback);
	menu_destroy(menu);

	// the commands check admin access themselves
	if (equal(info, "say ", 4))
		amxclient_cmd(id, "say", info[4]);
	else if (equal(info, "cmd ", 4))
		amxclient_cmd(id, info[4]);
	return PLUGIN_HANDLED;
}
