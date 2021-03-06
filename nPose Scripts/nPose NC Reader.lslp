// The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:
//
// The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
//   - If you distribute the nPose scripts, you must leave them full perms.
//    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.
//
// "Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
//
// Documentation:
// https://github.com/nPoseTeam/nPose-V3/wiki
// Report Bugs to:
// https://github.com/nPoseTeam/nPose-V3/issues
// or sent an IM to: slmember1 Resident (Leona)
//
// Have fun
// Leona

integer MEMORY_TO_BE_USED_SL=60000;
integer MEMORY_TO_BE_USED_IW=120000;
integer CARDS_TO_BE_USED=50;

string NC_READER_CONTENT_SEPARATOR="%&§";

integer DOPOSE=200;
integer PREPARE_MENU_STEP3_READER=221;
integer DOPOSE_READER=222;
integer NC_READER_REQUEST=224;
integer NC_READER_RESPONSE=225;
integer MEM_USAGE=34334;

integer PREPARE_MENU_STEP3=-822;

list CacheNcNames;
list CacheContent;
//the cache lists contains only fully read (valid) content

list NcReadStackNcNames;
list NcReadStack;
//this is the working list, it contains partly read content
integer NC_READ_STACK_LINE_ID=0;
integer NC_READ_STACK_CURRENT_LINE=1;
integer NC_READ_STACK_CONTENT=2;
integer NC_READ_STACK_STRIDE=3;

list ResponseStack;
//this is used to ensure that the requests are served in the right order
integer RESPONSE_STACK_NC_NAME=0;
integer RESPONSE_STACK_MENU_NAME=1;
integer RESPONSE_STACK_PLACEHOLDER=2;
integer RESPONSE_STACK_AVATAR_KEY=3;
integer RESPONSE_STACK_TYPE=4;
integer RESPONSE_STACK_STRIDE=5;

integer CacheMiss; //only used for statistical data
integer Requests; //only used for statistical data

integer GridType;
integer GRID_TYPE_OTHER=0; 
integer GRID_TYPE_SL=1; //Second Life
integer GRID_TYPE_IW=2; //InWorldz
integer GRID_TYPE_DW=4; //DigiWorldz
string GRID_TYPE_SL_STRING="Second Life Server";
string GRID_TYPE_IW_STRING="Halcyon Server";
string GRID_TYPE_DW_STRING="OpenSim";

checkMemory() {
    //if memory is low, discard the oldest cache entry
    if((GridType && GRID_TYPE_SL) || (GridType && GRID_TYPE_IW)) {
        integer memoryToBeUsed=MEMORY_TO_BE_USED_SL;
        if(GridType && GRID_TYPE_IW) {
            memoryToBeUsed=MEMORY_TO_BE_USED_IW;
        }
        while(llGetUsedMemory()>memoryToBeUsed) {
            CacheNcNames=llDeleteSubList(CacheNcNames, 0, 0);
            CacheContent=llDeleteSubList(CacheContent, 0, 0);
        }
    }
    else {
        //in OpenSimulator we are not able to detect the current used memory
        integer numberOfCards=llGetListLength(CacheNcNames);
        if(numberOfCards>CARDS_TO_BE_USED) {
            CacheNcNames=llDeleteSubList(CacheNcNames, 0, numberOfCards - CARDS_TO_BE_USED - 1);
            CacheContent=llDeleteSubList(CacheContent, 0, numberOfCards - CARDS_TO_BE_USED - 1);
        }
    }
}

//pragma inline
//debug(list message) {
//    llOwnerSay(llGetScriptName() + "\n#>" + llDumpList2String(message, "\n#>"));
//}

fetchNcContent(string str, key id, integer type) {
    //we can also use the expanded DOPOSE/DOBUTTON format:
    //str (separated by NC_READER_CONTENT_SEPARATOR): cardname, userDefinedData1, userDefinedData1
    list parts=llParseStringKeepNulls(str, [NC_READER_CONTENT_SEPARATOR], []);
    string ncName=llList2String(parts, 0);
    string param1=llList2String(parts, 1);
    string param2=llList2String(parts, 2);
    if(llGetInventoryType(ncName) == INVENTORY_NOTECARD) {
        Requests++;
        ResponseStack+=[ncName, param1, param2, id, type];
        processResponseStack();
        checkMemory();
    }
    else {
        llMessageLinked(LINK_SET, type, str, id);
    }
}

processResponseStack() {
    do{
        if(!llGetListLength(ResponseStack)) {
            //there are no pending Requests: nothing to do
            return;
        }
        string ncName=llList2String(ResponseStack, RESPONSE_STACK_NC_NAME);
        if(~llListFindList(NcReadStackNcNames, [ncName])) {
            // the reader is running, we cant do anything
            return;
        }
        integer index=llListFindList(CacheNcNames, [ncName]);
        if(~index) {
            //The data is in the cache (and therefore valid and fully read) .. send the response
            //data Format:
            //str (separated by the NC_READER_CONTENT_SEPARATOR: ncName, userDefinedData1, userDefinedData1, content
            llMessageLinked(
                LINK_SET,
                llList2Integer(ResponseStack, RESPONSE_STACK_TYPE),
                llDumpList2String(llList2List(ResponseStack, 0, 2), NC_READER_CONTENT_SEPARATOR) + llList2String(CacheContent, index),
                llList2Key(ResponseStack, RESPONSE_STACK_AVATAR_KEY)
            );
            //we serverd the response, so we can delete it from the stack and check if there is more to do
            ResponseStack=llDeleteSubList(ResponseStack, 0, RESPONSE_STACK_STRIDE - 1);
            //sort it to the end to keep it for a longer time
            CacheNcNames=llDeleteSubList(CacheNcNames, index, index) + llList2List(CacheNcNames, index, index);
            CacheContent=llDeleteSubList(CacheContent, index, index) + llList2List(CacheContent, index, index);
        }
        else {
            //we need to start the reader
            //sanity: check the presense of the nc once more. It should be almost impossible that the NC is deleted meanwhile, because
            //if it is deleted, all the lists (esp. the ResponseStack) is also deleted in the changed event and we should not be here
            if(llGetInventoryType(ncName) == INVENTORY_NOTECARD) {
                CacheMiss++;
                NcReadStackNcNames+=[ncName];
                NcReadStack+=[llGetNotecardLine(ncName, 0), 0, ""];
                return;
            }
            else {
                //we should remove this entry from the response stack, even if we expect all the lists to be deleted in the expected changed event
                ResponseStack=llDeleteSubList(ResponseStack, 0, RESPONSE_STACK_STRIDE - 1);
            }
        }
    }
    while(TRUE);
}

default {
    state_entry() {
        string simChannel=llGetEnv("sim_channel");
        GridType=
            GRID_TYPE_SL * (simChannel==GRID_TYPE_SL_STRING) + 
            GRID_TYPE_DW * (simChannel==GRID_TYPE_DW_STRING) + 
            GRID_TYPE_IW * (simChannel==GRID_TYPE_IW_STRING)
        ;
    }
    link_message(integer sender, integer num, string str, key id) {
        if(num==DOPOSE) {
            //str (separated by NC_READER_CONTENT_SEPARATOR): ncName, userDefinedData1, userDefinedData1
            //id: userDefinedKey
            fetchNcContent(str, id, DOPOSE_READER);
        }
        else if(num==PREPARE_MENU_STEP3) {
            //str (separated by NC_READER_CONTENT_SEPARATOR): ncName, userDefinedData1, userDefinedData1
            //id: userDefinedKey
            fetchNcContent(str, id, PREPARE_MENU_STEP3_READER);
        }
        else if(num==NC_READER_REQUEST) {
            //str (separated by NC_READER_CONTENT_SEPARATOR): ncName, userDefinedData1, userDefinedData2
            //id: userDefinedKey
            fetchNcContent(str, id, NC_READER_RESPONSE);
        }
        else if (num == MEM_USAGE){
            float hitRate;
            if(Requests) {
                hitRate=100.0 - (float)CacheMiss / (float)Requests * 100.0;
            }
            llSay(0,
                "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + 
                " of " + (string)llGetMemoryLimit() + 
                ", Leaving " + (string)llGetFreeMemory() + " memory free.\nWe served " +
                (string)Requests + " requests with a cache hit rate of " + 
                (string)llRound(hitRate) + "%." + 
                "\nGridType: " + (string)GridType + 
                "\n" + (string)llGetListLength(CacheNcNames) + " cards cached."
            );
        }
    }
    dataserver(key queryid, string data) {
        integer ncReadStackIndex=llListFindList(NcReadStack, [queryid]);
        if(~ncReadStackIndex) {
            //its for us
            string ncName=llList2String(NcReadStackNcNames, ncReadStackIndex);
            //do a sanity check: If the NC is deleted from the prims inventory while we read it, it may/will happen that the
            //dataserver event from the last line reading will trigger BEFORE the changed event. This will lead to a
            //shout on debug channel
            if(llGetInventoryType(ncName) != INVENTORY_NOTECARD) {
                //there should be a changed event inside the eventqueue, but nevertheless we clean up the stuff
                CacheNcNames=[];
                CacheContent=[];
                NcReadStackNcNames=[];
                NcReadStack=[];
                ResponseStack=[];
                return;
            }
            checkMemory();
            if(data==EOF) {
                //move the stuff to the cache and process the response stack
                CacheNcNames+=ncName;
                CacheContent+=llList2String(NcReadStack, ncReadStackIndex + NC_READ_STACK_CONTENT);
                NcReadStackNcNames=llDeleteSubList(NcReadStackNcNames, ncReadStackIndex, ncReadStackIndex);
                NcReadStack=llDeleteSubList(NcReadStack, ncReadStackIndex, ncReadStackIndex + NC_READ_STACK_STRIDE - 1);
                processResponseStack();
            }
            else {
                data=llStringTrim(data, STRING_TRIM);
                if(!llSubStringIndex(data, "#")) {
                    //ignore comments
                    data="";
                }
                if(data) {
                    data=NC_READER_CONTENT_SEPARATOR + data;
                }
                integer nextLine=llList2Integer(NcReadStack, ncReadStackIndex + NC_READ_STACK_CURRENT_LINE) + 1;
                NcReadStack=llListReplaceList(NcReadStack, [
                    llGetNotecardLine(ncName, nextLine),
                    nextLine,
                    llList2String(NcReadStack, ncReadStackIndex + NC_READ_STACK_CONTENT) + data
                ], ncReadStackIndex, ncReadStackIndex + NC_READ_STACK_STRIDE -1);
            }
        } 
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            CacheNcNames=[];
            CacheContent=[];
            NcReadStackNcNames=[];
            NcReadStack=[];
            ResponseStack=[];
        }
    }
}
