/*
*
*	Guillotine by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /guillotine [name]             "Opens the Guillotine menu or executes the specified player."
*       say_team /guillotine [name]        "Opens the Guillotine menu or executes the specified player."
*       guillotine_reload                  "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                         32
#define GUILLOTINE_CHECK                10.0
#define GUILLOTINE_OFFSET_BASE          120.0
#define GUILLOTINE_OFFSET_MIN           65.0
#define GUILLOTINE_OFFSET_MAX           900.0
#define GUILLOTINE_OFFSET_STEP          10.0
#define GUILLOTINE_GHOST_ALPHA          120
#define GUILLOTINE_ROTATION_STEP        22.5
#define ADMIN_ACCESS                    ADMIN_RCON
#define PDATA_NEXT_ATTACK               83
#define XO_CBASEPLAYER                  5
#define XO_CBASEPLAYERWEAPON            4
#define GUILLOTINE_KEY                  871002
#define GUILLOTINE_HEAD_KEY             123123
#define GUILLOTINE_ARRAY_ITEM           pev_iuser1
#define SEQ                             60
#define VIEW_FORWARD_OFFSET             192.0
#define VIEW_RIGHT_OFFSET               64.0
#define VIEW_UP_OFFSET                  32.0
#define GUILLOTINE_SEQ_DURATION         0.858
#define GUILLOTINE_SEQ_DOWN             0
#define GUILLOTINE_SEQ_UP               1
#define HEAD_FORWARD_OFFSET             22.5
#define HEAD_DAMPING_FACTOR             0.825
#define HEAD_SPEED_TO_STOP              30.0
#define HEAD_SPEED_FOR_SOUND            500.0
#define SOUND_NAV                       "buttons/blip1.wav"
#define SOUND_REMOVE                    "buttons/button10.wav"
#define SOUND_ALERT                     "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "Guillotine_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_GUILLOTINE
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_MODEL_HEAD,
    Array:SETTING_DEFAULT_SOUND,
    Array:SETTING_DEFAULT_SOUND_SLICE,
    Array:SETTING_DEFAULT_SOUND_FLESH,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    SETTING_DEFAULT_HOLD_DURATION[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_HEAD_VELOCITY[2],
    Float:SETTING_DEFAULT_HEAD_AVELOCITY[2],
    Float:SETTING_DEFAULT_HEAD_LIFE[2],
    bool:SETTING_PLAY_SOUND_ON_DEATH,
    bool:SETTING_WRITE_MESSAGE_ON_DEATH,
    bool:SETTING_CREATE_HEAD_ON_DEATH,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_GUILLOTINE_LOAD,
    Float:SETTING_GUILLOTINE_TASK,
}

enum _:GUILLOTINE
{
    GUILLOTINE_ID,
    GUILLOTINE_ITEM,
    GUILLOTINE_FLAGS,
    GUILLOTINE_TEAM,
    GUILLOTINE_VIEW,
    GUILLOTINE_NAME[MAX_VALUE_LENGTH],
    Float:GUILLOTINE_COOLDOWN[2],
    Float:GUILLOTINE_FRAMERATE,

    Float:GUILLOTINE_ORIGIN[3],
    Float:GUILLOTINE_ANGLES[3],
    Float:GUILLOTINE_ORIGIN_HEAD[3],
    Float:GUILLOTINE_DIRECTION[3],
    Float:GUILLOTINE_ORIGIN_VIEW[3],
    Float:GUILLOTINE_ANGLES_VIEW[3],
    Float:GUILLOTINE_MINS[3],
    Float:GUILLOTINE_MAXS[3],

    Float:GUILLOTINE_NEXT_ACTIVE,
    Float:GUILLOTINE_NEXT_KILL
}

enum _:PLAYER_DATA
{
    PDATA_GUILLOTINE_GHOST,
    PDATA_GUILLOTINE_MENU,
    bool:PDATA_GUILLOTINE_ACTION,
    PDATA_GUILLOTINE_ID,
    bool:PDATA_GUILLOTINE_HELD,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_HEAD,
    Float:PDATA_NEXT_CHECK,
    Float:PDATA_NEXT_DIE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_GUILLOTINE,
    SOUND_SLICE,
    SOUND_FLESH
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "guillotine"

new Array:g_aGuillotine,
    Array:g_aGuillotineConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdEmitSound, HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink, HamHook:g_iFwdPostThink, HamHook:g_iFwdTouch,
    g_iGuillotine, g_iGuillotineConfig, g_iBarTime, Float:g_iHudCurrentY,
    g_iMaxPlayers, g_iSilentVictim

new Float:g_fHeadOffset[] = { 2.5, 0.0, -22.0 }
new g_szModelRPG[MAX_RESOURCE_PATH_LENGTH] = "models/w_rpg.mdl"
new Float:g_fHeadSize[][] = { {-7.5, -7.5, -7.5}, {7.5, 7.5, 7.5} }

public plugin_init()
{
    register_plugin("Guillotine", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Guillotine", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /guillotine",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Guillotine menu.")
    register_clcmd("say_team /guillotine",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Guillotine menu.")
    register_concmd("guillotine_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Guillotine.txt")

    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdPostThink = RegisterHam(Ham_Player_PostThink, "player", "fwdPostThink", 1)
    g_iFwdTouch = RegisterHam(Ham_Touch, "info_target", "fwdTouch")
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableGuillotine()

    guillotineInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aGuillotine = ArrayCreate(GUILLOTINE)
    g_aGuillotineConfig = ArrayCreate(GUILLOTINE)
    g_eSettings[SETTING_DEFAULT_MODEL_HEAD] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SLICE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_FLESH] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    precache_model(g_szModelRPG)
    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aGuillotine)
    ArrayDestroy(g_aGuillotineConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MODEL_HEAD])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SLICE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_FLESH])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        guillotineSound(id, SOUND_MENU_NAV)
        guillotineMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new eGuillotine[GUILLOTINE], bool:bFoundGuillotine
    new iArgIndex = 2
    new bool:bProcessed[33]
    while ( szTarget[0] )
    {
        if ( equali(szTarget, "all") )
        {
            for ( new iTarget = 1; iTarget <= g_iMaxPlayers; iTarget ++ )
            {
                if ( !is_user_connected(iTarget) || bProcessed[iTarget] )
                    continue

                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                    continue

                bFoundGuillotine = false
                for ( new iItem = 0; iItem < g_iGuillotine; iItem ++ )
                {
                    ArrayGetArray(g_aGuillotine, iItem, eGuillotine)
                    if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_USED )
                        continue

                    guillotineHead(eGuillotine, iTarget, true)
                    ArraySetArray(g_aGuillotine, iItem, eGuillotine)
                    bFoundGuillotine = true
                    break
                }

                if ( !bFoundGuillotine )
                {
                    client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_NO_GALLOWS")
                    break
                }
            }
        }
        else
        {
            new iTarget = cmd_target(id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF)
            if ( iTarget && !bProcessed[iTarget] )
            {
                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                {
                    client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_NOT_ALIVE")
                }
                else
                {
                    bFoundGuillotine = false
                    for ( new iItem = 0; iItem < g_iGuillotine; iItem ++ )
                    {
                        ArrayGetArray(g_aGuillotine, iItem, eGuillotine)
                        if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_USED )
                            continue

                        guillotineHead(eGuillotine, iTarget, true)
                        ArraySetArray(g_aGuillotine, iItem, eGuillotine)
                        bFoundGuillotine = true
                        break
                    }

                    if ( !bFoundGuillotine )
                    {
                        client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_NO_GALLOWS")
                        break
                    }
                }
            }
        }

        iArgIndex ++
        szTarget[0] = EOS
        read_argv(iArgIndex, szTarget, charsmax(szTarget))
        remove_quotes(szTarget)
    }

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    guillotineReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aGuillotineConfig)
        g_iGuillotineConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Guillotine.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eGuillotine[GUILLOTINE], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iGuillotineConfig )
                            ArrayPushArray(g_aGuillotineConfig, eGuillotine)

                        copy(eGuillotine[GUILLOTINE_NAME], charsmax(eGuillotine[GUILLOTINE_NAME]), szData)
                        eGuillotine[GUILLOTINE_FLAGS]                     = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eGuillotine[GUILLOTINE_TEAM]                      = g_eSettings[SETTING_DEFAULT_TEAM]
                        eGuillotine[GUILLOTINE_FRAMERATE]                 = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eGuillotine[GUILLOTINE_COOLDOWN][0]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eGuillotine[GUILLOTINE_COOLDOWN][1]               = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]

                        iSection = SECTION_GUILLOTINE
                        g_iGuillotineConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MODEL_HEAD") )
                            parseSetting(DTYPE_ARRAY_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL_HEAD], charsmax(g_eSettings[SETTING_DEFAULT_MODEL_HEAD]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND], charsmax(g_eSettings[SETTING_DEFAULT_SOUND]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SLICE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SLICE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SLICE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_FLESH") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_FLESH], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_FLESH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HEAD_VELOCITY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HEAD_VELOCITY], charsmax(g_eSettings[SETTING_DEFAULT_HEAD_VELOCITY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HEAD_AVELOCITY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY], charsmax(g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HEAD_LIFE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HEAD_LIFE], charsmax(g_eSettings[SETTING_DEFAULT_HEAD_LIFE]))
                        else if ( equali(szKey, "SETTING_PLAY_SOUND_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PLAY_SOUND_ON_DEATH], charsmax(g_eSettings[SETTING_PLAY_SOUND_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_CREATE_HEAD_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_CREATE_HEAD_ON_DEATH], charsmax(g_eSettings[SETTING_CREATE_HEAD_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_GUILLOTINE_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GUILLOTINE_LOAD], charsmax(g_eSettings[SETTING_GUILLOTINE_LOAD]))
                        else if ( equali(szKey, "SETTING_GUILLOTINE_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_GUILLOTINE_TASK], charsmax(g_eSettings[SETTING_GUILLOTINE_TASK]))
                    }
                    case SECTION_GUILLOTINE:
                    {
                        if ( equali(szKey, "GUILLOTINE_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eGuillotine[GUILLOTINE_FLAGS], charsmax(eGuillotine[GUILLOTINE_FLAGS]))
                        else if ( equali(szKey, "GUILLOTINE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eGuillotine[GUILLOTINE_TEAM], charsmax(eGuillotine[GUILLOTINE_TEAM]))
                        else if ( equali(szKey, "GUILLOTINE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eGuillotine[GUILLOTINE_FRAMERATE], charsmax(eGuillotine[GUILLOTINE_FRAMERATE]))
                        else if ( equali(szKey, "GUILLOTINE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eGuillotine[GUILLOTINE_COOLDOWN], charsmax(eGuillotine[GUILLOTINE_COOLDOWN]))
                    }
                }
            }
        }
    }

    if ( g_iGuillotineConfig )
        ArrayPushArray(g_aGuillotineConfig, eGuillotine)
    else
        set_fail_state("No guillotines were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eGuillotine[GUILLOTINE], iItem
    if ( g_ePlayerData[id][PDATA_GUILLOTINE_GHOST]
    && (iItem = guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_GHOST])) != -1 )
    {
        guillotineKill(eGuillotine[GUILLOTINE_ID])
        guillotineRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_GUILLOTINE_GHOST]  = 0
    g_ePlayerData[id][PDATA_GUILLOTINE_MENU]   = 0
}

stock guillotineInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_GUILLOTINE_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock guillotineTerminate()
{
    new eGuillotine[GUILLOTINE]
    for ( new i = 0; i < g_iGuillotine; i ++ )
    {
        ArrayGetArray(g_aGuillotine, i, eGuillotine)
        eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aGuillotine, i, eGuillotine)
    }
}

stock guillotineMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "GUILLOTINE_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "GUILLOTINE_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "GUILLOTINE_ON" : "GUILLOTINE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "GUILLOTINE_ON" : "GUILLOTINE_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iGuillotine >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_LIMIT", MAX_ENT)

                guillotineSound(id, SOUND_MENU_REMOVE)
                guillotineMenu(id, MENU_ROOT)
            }
            else
            {
                guillotineSound(id, SOUND_MENU_NAV)
                guillotineMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iGuillotine )
            {
                client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_NO_GUILLOTINE")

                guillotineSound(id, SOUND_MENU_REMOVE)
                guillotineMenu(id, MENU_ROOT)
            }
            else
            {
                guillotineSound(id, SOUND_MENU_NAV)
                guillotineMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iGuillotine )
            {
                client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_NO_GUILLOTINE")

                guillotineSound(id, SOUND_MENU_REMOVE)
                guillotineMenu(id, MENU_ROOT)
            }
            else
            {
                guillotineSound(id, SOUND_MENU_REMOVE)
                guillotineMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            guillotineNoClip(id)
        }
        case ROOT_GODMODE:
        {
            guillotineGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eGuillotine[GUILLOTINE], szItem[64]
    for ( new i = 0; i < g_iGuillotineConfig; i ++ )
    {
        ArrayGetArray(g_aGuillotineConfig, i, eGuillotine)

        copy(szItem, charsmax(szItem), eGuillotine[GUILLOTINE_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        guillotineSound(id, SOUND_MENU_NAV)
        guillotineMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    guillotineCreate(id, item)
    guillotineSound(id, SOUND_MENU_NAV)
    guillotineMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eGuillotine[GUILLOTINE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_REMOVE_CURRENT", eGuillotine[GUILLOTINE_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    guillotineSelect(eGuillotine, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
}

public menuHandlerRemove(id, menu, item)
{
    new eGuillotine[GUILLOTINE]
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        guillotineSelect(eGuillotine, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] >= g_iGuillotine - 1 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] ++

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = g_iGuillotine - 1
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] --

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_ACTIVE
            guillotineSetState(eGuillotine)
            guillotineKill(eGuillotine[GUILLOTINE_ID])
            guillotineRemove(g_ePlayerData[id][PDATA_GUILLOTINE_MENU])

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_REMOVE_CURRENT", eGuillotine[GUILLOTINE_NAME])
            g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0

            guillotineSound(id, g_iGuillotine > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            guillotineMenu(id, g_iGuillotine > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iGuillotine )
            {
                ArrayGetArray(g_aGuillotine, 0, eGuillotine)
                eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_ACTIVE

                guillotineSetState(eGuillotine)
                guillotineKill(eGuillotine[GUILLOTINE_ID])
                guillotineRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0

            guillotineSound(id, SOUND_MENU_ALERT)
            guillotineMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                guillotineSound(id, SOUND_MENU_NAV)
                guillotineMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eGuillotine[GUILLOTINE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_SHOW_CURRENT",
    eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? "\y" : "\r", eGuillotine[GUILLOTINE_NAME], id, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? "GUILLOTINE_SHOWN" : "GUILLOTINE_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    guillotineSelect(eGuillotine, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
}

public menuHandlerShow(id, menu, item)
{
    new eGuillotine[GUILLOTINE]
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        guillotineSelect(eGuillotine, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] >= g_iGuillotine - 1 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] ++

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = g_iGuillotine - 1
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] --

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eGuillotine[GUILLOTINE_FLAGS] ^= FLAG_SHOW
            if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW )
                eGuillotine[GUILLOTINE_FLAGS] |= FLAG_ACTIVE
            else
                eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_ACTIVE
            guillotineSetState(eGuillotine)

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_SHOW_CURRENT",
            eGuillotine[GUILLOTINE_NAME], id, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? "GUILLOTINE_CHAT_SHOWN" : "GUILLOTINE_CHAT_HIDDEN")
            ArraySetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iGuillotine; i ++ )
            {
                ArrayGetArray(g_aGuillotine, i, eGuillotine)
                eGuillotine[GUILLOTINE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                guillotineSetState(eGuillotine)

                ArraySetArray(g_aGuillotine, i, eGuillotine)
            }

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_SHOW_ALL_SHOWN")
            guillotineSound(id, SOUND_MENU_ALERT)
            guillotineMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iGuillotine; i ++ )
            {
                ArrayGetArray(g_aGuillotine, i, eGuillotine)
                eGuillotine[GUILLOTINE_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                guillotineSetState(eGuillotine)

                ArraySetArray(g_aGuillotine, i, eGuillotine)
            }

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_SHOW_ALL_HIDDEN")
            guillotineSound(id, SOUND_MENU_ALERT)
            guillotineMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                guillotineSound(id, SOUND_MENU_NAV)
                guillotineMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eGuillotine[GUILLOTINE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_STATUS_CURRENT",
    eGuillotine[GUILLOTINE_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eGuillotine[GUILLOTINE_NAME], id, eGuillotine[GUILLOTINE_FLAGS] & FLAG_ACTIVE ? "GUILLOTINE_ENABLED" : "GUILLOTINE_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    guillotineSelect(eGuillotine, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
}

public menuHandlerStatus(id, menu, item)
{
    new eGuillotine[GUILLOTINE]
    ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        guillotineSelect(eGuillotine, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] >= g_iGuillotine - 1 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] ++

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_GUILLOTINE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = g_iGuillotine - 1
            else
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] --

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eGuillotine[GUILLOTINE_FLAGS] ^= FLAG_ACTIVE
            guillotineSetState(eGuillotine)

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_STATUS_CURRENT",
            eGuillotine[GUILLOTINE_NAME], id, eGuillotine[GUILLOTINE_FLAGS] & FLAG_ACTIVE ? "GUILLOTINE_CHAT_ENABLED" : "GUILLOTINE_CHAT_DISABLED")
            ArraySetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iGuillotine; i ++ )
            {
                ArrayGetArray(g_aGuillotine, i, eGuillotine)
                eGuillotine[GUILLOTINE_FLAGS] |= FLAG_ACTIVE
                guillotineSetState(eGuillotine)

                ArraySetArray(g_aGuillotine, i, eGuillotine)
            }

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_STATUS_ALL_ENABLED")
            guillotineSound(id, SOUND_MENU_ALERT)
            guillotineMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iGuillotine; i ++ )
            {
                ArrayGetArray(g_aGuillotine, i, eGuillotine)
                eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_ACTIVE
                guillotineSetState(eGuillotine)

                ArraySetArray(g_aGuillotine, i, eGuillotine)
            }

            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_STATUS_ALL_DISABLED")
            guillotineSound(id, SOUND_MENU_ALERT)
            guillotineMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                guillotineSound(id, SOUND_MENU_NAV)
                guillotineMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eGuillotine[GUILLOTINE]
    if ( guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROTATE_GROUND",
    id, eGuillotine[GUILLOTINE_FLAGS] & FLAG_GROUND ? "GUILLOTINE_ON" : "GUILLOTINE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "GUILLOTINE_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eGuillotine[GUILLOTINE], iItem
    if ( (iItem = guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eGuillotine[GUILLOTINE_ID], pev_angles, eGuillotine[GUILLOTINE_ANGLES])
            eGuillotine[GUILLOTINE_ANGLES][1] -= GUILLOTINE_ROTATION_STEP
            if ( eGuillotine[GUILLOTINE_ANGLES][1] < -180.0 ) eGuillotine[GUILLOTINE_ANGLES][1] += 360.0

            set_pev(eGuillotine[GUILLOTINE_ID], pev_angles, eGuillotine[GUILLOTINE_ANGLES])
            ArraySetArray(g_aGuillotine, iItem, eGuillotine)

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eGuillotine[GUILLOTINE_ID], pev_angles, eGuillotine[GUILLOTINE_ANGLES])
            eGuillotine[GUILLOTINE_ANGLES][1] += GUILLOTINE_ROTATION_STEP
            if ( eGuillotine[GUILLOTINE_ANGLES][1] > 180.0 ) eGuillotine[GUILLOTINE_ANGLES][1] -= 360.0

            set_pev(eGuillotine[GUILLOTINE_ID], pev_angles, eGuillotine[GUILLOTINE_ANGLES])
            ArraySetArray(g_aGuillotine, iItem, eGuillotine)

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eGuillotine[GUILLOTINE_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aGuillotine, iItem, eGuillotine)

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            guillotineTrace(eGuillotine, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] = 0

            eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_GHOST
            eGuillotine[GUILLOTINE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eGuillotine[GUILLOTINE_ANGLES][0] = -eGuillotine[GUILLOTINE_ANGLES][0]
            guillotineSetSize(eGuillotine)
            guillotineSetState(eGuillotine)
            client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_CREATE_NEW", eGuillotine[GUILLOTINE_NAME])

            ArraySetArray(g_aGuillotine, iItem, eGuillotine)
            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            guillotineKill(eGuillotine[GUILLOTINE_ID])
            guillotineRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] = 0

            guillotineSound(id, SOUND_MENU_NAV)
            guillotineMenu(id, MENU_CREATE)
        }
        default:
        {
            guillotineKill(eGuillotine[GUILLOTINE_ID])
            guillotineRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public guillotineTask()
{
    new eGuillotine[GUILLOTINE], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        if ( g_ePlayerData[id][PDATA_NEXT_HEAD] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_HEAD] )
            {
                if ( (iItem = guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_GUILLOTINE_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_HEAD] = 0.0

                    guillotineHead(eGuillotine, id)
                    ArraySetArray(g_aGuillotine, iItem, eGuillotine)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                guillotineBar(id, 0)
                g_ePlayerData[id][PDATA_GUILLOTINE_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_HEAD] = 0.0
            }
        }
        else if ( g_ePlayerData[id][PDATA_NEXT_DIE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_DIE] )
            {
                if ( (iItem = guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_ID])) != -1 )
                {
                    if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_USED
                    && is_user_alive(id) )
                    {
                        engfunc(EngFunc_SetView, id, id)
                        set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
                        set_pev(id, pev_movetype, MOVETYPE_WALK)

                        g_iSilentVictim = id
                        ExecuteHamB(Ham_Killed, id, id, GIB_ALWAYS)
                        guillotineSound(eGuillotine[GUILLOTINE_ID], SOUND_SLICE, false)
                        if ( g_eSettings[SETTING_CREATE_HEAD_ON_DEATH] )
                            guillotineCreateHead(eGuillotine)
                    }

                    g_ePlayerData[id][PDATA_GUILLOTINE_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_DIE] = 0.0
                    eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_USED
                    eGuillotine[GUILLOTINE_NEXT_ACTIVE] = fCurrentTime + random_float(eGuillotine[GUILLOTINE_COOLDOWN][0], eGuillotine[GUILLOTINE_COOLDOWN][1])
                    guillotineSetSeq(eGuillotine[GUILLOTINE_ID], GUILLOTINE_SEQ_UP, eGuillotine[GUILLOTINE_FRAMERATE])

                    ArraySetArray(g_aGuillotine, iItem, eGuillotine)
                }
            }
        }
    }
}

stock guillotineCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eGuillotine[GUILLOTINE]
    ArrayGetArray(g_aGuillotineConfig, iItem, eGuillotine)
    eGuillotine[GUILLOTINE_ID] = iEnt
    eGuillotine[GUILLOTINE_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] = eGuillotine[GUILLOTINE_ID]
        g_ePlayerData[id][PDATA_OFFSET] = GUILLOTINE_OFFSET_BASE

        eGuillotine[GUILLOTINE_FLAGS] |= FLAG_GHOST
    }

    guillotineSelect(eGuillotine, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, GUILLOTINE_KEY)
    set_pev(iEnt, GUILLOTINE_ARRAY_ITEM, g_iGuillotine)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aGuillotine, eGuillotine)
    if ( ++ g_iGuillotine == 1 )
    {
        set_task(g_eSettings[SETTING_GUILLOTINE_TASK], "guillotineTask", GUILLOTINE_KEY, .flags = "b")
        EnableGuillotine()
    }
}

stock guillotineCreateHead(eGuillotine[GUILLOTINE])
{
    new iHead = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iHead) )
        return 0

    new szCN[32], szModel[96], Float:fOrigin[3], Float:fVelocity[3], Float:fAvelocity[3]
    formatex(szCN, charsmax(szCN), "%s_head", g_szCN)
    ArrayGetString(g_eSettings[SETTING_DEFAULT_MODEL_HEAD], random_num(0, ArraySize(g_eSettings[SETTING_DEFAULT_MODEL_HEAD]) - 1), szModel, charsmax(szModel))

    xs_vec_copy(eGuillotine[GUILLOTINE_ORIGIN_HEAD], fOrigin)
    xs_vec_add_scaled(fOrigin, eGuillotine[GUILLOTINE_DIRECTION], HEAD_FORWARD_OFFSET, fOrigin)
    set_pev(iHead, pev_classname, szCN)
    set_pev(iHead, pev_impulse, GUILLOTINE_HEAD_KEY)
    engfunc(EngFunc_SetModel, iHead, szModel)
    set_pev(iHead, pev_movetype, MOVETYPE_BOUNCE)
    set_pev(iHead, pev_solid, SOLID_BBOX)
    set_pev(iHead, pev_takedamage, DAMAGE_NO)
    engfunc(EngFunc_SetSize, iHead, g_fHeadSize[0], g_fHeadSize[1])
    engfunc(EngFunc_SetOrigin, iHead, fOrigin)

    xs_vec_mul_scalar(eGuillotine[GUILLOTINE_DIRECTION], random_float(g_eSettings[SETTING_DEFAULT_HEAD_VELOCITY][0], g_eSettings[SETTING_DEFAULT_HEAD_VELOCITY][1]), fVelocity)
    set_pev(iHead, pev_velocity, fVelocity)

    fAvelocity[0] = random_float(g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][0], g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][1])
    fAvelocity[1] = random_float(g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][0], g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][1])
    fAvelocity[2] = random_float(g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][0], g_eSettings[SETTING_DEFAULT_HEAD_AVELOCITY][1])
    set_pev(iHead, pev_avelocity, fAvelocity)
    set_task(random_float(g_eSettings[SETTING_DEFAULT_HEAD_LIFE][0], g_eSettings[SETTING_DEFAULT_HEAD_LIFE][1]), "guillotineRemoveHead", GUILLOTINE_HEAD_KEY + iHead)

    return iHead
}

stock guillotineCreateView(eGuillotine[GUILLOTINE])
{
    new Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eGuillotine[GUILLOTINE_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(fForward, eGuillotine[GUILLOTINE_DIRECTION])
    xs_vec_copy(eGuillotine[GUILLOTINE_ORIGIN], eGuillotine[GUILLOTINE_ORIGIN_VIEW])
    xs_vec_mul_scalar(fForward, VIEW_FORWARD_OFFSET, fForward)
    xs_vec_mul_scalar(fRight, VIEW_RIGHT_OFFSET, fRight)
    xs_vec_add(eGuillotine[GUILLOTINE_ORIGIN_VIEW], fForward, eGuillotine[GUILLOTINE_ORIGIN_VIEW])
    xs_vec_add(eGuillotine[GUILLOTINE_ORIGIN_VIEW], fRight, eGuillotine[GUILLOTINE_ORIGIN_VIEW])
    eGuillotine[GUILLOTINE_ORIGIN_VIEW][2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eGuillotine[GUILLOTINE_ORIGIN], eGuillotine[GUILLOTINE_ORIGIN_VIEW], IGNORE_MONSTERS, eGuillotine[GUILLOTINE_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, eGuillotine[GUILLOTINE_ORIGIN_VIEW])

    eGuillotine[GUILLOTINE_ORIGIN_VIEW][2] -= VIEW_UP_OFFSET
    xs_vec_sub(eGuillotine[GUILLOTINE_ORIGIN], eGuillotine[GUILLOTINE_ORIGIN_VIEW], fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, eGuillotine[GUILLOTINE_ANGLES_VIEW])
    new iView = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iView) )
        return

    new szCN[32]
    formatex(szCN, charsmax(szCN), "%s_view", g_szCN)
    set_pev(iView, pev_classname, szCN)
    set_pev(iView, pev_movetype, MOVETYPE_NONE)
    set_pev(iView, pev_solid, SOLID_NOT)
    engfunc(EngFunc_SetModel, iView, g_szModelRPG)
    set_pev(iView, pev_rendermode, kRenderTransTexture)
    set_pev(iView, pev_renderamt, 0.0)
    engfunc(EngFunc_SetOrigin, iView, eGuillotine[GUILLOTINE_ORIGIN_VIEW])
    set_pev(iView, pev_angles, eGuillotine[GUILLOTINE_ANGLES_VIEW])

    eGuillotine[GUILLOTINE_VIEW] = iView
}

public guillotineRemove(iItem)
{
    new eGuillotine[GUILLOTINE]
    ArrayDeleteItem(g_aGuillotine, iItem)

    if ( -- g_iGuillotine == 0 )
    {
        remove_task(GUILLOTINE_KEY)
        DisableGuillotine()
    }

    for ( new i = iItem; i < g_iGuillotine; i ++ )
    {
        ArrayGetArray(g_aGuillotine, i, eGuillotine)
        set_pev(eGuillotine[GUILLOTINE_ID], GUILLOTINE_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eGuillotine[GUILLOTINE],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Guillotine.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    guillotineTerminate()
    for ( new i = 0; i < g_iGuillotine; i ++ )
    {
        ArrayGetArray(g_aGuillotine, i, eGuillotine)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eGuillotine[GUILLOTINE_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eGuillotine[GUILLOTINE_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eGuillotine[GUILLOTINE_ORIGIN][0], eGuillotine[GUILLOTINE_ORIGIN][1], eGuillotine[GUILLOTINE_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eGuillotine[GUILLOTINE_ANGLES][0], eGuillotine[GUILLOTINE_ANGLES][1], eGuillotine[GUILLOTINE_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "GUILLOTINE_CHAT_TAG", id, "GUILLOTINE_CHAT_SAVE", szFile)
    fclose(iFile)

    guillotineSound(id, SOUND_MENU_NAV)
    guillotineMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Guillotine.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataGuillotine(iItem, iFlags, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataGuillotine(iItem, iFlags, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataGuillotine(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eGuillotine[GUILLOTINE]
    guillotineCreate(0, iItem)
    ArrayGetArray(g_aGuillotine, iCount, eGuillotine)

    eGuillotine[GUILLOTINE_FLAGS] = iFlags
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eGuillotine[GUILLOTINE_ORIGIN])
    xs_vec_copy(fAngles, eGuillotine[GUILLOTINE_ANGLES])

    guillotineSetBox(eGuillotine)
    guillotineSetSize(eGuillotine)
    guillotineSetState(eGuillotine)
    ArraySetArray(g_aGuillotine, iCount, eGuillotine)
}

public guillotineNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    guillotineSound(id, SOUND_MENU_NAV)
    guillotineMenu(id, MENU_ROOT)
}

public guillotineGodMode(id)
{
    new Float:flTakeDamage
    pev(id, pev_takedamage, flTakeDamage)
    set_pev(id, pev_takedamage, flTakeDamage == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    guillotineSound(id, SOUND_MENU_NAV)
    guillotineMenu(id, MENU_ROOT)
}

public fwdEmitSound(iEnt, iChannel, const szSample[])
{
    if ( g_iSilentVictim && iEnt == g_iSilentVictim )
        return FMRES_SUPERCEDE

    return FMRES_IGNORED
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isGuillotine(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eGuillotine[GUILLOTINE]
    if ( guillotineGet(eGuillotine, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eGuillotine[GUILLOTINE_FLAGS] & FLAG_ACTIVE)
    || (eGuillotine[GUILLOTINE_FLAGS] & FLAG_USED)
    || !(eGuillotine[GUILLOTINE_TEAM] & get_user_team(iActivator))
    || fCurrentTime < eGuillotine[GUILLOTINE_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_HEAD] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        guillotineBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_GUILLOTINE_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_HEAD] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        guillotineBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_GUILLOTINE_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_HEAD] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isGuillotine(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eGuillotine[GUILLOTINE], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += GUILLOTINE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], GUILLOTINE_OFFSET_MIN, GUILLOTINE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= GUILLOTINE_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], GUILLOTINE_OFFSET_MIN, GUILLOTINE_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            guillotineTrace(eGuillotine, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_GUILLOTINE_ACTION] )
    {
        guillotineCheck(id)
    }

    return HAM_IGNORED
}

public fwdPostThink(id)
{
    if ( !is_user_alive(id)
    || !g_ePlayerData[id][PDATA_GUILLOTINE_HELD] )
        return FMRES_IGNORED

    set_pev(id, pev_sequence, SEQ)
    set_pev(id, pev_gaitsequence, SEQ)
    set_pev(id, pev_framerate, 1.0)
    return FMRES_IGNORED
}

public fwdTouch(iEnt, iOther)
{
    if ( !pev_valid(iEnt)
    || pev(iEnt, pev_impulse) != GUILLOTINE_HEAD_KEY )
        return FMRES_IGNORED

    new Float:fVelocity[3], Float:fAvelocity[3], Float:fVelo
    pev(iEnt, pev_velocity, fVelocity)
    pev(iEnt, pev_avelocity, fAvelocity)
    fVelo = xs_vec_len(fVelocity)

    xs_vec_mul_scalar(fVelocity, HEAD_DAMPING_FACTOR, fVelocity)
    xs_vec_mul_scalar(fAvelocity, HEAD_DAMPING_FACTOR, fAvelocity)
    if ( fVelo < HEAD_SPEED_TO_STOP )
    {
        fVelocity = Float:{0.0, 0.0, 0.0}
        fAvelocity = Float:{0.0, 0.0, 0.0}
        set_pev(iEnt, pev_movetype, MOVETYPE_TOSS)
    }
    else if ( fVelo >= HEAD_SPEED_FOR_SOUND )
        guillotineSound(iEnt, SOUND_FLESH, false)

    set_pev(iEnt, pev_velocity, fVelocity)
    set_pev(iEnt, pev_avelocity, fAvelocity)
    return FMRES_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = 0
    if ( g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] )
    {
        new eGuillotine[GUILLOTINE], iItem
        if ( (iItem = guillotineGet(eGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_GHOST])) != -1 )
        {
            guillotineKill(eGuillotine[GUILLOTINE_ID])
            guillotineRemove(iItem)
        }

        g_ePlayerData[id][PDATA_GUILLOTINE_GHOST] = 0
    }

    if ( id == g_iSilentVictim )
    {
        set_pev(id, pev_deadflag, DEAD_DISCARDBODY)
        g_iSilentVictim = 0
    }

    if ( g_ePlayerData[id][PDATA_GUILLOTINE_HELD] )
        g_ePlayerData[id][PDATA_GUILLOTINE_HELD] = false
}

stock guillotineTrace(eGuillotine[GUILLOTINE], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eGuillotine[GUILLOTINE_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eGuillotine[GUILLOTINE_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eGuillotine[GUILLOTINE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eGuillotine[GUILLOTINE_ORIGIN])

    guillotineSetBox(eGuillotine)
    guillotineSetOffset(eGuillotine)
    set_pev(eGuillotine[GUILLOTINE_ID], pev_origin, eGuillotine[GUILLOTINE_ORIGIN])
}

stock guillotineCheck(id)
{
    new eGuillotine[GUILLOTINE], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = GUILLOTINE_CHECK
    for ( new i = 0; i < g_iGuillotine; i ++ )
    {
        ArrayGetArray(g_aGuillotine, i, eGuillotine)
        xs_vec_sub(eGuillotine[GUILLOTINE_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eGuillotine[GUILLOTINE_ID], pev_absmin, fMins)
        pev(eGuillotine[GUILLOTINE_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_GUILLOTINE_MENU] != iBest )
    {
        ArrayGetArray(g_aGuillotine, g_ePlayerData[id][PDATA_GUILLOTINE_MENU], eGuillotine)
        guillotineSelect(eGuillotine, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_GUILLOTINE_MENU] = iBest
        guillotineMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock guillotineSetBox(eGuillotine[GUILLOTINE])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eGuillotine[GUILLOTINE_ANGLES][0] = -eGuillotine[GUILLOTINE_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eGuillotine[GUILLOTINE_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eGuillotine[GUILLOTINE_MINS])
    xs_vec_copy(fMaxs, eGuillotine[GUILLOTINE_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock guillotineSetOffset(eGuillotine[GUILLOTINE])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eGuillotine[GUILLOTINE_MINS][0]
    fGaps[1] = eGuillotine[GUILLOTINE_MAXS][0]
    fGaps[2] = -eGuillotine[GUILLOTINE_MINS][1]
    fGaps[3] = eGuillotine[GUILLOTINE_MAXS][1]
    fGaps[4] = -eGuillotine[GUILLOTINE_MINS][2]
    fGaps[5] = eGuillotine[GUILLOTINE_MAXS][2]

    if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eGuillotine[GUILLOTINE_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eGuillotine[GUILLOTINE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eGuillotine[GUILLOTINE_ID], 0)
        get_tr2(0, TR_vecEndPos, eGuillotine[GUILLOTINE_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eGuillotine[GUILLOTINE_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eGuillotine[GUILLOTINE_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eGuillotine[GUILLOTINE_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eGuillotine[GUILLOTINE_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eGuillotine[GUILLOTINE_ORIGIN], fVec1, eGuillotine[GUILLOTINE_ORIGIN])
        }
    }
}

stock guillotineSetSeq(iEnt, iSeq, Float:fFramerate)
{
    set_pev(iEnt, pev_sequence, iSeq)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFramerate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock guillotineSetSize(eGuillotine[GUILLOTINE])
{
    guillotineSelect(eGuillotine, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eGuillotine[GUILLOTINE_ID], eGuillotine[GUILLOTINE_ORIGIN])
    set_pev(eGuillotine[GUILLOTINE_ID], pev_angles, eGuillotine[GUILLOTINE_ANGLES])
    set_pev(eGuillotine[GUILLOTINE_ID], pev_solid, eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eGuillotine[GUILLOTINE_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eGuillotine[GUILLOTINE_ID], eGuillotine[GUILLOTINE_MINS], eGuillotine[GUILLOTINE_MAXS])
    engfunc(EngFunc_GetAttachment, eGuillotine[GUILLOTINE_ID], 0, eGuillotine[GUILLOTINE_ORIGIN_HEAD], NULL_VECTOR)
    guillotineCreateView(eGuillotine)
}

stock guillotineSetState(eGuillotine[GUILLOTINE])
{
    if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW )
    {
        set_pev(eGuillotine[GUILLOTINE_ID], pev_solid, SOLID_BBOX)
        guillotineSelect(eGuillotine, TARGET_CLEAR)
    }
    else
    {
        set_pev(eGuillotine[GUILLOTINE_ID], pev_solid, SOLID_NOT)
        guillotineSelect(eGuillotine, TARGET_HIDE)
    }
}

stock guillotineStrip(id)
{
    new iWeapons[32], iNum, szName[32], iEnt
    get_user_weapons(id, iWeapons, iNum)
    for ( new i; i < iNum; i ++ )
    {
        if ( !get_weaponname(iWeapons[i], szName, charsmax(szName)) )
            continue

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", szName)) > 0 )
        {
            if ( pev(iEnt, pev_owner) != id )
                continue

            ExecuteHam(Ham_RemovePlayerItem, id, iEnt)
            user_has_weapon(id, iWeapons[i], 0)
            ExecuteHamB(Ham_Item_Kill, iEnt)
            break
        }
    }
}

stock guillotineHeadOffset(eGuillotine[GUILLOTINE], id)
{
    new Float:fAng[3], Float:fFwd[3], Float:fRight[3], Float:fOrigin[3]
    xs_vec_copy(eGuillotine[GUILLOTINE_ANGLES], fAng)
    fAng[0] = 0.0
    fAng[2] = 0.0
    engfunc(EngFunc_AngleVectors, fAng, fFwd, fRight, NULL_VECTOR)

    xs_vec_copy(eGuillotine[GUILLOTINE_ORIGIN_HEAD], fOrigin)
    xs_vec_add_scaled(fOrigin, fFwd, g_fHeadOffset[0], fOrigin)
    xs_vec_add_scaled(fOrigin, fRight, g_fHeadOffset[1], fOrigin)
    fOrigin[2] += g_fHeadOffset[2]

    engfunc(EngFunc_SetOrigin, id, fOrigin)
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
    set_pev(id, pev_angles, fAng)
    set_pev(id, pev_v_angle, fAng)
    set_pev(id, pev_fixangle, 1)
}

stock guillotineHead(eGuillotine[GUILLOTINE], id, bool:bForced = false)
{
    if ( !pev_valid(eGuillotine[GUILLOTINE_VIEW]) )
        return

    guillotineStrip(id)
    guillotineHeadOffset(eGuillotine, id)
    guillotineSetSeq(eGuillotine[GUILLOTINE_ID], GUILLOTINE_SEQ_DOWN, eGuillotine[GUILLOTINE_FRAMERATE])
    eGuillotine[GUILLOTINE_FLAGS] |= FLAG_USED
    g_ePlayerData[id][PDATA_GUILLOTINE_ID] = eGuillotine[GUILLOTINE_ID]
    g_ePlayerData[id][PDATA_GUILLOTINE_HELD] = true
    g_ePlayerData[id][PDATA_NEXT_DIE] = get_gametime() + (GUILLOTINE_SEQ_DURATION / g_eSettings[SETTING_DEFAULT_FRAMERATE])
    set_pev(id, pev_movetype, MOVETYPE_NONE)
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
    engfunc(EngFunc_SetView, id, eGuillotine[GUILLOTINE_VIEW])

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH] )
        guillotineMessage(id, bForced)

    if ( g_eSettings[SETTING_PLAY_SOUND_ON_DEATH] )
        for ( new i = 1; i <= g_iMaxPlayers; i ++ )
            guillotineSound(i, SOUND_GUILLOTINE)
}

public guillotineRemoveHead(iTask)
{
    guillotineKill(iTask - GUILLOTINE_HEAD_KEY)
}

stock guillotineBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

stock guillotineSelect(eGuillotine[GUILLOTINE], iAction)
{
    if ( iAction == TARGET_SELECT )
    {
        if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_ACTIVE )  { set_pev(eGuillotine[GUILLOTINE_ID], pev_rendercolor, Float:{0.0, 255.0, 0.0}); }
        else                                                { set_pev(eGuillotine[GUILLOTINE_ID], pev_rendercolor, Float:{255.0, 0.0, 0.0}); }

        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderfx, kRenderFxGlowShell)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderamt, 16.0)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderamt, float(GUILLOTINE_GHOST_ALPHA))
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderamt, 0.0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderfx, kRenderFxNone)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eGuillotine[GUILLOTINE_ID], pev_rendermode, kRenderNormal)
        set_pev(eGuillotine[GUILLOTINE_ID], pev_renderamt, 255.0)
    }
}

stock guillotineMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128]
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    show_hudmessage(0, "%s%s", szName, szMessage)
    g_iHudCurrentY += 0.025
    if ( g_iHudCurrentY >= 0.7 )
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
}

stock guillotineSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_GUILLOTINE:  ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND])), szSample, charsmax(szSample))
        case SOUND_SLICE:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_SLICE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_SLICE])), szSample, charsmax(szSample))
        case SOUND_FLESH:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_FLESH], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_FLESH])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_VOICE, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock guillotineReset()
{
    new eGuillotine[GUILLOTINE]
    for ( new i = 0; i < g_iGuillotine; i ++ )
    {
        ArrayGetArray(g_aGuillotine, i, eGuillotine)
        eGuillotine[GUILLOTINE_NEXT_ACTIVE] = 0.0
        eGuillotine[GUILLOTINE_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aGuillotine, i, eGuillotine)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_NEXT_HEAD] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
    }
}

stock guillotineGet(eGuillotine[GUILLOTINE], iEnt)
{
    if ( !isGuillotine(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, GUILLOTINE_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iGuillotine )
        return -1

    ArrayGetArray(g_aGuillotine, iItem, eGuillotine)
    return iItem
}

stock bool:isGuillotine(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == GUILLOTINE_KEY
}

stock guillotineKill(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            precache_model(szValue)
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_GUILLOTINE_ACTION] )
    {
        new eGuillotine[GUILLOTINE]
        for ( new i = 0; i < g_iGuillotine; i ++ )
        {
            ArrayGetArray(g_aGuillotine, i, eGuillotine)
            if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW )
                continue

            guillotineSelect(eGuillotine, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_GUILLOTINE_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_GUILLOTINE_ACTION] )
    {
        new eGuillotine[GUILLOTINE]
        for ( new i = 0; i < g_iGuillotine; i ++ )
        {
            ArrayGetArray(g_aGuillotine, i, eGuillotine)
            if ( eGuillotine[GUILLOTINE_FLAGS] & FLAG_SHOW )
                continue

            guillotineSelect(eGuillotine, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_GUILLOTINE_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableGuillotine()
{
    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
    EnableHamForward(g_iFwdPostThink)
    EnableHamForward(g_iFwdTouch)
}

stock DisableGuillotine()
{
    unregister_forward(FM_EmitSound, g_iFwdEmitSound)
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
    DisableHamForward(g_iFwdPostThink)
    DisableHamForward(g_iFwdTouch)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}





