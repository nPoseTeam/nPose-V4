key System;
string Library;
integer gH = 200;
integer edefaultstate_entry = 310;
integer edefaultlink_message = -242;
integer g_ = -600;
integer gA = -601;
string gE;
key edefaultchanged;
key IsSaveDue;
integer LslUserScript;
list LslLibrary;
key Pop;
string UThread;
integer gB;
integer ResumeVoid;
vector gC = <0, 0, 0>;
string UThreadStackFrame = "a";
integer gG = 1;
list IsRestoring = 
    [ "PLUGINCOMMAND"
    , edefaultstate_entry
    , 0
    , "DEFAULTCARD"
    , edefaultlink_message
    , 0
    , "DOCARD"
    , gH
    , 0
    , "TIMER"
    , g_
    , 1
    , "TIMER_REMOVE"
    , gA
    , 0
    ];
list gD;
list edefaultrez;
list gF;

G()
{
    if (llGetInventoryType(".init") ^ 7)
    {
        integer loc_index;
        integer loc_length = llGetInventoryNumber(7);
        for (loc_index = 0; loc_index < loc_length; ++loc_index)
        {
            string loc_cardName = llGetInventoryName(7, loc_index);
            if (!llSubStringIndex(loc_cardName, "SET" + ":"))
            {
                llMessageLinked(((integer)-1), edefaultlink_message, loc_cardName, "00000000-0000-0000-0000-000000000000");
                return;
            }
        }
    }
    else
    {
        key loc_newInitCardUuid = llGetInventoryKey(".init");
        if (!(loc_newInitCardUuid == System))
        {
            System = loc_newInitCardUuid;
            llMessageLinked(((integer)-1), gH, ".init", "00000000-0000-0000-0000-000000000000");
        }
    }
}

C()
{
    integer loc_slotIndex;
    integer loc_slots = (LslLibrary != []) / 11;
    key loc_AVID;
    for (loc_slotIndex = 0; loc_slotIndex < loc_slots; ++loc_slotIndex)
    {
        loc_AVID = llList2Key(LslLibrary, 8 + loc_slotIndex * 11);
        llMessageLinked(((integer)-1), 220, "UDPBOOL|MS" + (string)(-~loc_slotIndex) + "=" + (string)llList2Float(llGetObjectDetails(loc_AVID, (list)26), 0), "");
    }
}

integer B()
{
    integer loc_slotsChangeDetected;
    list loc_sittingAvatars;
    integer loc_index;
    for (loc_index = llGetNumberOfPrims(); 1 < loc_index; --loc_index)
    {
        key loc_id = llGetLinkKey(loc_index);
        if (llGetAgentSize(loc_id) == <((float)0), ((float)0), ((float)0)>)
        {
            key loc_sitter = llAvatarOnLinkSitTarget(loc_index);
            if (loc_sitter)
            {
                integer loc_indexSittingAvatars = llListFindList(loc_sittingAvatars, (list)loc_sitter);
                if (~loc_indexSittingAvatars)
                {
                    loc_sittingAvatars = llListReplaceList(loc_sittingAvatars, (list)((integer)llGetLinkName(loc_index)), -~loc_indexSittingAvatars, -~loc_indexSittingAvatars);
                }
            }
        }
        else
        {
            loc_sittingAvatars = (list)loc_id + 0 + loc_sittingAvatars;
        }
    }
    integer loc_length = LslLibrary != [];
    for (loc_index = 0; loc_index < loc_length; loc_index = 11 + loc_index)
    {
        if (!~-llList2Integer(LslLibrary, 9 + loc_index))
        {
            integer loc_indexSittingAvatars;
            if (-!(loc_sittingAvatars == []) & ~(loc_indexSittingAvatars = llListFindList(loc_sittingAvatars, (list)llList2Key(LslLibrary, 8 + loc_index))))
            {
                loc_sittingAvatars = llDeleteSubList(loc_sittingAvatars, loc_indexSittingAvatars, -~loc_indexSittingAvatars);
            }
            else
            {
                LslLibrary = llListReplaceList(LslLibrary, (list)"" + 0 + "", 8 + loc_index, 10 + loc_index);
                loc_slotsChangeDetected = 1;
            }
        }
    }
    list loc_unsitAvatars;
    while (loc_sittingAvatars != [])
    {
        key loc_id = llList2Key(loc_sittingAvatars, 0);
        integer loc_emptySlot = _(loc_id, ~-llList2Integer(loc_sittingAvatars, 1));
        if (~loc_emptySlot)
        {
            string loc_sitterName;
            if (gG)
            {
                loc_sitterName = E(llGetDisplayName(loc_id));
            }
            else
            {
                loc_sitterName = llKey2Name(loc_id);
            }
            LslLibrary = llListReplaceList(LslLibrary, (list)loc_id + 1 + loc_sitterName, 8 + loc_emptySlot * 11, 10 + loc_emptySlot * 11);
            loc_sittingAvatars = llListReplaceList(loc_sittingAvatars, (list)(-~loc_emptySlot), 1, 1);
            loc_slotsChangeDetected = 1;
            if (gB)
            {
                Pop = loc_id;
            }
        }
        else
        {
            loc_unsitAvatars = loc_unsitAvatars + loc_id;
        }
        C();
        loc_sittingAvatars = llDeleteSubList(loc_sittingAvatars, 0, 1);
    }
    if (loc_unsitAvatars != [])
    {
        llMessageLinked(((integer)-1), 220, "UNSIT|" + llList2CSV(loc_unsitAvatars), "00000000-0000-0000-0000-000000000000");
    }
    return loc_slotsChangeDetected;
}

integer _(key llGetObjectDetails, integer llDeleteSubList)
{
    integer loc_slotNumber;
    list loc_freeSlotNumberList;
    for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
    {
        if (llList2Integer(LslLibrary, 9 + loc_slotNumber * 11) ^ 1)
        {
            if (F(llGetObjectDetails, llList2String(LslLibrary, -~(loc_slotNumber * 11))))
            {
                loc_freeSlotNumberList = loc_freeSlotNumberList + loc_slotNumber;
            }
        }
    }
    if (loc_freeSlotNumberList == [])
    {
        return ((integer)-1);
    }
    if (~llListFindList(loc_freeSlotNumberList, (list)llDeleteSubList))
    {
        return llDeleteSubList;
    }
    list loc_parts = llCSV2List(UThreadStackFrame);
    while (loc_parts != [])
    {
        string loc_item = llList2String(loc_parts, 0);
        if (loc_item == "a")
        {
            return llList2Integer(loc_freeSlotNumberList, 0);
        }
        else if (loc_item == "d")
        {
            return llList2Integer(loc_freeSlotNumberList, ((integer)-1));
        }
        else if (loc_item == "r")
        {
            return llList2Integer(llListRandomize(loc_freeSlotNumberList, 1), 0);
        }
        else if (~llListFindList(loc_freeSlotNumberList, (list)(~-(integer)loc_item)))
        {
            return ~-(integer)loc_item;
        }
        loc_parts = llDeleteSubList(loc_parts, 0, 0);
    }
    return ((integer)-1);
}

string H(string llGetObjectDetails)
{
    if (!~llSubStringIndex(llGetObjectDetails, "/@"))
    {
        return llGetObjectDetails;
    }
    string loc_returnValue = llGetObjectDetails;
    integer loc_index;
    integer loc_length = edefaultrez != [];
    for (loc_index = 0; loc_index < loc_length; loc_index = 3 + loc_index)
    {
        loc_returnValue = llDumpList2String(llParseStringKeepNulls(loc_returnValue, (list)("/@" + llList2String(edefaultrez, loc_index) + "@/"), []), llList2String(edefaultrez, -~-~loc_index));
    }
    if (!(loc_returnValue == llGetObjectDetails))
    {
        loc_returnValue = H(loc_returnValue);
    }
    return loc_returnValue;
}

string A(string llGetObjectDetails, integer llList2String, string llGetRootPosition, list llDeleteSubList, list llToLower)
{
    return llDumpList2String((list)llGetObjectDetails + llList2String + llDumpList2String(llParseStringKeepNulls(llGetRootPosition, (list)",", []), "‚") + llDumpList2String(llDeleteSubList, ",") + llList2List(llToLower + "" + "" + "" + "", 0, 3), "|");
}

integer D(string llDeleteSubList, list llGetObjectDetails)
{
    string loc_currentSlotsHash = llMD5String(llDumpList2String(LslLibrary, "^"), 0);
    if (!(loc_currentSlotsHash == UThread & llGetObjectDetails == []))
    {
        UThread = loc_currentSlotsHash;
        llMessageLinked(((integer)-1), 251, llDumpList2String((list)11 + 3 + llDumpList2String(llGetObjectDetails, ",") + LslLibrary, "^"), (key)llDeleteSubList);
        if (Pop)
        {
            llMessageLinked(((integer)-1), ((integer)-800), "", Pop);
            Pop = "";
        }
        return 1;
    }
    return 0;
}

integer F(key llGetObjectDetails, string llDeleteSubList)
{
    llDeleteSubList = llStringTrim(llDeleteSubList, 3);
    if (llDeleteSubList == "")
    {
        return 1;
    }
    list loc_permItemsOr = llParseString2List(llToLower(llDeleteSubList), (list)"~", []);
    integer loc_indexOr = ~(loc_permItemsOr != []);
    integer loc_result;
    while (++loc_indexOr & -!loc_result)
    {
        list loc_permItemsAnd = llParseString2List(llList2String(loc_permItemsOr, loc_indexOr), (list)"&", []);
        integer loc_indexAnd = ~(loc_permItemsAnd != []);
        loc_result = 1;
        while (!(!++loc_indexAnd | !loc_result))
        {
            integer loc_invert;
            string loc_item = llStringTrim(llList2String(loc_permItemsAnd, loc_indexAnd), 3);
            if (llGetSubString(loc_item, 0, 0) == "!")
            {
                loc_invert = 1;
                loc_item = llStringTrim(llDeleteSubString(loc_item, 0, 0), 3);
            }
            if (loc_item == "group")
            {
                loc_result = llSameGroup(llGetObjectDetails);
            }
            else if (loc_item == "owner")
            {
                loc_result = llGetOwner() == llGetObjectDetails;
            }
            else if (loc_item == "seated")
            {
                loc_result = !!~llListFindList(llList2ListStrided(llDeleteSubList(LslLibrary, 0, 7), 0, ((integer)-1), 11), (list)llGetObjectDetails);
            }
            else if (~llSubStringIndex(loc_item, ".empty"))
            {
                loc_result = !!~-llList2Integer(LslLibrary, 9 + (~-(integer)llGetSubString(loc_item, 0, ((integer)-7))) * 11);
            }
            else if ((string)((integer)loc_item) == loc_item)
            {
                loc_result = llList2Key(LslLibrary, 8 + (~-(integer)loc_item) * 11) == llGetObjectDetails;
            }
            else if (llGetSubString(loc_item, 0, 0) == "@")
            {
                integer loc_macroIndex = llListFindList(edefaultrez, (list)llDeleteSubString(loc_item, 0, 0) + "m");
                if (~loc_macroIndex)
                {
                    loc_result = F(llGetObjectDetails, llList2String(edefaultrez, -~-~loc_macroIndex));
                }
                else
                {
                    loc_result = 0;
                }
            }
            else
            {
                integer loc_udpIndex = llListFindList(gF, (list)loc_item);
                if (~loc_udpIndex)
                {
                    string loc_pluginPermissionType = llList2String(gF, -~loc_udpIndex);
                    if (loc_pluginPermissionType == "l")
                    {
                        loc_result = ~llSubStringIndex(llList2String(gF, -~-~loc_udpIndex), (string)llGetObjectDetails);
                    }
                    else if (loc_pluginPermissionType == "b")
                    {
                        loc_result = (integer)llList2String(gF, -~-~loc_udpIndex);
                    }
                    else
                    {
                        loc_result = 0;
                    }
                }
                else
                {
                    loc_result = 0;
                }
            }
            loc_result = !!(loc_invert & -!loc_result | -!loc_invert & loc_result);
        }
    }
    return loc_result;
}

string E(string llGetObjectDetails)
{
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)"`", []), "‵");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)"|", []), "┃");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)"/", []), "⁄");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)":", []), "꞉");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)",", []), "‚");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)"^", []), "⌃");
    llGetObjectDetails = llDumpList2String(llParseStringKeepNulls(llGetObjectDetails, (list)"=", []), "═");
    return llGetObjectDetails;
}

default
{
    state_entry()
    {
        integer loc_index;
        for (loc_index = 0; !(llGetNumberOfPrims() < loc_index); ++loc_index)
        {
            llLinkSitTarget(loc_index, <((float)0), ((float)0), 0.5>, <((float)0), ((float)0), ((float)0), ((float)1)>);
        }
        llSleep(((float)1));
        G();
    }

    link_message(integer llDeleteSubList, integer llGetObjectDetails, string llGetRootPosition, key llList2String)
    {
        if (llGetObjectDetails == 222 | llGetObjectDetails == 221 | llGetObjectDetails == 220)
        {
            list loc_allData = llParseStringKeepNulls(llGetRootPosition, (list)"%&§", []);
            llGetRootPosition = "";
            if (llGetObjectDetails == 220)
            {
                loc_allData = (list)"" + "" + "" + loc_allData;
            }
            string loc_ncName = llList2String(loc_allData, 0);
            if (loc_ncName == Library & llGetObjectDetails == 222)
            {
                llMessageLinked(((integer)-1), ((integer)-500), "PROP_DO|*|0||DIE", llList2String);
            }
            list loc_paramSet1List = llParseStringKeepNulls(llList2String(loc_allData, 1), (list)"|", []);
            string loc_path = llList2String(loc_paramSet1List, 0);
            integer loc_page = (integer)llList2String(loc_paramSet1List, 1);
            string loc_prompt = llList2String(loc_paramSet1List, 2);
            integer loc_avSeat = -~(llListFindList(LslLibrary, (list)llList2String) / 11);
            integer loc_slotsChangeDetected;
            list loc_slotsAnimChanged;
            list loc_events;
            list loc_buddy;
            loc_allData = llDeleteSubList(loc_allData, 0, 2);
            while (loc_allData != [])
            {
                list loc_paramsOriginal = llParseStringKeepNulls(llList2String(loc_allData, 0), (list)"|", []);
                string loc_data = H(llList2String(loc_allData, 0));
                loc_allData = llDeleteSubList(loc_allData, 0, 0);
                if (!(-(llGetObjectDetails == 221) & llSubStringIndex(loc_data, "MENU")))
                {
                    if (~llSubStringIndex(loc_data, "%"))
                    {
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%CARDNAME%", []), loc_ncName);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%AVKEY%", []), (string)llList2String);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%AVSEAT%", []), (string)loc_avSeat);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%PATH%", []), loc_path);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%PAGE%", []), (string)loc_page);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%DISPLAYNAME%", []), E(llGetDisplayName(llList2String)));
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%USERNAME%", []), llGetUsername(llList2String));
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%SCALECUR%", []), (string)llList2Vector(llGetLinkPrimitiveParams(1 < llGetNumberOfPrims(), (list)7), 0));
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%SCALEREF%", []), (string)gC);
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%POSITION%", []), (string)llGetRootPosition());
                        loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%ROTATION%", []), (string)llGetRootRotation());
                        integer loc_slotNumber;
                        if (~llSubStringIndex(loc_data, ".KEY%"))
                        {
                            loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)"%OWNER.KEY%", []), llGetOwner());
                            for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
                            {
                                loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)("%" + (string)(-~loc_slotNumber) + ".KEY%"), []), (string)llList2Key(LslLibrary, 8 + loc_slotNumber * 11));
                            }
                        }
                        if (~llSubStringIndex(loc_data, ".NAME%"))
                        {
                            for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
                            {
                                loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)("%" + (string)(-~loc_slotNumber) + ".NAME%"), []), llList2String(LslLibrary, 10 + loc_slotNumber * 11));
                            }
                        }
                        if (~llSubStringIndex(loc_data, ".SEATNAME%"))
                        {
                            for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
                            {
                                loc_data = llDumpList2String(llParseStringKeepNulls(loc_data, (list)("%" + (string)(-~loc_slotNumber) + ".SEATNAME%"), []), llList2String(LslLibrary, loc_slotNumber * 11));
                            }
                        }
                    }
                    list loc_params = llParseStringKeepNulls(loc_data, (list)"|", []);
                    string loc_actionWithPerms = llList2String(loc_params, 0);
                    string loc_action = loc_actionWithPerms;
                    string loc_perms;
                    list loc_temp = llParseString2List(loc_action, (list)"{" + "}", []);
                    if (1 < (loc_temp != []))
                    {
                        loc_action = llList2String(loc_temp, 0);
                        loc_perms = llToLower(llStringTrim(llList2String(loc_temp, 1), 3));
                    }
                    loc_params = llListReplaceList(loc_params, (list)loc_action, 0, 0);
                    loc_data = llDumpList2String(loc_params, "|");
                    loc_paramsOriginal = llListReplaceList(loc_paramsOriginal, (list)loc_action, 0, 0);
                    string loc_dataOriginal = llDumpList2String(loc_paramsOriginal, "|");
                    if (F(llList2String, loc_perms))
                        if (loc_action == "MENUPROMPT")
                        {
                            loc_prompt = llDumpList2String(llParseStringKeepNulls(llList2String(loc_params, 1), (list)"\\n", []), "\n");
                        }
                        else if (loc_action == "SEAT_INIT")
                        {
                            list loc_oldSitters = llList2ListStrided(llDeleteSubList(LslLibrary, 0, 7), 0, ((integer)-1), 11);
                            list loc_oldSittersType = llList2ListStrided(llDeleteSubList(LslLibrary, 0, 8), 0, ((integer)-1), 11);
                            list loc_oldSittersName = llList2ListStrided(llDeleteSubList(LslLibrary, 0, 9), 0, ((integer)-1), 11);
                            LslLibrary = [];
                            loc_slotsAnimChanged = [];
                            loc_slotsChangeDetected = 1;
                            LslUserScript = llList2Integer(loc_params, 1);
                            integer loc_slotNumber;
                            for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
                            {
                                loc_slotsAnimChanged = loc_slotsAnimChanged + loc_slotNumber;
                                LslLibrary = LslLibrary + ("Seat " + (string)(-~loc_slotNumber)) + "" + "" + <((float)0), ((float)0), ((float)0)> + <((float)0), ((float)0), ((float)0), ((float)1)> + "" + loc_ncName + loc_actionWithPerms + llList2Key(loc_oldSitters, 0) + llList2Integer(loc_oldSittersType, 0) + llList2String(loc_oldSittersName, 0);
                                loc_oldSitters = llDeleteSubList(loc_oldSitters, 0, 0);
                                loc_oldSittersType = llDeleteSubList(loc_oldSittersType, 0, 0);
                                loc_oldSittersName = llDeleteSubList(loc_oldSittersName, 0, 0);
                            }
                            B();
                            llMessageLinked(((integer)-1), 250, (string)LslUserScript, llList2String);
                            llMessageLinked(((integer)-1), ((integer)-500), "PROP_DO|*|0||DIE", llList2String);
                        }
                        else if (loc_action == "DEF")
                        {
                            string loc_targetParam = llStringTrim(llToLower(llList2String(loc_params, 1)), 3);
                            list loc_myParams = llDeleteSubList(loc_params, 0, 1);
                            integer loc_offset;
                            string loc_dataType = "s";
                            if (loc_targetParam == "seatname")
                            {
                                loc_offset = 0;
                            }
                            else if (loc_targetParam == "seatperm")
                            {
                                loc_offset = 1;
                            }
                            else if (loc_targetParam == "animname")
                            {
                                loc_offset = 2;
                            }
                            else if (loc_targetParam == "animpos")
                            {
                                loc_offset = 3;
                                loc_dataType = "v";
                            }
                            else if (loc_targetParam == "animrot")
                            {
                                loc_offset = 4;
                                loc_dataType = "r";
                            }
                            else if (loc_targetParam == "animfacials")
                            {
                                loc_offset = 5;
                            }
                            else if (loc_targetParam == "animncname")
                            {
                                loc_offset = 6;
                            }
                            else if (loc_targetParam == "animcommand")
                            {
                                loc_offset = 7;
                            }
                            else if (loc_targetParam == "sitterkey")
                            {
                                loc_offset = 8;
                                loc_dataType = "k";
                            }
                            else if (loc_targetParam == "sittertype")
                            {
                                loc_offset = 9;
                                loc_dataType = "i";
                            }
                            else if (loc_targetParam == "sittername")
                            {
                                loc_offset = 10;
                            }
                            else
                            {
                                loc_myParams = [];
                            }
                            while (loc_myParams != [])
                            {
                                string loc_item = llList2String(loc_myParams, 0);
                                loc_myParams = llDeleteSubList(loc_myParams, 0, 0);
                                list loc_itemParts = llParseStringKeepNulls(loc_item, (list)"=", []);
                                string loc_targetSeatsString = llStringTrim(llList2String(loc_itemParts, 0), 3);
                                string loc_targetValueString = llList2String(loc_itemParts, 1);
                                list loc_targetValueList = (list)loc_targetValueString;
                                if (loc_dataType == "v")
                                {
                                    loc_targetValueList = (list)((vector)loc_targetValueString);
                                }
                                else if (loc_dataType == "r")
                                {
                                    loc_targetValueList = (list)((rotation)loc_targetValueString);
                                }
                                else if (loc_dataType == "k")
                                {
                                    loc_targetValueList = (list)((key)loc_targetValueString);
                                }
                                else if (loc_dataType == "i")
                                {
                                    loc_targetValueList = (list)((integer)loc_targetValueString);
                                }
                                list loc_targetSeats = llParseString2List(loc_targetSeatsString, (list)"/", []);
                                integer loc_slotNumber;
                                if (loc_targetSeatsString == "*")
                                {
                                    loc_targetSeats = [];
                                    for (loc_slotNumber = 0; loc_slotNumber < LslUserScript; ++loc_slotNumber)
                                    {
                                        loc_targetSeats = loc_targetSeats + -~loc_slotNumber;
                                    }
                                }
                                while (loc_targetSeats != [])
                                {
                                    loc_slotNumber = ~-(integer)llList2String(loc_targetSeats, 0);
                                    loc_targetSeats = llDeleteSubList(loc_targetSeats, 0, 0);
                                    if (((integer)-1) < loc_slotNumber & loc_slotNumber < LslUserScript)
                                    {
                                        LslLibrary = llListReplaceList(LslLibrary, loc_targetValueList, loc_slotNumber * 11 + loc_offset, loc_slotNumber * 11 + loc_offset);
                                        loc_slotsChangeDetected = 1;
                                    }
                                }
                            }
                        }
                        else if (loc_action == "XANIM")
                        {
                            llMessageLinked(((integer)-1), ((integer)-500), "PROP_DO|*|0||DIE", llList2String);
                            integer loc_slotNumber = ~-(integer)llList2String(loc_params, 1);
                            if (((integer)-1) < loc_slotNumber & loc_slotNumber < LslUserScript)
                            {
                                loc_events = (list)("ON_SIT|" + (string)(-~loc_slotNumber)) + ("ON_UNSIT|" + (string)(-~loc_slotNumber)) + loc_events;
                                LslLibrary = llListReplaceList(LslLibrary, (list)loc_ncName + loc_actionWithPerms, 6 + loc_slotNumber * 11, 7 + loc_slotNumber * 11);
                                integer loc_index;
                                for (loc_index = 2; loc_index < 6; ++loc_index)
                                {
                                    if (loc_index ^ 2)
                                        if (loc_index ^ 3)
                                            if (loc_index ^ 4)
                                            {
                                                if (loc_index == 5)
                                                {
                                                    LslLibrary = llListReplaceList(LslLibrary, (list)llList2String(loc_params, loc_index), 5 + loc_slotNumber * 11, 5 + loc_slotNumber * 11);
                                                }
                                            }
                                            else
                                            {
                                                LslLibrary = llListReplaceList(LslLibrary, (list)llEuler2Rot((vector)llList2String(loc_params, loc_index) * 0.017453292), 4 + loc_slotNumber * 11, 4 + loc_slotNumber * 11);
                                            }
                                        else
                                        {
                                            LslLibrary = llListReplaceList(LslLibrary, (list)((vector)llList2String(loc_params, loc_index)), 3 + loc_slotNumber * 11, 3 + loc_slotNumber * 11);
                                        }
                                    else
                                    {
                                        LslLibrary = llListReplaceList(LslLibrary, (list)llList2String(loc_params, loc_index), -~-~(loc_slotNumber * 11), -~-~(loc_slotNumber * 11));
                                    }
                                }
                                loc_slotsChangeDetected = 1;
                                loc_index = llListFindList(loc_slotsAnimChanged, (list)loc_slotNumber);
                                if (!~loc_index)
                                {
                                    loc_slotsAnimChanged = loc_slotsAnimChanged + loc_slotNumber;
                                }
                            }
                        }
                        else if (loc_action == "UNSIT")
                        {
                            string loc_myParam = llToLower(llStringTrim(llList2String(loc_params, 1), 3));
                            list loc_avatarKeyOrSeatNumbers;
                            if (loc_myParam == "*" | loc_myParam == "others")
                            {
                                integer loc_seatNumber;
                                for (loc_seatNumber = LslUserScript; 0 < loc_seatNumber; --loc_seatNumber)
                                {
                                    if (loc_myParam == "*" | loc_seatNumber ^ loc_avSeat)
                                    {
                                        loc_avatarKeyOrSeatNumbers = loc_avatarKeyOrSeatNumbers + loc_seatNumber;
                                    }
                                }
                            }
                            else
                            {
                                loc_avatarKeyOrSeatNumbers = llCSV2List(loc_myParam);
                            }
                            while (loc_avatarKeyOrSeatNumbers != [])
                            {
                                string loc_avatar = llList2String(loc_avatarKeyOrSeatNumbers, 0);
                                loc_avatarKeyOrSeatNumbers = llDeleteSubList(loc_avatarKeyOrSeatNumbers, 0, 0);
                                key loc_avatarKey = (key)loc_avatar;
                                if ((string)((integer)loc_avatar) == loc_avatar)
                                {
                                    integer loc_slotNumber = ~-(integer)loc_avatar;
                                    if (((integer)-1) < loc_slotNumber & loc_slotNumber < LslUserScript)
                                    {
                                        integer loc_sitterType = llList2Integer(LslLibrary, 9 + loc_slotNumber * 11);
                                        if (loc_sitterType ^ 1)
                                        {
                                            if (loc_sitterType)
                                            {
                                                LslLibrary = llListReplaceList(LslLibrary, (list)"" + 0 + "", 8 + loc_slotNumber * 11, 10 + loc_slotNumber * 11);
                                                loc_slotsChangeDetected = 1;
                                            }
                                        }
                                        else
                                        {
                                            loc_avatarKey = llList2Key(LslLibrary, 8 + loc_slotNumber * 11);
                                        }
                                    }
                                }
                                if (loc_avatarKey)
                                {
                                    integer loc_index = llGetNumberOfPrims();
                                    integer loc_found;
                                    while (!(loc_index < 1 | loc_found | llGetAgentSize(llGetLinkKey(loc_index)) == <((float)0), ((float)0), ((float)0)>))
                                    {
                                        loc_found = llGetLinkKey(loc_index--) == loc_avatarKey;
                                    }
                                    if (loc_found)
                                    {
                                        llUnSit(loc_avatarKey);
                                    }
                                }
                            }
                        }
                        else if (loc_action == "SWAP")
                        {
                            list loc_SeatNumbers = llCSV2List(llList2String(loc_params, 1));
                            integer loc_seatNumber1 = (integer)llList2String(loc_SeatNumbers, 0);
                            integer loc_seatNumber2 = (integer)llList2String(loc_SeatNumbers, 1);
                            if (!(!(0 < loc_seatNumber1 & 0 < loc_seatNumber2) | LslUserScript < loc_seatNumber1 | LslUserScript < loc_seatNumber2))
                            {
                                loc_slotsChangeDetected = 1;
                                integer loc_index1 = (~-loc_seatNumber1) * 11;
                                integer loc_index2 = (~-loc_seatNumber2) * 11;
                                LslLibrary = llListReplaceList(llListReplaceList(LslLibrary, llList2List(LslLibrary, 8 + loc_index2, 10 + loc_index2), 8 + loc_index1, 10 + loc_index1), llList2List(LslLibrary, 8 + loc_index1, 10 + loc_index1), 8 + loc_index2, 10 + loc_index2);
                            }
                            C();
                        }
                        else if (loc_action == "PAUSE")
                        {
                            llSleep((float)llList2String(loc_params, 1));
                        }
                        else if (loc_action == "LINKMSG")
                        {
                            llMessageLinked(((integer)-1), (integer)llList2String(loc_params, 1), llList2String(loc_params, 2), (key)llList2String(loc_params, 3));
                        }
                        else if (llSubStringIndex(loc_action, "ON_"))
                            if (loc_action == "PLUGINMENU")
                            {
                                llMessageLinked(((integer)-1), ((integer)-810), llDumpList2String(llListReplaceList(loc_params, (list)loc_path, 0, 0), "|"), "");
                            }
                            else if (loc_action == "PROPDIE")
                            {
                                llMessageLinked(((integer)-1), ((integer)-500), "PROP_DO" + ("|" + (llList2String(loc_params, 1) + ("|" + (llList2String(loc_params, 2) + ("|" + ("|" + "DIE")))))), llList2String);
                            }
                            else if (loc_action == "PROP" | loc_action == "PROP_DO" | loc_action == "PROP_DO_ALL" | loc_action == "PARENT_DO" | loc_action == "PARENT_DO_ALL" | loc_action == "DIE" | loc_action == "TEMPATTACH" | loc_action == "ATTACH" | loc_action == "POS" | loc_action == "ROT")
                            {
                                llMessageLinked(((integer)-1), ((integer)-500), loc_data, llList2String);
                            }
                            else if (loc_action == "OPTION" | loc_action == "OPTIONS" | loc_action == "MACRO" | loc_action == "UDPBOOL" | loc_action == "UDPLIST")
                            {
                                integer loc_newNum = ((integer)-240);
                                llMessageLinked(((integer)-1), loc_newNum, llDumpList2String(llDeleteSubList(loc_params, 0, 0), "|"), llList2String);
                                integer loc_paramsLength = loc_params != [];
                                integer loc_index;
                                for (loc_index = 1; loc_index < loc_paramsLength; ++loc_index)
                                {
                                    list loc_optionsItems = llParseString2List(llList2String(loc_params, loc_index), (list)"=", []);
                                    string loc_optionItem = llToLower(llStringTrim(llList2String(loc_optionsItems, 0), 3));
                                    integer loc_operationType = (llGetSubString(loc_optionItem, ((integer)-1), ((integer)-1)) == "+") + 2 * (llGetSubString(loc_optionItem, ((integer)-1), ((integer)-1)) == "-");
                                    if (loc_operationType)
                                    {
                                        loc_optionItem = llStringTrim(llDeleteSubString(loc_optionItem, ((integer)-1), ((integer)-1)), 3);
                                    }
                                    string loc_optionString = llList2String(loc_optionsItems, 1);
                                    string loc_optionSetting = llToLower(llStringTrim(loc_optionString, 3));
                                    integer loc_optionSettingFlag = !!(loc_optionSetting == "on" | (integer)loc_optionSetting);
                                    if (loc_action == "MACRO")
                                    {
                                        integer loc_macroIndex = llListFindList(edefaultrez, (list)loc_optionItem + "m");
                                        if (~loc_macroIndex)
                                        {
                                            edefaultrez = llDeleteSubList(edefaultrez, loc_macroIndex, -~-~loc_macroIndex);
                                        }
                                        edefaultrez = edefaultrez + loc_optionItem + "m" + loc_optionString;
                                    }
                                    else if (loc_action == "UDPBOOL" | loc_action == "UDPLIST")
                                    {
                                        integer loc_udpIndex = llListFindList(gF, (list)loc_optionItem);
                                        string loc_oldValue;
                                        if (~loc_udpIndex)
                                        {
                                            loc_oldValue = llList2String(gF, -~-~loc_udpIndex);
                                            gF = llDeleteSubList(gF, loc_udpIndex, -~-~loc_udpIndex);
                                        }
                                        if (loc_action == "UDPLIST")
                                        {
                                            string loc_newValue = loc_optionString;
                                            if (loc_operationType)
                                            {
                                                loc_newValue = (string)llParseStringKeepNulls(loc_oldValue, (list)loc_optionString, []);
                                                if (!~-loc_operationType)
                                                {
                                                    loc_newValue = loc_newValue + loc_optionString;
                                                }
                                            }
                                            gF = gF + loc_optionItem + "l" + loc_newValue;
                                        }
                                        else if (loc_action == "UDPBOOL")
                                        {
                                            integer loc_newValue = loc_optionSettingFlag;
                                            if (loc_optionSetting == "!")
                                            {
                                                loc_newValue = !(integer)loc_oldValue;
                                            }
                                            gF = gF + loc_optionItem + "b" + loc_newValue;
                                        }
                                    }
                                    else if (loc_action == "OPTIONS" | loc_action == "OPTION")
                                    {
                                        if (loc_optionItem == "menuonsit")
                                        {
                                            gB = loc_optionSettingFlag;
                                        }
                                        else if (loc_optionItem == "2default")
                                        {
                                            ResumeVoid = loc_optionSettingFlag;
                                        }
                                        else if (loc_optionItem == "scaleref")
                                        {
                                            gC = (vector)loc_optionString;
                                        }
                                        else if (loc_optionItem == "seatassignlist")
                                        {
                                            UThreadStackFrame = loc_optionSetting;
                                        }
                                        else if (loc_optionItem == "usedisplaynames")
                                        {
                                            gG = loc_optionSettingFlag;
                                        }
                                    }
                                }
                                if (loc_action == "MACRO")
                                {
                                    llMessageLinked(((integer)-1), ((integer)-809), llDumpList2String(edefaultrez, "|"), llList2String);
                                }
                                else if (loc_action == "UDPBOOL" | loc_action == "UDPLIST")
                                {
                                    llMessageLinked(((integer)-1), ((integer)-808), llDumpList2String(gF, "|"), llList2String);
                                }
                            }
                            else if (llSubStringIndex(loc_action, "BUDDY_ON_"))
                                if (llSubStringIndex(loc_action, "BUDDY"))
                                {
                                    integer loc_index = llListFindList(gD + IsRestoring, (list)loc_action);
                                    if (~loc_index)
                                    {
                                        integer loc_newNum = llList2Integer(gD + IsRestoring, -~loc_index);
                                        string loc_newStr = llDumpList2String(llDeleteSubList(loc_params, 0, 0), "|");
                                        if (llList2Integer(gD + IsRestoring, -~-~loc_index))
                                        {
                                            loc_newStr = llDumpList2String(llDeleteSubList(loc_paramsOriginal, 0, 0), "|");
                                        }
                                        llMessageLinked(((integer)-1), loc_newNum, loc_newStr, llList2String);
                                    }
                                    else
                                    {
                                        llMessageLinked(((integer)-1), 311, loc_data, llList2String);
                                    }
                                }
                                else
                                {
                                    loc_buddy = loc_buddy + loc_data;
                                }
                            else
                            {
                                loc_buddy = loc_buddy + loc_dataOriginal;
                            }
                        else
                        {
                            loc_events = loc_events + loc_dataOriginal;
                        }
                }
            }
            if (loc_events != [])
            {
                llMessageLinked(((integer)-1), ((integer)-520), llDumpList2String(loc_events, "%&§"), llList2String);
            }
            if (loc_buddy != [])
            {
                llMessageLinked(((integer)-1), ((integer)-510), llDumpList2String(loc_buddy, "%&§"), llList2String);
            }
            if (loc_slotsChangeDetected)
            {
                if (loc_slotsChangeDetected = D(loc_ncName, loc_slotsAnimChanged))
                {
                    if (llGetInventoryType(loc_ncName) == 7)
                    {
                        gE = loc_ncName;
                        edefaultchanged = llGetInventoryKey(gE);
                        IsSaveDue = llList2String;
                    }
                }
            }
            if (!(loc_slotsChangeDetected | loc_buddy == []))
            {
                llMessageLinked(((integer)-1), ((integer)-511), "", "");
            }
            if (!(loc_path == ""))
            {
                string loc_paramSet1 = A(loc_path, loc_page, loc_prompt, (list)llList2String(loc_paramSet1List, 3), llList2List(loc_paramSet1List, 4, 7));
                if (llGetObjectDetails ^ 221)
                {
                    if (llGetObjectDetails == 222)
                    {
                        llMessageLinked(((integer)-1), ((integer)-820), loc_paramSet1, llList2String);
                    }
                }
                else
                {
                    llMessageLinked(((integer)-1), ((integer)-815), loc_paramSet1, llList2String);
                }
            }
        }
        else if (llGetObjectDetails ^ ((integer)-831))
            if (llGetObjectDetails ^ edefaultlink_message)
                if (llGetObjectDetails == edefaultstate_entry | llGetObjectDetails == 309)
                {
                    if (!~llSubStringIndex(llGetRootPosition, ","))
                    {
                        llGetRootPosition = llList2CSV(llDeleteSubList(llParseStringKeepNulls(llGetRootPosition, (list)"|", []), 2, 2));
                    }
                    list loc_parts = llParseString2List(llGetRootPosition, (list)"|", []);
                    while (loc_parts != [])
                    {
                        list loc_subParts = llCSV2List(llList2String(loc_parts, 0));
                        loc_parts = llDeleteSubList(loc_parts, 0, 0);
                        string loc_action = llList2String(loc_subParts, 0);
                        integer loc_index = llListFindList(gD, (list)loc_action);
                        if (-(llGetObjectDetails == edefaultstate_entry) & ~loc_index)
                        {
                            gD = llDeleteSubList(gD, loc_index, ~-(3 + loc_index));
                        }
                        if (!(-!(llGetObjectDetails == edefaultstate_entry) & ~loc_index))
                        {
                            gD = gD + loc_action + (integer)llList2String(loc_subParts, 1) + (integer)llList2String(loc_subParts, 2);
                        }
                    }
                }
                else if (llGetObjectDetails ^ ((integer)-902))
                {
                    if (llGetObjectDetails == 34334)
                    {
                        llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
                        llSay(0, "running script time for all scripts in this nPose object are consuming " + (string)(llList2Float(llGetObjectDetails(llGetKey(), (list)12), 0) * ((float)1000)) + " ms of cpu time");
                    }
                }
                else
                {
                    if (ResumeVoid & -(llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims()) & -!(Library == ""))
                    {
                        llMessageLinked(((integer)-1), gH, Library, "00000000-0000-0000-0000-000000000000");
                    }
                }
            else
            {
                Library = llGetRootPosition;
                llMessageLinked(((integer)-1), gH, Library, llList2String);
            }
        else
        {
            llMessageLinked(((integer)-1), ((integer)-821), llGetRootPosition, llList2String);
        }
    }

    changed(integer llGetObjectDetails)
    {
        if (llGetObjectDetails & 1)
        {
            llSleep(0.5);
            if (llGetInventoryType(gE) ^ 7)
            {
                G();
            }
            else
            {
                if (edefaultchanged == llGetInventoryKey(gE))
                {
                    G();
                }
                else
                {
                    llMessageLinked(((integer)-1), gH, gE, IsSaveDue);
                }
            }
        }
        if (llGetObjectDetails & 32)
        {
            if (B())
            {
                D(gE, []);
            }
            if (ResumeVoid & -(llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims()) & -!(Library == ""))
            {
                llMessageLinked(((integer)-1), gH, Library, "00000000-0000-0000-0000-000000000000");
            }
        }
    }

    on_rez(integer llGetObjectDetails)
    {
        llResetScript();
    }
}
