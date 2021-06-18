/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/

string INIT_CARD_NAME=".init";
key InitCardUuid;
string DefaultCardName;

//define block start
string DEFAULT_PREFIX="SET";
integer MEMORY_USAGE=34334;
integer SEAT_INIT=250;
integer SEAT_UPDATE=251;
integer DOPOSE=200;
integer DO=220;
integer PREPARE_MENU_STEP3_READER=221;
integer DOPOSE_READER=222;
integer PLUGIN_COMMAND_REGISTER_NO_OVERWRITE=309;
integer PLUGIN_COMMAND_REGISTER=310;
integer UNKNOWN_COMMAND=311;
integer OPTIONS=-240;
integer DEFAULT_CARD=-242;
integer TIMER=-600;
integer TIMER_REMOVE=-601;
integer DOMENU=-800;
integer UPDATE_UDP=-808; //sends a 3-strided list udpName|udpType|udpValue
integer UPDATE_MACRO=-809; //sends a 3-strided list macroName|macroType|macroValue
integer PLUGIN_MENU_REGISTER=-810;
integer MENU_SHOW=-815;
integer PREPARE_MENU_STEP1=-820;
integer PREPARE_MENU_STEP2=-821;

integer PLUGIN_ACTION_DONE=-831;
integer DIALOG_TIMEOUT=-902;

integer PROP_PLUGIN=-500;
integer BUDDY_PLUGIN=-510;
integer BUDDY_REFRESH=-511;
integer SATNOTSAT_PLUGIN=-520;
//define block end

string LastAssignSlotsCardName;
key LastAssignSlotsCardId;
key LastAssignSlotsAvatarId;
integer SlotsCount; //the number of slots
list Slots;
integer SLOTS_SEAT_NAME=0;
integer SLOTS_SEAT_PERM=1;
integer SLOTS_ANIM_NAMES=2;
integer SLOTS_ANIM_POS=3;
integer SLOTS_ANIM_ROT=4;
integer SLOTS_FACIALS=5;
integer SLOTS_ANIM_NC_NAME=6;
integer SLOTS_ANIM_COMMAND=7;
integer SLOTS_SITTER_KEY=8;
integer SLOTS_SITTER_TYPE=9;
integer SLOTS_SITTER_NAME=10;

integer SLOTS_STRIDE=11;
key menuOnSitID;
string SlotsHash; //MD5; whenever you manipulate the Slots list:update the hash
integer SEAT_UPDATE_PREAMBLE_LENGTH=3; //Preamble: SlotsStride, preambleLength, csv slotsAnimChanged
integer SITTER_TYPE_NONE=0;
integer SITTER_TYPE_AVATAR=1;
integer SITTER_TYPE_BUDDY=2;

integer CurMenuOnSit; //default menuonsit option
integer Cur2default;  //default action to revert back to default pose when last sitter has stood
vector ScaleRef; //perhaps we want to do rezzing etc. relative to the current scale of the object. If yes: we need a reference scale.
string SeatAssignList="a"; //SeatAssignList contains a list (separated by ",") with seatnumbers and keyword. //a(scending), d(escending), r(andom)
integer OptionUseDisplayNames=1; //use display names instead of usernames in our Slots list (changeSeat/unsit menu)

string NC_READER_CONTENT_SEPARATOR="%&§";

//PluginCommands=[string name, integer num, integer sendToProps, integer sendUntouchedParams]
list PluginCommandsDefault=[
    "PLUGINCOMMAND", PLUGIN_COMMAND_REGISTER, 0,
    "DEFAULTCARD", DEFAULT_CARD, 0,
/* we don't need the next values here, but don't forget to implement them in the Prop Plugin
    "OPTION", OPTIONS, 0,
    "OPTIONS", OPTIONS, 0,
*/
    "DOCARD", DOPOSE, 0,
    "TIMER", TIMER, 1, //If ON_(UN)SIT is known without registration
    "TIMER_REMOVE", TIMER_REMOVE, 0 //then we also should know the TIMER(_REMOVE) commands
];
list PluginCommands;
integer PLUGIN_COMMANDS_NAME=0;
integer PLUGIN_COMMANDS_NUM=1;
integer PLUGIN_COMMANDS_SEND_UNTOUCHED=2;
integer PLUGIN_COMMANDS_STRIDE=3;

//list MacroNames;
//list MacroValues;
list MacroList;
list UdpList;
// userDefinedPermissions
string PERMISSION_GROUP="group";
string PERMISSION_OWNER="owner";
string UDP_TYPE_LIST="l";
string UDP_TYPE_BOOL="b";
string MACRO_TYPE="m";

debug(list message){
    llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

UpdateDefaultCard() {
    if(llGetInventoryType(INIT_CARD_NAME)==INVENTORY_NOTECARD) {
        key newInitCardUuid=llGetInventoryKey(INIT_CARD_NAME);
        if(newInitCardUuid!=InitCardUuid) {
            InitCardUuid=newInitCardUuid;
            llMessageLinked(LINK_SET, DOPOSE, INIT_CARD_NAME, NULL_KEY);
        }
    }
    else {
        //this is the old default notcard detection.
        integer index;
        integer length = llGetInventoryNumber(INVENTORY_NOTECARD);
        for(index=0; index < length; index++) {
            string cardName = llGetInventoryName(INVENTORY_NOTECARD, index);
            if((llSubStringIndex(cardName, DEFAULT_PREFIX + ":") == 0)) {
                llMessageLinked(LINK_SET, DEFAULT_CARD, cardName, NULL_KEY);
                return;
            }
        }
    }
}

GetGender() {
    integer slotIndex;
    integer slots = llGetListLength(Slots)/11;
    key AVID;
    for(slotIndex=0; slotIndex<slots; ++slotIndex) {
        AVID= llList2Key(Slots, (slotIndex*11) + 8);
        llMessageLinked(LINK_SET, DO, "UDPBOOL|MS" + (string)(slotIndex + 1) + "=" +  (string)llList2Float(llGetObjectDetails(AVID, ([OBJECT_BODY_SHAPE_TYPE])), 0), "");
    }
}

integer assignSlots() {
    //returns true if the Slots list was changed
    integer slotsChangeDetected;
    //Get the seated Avs and the named seat they are sitting on
    list sittingAvatars; // stride: [sitterKey, (integer)namedSeatNumber]
    integer index;
    for(index = llGetNumberOfPrims(); index>1; index--) {
        key id=llGetLinkKey(index);
        if(llGetAgentSize(id) != ZERO_VECTOR) {
            //is an Avatar
            //add gender to the list ... howard
            sittingAvatars = [id, 0] + sittingAvatars;
        }
        else {
            //is a prim
            key sitter=llAvatarOnLinkSitTarget(index);
            if(sitter) {
                integer indexSittingAvatars=llListFindList(sittingAvatars, [sitter]);
                if(~indexSittingAvatars) {
                    sittingAvatars=llListReplaceList(sittingAvatars, [(integer)llGetLinkName(index)], indexSittingAvatars+1, indexSittingAvatars+1);
                }
            }
        }
    }
    //check if all Avatars in our Slots list are valid
    integer length=llGetListLength(Slots);
    for(index=0; index<length; index+=SLOTS_STRIDE) {
        if(llList2Integer(Slots, index+SLOTS_SITTER_TYPE)==SITTER_TYPE_AVATAR) {
            integer indexSittingAvatars;
            if(llGetListLength(sittingAvatars) && ~(indexSittingAvatars=llListFindList(sittingAvatars, [llList2Key(Slots, index + SLOTS_SITTER_KEY)]))) {
                sittingAvatars=llDeleteSubList(sittingAvatars, indexSittingAvatars, indexSittingAvatars+1);
            }
            else {
                Slots=llListReplaceList(Slots, ["", SITTER_TYPE_NONE, ""], index + SLOTS_SITTER_KEY, index + SLOTS_SITTER_NAME);
                slotsChangeDetected=TRUE;
            }
        }
    }
    //our Slots list is now valid and the sittingAvatars list contains
    //new sitter(s). The list is sorted by the time they sit down
    //so all we have to do is trying to place them in the Slots list
    //if they are sitting on a numbered seat we should first try to sit them in the corresponding slot.
    //if there is no slot available, unsit them
    list unsitAvatars;
    while(llGetListLength(sittingAvatars)) {
        key id=llList2Key(sittingAvatars, 0);
        integer emptySlot=FindEmptySlot(id, llList2Integer(sittingAvatars, 1)-1);
        if(~emptySlot) {
            string sitterName;
            if(OptionUseDisplayNames) {
                sitterName=sanitizeString(llGetDisplayName(id));
            }
            else {
                sitterName=llKey2Name(id);
            }
            Slots=llListReplaceList(Slots, [id, SITTER_TYPE_AVATAR, sitterName], emptySlot*SLOTS_STRIDE+SLOTS_SITTER_KEY, emptySlot*SLOTS_STRIDE+SLOTS_SITTER_NAME);
            //correct the seat number based upon the slot chosen so we can marry up seat and gender
            sittingAvatars = llListReplaceList(sittingAvatars, [emptySlot+1], 1,1);
            slotsChangeDetected=TRUE;
            //check if the menu should be displayed
            if(CurMenuOnSit) {
                menuOnSitID=id;
//                llMessageLinked(LINK_SET, DOMENU, "", id);
//                  moved this line to right after seat update command cause menuonsit=1 combined with SET{seated} was not working.  Menu got DOMENU command before the seat update.
            }
        }
        else {
            unsitAvatars+=[id];
        }
        //create the gender for this seat as a udpbool
        GetGender();
        sittingAvatars=llDeleteSubList(sittingAvatars, 0, 1);
    }
    if(llGetListLength(unsitAvatars)) {
        llMessageLinked(LINK_SET, DO, "UNSIT|" + llList2CSV(unsitAvatars), NULL_KEY);
    }
    return slotsChangeDetected;
}

integer FindEmptySlot(key avatarKey, integer preferredSlotNumber) {
    integer slotNumber;
    list freeSlotNumberList;
    for(slotNumber=0; slotNumber < SlotsCount; slotNumber++) {
        if(llList2Integer(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_TYPE)!=SITTER_TYPE_AVATAR) {
            if(isAllowed(avatarKey, llList2String(Slots, slotNumber*SLOTS_STRIDE + SLOTS_SEAT_PERM))) {
                freeSlotNumberList+=slotNumber;
            }
        }
    }
    if(!llGetListLength(freeSlotNumberList)) {
        return -1;
    }
    if(~llListFindList(freeSlotNumberList, [preferredSlotNumber])) {
        return preferredSlotNumber;
    }
    list parts=llCSV2List(SeatAssignList);
    while(llGetListLength(parts)) {
        string item=llList2String(parts, 0);
        if(item=="a") {
            return llList2Integer(freeSlotNumberList, 0);
        }
        else if(item=="d") {
            return llList2Integer(freeSlotNumberList, -1);
        }
        else if(item=="r") {
            return llList2Integer(llListRandomize(freeSlotNumberList, 1), 0);
        }
        else if(~llListFindList(freeSlotNumberList, [(integer)item - 1])) {
            return (integer)item - 1;
        }
        parts=llDeleteSubList(parts, 0, 0);
    }
    return -1;
}

string insertMacros(string text) {
    // inserts the macros recursiv /@thisIsAMacro@/
    // doesn't support nesting.
    if(!~llSubStringIndex(text, "/@")) {
        return text;
    }
    string returnValue=text;
    integer index;
    integer length=llGetListLength(MacroList);
    for(index=0; index<length; index+=3) {
        returnValue=llDumpList2String(llParseStringKeepNulls(returnValue, ["/@" + llList2String(MacroList, index) + "@/"], []), llList2String(MacroList, index+2));
    }
    if(returnValue!=text) {
        returnValue=insertMacros(returnValue);
    }
    return returnValue;
}

string buildParamSet1(string path, integer page, string prompt, list additionalButtons, list pluginParams) {
    //pluginParams are: string pluginLocalPath, string pluginName, string pluginMenuParams, string pluginActionParams
    //We can't use colons in the promt, because they are used as a seperator in other messages
    //so we replace them with a UTF Symbol
    return llDumpList2String([
        path,
        page,
        llDumpList2String(llParseStringKeepNulls(prompt, [","], []), "‚"), // CAUTION: the 2nd "‚" is a UTF sign!
        llDumpList2String(additionalButtons, ",")
    ] + llList2List(pluginParams + ["", "", "", ""], 0, 3), "|");
}

integer checkSlotsChange(string ncNameForSequencer, list slotsAnimChanged) {
    string currentSlotsHash=llMD5String(llDumpList2String(Slots, "^"), 0);
    if(currentSlotsHash!=SlotsHash || llGetListLength(slotsAnimChanged)) {
        SlotsHash=currentSlotsHash;
        llMessageLinked(LINK_SET, SEAT_UPDATE, llDumpList2String([SLOTS_STRIDE, SEAT_UPDATE_PREAMBLE_LENGTH, llDumpList2String(slotsAnimChanged, ",")] + Slots, "^"), (key)ncNameForSequencer);
        if(menuOnSitID) {
            llMessageLinked(LINK_SET, DOMENU, "", menuOnSitID);
            menuOnSitID = "";
        }
        return TRUE;
    }
    return FALSE;
}


integer isAllowed(key avatarKey, string permissions) {
    // avatarKey: the key of the avatar who wants to sit or who uses the menu
    // 

    // Syntax of the permission string:
    // It contains KEYWORDS and OPERATORS.

    // OPERATORS (listed in order of their precedence)
    // ! means a logical NOT
    // & means a logical AND
    // ~ means a logical OR
    // Operators may be surrounded by spaces

    // KEYWORDS (case insensitive)
    // owner:
    //        returns TRUE if the avatar is the object owner
    // group:
    //        returns TRUE if the active group of the avatar is equal to the group of the object
    // seated:
    //        returns TRUE if the menu user is seated
    // any integer counts as a seatNumber:
    //        returns TRUE if menu user sits on the seat with the number seatNumber
    // any integer followed by ".empty" counts as a seatNumber:
    //        returns TRUE if the seat is not occupied with an avatar
    // any string that beginns with a "@":
    //       is a macro, which gets recursivly parsed
    // any other string counts as a UserDefinedPermission
    //        type list:
    //            returns TRUE if the avatar is within the list
    //        type bool:
    //            returns the value of the UserDefinedPermission
    permissions=llStringTrim(permissions, STRING_TRIM);
    if(permissions=="") {
        return TRUE;
    }
    list permItemsOr=llParseString2List(llToLower(permissions), ["~"], []);
    integer indexOr=~llGetListLength(permItemsOr);
    integer result;
    while(++indexOr && !result) {
        list permItemsAnd=llParseString2List(llList2String(permItemsOr, indexOr), ["&"], []);
        integer indexAnd=~llGetListLength(permItemsAnd);
        result=TRUE;
        while(++indexAnd && result) {
            integer invert;
            string item=llStringTrim(llList2String(permItemsAnd, indexAnd), STRING_TRIM);
            if(llGetSubString(item, 0, 0)=="!") {
                invert=TRUE;
                item=llStringTrim(llDeleteSubString(item, 0, 0), STRING_TRIM);
            }
            if(item==PERMISSION_GROUP) {
                result=llSameGroup(avatarKey);
            }
            else if(item==PERMISSION_OWNER) {
                result=llGetOwner()==avatarKey;
            }
            else if(item=="seated") {
                result=llListFindList(llList2ListStrided(llDeleteSubList(Slots, 0, SLOTS_SITTER_KEY-1), 0, -1, SLOTS_STRIDE), [avatarKey])!=-1;
            }
            else if(~llSubStringIndex(item, ".empty")) {
                result=llList2Integer(Slots, ((integer)llGetSubString(item, 0, -7)-1)*SLOTS_STRIDE + SLOTS_SITTER_TYPE)!=SITTER_TYPE_AVATAR;
            }
            else if((string)((integer)item)==item){
                result=llList2Key(Slots, ((integer)item-1)*SLOTS_STRIDE + SLOTS_SITTER_KEY)==avatarKey;
            }
            else if(llGetSubString(item, 0, 0)=="@") {
                integer macroIndex=llListFindList(MacroList, [llDeleteSubString(item, 0, 0), MACRO_TYPE]);
                if(~macroIndex) {
                    result=isAllowed(avatarKey, llList2String(MacroList, macroIndex+2));
                }
                else {
                    //unknown Macro: assume that it is set to ""
                    result=FALSE;
                }
            }
            else {
                //maybe a user defined permission
                integer udpIndex=llListFindList(UdpList, [item]);
                if(~udpIndex) {
                    //plugin permission
                    string pluginPermissionType=llList2String(UdpList, udpIndex+1);
                    if(pluginPermissionType==UDP_TYPE_LIST) {
                        result=~llSubStringIndex(llList2String(UdpList, udpIndex+2), (string)avatarKey);
                    }
                    else if(pluginPermissionType==UDP_TYPE_BOOL) {
                        result=(integer)llList2String(UdpList, udpIndex+2);
                    }
                    else {
                        //error unknown plugin permission type
                        result=FALSE;
                    }
                }
                else {
                    //maybe the plugin has not registered itself right now. So assume a blank list or a 0 as value
                    result=FALSE;
                }
            }
            //logicalXor
            result=(invert && !result) || (!invert && result);
        }
    }
    return result;
}

string sanitizeString(string str) {
    str=llDumpList2String(llParseStringKeepNulls(str, ["`"], []), "‵");
    str=llDumpList2String(llParseStringKeepNulls(str, ["|"], []), "┃");
    str=llDumpList2String(llParseStringKeepNulls(str, ["/"], []), "⁄");
    str=llDumpList2String(llParseStringKeepNulls(str, [":"], []), "꞉");
    str=llDumpList2String(llParseStringKeepNulls(str, [","], []), "‚");
    str=llDumpList2String(llParseStringKeepNulls(str, ["^"], []), "⌃");
    str=llDumpList2String(llParseStringKeepNulls(str, ["="], []), "═");
    return str;
}

default{
    state_entry() {
        integer index;
        for(index=0; index<=llGetNumberOfPrims(); ++index) {
            llLinkSitTarget(index, <0.0, 0.0, 0.5>, ZERO_ROTATION);
        }
        llSleep(1.0); //wait for other scripts
        UpdateDefaultCard();
    }
    link_message(integer sender, integer num, string str, key id) {
        if(num == DOPOSE_READER || num==PREPARE_MENU_STEP3_READER || num==DO) {
            list allData=llParseStringKeepNulls(str, [NC_READER_CONTENT_SEPARATOR], []);
            str = "";
            if(num==DO) {
                allData=["", "", ""] + allData;
            }
            //allData: [ncName, paramSet1, "", contentLine1, contentLine2, ...]
            string ncName=llList2String(allData, 0);
            if(ncName==DefaultCardName && num == DOPOSE_READER) {
                //props (propGroup 0) die when the default card is read
                llMessageLinked(LINK_SET, PROP_PLUGIN, "PROP_DO|*|0||DIE", id);
            }
            list paramSet1List=llParseStringKeepNulls(llList2String(allData, 1), ["|"], []);
            string path=llList2String(paramSet1List, 0);
            integer page=(integer)llList2String(paramSet1List, 1);
            string prompt=llList2String(paramSet1List, 2);
            
            integer avSeat=llListFindList(Slots, [id])/SLOTS_STRIDE+1;
            integer slotsChangeDetected;
            list slotsAnimChanged;
            //initialize list for SAT/NOTSAT Plugin
            list events;
            //initialize list for Buddy Plugin
            list buddy;
            
            //parse the NC content
            allData=llDeleteSubList(allData, 0, 2);
            while(llGetListLength(allData)) {
                list paramsOriginal = llParseStringKeepNulls(llList2String(allData, 0), ["|"], []);
                string data = insertMacros(llList2String(allData, 0));
                allData=llDeleteSubList(allData, 0, 0);
                if(num!=PREPARE_MENU_STEP3_READER || !llSubStringIndex(data, "MENU")) {
                    //if we prepare the menu we only need to parse lines beginning with MENU...
// begin: the old ProcessLine function is here now, because it saves memory
    //begin: the old insertPlaceholder is here now, because it saves memory
                    if(~llSubStringIndex(data, "%")) {
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%CARDNAME%"], []), ncName);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%AVKEY%"], []), (string)id);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%AVSEAT%"], []), (string)avSeat);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%PATH%"], []), path);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%PAGE%"], []), (string)page);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%DISPLAYNAME%"], []), sanitizeString(llGetDisplayName(id)));
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%USERNAME%"], []), llGetUsername(id));
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%SCALECUR%"], []), (string)llList2Vector(llGetLinkPrimitiveParams((integer)(llGetNumberOfPrims()>1), [PRIM_SIZE]), 0));
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%SCALEREF%"], []), (string)ScaleRef);
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%POSITION%"], []), (string)llGetRootPosition());
                        data = llDumpList2String(llParseStringKeepNulls(data, ["%ROTATION%"], []), (string)llGetRootRotation());
                
                        integer slotNumber;
                        if(~llSubStringIndex(data, ".KEY%")) {
                            data = llDumpList2String(llParseStringKeepNulls(data, ["%OWNER.KEY%"], []), llGetOwner());
                            for(slotNumber=0; slotNumber<SlotsCount; slotNumber++) {
                                data = llDumpList2String(llParseStringKeepNulls(data, ["%" + (string)(slotNumber+1) + ".KEY%"], []), (string)llList2Key(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_KEY));
                            }
                        }
                        if(~llSubStringIndex(data, ".NAME%")) {
                            for(slotNumber=0; slotNumber<SlotsCount; slotNumber++) {
                                data = llDumpList2String(llParseStringKeepNulls(data, ["%" + (string)(slotNumber+1) + ".NAME%"], []), llList2String(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_NAME));
                            }
                        }
                        if(~llSubStringIndex(data, ".SEATNAME%")) {
                            for(slotNumber=0; slotNumber<SlotsCount; slotNumber++) {
                                data = llDumpList2String(llParseStringKeepNulls(data, ["%" + (string)(slotNumber+1) + ".SEATNAME%"], []), llList2String(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SEAT_NAME));
                            }
                        }
                    }
    //end: the old insertPlaceholder is here now, because it saves memory
                    list params = llParseStringKeepNulls(data, ["|"], []);
                    string actionWithPerms = llList2String(params, 0);
                    string action = actionWithPerms;
                    string perms;
                    list temp=llParseString2List(action, ["{", "}"], []);
                    if(llGetListLength(temp)>1) {
                        action=llList2String(temp, 0);
                        perms=llToLower(llStringTrim(llList2String(temp, 1), STRING_TRIM));
                    }
                    //strip the permissions
                    params=llListReplaceList(params, [action], 0,0);
                    data=llDumpList2String(params, "|");
                    paramsOriginal=llListReplaceList(paramsOriginal, [action], 0,0);
                    string dataOriginal=llDumpList2String(paramsOriginal, "|");
                    
                    //check the permissions
                    if(!isAllowed(id, perms)) {
                    }
                    
                    else if(action == "MENUPROMPT") {
                        //"\n" are escaped in NC content
                        prompt=llDumpList2String(llParseStringKeepNulls(llList2String(params, 1), ["\\n"], []), "\n");
                    }
                    
                    else if(action == "SEAT_INIT") {
                        list oldSitters=llList2ListStrided(llDeleteSubList(Slots, 0, SLOTS_SITTER_KEY - 1), 0, -1, SLOTS_STRIDE);
                        list oldSittersType=llList2ListStrided(llDeleteSubList(Slots, 0, SLOTS_SITTER_TYPE - 1), 0, -1, SLOTS_STRIDE);
                        list oldSittersName=llList2ListStrided(llDeleteSubList(Slots, 0, SLOTS_SITTER_NAME - 1), 0, -1, SLOTS_STRIDE);
                        Slots=[];
                        slotsAnimChanged=[];
                        slotsChangeDetected=TRUE;
                        SlotsCount=llList2Integer(params, 1);
                        integer slotNumber;
                        for(slotNumber=0; slotNumber<SlotsCount; slotNumber++) {
                            slotsAnimChanged+=[slotNumber];
                            Slots+=[
                                "Seat "+(string)(slotNumber+1), // SLOTS_SEAT_NAME
                                "", // SLOTS_SEAT_PERM
                                "", // SLOTS_ANIM_NAMES
                                ZERO_VECTOR, // SLOTS_ANIM_POS
                                ZERO_ROTATION, // SLOTS_ANIM_ROT
                                "", // SLOTS_FACIALS
                                ncName, // SLOTS_ANIM_NC_NAME
                                actionWithPerms, // SLOTS_ANIM_COMMAND
                                llList2Key(oldSitters, 0), // SLOTS_SITTER_KEY
                                llList2Integer(oldSittersType, 0), // SLOTS_SITTER_TYPE
                                llList2String(oldSittersName, 0) // SLOTS_SITTER_NAME
                            ];
                            oldSitters=llDeleteSubList(oldSitters, 0, 0);
                            oldSittersType=llDeleteSubList(oldSittersType, 0, 0);
                            oldSittersName=llDeleteSubList(oldSittersName, 0, 0);
                        }
                        assignSlots(); //1) this is usefull after a reset and 2) this also makes sure that there are not too much sitters
                        llMessageLinked(LINK_SET, SEAT_INIT, (string)SlotsCount, id);
                        llMessageLinked(LINK_SET, PROP_PLUGIN, "PROP_DO|*|0||DIE", id);
                    }
                
                    else if(action == "DEF") {
                        //examples
                        //DEF|seatNames|1=name1|2=name2
                        //DEF|seatPermissions|*=group
                        //DEF|seatKeywords|*=test|1=
                        //DEF|animnames|*=anim1|2/3/4=anim2
                        string targetParam=llStringTrim(llToLower(llList2String(params, 1)), STRING_TRIM);
                        list myParams=llDeleteSubList(params, 0, 1);
                        integer offset;
                        string dataType="s";
                        if(targetParam=="seatname") {offset=SLOTS_SEAT_NAME;}
                        else if(targetParam=="seatperm") {offset=SLOTS_SEAT_PERM;}
                        else if(targetParam=="animname") {offset=SLOTS_ANIM_NAMES;}
                        else if(targetParam=="animpos") {offset=SLOTS_ANIM_POS; dataType="v";}
                        else if(targetParam=="animrot") {offset=SLOTS_ANIM_ROT; dataType="r";}
                        else if(targetParam=="animfacials") {offset=SLOTS_FACIALS;}
                        else if(targetParam=="animncname") {offset=SLOTS_ANIM_NC_NAME;}
                        else if(targetParam=="animcommand") {offset=SLOTS_ANIM_COMMAND;}
                        else if(targetParam=="sitterkey") {offset=SLOTS_SITTER_KEY; dataType="k";}
                        else if(targetParam=="sittertype") {offset=SLOTS_SITTER_TYPE; dataType="i";}
                        else if(targetParam=="sittername") {offset=SLOTS_SITTER_NAME;}
                        else {myParams=[];}
                        while(llGetListLength(myParams)) {
                            string item=llList2String(myParams, 0);
                            myParams=llDeleteSubList(myParams, 0, 0);
                            list itemParts=llParseStringKeepNulls(item, ["="], []);
                            string targetSeatsString=llStringTrim(llList2String(itemParts, 0), STRING_TRIM);
                            string targetValueString=llList2String(itemParts, 1);
                            list targetValueList=[targetValueString];
                            if(dataType=="v") {targetValueList=[(vector)targetValueString];}
                            else if(dataType=="r") {targetValueList=[(rotation)targetValueString];}
                            else if(dataType=="k") {targetValueList=[(key)targetValueString];}
                            else if(dataType=="i") {targetValueList=[(integer)targetValueString];}
                            list targetSeats=llParseString2List(targetSeatsString, ["/"], []);
                            integer slotNumber;
                            if(targetSeatsString=="*") {
                                targetSeats=[];
                                for(slotNumber=0; slotNumber<SlotsCount; slotNumber++) {
                                    targetSeats+=[slotNumber+1];
                                }
                            }
                            while(llGetListLength(targetSeats)) {
                                slotNumber=(integer)llList2String(targetSeats,0)-1;
                                targetSeats=llDeleteSubList(targetSeats, 0, 0);
                                if(slotNumber>=0 && slotNumber < SlotsCount) { //sanity
//                                    //generate a hash to determine a animation change
//                                    string oldHash=llDumpList2String(llList2List(Slots, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NC_NAME), "");
                                    Slots=llListReplaceList(Slots, targetValueList, slotNumber*SLOTS_STRIDE + offset, slotNumber*SLOTS_STRIDE + offset);
                                    slotsChangeDetected=TRUE;
//                                    if(oldHash!=llDumpList2String(llList2List(Slots, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NC_NAME), "")) {
//                                        integer index=llListFindList(slotsAnimChanged, [slotNumber]);
//                                        if(!~index) {
//                                            slotsAnimChanged+=[slotNumber];
//                                        }
//                                    }
                                }
                            }
                        }
                    }
                
                    else if(action == "XANIM") {
                        //XANIM|seatNumber|csv animations|pos|rot|facials
                        //XANIM works almost like the old SCHMOE command
                        //if you want to implement a command like the old SCHMO|seatnumber... you have to write: XANIM{seatnumber}|seatnumber....
                        llMessageLinked(LINK_SET, PROP_PLUGIN, "PROP_DO|*|0||DIE", id);
                        integer slotNumber = (integer)llList2String(params,1)-1;
                        if(slotNumber>=0 && slotNumber < SlotsCount) { //sanity
//                            //generate a hash to determine a animation change
//                            string oldHash=llDumpList2String(llList2List(Slots, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NC_NAME), "");
                            //Clear out the ON_SIT/ON_UNSIT. If we need them, we must add them back in the NC
                            events=["ON_SIT|" + (string)(slotNumber + 1), "ON_UNSIT|" + (string)(slotNumber + 1)] + events;
                            //add ncName and action
                            Slots=llListReplaceList(Slots, [ncName, actionWithPerms], slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NC_NAME, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_COMMAND);
                            integer index;
                            integer length=llGetListLength(params);
                            for(index=2; index<=5; index++) {
                                if(index==2) {
                                    Slots=llListReplaceList(Slots, [llList2String(params, index)],
                                        slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES);
                                }
                                else if(index==3) {
                                    Slots=llListReplaceList(Slots, [(vector)llList2String(params, index)],
                                        slotNumber * SLOTS_STRIDE + SLOTS_ANIM_POS, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_POS);
                                }
                                else if(index==4) {
                                    Slots=llListReplaceList(Slots, [llEuler2Rot((vector)llList2String(params, index) * DEG_TO_RAD)],
                                        slotNumber * SLOTS_STRIDE + SLOTS_ANIM_ROT, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_ROT);
                                }
                                else if(index==5) {
                                    Slots=llListReplaceList(Slots, [llList2String(params, index)],
                                        slotNumber * SLOTS_STRIDE + SLOTS_FACIALS, slotNumber * SLOTS_STRIDE + SLOTS_FACIALS);
                                }
                            }
                            slotsChangeDetected=TRUE;
                            //add the slotnummer to the slotsAnimChanged list
//                            if(oldHash!=llDumpList2String(llList2List(Slots, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NAMES, slotNumber * SLOTS_STRIDE + SLOTS_ANIM_NC_NAME), "")) {
                                index=llListFindList(slotsAnimChanged, [slotNumber]);
                                if(!~index) {
                                    slotsAnimChanged+=[slotNumber];
                                }
//                            }

                        }
                    }
                    else if(action == "UNSIT") {
                        // UNSIT|csv list of seatNumbers (or avatar keys) or "*" (all) or "others" (all but me)
                        string myParam=llToLower(llStringTrim(llList2String(params, 1), STRING_TRIM));
                        list avatarKeyOrSeatNumbers;
                        if(myParam=="*" || myParam=="others") {
                            integer seatNumber;
                            for(seatNumber=SlotsCount; seatNumber>0; seatNumber--) {
                                //reverse order, because of possible performance improvements later on
                                if(myParam=="*" || seatNumber!=avSeat) {
                                    avatarKeyOrSeatNumbers+=[seatNumber];
                                }
                            }
                        }
                        else {
                            avatarKeyOrSeatNumbers=llCSV2List(myParam);
                        }
                        while(llGetListLength(avatarKeyOrSeatNumbers)) {
                            string avatar=llList2String(avatarKeyOrSeatNumbers, 0);
                            avatarKeyOrSeatNumbers=llDeleteSubList(avatarKeyOrSeatNumbers, 0, 0);
                            key avatarKey=(key)avatar;
                            if(((string)((integer)avatar))==avatar) {
                                //it is a seat number
                                integer slotNumber=(integer)avatar - 1;
                                if(slotNumber>=0 && slotNumber<SlotsCount) { //sanity
                                    integer sitterType=llList2Integer(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_TYPE);
                                    if(sitterType==SITTER_TYPE_AVATAR) {
                                        //it is an avatar: the unsit happens later in this function, the Slots list will be updated in the change event
                                        avatarKey=llList2Key(Slots, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_KEY);
                                    }
//TODO: should we be able to unsit a non avatar?
                                    else if(sitterType) {
                                        //it is not an avatar: remove it from the slots list
                                        Slots=llListReplaceList(Slots, ["", SITTER_TYPE_NONE, ""], slotNumber * SLOTS_STRIDE + SLOTS_SITTER_KEY, slotNumber * SLOTS_STRIDE + SLOTS_SITTER_NAME);
                                        slotsChangeDetected=TRUE;
                                    }
                                }
                            }
                            if(avatarKey) {
                                //it is a valid key
                                integer index=llGetNumberOfPrims();
                                integer found;
                                while(index>0 && !found && llGetAgentSize(llGetLinkKey(index)) != ZERO_VECTOR) {
                                    found=llGetLinkKey(index--)==avatarKey;
                                }
                                if(found) {
                                    //it is a valid sitter
                                    llUnSit(avatarKey);
                                }
                            }
                        }
                    }
                    else if(action == "SWAP") {
                        //SWAP|(csv) two seatNumbers
                        list SeatNumbers=llCSV2List(llList2String(params, 1));
                        integer seatNumber1=(integer)llList2String(SeatNumbers, 0);
                        integer seatNumber2=(integer)llList2String(SeatNumbers, 1);
                        if(seatNumber1 > 0 && seatNumber2 > 0 && seatNumber1 <= SlotsCount && seatNumber2 <= SlotsCount) { //sanity
                            //TODO: if we use seat permissions we may want to implement a check here
                            slotsChangeDetected=TRUE;
                            integer index1=(seatNumber1-1) * SLOTS_STRIDE;
                            integer index2=(seatNumber2-1) * SLOTS_STRIDE;
                            Slots=llListReplaceList(
                                llListReplaceList(
                                    Slots, 
                                    llList2List(Slots, index2 + SLOTS_SITTER_KEY, index2 + SLOTS_SITTER_NAME),
                                    index1 + SLOTS_SITTER_KEY,
                                    index1 + SLOTS_SITTER_NAME
                                ),
                                llList2List(Slots, index1 + SLOTS_SITTER_KEY, index1 + SLOTS_SITTER_NAME),
                                index2 + SLOTS_SITTER_KEY,
                                index2 + SLOTS_SITTER_NAME
                            );
                        }
                        //update gender
                        GetGender();
                    }
                    else if(action=="PAUSE") {
                        llSleep((float)llList2String(params, 1));
                    }
                    else if(action == "LINKMSG") {
                        //LINKMSG|(integer)num|(string)str|(key)id
                        //notice: LINKMSG will not fire inside the props anymore, use PROP_DO|propName|propGroup|propNamespace|LINKMSG....
                        //reason: waste of CPU time
                        //notice: LINKMSG doesn't support the pause parameter anymore
                        //reason: the pause was evil
                        //notice: LINKMSG will not add the menu user to the id part automaticly anymore
                        //reason: I (Leona) want to be able to send linkmessages with a blank id part which was not possible
                        //        You can easily add %AVKEY% as the third parameter to get the old behaviour
                        llMessageLinked(LINK_SET, (integer)llList2String(params, 1), llList2String(params, 2), (key)llList2String(params, 3));
                    }
                    else if(llSubStringIndex(action, "ON_")==0) {
                        //NEW Syntax: ON_X|csv seatNumbers or *|any command ...
                        events+=dataOriginal;
                    }
/*
                    else if (action == "ON_SIT" || action == "ON_UNSIT" || action == "BUDDY_ON_SIT" || action == "BUDDY_ON_UNSIT") {
                        //Syntax: ON_SIT|seatNumber|any command ...
                        //example
                        //  ON_SIT|1|LINKMSG|1234|This is a test|%AVKEY%
                        //if you want to set the ON_SIT command only for the menu user (like the SCHMO command) then use the new command permissions:
                        //example:
                        //  ON_SIT{2}|2|LINKMSG|1234|Seat2 is now occupied
                        //  ON_UNSIT{2}|2|LINKMSG|1234|Seat2 is now free
                        integer offset;
                        if(action == "ON_SIT") {offset=SLOTS_ON_SIT;}
                        else if(action == "ON_UNSIT") {offset=SLOTS_ON_UNSIT;}
                        else if(action == "BUDDY_ON_SIT") {offset=SLOTS_BUDDY_ON_SIT;}
                        else if(action == "BUDDY_ON_UNSIT") {offset=SLOTS_BUDDY_ON_UNSIT;}
                        integer index=((integer)llList2String(params, 1)-1) * SLOTS_STRIDE + offset;
                        if(index>=0 && index < llGetListLength(Slots)) { //sanity
                            string msg=llList2String(Slots, index);
                            if(msg) {
                                msg+=NC_READER_CONTENT_SEPARATOR;
                            }
                            slotsChangeDetected=TRUE;
                            Slots = llListReplaceList(
                                Slots,
                                [msg + llDumpList2String(llDeleteSubList(paramsOriginal, 0, 1), "|")],
                                index,
                                index
                            );
                        }
                    }
*/
                    else if(action == "PLUGINMENU") {
                        llMessageLinked(LINK_SET, PLUGIN_MENU_REGISTER, llDumpList2String(llListReplaceList(params, [path], 0, 0), "|"), "");
                    }
                    else if(action=="PROPDIE") {
                        //PROPDIE is deprecated and should be replaced by: PROP_DO|propName|propGroup|propNamespace|DIE
                        llMessageLinked(LINK_SET, PROP_PLUGIN, llDumpList2String(["PROP_DO", llList2String(params, 1), llList2String(params, 2), "", "DIE"], "|"), id);
                    }
                    else if(action=="PROP" || action=="PROP_DO"  || action=="PROP_DO_ALL" || action=="PARENT_DO" || action=="PARENT_DO_ALL" || action=="DIE" || action=="TEMPATTACH" || action=="ATTACH" || action=="POS" || action=="ROT") {
                        //Prop related
                        llMessageLinked(LINK_SET, PROP_PLUGIN, data, id);
                    }
                    else if (action=="OPTION" || action=="OPTIONS" || action=="MACRO" || action=="UDPBOOL" || action=="UDPLIST") {
                        integer newNum=OPTIONS;
                        llMessageLinked(LINK_SET, newNum, llDumpList2String(llDeleteSubList(params, 0, 0), "|"), id);
                        //save new option(s) or macro(s)
                        list optionsToSet;
                        integer paramsLength = llGetListLength(params);
                        integer index;
                        for(index=1; index<paramsLength; ++index) {
                            list optionsItems = llParseString2List(llList2String(params, index), ["="], []);
                            string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
                            integer operationType=(llGetSubString(optionItem, -1, -1)=="+") + 2*(llGetSubString(optionItem, -1, -1)=="-"); //0: replace, 1:add, 2:subtract
                            if(operationType) {
                                optionItem=llStringTrim(llDeleteSubString(optionItem, -1, -1), STRING_TRIM);
                            }
                            string optionString = llList2String(optionsItems, 1);
                            string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
                            integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;
                            if(action=="MACRO") {
                                integer macroIndex=llListFindList(MacroList, [optionItem, MACRO_TYPE]);
                                if(~macroIndex) {
                                    MacroList=llDeleteSubList(MacroList, macroIndex, macroIndex+2);
                                }
                                MacroList+=[optionItem, MACRO_TYPE, optionString];
                            }
            
                            else if(action=="UDPBOOL" || action=="UDPLIST") {
                                integer udpIndex=llListFindList(UdpList, [optionItem]);
                                string oldValue;
                                if(~udpIndex) {
                                    oldValue=llList2String(UdpList, udpIndex+2);
                                    UdpList=llDeleteSubList(UdpList, udpIndex, udpIndex+2);
                                }
                                if(action=="UDPLIST") {
                                    string newValue=optionString;
                                    if(operationType) {
                                        newValue=llDumpList2String(llParseStringKeepNulls(oldValue, [optionString], []), "");
                                        if(operationType==1) {
                                            newValue=newValue+optionString;
                                        }
                                    }
                                    UdpList+=[optionItem, UDP_TYPE_LIST, newValue];
                                }
                                else if(action=="UDPBOOL") {
                                    integer newValue=optionSettingFlag;
                                    if(optionSetting=="!") {
                                        newValue=!(integer)oldValue;
                                    }
                                    UdpList+=[optionItem, UDP_TYPE_BOOL, newValue];
                                }
                            }
            
                            else if(action=="OPTIONS" || action=="OPTION") {
                                if(optionItem == "menuonsit") {CurMenuOnSit = optionSettingFlag;}
                                else if(optionItem == "2default") {Cur2default = optionSettingFlag;}
                                else if(optionItem == "scaleref") {ScaleRef = (vector)optionString;}
                                else if(optionItem == "seatassignlist") {SeatAssignList = optionSetting;}
                                else if(optionItem == "usedisplaynames") {OptionUseDisplayNames = optionSettingFlag;}
                            }
                        }
                        if(action=="MACRO") {
                            llMessageLinked(LINK_SET, UPDATE_MACRO, llDumpList2String(MacroList, "|"), id);
                        }
                        else if(action=="UDPBOOL" || action=="UDPLIST") {
                            llMessageLinked(LINK_SET, UPDATE_UDP, llDumpList2String(UdpList, "|"), id);
                        }
                    }
                    else if(!llSubStringIndex(action, "BUDDY_ON_")) {
                        buddy+=dataOriginal;
                    }
                    else if(!llSubStringIndex(action, "BUDDY")) {
                        //all BUDDY related commands
                        buddy+=data;
                    }
                    else {
                        integer index=llListFindList(PluginCommands + PluginCommandsDefault, [action]);
                        if(~index) {
                            integer newNum=llList2Integer(PluginCommands + PluginCommandsDefault, index + PLUGIN_COMMANDS_NUM);
                            string newStr=llDumpList2String(llDeleteSubList(params, 0, 0), "|");
                            if(llList2Integer(PluginCommands + PluginCommandsDefault, index + PLUGIN_COMMANDS_SEND_UNTOUCHED)) {
                                newStr=llDumpList2String(llDeleteSubList(paramsOriginal, 0, 0), "|");
                            }
                            llMessageLinked(LINK_SET, newNum, newStr, id);
                        }
                        else {
                            llMessageLinked(LINK_SET, UNKNOWN_COMMAND, data, id);
                        }
                    }
// end: the old ProcessLine function is here now, because it saves memory
                }
            }
            if(events) {
                llMessageLinked(LINK_SET, SATNOTSAT_PLUGIN, llDumpList2String(events, NC_READER_CONTENT_SEPARATOR), id);
            }
            if(buddy) {
                llMessageLinked(LINK_SET, BUDDY_PLUGIN, llDumpList2String(buddy, NC_READER_CONTENT_SEPARATOR), id);
            }
                
            if(slotsChangeDetected) {
                // a command has (probably) changed the Slots list
                if(slotsChangeDetected=checkSlotsChange(ncName, slotsAnimChanged)) {
                    //Slots List changed
                    if (llGetInventoryType(ncName) == INVENTORY_NOTECARD){ //sanity
                        LastAssignSlotsCardName=ncName;
                        LastAssignSlotsCardId=llGetInventoryKey(LastAssignSlotsCardName);
                        LastAssignSlotsAvatarId=id;
                    }
                }
            }
            if(!slotsChangeDetected && llGetListLength(buddy)) {
                llMessageLinked(LINK_SET, BUDDY_REFRESH, "", "");
            }
            if(path!="") {
                //only try to remenu if there are parameters to do so
                string paramSet1=buildParamSet1(path, page, prompt, [llList2String(paramSet1List, 3)], llList2List(paramSet1List, 4, 7));
                if(num==PREPARE_MENU_STEP3_READER) {
                    //we are ready to show the menu
                    llMessageLinked(LINK_SET, MENU_SHOW, paramSet1, id);
                }
                else if(num==DOPOSE_READER) {
                    llMessageLinked(LINK_SET, PREPARE_MENU_STEP1, paramSet1, id);
                }
            }
        }
        else if(num==PLUGIN_ACTION_DONE) {
            //only relay through the core to keep messages in sync
            llMessageLinked(LINK_SET, PREPARE_MENU_STEP2, str, id);
        }
/*
        // CORERELAY not longer supported, use llMessageLinked(LINK_SET, PROP_PLUGIN(-500), "PROP_DO|*|*||LINKMSG..."
        else if(num == CORERELAY) {
            list msg = llParseString2List(str, ["|"], []);
            if(id != NULL_KEY) msg = llListReplaceList((msg = []) + msg, [id], 2, 2);
            llRegionSay(ChatChannel,llDumpList2String(["LINKMSG", (string)llList2String(msg, 0),
                llList2String(msg, 1), (string)llList2String(msg,2)], "|"));
        }
*/
        else if(num == DEFAULT_CARD) {
            DefaultCardName=str;
            llMessageLinked(LINK_SET, DOPOSE, DefaultCardName, id);
        }
        else if(num==PLUGIN_COMMAND_REGISTER || num==PLUGIN_COMMAND_REGISTER_NO_OVERWRITE) {
            //old Format (remove in nPose V5): PLUGINCOMMAND|name|num|[sendToProps[|sendUntouchedParams]]
            //new Format: PLUGINCOMMAND|name, num[, sendUntouchedParams][|name...]...
            if(!~llSubStringIndex(str, ",")) {
                //old Format:convert to new format
                str=llList2CSV(llDeleteSubList(llParseStringKeepNulls(str, ["|"], []), 2, 2));
            }
            list parts=llParseString2List(str, ["|"], []);
            while(llGetListLength(parts)) {
                list subParts=llCSV2List(llList2String(parts, 0));
                parts=llDeleteSubList(parts, 0, 0);
                string action=llList2String(subParts, PLUGIN_COMMANDS_NAME);
                integer index=llListFindList(PluginCommands, [action]);
                if(num==PLUGIN_COMMAND_REGISTER && ~index) {
                    PluginCommands=llDeleteSubList(PluginCommands, index, index + PLUGIN_COMMANDS_STRIDE - 1);
                }
                if(num==PLUGIN_COMMAND_REGISTER || !~index) {
                    PluginCommands+=[
                        action,
                        (integer)llList2String(subParts, PLUGIN_COMMANDS_NUM),
                        (integer)llList2String(subParts, PLUGIN_COMMANDS_SEND_UNTOUCHED)
                    ];
                }
            }
        }
        else if(num == DIALOG_TIMEOUT) {
            if(Cur2default && (llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims()) && (DefaultCardName != "")) {
                llMessageLinked(LINK_SET, DOPOSE, DefaultCardName, NULL_KEY);
            }
        }
/*
        else if(num == OPTIONS) {
            //save new option(s) from LINKMSG
            list optionsToSet = llParseStringKeepNulls(str, ["~","|"], []);
            integer length = llGetListLength(optionsToSet);
            integer index;
            for(index=0; index<length; ++index) {
                list optionsItems = llParseString2List(llList2String(optionsToSet, index), ["="], []);
                string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
                string optionString = llList2String(optionsItems, 1);
                string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
                integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;

                if(optionItem == "menuonsit") {CurMenuOnSit = optionSettingFlag;}
                else if(optionItem == "2default") {Cur2default = optionSettingFlag;}
                else if(optionItem == "scaleref") {ScaleRef = (vector)optionString;}
                else if(optionItem == "seatassignlist") {SeatAssignList = optionSetting;}
            }
        }
*/
        else if(num == MEMORY_USAGE) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
             + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
        llSay(0, "running script time for all scripts in this nPose object are consuming " 
         + (string)(llList2Float(llGetObjectDetails(llGetKey(), ([OBJECT_SCRIPT_TIME])), 0)*1000.0) + " ms of cpu time");
        }
    }

    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            llSleep(0.5); //be sure that the NC reader is ready
            if(llGetInventoryType(LastAssignSlotsCardName) == INVENTORY_NOTECARD) {
                if(LastAssignSlotsCardId!=llGetInventoryKey(LastAssignSlotsCardName)) {
                    //the last used nc changed, "redo" the nc
                    llMessageLinked(LINK_SET, DOPOSE, LastAssignSlotsCardName, LastAssignSlotsAvatarId); 
                }
                else {
                    UpdateDefaultCard();
                }
            }
            else {
                UpdateDefaultCard();
            }
        }
        if(change & CHANGED_LINK) {
            if(assignSlots()) {
                checkSlotsChange(LastAssignSlotsCardName, []);
            }
            //check if there is no sitter anymore
            if(Cur2default && (llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims()) && (DefaultCardName != "")) {
                llMessageLinked(LINK_SET, DOPOSE, DefaultCardName, NULL_KEY);
            }
        }
    }
    
    on_rez(integer param) {
        llResetScript();
    }
}
