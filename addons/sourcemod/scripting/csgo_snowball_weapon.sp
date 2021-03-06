#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define DATA "1.0"

public Plugin myinfo =
{
	name = "SM CS:GO SnowBall Weapon",
	author = "Chris187",
	description = "For use the new weapon_snowball",
	version = DATA,
	url = "https://cgaming.eu/"
};

ConVar cv_team;
ConVar cv_snowballs;
ConVar cv_wtimer;

int g_iTeam;
int g_iSnowballs;
float g_fTimer;

public void OnPluginStart()
{
	CreateConVar("sm_snowballweapon_version", DATA, "Plugin Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cv_team = CreateConVar("sm_snowballweapon_team", "4", "Apply only to a team. 2 = terrorist, 3 = counter-terrorist, 4 = both.", 0, true, 0.0, true, 4.0);
	cv_snowballs = CreateConVar("sm_snowballweapon_amount", "3", "Amount of snowballs that you will receive on spawn.", 0, true, 0.0);
	cv_wtimer = CreateConVar("sm_snowballweapon_timer", "1.6", "Time in seconds after spawn to give snowball weapons.", 0, true, 0.0);
	
	g_iTeam = GetConVarInt(cv_team);
	g_iSnowballs = GetConVarInt(cv_snowballs);
	g_fTimer = GetConVarFloat(cv_wtimer);
	
	HookConVarChange(cv_team, OnConVarChanged);
	HookConVarChange(cv_snowballs, OnConVarChanged);
	HookConVarChange(cv_wtimer, OnConVarChanged);
	
	// Plugin only for csgo
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
		
	// hook spawn event
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	AutoExecConfig(true, "csgo_snowball_weapon");
}

public void OnConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if (convar == cv_team) {
		g_iTeam = StringToInt(newVal);
	} else if (convar == cv_snowballs) {
		g_iSnowballs = StringToInt(newVal);
	} else if (convar == cv_wtimer) {
		g_fTimer = StringToFloat(newVal);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // delay for don't conflict with others plugins that give weapons on spawn (?)
    CreateTimer(g_fTimer, Timer_Delay, GetClientUserId(client));
}  

public Action Timer_Delay(Handle timer, int id)
{
	// check if client valid
	int client = GetClientOfUserId(id);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || (g_iTeam < 4 && g_iTeam != GetClientTeam(client)))
		return;
			
	// remove all the snowball weapons for prevent extra weapons on ground
	StripAllSnowBalls(client);
	
	if(g_iSnowballs > 0)
	{
		for (int i = 0; i < g_iSnowballs; i++)
			GivePlayerItem(client, "weapon_snowball");
	}
}
	
stock void StripAllSnowBalls(int client)
{
	int m_hMyWeapons_size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons"); // array size 
	int item; 
	char classname[64];
	
	for(int index = 0; index < m_hMyWeapons_size; index++) 
	{ 
		item = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", index); 

		if(item != -1 && GetEntityClassname(item, classname, sizeof(classname)) && StrEqual(classname, "weapon_snowball")) 
		{ 
			RemovePlayerItem(client, item);
			AcceptEntityInput(item, "Kill");
		} 
	} 
}