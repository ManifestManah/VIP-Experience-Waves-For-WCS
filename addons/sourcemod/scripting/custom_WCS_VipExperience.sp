// List of Includes
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

// The code formatting rules we wish to follow
#pragma semicolon 1;
#pragma newdecls required;


// The retrievable information about the plugin itself 
public Plugin myinfo =
{
	name		= "[CS:GO] VIP Experience",
	author		= "Manifest @Road To Glory",
	description	= "All online active VIP players receives bonus experience in waves.",
	version		= "V. 1.0.0 [Beta]",
	url			= ""
};


// Config Convars
Handle cvar_VipExperienceInterval;
Handle cvar_VipExperienceAmount;

// Cookie Related Variables
bool option_vipxp_message[MAXPLAYERS + 1] = {true,...};
Handle cookie_vipxp_message = INVALID_HANDLE;


// This happens when the plugin is loaded
public void OnPluginStart()
{
	// The list of convars which we'll use to adjust features through our auto generated config file
	cvar_VipExperienceInterval = CreateConVar("Mani_VipExperienceInterval", "120.0", "The amount of time in seconds between each VIP experience handout - [Default = 120.0]");
	cvar_VipExperienceAmount = CreateConVar("Mani_VipExperienceAmount", "25", "The amount of experience a VIP player should receive whenever an experience handout happens - [Default = 25]");
	
	//Cookie Stuff
	cookie_vipxp_message = RegClientCookie("VIP XP Messages On/Off 1", "vipmsg1337", CookieAccess_Private);
	SetCookieMenuItem(CookieMenuHandler_vipxp_message, cookie_vipxp_message, "VIP XP Messages");

	// Automatically generates a config file that contains our variables
	AutoExecConfig(true, "custom_WCS_VipExperience");

	// Loads the multi-language translation file
	LoadTranslations("custom_WCS_VipExperience.phrases");

	// Creates our timer that we'll use to update our players' HUD
	CreateTimer(GetConVarFloat(cvar_VipExperienceInterval), TimerExperienceVIP, _, TIMER_REPEAT && TIMER_FLAG_NO_MAPCHANGE);
}


public Action TimerExperienceVIP(Handle timer, any unused)
{
	for(int client = 1;client < MaxClients+1;client++)
	{
		// Checks if the player meets our client validation criteria
		if(IsValidClient(client))
		{
			// If the player is alive then proceed
			if (!IsFakeClient(client))
			{
				// If the player is on the Terrorist or Counter-Terrorist team then execute this section
				if (GetClientTeam(client) <= 2)
				{
					// Checks if the player has the "O" admin flag, if he does then execute this section
					if (CheckCommandAccess(client, "ViPExperienceInterval", ADMFLAG_CUSTOM1))
					{
						// We create a variable named userid which we need as Source-Python commands uses userid's instead of indexes
						int userid = GetClientUserId(client);

						// Obtains the value of the Convar and store the value within our variable IntervalExperienceVIP
						int VipExperienceAmount = GetConVarInt(cvar_VipExperienceAmount);

						// Creates a variable named ServerCommandMessage which we'll store our message data within
						char ServerCommandMessage[128];

						// Formats a message and store it within our ServerCommandMessage variable
						FormatEx(ServerCommandMessage, sizeof(ServerCommandMessage), "wcs_givexp %i %i", userid, VipExperienceAmount);

						// Executes our GiveLevel server command on the player, to award them with levels
						ServerCommand(ServerCommandMessage);

						// If the client has VIP Experience Messages Enabled
						if (option_vipxp_message[client])
						{
							// Prints a message to the client's chat
							CPrintToChat(client, "%t", "VIP Experience Reward", VipExperienceAmount);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}


// We call upon this true and false statement whenever we wish to validate our player
bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientConnected(client) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}

	return true;
}


// Cookie Stuff
public void OnClientCookiesCached(int client)
{
	option_vipxp_message[client] = GetCookievipxp_message(client);
}


bool GetCookievipxp_message(int client)
{
	char buffer[10];

	GetClientCookie(client, cookie_vipxp_message, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}


public void CookieMenuHandler_vipxp_message(int client, CookieMenuAction action, any vipxp_message, char[] buffer, int maxlen)
{	
	if (action == CookieMenuAction_DisplayOption)
	{
		char status[16];
		if (option_vipxp_message[client])
		{
			Format(status, sizeof(status), "%s", "[ON]", client);
		}
		else
		{
			Format(status, sizeof(status), "%s", "[OFF]", client);
		}
		
		Format(buffer, maxlen, "EXP VIP Messages: %s", status);
	}
	else
	{
		option_vipxp_message[client] = !option_vipxp_message[client];
		
		if (option_vipxp_message[client])
		{
			SetClientCookie(client, cookie_vipxp_message, "On");
			CPrintToChat(client, "%t", "VIP Experience Messages Enabled");
		}
		else
		{
			SetClientCookie(client, cookie_vipxp_message, "Off");
			CPrintToChat(client, "%t", "VIP Experience Messages Disabled");
		}
		
		ShowCookieMenu(client);
	}
}
