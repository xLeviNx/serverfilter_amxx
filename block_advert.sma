#include <amxmodx>
#include <fakemeta>

#define BLOCK_NAME_SPAM				
#define TIME_WAIT	5.0			
#define DEFAULT_NAME	"Example"	
#define TRUE_KEY	"example.co"		
						
new const g_sBadKeys[][] = 
{ 
	"skype", "icq", "connect", "guns", ":27", 
	"http:", "https:", "www.", ".net", ".com", ".ua", ".ru", ".info", ".org", ".tv", ".su", ".biz", ".eu", ".uc", ".ee", ".name", ".ucoz",
	".net", ".de", ".uk", ".lv", ".at", ".3dn", ".my", ".su", ".do", ".am", ".es", ".hu", ".ae", ".po", ".pl", ".lt", ".ro"
}

#define FM_ChangeName(%1,%2,%3) engfunc(EngFunc_SetClientKeyValue, %1, %3, "name", %2)
#define	GetBit(%1,%2)		(%1 & (1 << (%2 & 31)))
#define	SetBit(%1,%2)		%1 |= (1 << (%2 & 31))
#define	ResetBit(%1,%2)		%1 &= ~(1 << (%2 & 31))
new g_bConnected, g_bChecked;

public plugin_init()
{
	register_plugin("Block All Adverts", "1.0", "");
	
	register_forward(FM_ClientUserInfoChanged, "FmClientUserInfoChanged");
	register_clcmd("say", "HookSay");
	register_clcmd("say_team", "HookSay");
}

public client_putinserver(id)
	SetBit(g_bConnected, id);

public client_disconnected(id)
{
	ResetBit(g_bConnected, id);
	ResetBit(g_bChecked, id);
}

public FmClientUserInfoChanged(pClient, Infobuffer)
{
	if(!GetBit(g_bConnected, pClient))
		return FMRES_IGNORED;
		
	static sNewName[32], sOldName[32];
	get_user_name(pClient, sOldName, charsmax(sOldName));
	engfunc(EngFunc_InfoKeyValue, Infobuffer, "name", sNewName, charsmax(sNewName));
	if(!GetBit(g_bChecked, pClient) || strcmp(sNewName, sOldName))
	{
#if defined BLOCK_NAME_SPAM
		if(GetBit(g_bChecked, pClient))
		{
			if(is_user_alive(pClient))
			{
				static Float:flCurrentTime, Float:flWaitName[33];
				if((flCurrentTime = get_gametime()) < flWaitName[pClient])
				{
					flWaitName[pClient] = flCurrentTime + TIME_WAIT;
					FM_ChangeName(pClient, sOldName, Infobuffer);
					return FMRES_HANDLED; 
				}
				flWaitName[pClient] = flCurrentTime + TIME_WAIT;
			}
		}	
#endif	
		if(!IsValidString(sNewName))
			FM_ChangeName(pClient, DEFAULT_NAME, Infobuffer);
		else
		{
			new bool:bChange;
			for(new i; sNewName[i] != '^0'; i++)
			{
				if(sNewName[i] == '#' || sNewName[i] == '+')
				{
					sNewName[i] = ' ';
					bChange = true;
				}	
			}
			if(bChange) FM_ChangeName(pClient, sNewName, Infobuffer);
		}
		SetBit(g_bChecked, pClient);	
	}	
	return FMRES_IGNORED;
}

public HookSay(id)
{
	static sMsg[128]; read_args(sMsg, charsmax(sMsg));
	if(!sMsg[0]) return PLUGIN_HANDLED;
	
	return (IsValidString(sMsg)) ? PLUGIN_CONTINUE : PLUGIN_HANDLED;
}

bool:IsValidString(string[])
{
	if(containi(string, TRUE_KEY) != -1) return true;
	for(new i; i < sizeof g_sBadKeys; i++)
		if(containi(string, g_sBadKeys[i]) != -1) return false;
	return true;	
}
