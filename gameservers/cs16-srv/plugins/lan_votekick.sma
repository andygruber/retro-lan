// Player vote kick
//
// say /votekick   pick a player, everyone else votes yes/no
//
// On a LAN server every player has the same STEAM_ID_LAN, so the temporary
// ban (lan_votekick_bantime) is done by IP.

#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "LAN Vote Kick"
#define VERSION "1.0"
#define AUTHOR  "cs16-srv"

#define TASK_VOTE 51300

new const PREFIX[] = "^4[VoteKick]^1";

new bool:g_running;
new g_voteMenu;
new g_targetUserId;
new g_targetName[32];
new g_yes, g_no, g_needed;
new bool:g_voted[MAX_PLAYERS + 1];
new Float:g_nextAllowed[MAX_PLAYERS + 1];

new g_pRatio, g_pMinPlayers, g_pTime, g_pDelay, g_pBanTime, g_pImmunity;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pRatio = create_cvar("lan_votekick_ratio", "0.6", _, "Share of players (without the target) that must vote yes", true, 0.0, true, 1.0);
	g_pMinPlayers = create_cvar("lan_votekick_minplayers", "3", _, "Minimum players on the server to start a vote kick", true, 2.0);
	g_pTime = create_cvar("lan_votekick_time", "20", _, "Duration of a vote kick in seconds", true, 5.0);
	g_pDelay = create_cvar("lan_votekick_delay", "60", _, "Seconds a player has to wait before starting another vote kick", true, 0.0);
	g_pBanTime = create_cvar("lan_votekick_bantime", "5", _, "Minutes the kicked player's IP is banned (0 = kick only)", true, 0.0);
	g_pImmunity = create_cvar("lan_votekick_immunity", "1", _, "Players with admin immunity (flag a) cannot be vote kicked", true, 0.0, true, 1.0);

	register_clcmd("say /votekick", "CmdVoteKick");
	register_clcmd("say votekick", "CmdVoteKick");
	register_clcmd("say_team /votekick", "CmdVoteKick");
	register_clcmd("lan_votekick", "CmdVoteKick");
}

public client_disconnected(id)
{
	g_nextAllowed[id] = 0.0;
}

public CmdVoteKick(id)
{
	if (g_running)
	{
		client_print_color(id, print_team_default, "%s A vote kick is already running.", PREFIX);
		return PLUGIN_HANDLED;
	}

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");
	new minPlayers = get_pcvar_num(g_pMinPlayers);
	if (num < minPlayers)
	{
		client_print_color(id, print_team_default, "%s At least ^4%d^1 players are needed for a vote kick.", PREFIX, minPlayers);
		return PLUGIN_HANDLED;
	}

	new wait = floatround(g_nextAllowed[id] - get_gametime(), floatround_ceil);
	if (wait > 0)
	{
		client_print_color(id, print_team_default, "%s Please wait ^4%d^1 seconds before starting another vote kick.", PREFIX, wait);
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\yVote kick player", "PickMenuHandler");
	new name[32], info[8], count;
	new bool:immunity = get_pcvar_num(g_pImmunity) != 0;
	for (new i = 0; i < num; i++)
	{
		new p = players[i];
		if (p == id || (immunity && access(p, ADMIN_IMMUNITY)))
			continue;

		get_user_name(p, name, charsmax(name));
		num_to_str(get_user_userid(p), info, charsmax(info));
		menu_additem(menu, name, info);
		count++;
	}

	if (!count)
	{
		menu_destroy(menu);
		client_print_color(id, print_team_default, "%s There is nobody you can vote kick.", PREFIX);
		return PLUGIN_HANDLED;
	}

	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public PickMenuHandler(id, menu, item)
{
	if (item < 0)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new info[8], access_, callback;
	menu_item_getinfo(menu, item, access_, info, charsmax(info), _, _, callback);
	menu_destroy(menu);

	new target = find_player("k", str_to_num(info));
	if (!target)
	{
		client_print_color(id, print_team_default, "%s That player has left.", PREFIX);
		return PLUGIN_HANDLED;
	}
	if (g_running)
	{
		client_print_color(id, print_team_default, "%s A vote kick is already running.", PREFIX);
		return PLUGIN_HANDLED;
	}

	StartVote(id, target);
	return PLUGIN_HANDLED;
}

StartVote(id, target)
{
	g_running = true;
	g_targetUserId = get_user_userid(target);
	get_user_name(target, g_targetName, charsmax(g_targetName));
	g_nextAllowed[id] = get_gametime() + get_pcvar_float(g_pDelay);
	arrayset(g_voted, false, sizeof(g_voted));

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");

	// starter votes yes automatically, the target does not vote
	g_yes = 1;
	g_no = 0;
	g_voted[id] = true;
	g_needed = floatround(get_pcvar_float(g_pRatio) * float(num - 1), floatround_ceil);
	if (g_needed < 2)
		g_needed = 2;

	new voteTime = get_pcvar_num(g_pTime);
	new title[96];
	formatex(title, charsmax(title), "\yKick %s?", g_targetName);
	g_voteMenu = menu_create(title, "VoteMenuHandler");
	menu_additem(g_voteMenu, "Yes");
	menu_additem(g_voteMenu, "No");
	menu_setprop(g_voteMenu, MPROP_EXIT, MEXIT_NEVER);

	for (new i = 0; i < num; i++)
	{
		if (players[i] != id && players[i] != target)
			menu_display(players[i], g_voteMenu, 0, voteTime);
	}

	new name[32];
	get_user_name(id, name, charsmax(name));
	client_print_color(0, id, "%s ^3%s^1 started a vote to kick ^4%s^1 (%d yes votes needed).", PREFIX, name, g_targetName, g_needed);
	log_amx("%s started a vote kick against %s", name, g_targetName);

	set_task(float(voteTime), "EndVote", TASK_VOTE);
}

public VoteMenuHandler(id, menu, item)
{
	if (item < 0 || !g_running || g_voted[id])
		return PLUGIN_HANDLED;

	g_voted[id] = true;
	if (item == 0)
		g_yes++;
	else
		g_no++;

	new name[32];
	get_user_name(id, name, charsmax(name));
	client_print_color(0, id, "%s ^3%s^1 voted ^4%s^1 (%d/%d yes)", PREFIX, name, item == 0 ? "yes" : "no", g_yes, g_needed);

	// finish early once the result is clear; not from inside the handler of
	// the menu that EndVote destroys
	if (g_yes >= g_needed && task_exists(TASK_VOTE))
	{
		remove_task(TASK_VOTE);
		set_task(0.1, "EndVote", TASK_VOTE);
	}
	return PLUGIN_HANDLED;
}

public EndVote()
{
	g_running = false;

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");
	for (new i = 0; i < num; i++)
		show_menu(players[i], 0, "^n", 1);
	menu_destroy(g_voteMenu);

	new target = find_player("k", g_targetUserId);
	if (!target)
	{
		client_print_color(0, print_team_default, "%s ^4%s^1 left before the vote ended.", PREFIX, g_targetName);
		return;
	}

	if (g_yes < g_needed)
	{
		client_print_color(0, print_team_default, "%s Vote kick against ^4%s^1 failed (%d yes, %d no, %d needed).", PREFIX, g_targetName, g_yes, g_no, g_needed);
		return;
	}

	new banTime = get_pcvar_num(g_pBanTime);
	new ip[32];
	get_user_ip(target, ip, charsmax(ip), 1);
	if (banTime > 0 && ip[0] && !equal(ip, "127.0.0.1") && !equal(ip, "loopback"))
		server_cmd("addip %d %s", banTime, ip);

	client_print_color(0, print_team_default, "%s ^4%s^1 was kicked by vote (%d yes, %d no).", PREFIX, g_targetName, g_yes, g_no);
	log_amx("%s (%s) was vote kicked (%d yes, %d no)", g_targetName, ip, g_yes, g_no);
	server_cmd("kick #%d ^"Kicked by player vote^"", g_targetUserId);
}
