float TIMEOUT = 0.1;

vector TEXT_COLOR=<0.0, 1.0, 0.0>;
float TEXT_ALPHA=1.0;

string DefaultPose="nPose Adjuster Default Pose"; //Prio 0 looping Animation with all bones loc/rot/scale set to 0

//The plain Adjuster consits of 1 Prim (Linknumber 0)
//Animesh Adjusters consists of more than one Prim and each prim can be an Animesh object
integer ActiveAnimeshLinkNumber=2;
float ANIMESH_ALPHA_FOR_INACTIVE_ANIMESH=0.0;
float ANIMESH_ALPHA_FOR_OCCUPIED_SEATS=0.0;
float ANIMESH_ALPHA_FOR_UNOCCUPIED_SEATS=1.0;

integer AdjusterChannel;

key MyParentId;

integer MySlotNumber=-1;
integer MyAdjustRefRoot;
integer MyQuietAdjusters;
string MySeatName;
string MyAnimations;
vector MyInitialNcPosition;
rotation MyInitialNcRotation;
string MyNcName;
integer MySitterType;

integer SITTER_TYPE_NONE=0;
integer SITTER_TYPE_AVATAR=1;
integer SITTER_TYPE_BUDDY=2;

vector MyCurrentGlobalPosition;
rotation MyCurrentGlobalRotation;
vector MyCurrentNcPosition;
rotation MyCurrentNcRotation;

list AnimationsToStart;
list AnimationsToLoad;

integer IsAnimeshAdjuster;

//dimensions
//vector ANIMESH_PELVIS_CENTER_OFFSET=<0.0, 0.0, -0.22511>;
//vector ANIMESH_SIZE=<1.0, 1.0, 1.86477>;

vector ParentPos;
rotation ParentRot;
vector ParentRootPos;
rotation ParentRootRot;


// JSON Message Format:
//    [
//         [cmd, param, param ...]
//        ...
//    ]
// the command has a 2 letter prefix: first letter is the source and the second letter is the destination
// usually SA_ (Slave->Adjuster) or AS_ (Adjuster->Slave)


debug(list message){
    llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

setAlpha() {
    if(IsAnimeshAdjuster) {
        float activeAlpha=ANIMESH_ALPHA_FOR_UNOCCUPIED_SEATS;
        if(MySitterType==SITTER_TYPE_AVATAR) {
            activeAlpha=ANIMESH_ALPHA_FOR_OCCUPIED_SEATS;
        }
        integer index;
        integer length=llGetNumberOfPrims();
        for(index=2; index<=length; index++) {
            if(index==ActiveAnimeshLinkNumber) {
                llSetLinkAlpha(index, activeAlpha, ALL_SIDES);
            }
            else {
                llSetLinkAlpha(index, ANIMESH_ALPHA_FOR_INACTIVE_ANIMESH, ALL_SIDES);
            }
        }
    }
}

stopAllAnimations() {
    list runningAnimations=llGetObjectAnimationNames();
    integer length=llGetListLength(runningAnimations);
    integer index;
    integer defaultPoseRunning;
    for(index=0; index<length; index++) {
        string animation=llList2String(runningAnimations, index);
        if(animation==DefaultPose) {
            defaultPoseRunning=TRUE;
        }
        else {
            llStopObjectAnimation(animation);
        }
    }
    if(!defaultPoseRunning) {
        llStartObjectAnimation(DefaultPose);
    }
}

startAnimations() {
    while(llGetListLength(AnimationsToStart)) {
        string animation=llList2String(AnimationsToStart, 0);
        AnimationsToStart=llDeleteSubList(AnimationsToStart, 0, 0);
        if(llGetInventoryType(animation)==INVENTORY_ANIMATION) {
            llStartObjectAnimation(animation);
        }
    }
}

getParentPos() {
    //get the information about the parent and the root of the parent
    list temp=llGetObjectDetails(MyParentId, [OBJECT_POS, OBJECT_ROT, OBJECT_ROOT]);
    ParentPos=llList2Vector(temp, 0);
    ParentRot=llList2Rot(temp, 1);
    key parentRootId=llList2Key(temp, 2);
    temp=llGetObjectDetails(parentRootId, [OBJECT_POS, OBJECT_ROT]);
    ParentRootPos=llList2Vector(temp, 0);
    ParentRootRot=llList2Rot(temp, 1);
}

setText() {
    string text="Seat" + (string)(MySlotNumber+1) + " (" + MySeatName + ")"
        + "\n" + MyNcName
        + "\n" + MyAnimations
    ;
    //Text output
    llSetText(text, TEXT_COLOR, TEXT_ALPHA);
}

string addCommand(string commands, list commandWithParamList) {
    if(commands=="") {
        return llList2Json(JSON_ARRAY, [llList2Json(JSON_ARRAY, commandWithParamList)]);
    }
    else {
        return llList2Json(JSON_ARRAY, llJson2List(commands) + [llList2Json(JSON_ARRAY, commandWithParamList)]);
    }
}

string vectorToString(vector value, integer precision) {
    return
         "<" +
        floatToString(value.x, precision) + 
        ", " +
        floatToString(value.y, precision) + 
        ", " +
        floatToString(value.z, precision) + 
        ">"
    ;
}

string floatToString(float value,  integer precision) {
    // precision: number of decimal places
    // return (string)value;
    string valueString=(string)((float)llRound(value*llPow(10,precision))/llPow(10,precision));
    string char;
    do {
        char=llGetSubString(valueString, -1, -1);
        if(char=="." || char=="0") {
            valueString=llDeleteSubString(valueString, -1, -1);
        }
    } while (char=="0");
    return valueString;
}

default {
    on_rez(integer param) {
        llSetTimerEvent(0.0);
        llSetText("", ZERO_VECTOR, 0.0);
        IsAnimeshAdjuster=llGetLinkNumber(); //a plain adjuster has only 1 prim, an animesh adjuster is a linkset of 2 prims
        ActiveAnimeshLinkNumber=2;
        MyParentId=llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        AdjusterChannel=(integer)("0x7F" + llGetSubString((string)MyParentId, 1, 6));
        llListen(AdjusterChannel, "", "", "");
        llRegionSayTo(MyParentId, AdjusterChannel, addCommand("", ["AS_UPDATE_REQUEST"]));
        getParentPos();
    }

    touch_start(integer total_number) {
        ActiveAnimeshLinkNumber++;
        if(ActiveAnimeshLinkNumber>llGetNumberOfPrims()) {
            ActiveAnimeshLinkNumber=2;
        }
        setAlpha();
    }

    listen(integer channel, string name, key id, string message) {
        if(MyParentId==id) {
            if(llJsonValueType(message, [])==JSON_ARRAY) {
                list commandLines=llJson2List(message);
                while(llGetListLength(commandLines)) {
                    list commandParts=llJson2List(llList2String(commandLines, 0));
                    commandLines=llDeleteSubList(commandLines, 0, 0);
                    string cmd=llList2String(commandParts, 0);
                    if(cmd=="SA_UPDATE") {
                        llSetTimerEvent(TIMEOUT);
                        integer setNewPosition;

                        if(MySlotNumber!=(integer)llList2String(commandParts, 1)) {
                            MySlotNumber=(integer)llList2String(commandParts, 1);
                            setNewPosition=TRUE;
                        }
                        MyAdjustRefRoot=(integer)llList2String(commandParts, 2);
                        MyQuietAdjusters=(integer)llList2String(commandParts, 3);
                        MySeatName=llList2String(commandParts, 4);
                        if(MyAnimations!=llList2String(commandParts, 5)) {
                            MyAnimations=llList2String(commandParts, 5);
                            setNewPosition=TRUE;
                        }
                        if(MyInitialNcPosition!=(vector)llList2String(commandParts, 6)) {
                            MyInitialNcPosition=(vector)llList2String(commandParts, 6);
                            setNewPosition=TRUE;
                        }
                        if(MyInitialNcRotation!=(rotation)llList2String(commandParts, 7)) {
                            MyInitialNcRotation=(rotation)llList2String(commandParts, 7);
                            setNewPosition=TRUE;
                        }
                        if(MyNcName!=llList2String(commandParts, 8)) {
                            MyNcName=llList2String(commandParts, 8);
                            setNewPosition=TRUE;
                        }
                        MySitterType=(integer)llList2String(commandParts, 9);
                        setAlpha();
                        setText();

                        if(setNewPosition) {
                            //set new pos/rot
                            if(MyAdjustRefRoot) {
                                MyCurrentGlobalPosition = ParentRootPos + MyInitialNcPosition * ParentRootRot;
                                MyCurrentGlobalRotation = MyInitialNcRotation * ParentRootRot;
                            }
                            else {
                                MyCurrentGlobalPosition = ParentPos + MyInitialNcPosition * ParentRot;
                                MyCurrentGlobalRotation = MyInitialNcRotation * ParentRot;
                            }
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, MyCurrentGlobalRotation]);
                            llSetRegionPos(MyCurrentGlobalPosition);
                            MyCurrentNcPosition=MyInitialNcPosition;
                            MyCurrentNcRotation=MyInitialNcRotation;
                        }
                        
                        //HB.. Added the two following lines because:  When a notecard is changed, changing pos/rot, the adjuster follows the change but sitter does not.
                        string command=addCommand("", ["AS_POS_ROT", MyCurrentNcPosition, MyCurrentNcRotation]);
                        llRegionSayTo(MyParentId, AdjusterChannel, command);
                        //HB end
                        
                        //animesh stuff
                        if(IsAnimeshAdjuster) {
                            //this is a Animesh Adjuster, wich contains the Plain Adjuster as Root Prim and the Animash as link number 2
                            
                            //Animations
                            stopAllAnimations();
                            AnimationsToStart=[];

                            AnimationsToLoad=[];
                            list animations=llCSV2List(MyAnimations);
                            AnimationsToStart=animations;
                            integer index;
                            integer length=llGetListLength(animations);
                            for(index=0; index<length; index++) {
                                if(llGetInventoryType(llList2String(animations, index))!=INVENTORY_ANIMATION) {
                                    AnimationsToLoad+=llList2String(animations, index);
                                }
                            }
                            if(llGetListLength(AnimationsToLoad)) {
                                llRegionSayTo(MyParentId, AdjusterChannel, addCommand("", ["AS_INVENTORY_REQUEST"]+AnimationsToLoad));
                            }
                            else {
                                startAnimations();
                            }
                        }
                    }
                    else if(cmd=="SA_DIE") {
                        llDie();
                    }
                }
            }
        }
    }
    
    timer() {
        if(MyParentId!=NULL_KEY) {
            if (llKey2Name(MyParentId)=="") {
                //parent has died.  do likewise
                llDie();
            }
        }
        integer adjusterPosRotChanged;
        vector pos=llGetPos();
        rotation rot=llGetRot();

        if(pos!=MyCurrentGlobalPosition) {
            MyCurrentGlobalPosition=pos;
            adjusterPosRotChanged=TRUE;
        }
        if(rot!=MyCurrentGlobalRotation) {
            MyCurrentGlobalRotation=rot;
            adjusterPosRotChanged=TRUE;
        }
        if(adjusterPosRotChanged) {
            if(MyAdjustRefRoot) {
                MyCurrentNcPosition = (MyCurrentGlobalPosition - ParentRootPos) / ParentRootRot;
                MyCurrentNcRotation = MyCurrentGlobalRotation / ParentRootRot;
            }
            else {
                MyCurrentNcPosition = (MyCurrentGlobalPosition - ParentPos) / ParentRot;
                MyCurrentNcRotation = MyCurrentGlobalRotation / ParentRot;
            }
            string command=addCommand("", ["AS_POS_ROT", MyCurrentNcPosition, MyCurrentNcRotation]);

            if(!MyQuietAdjusters) {
                command=addCommand(command, ["AS_DUMP"]);
            }
            llRegionSayTo(MyParentId, AdjusterChannel, command);
        }
        
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            integer index;
            integer break;
            while(llGetListLength(AnimationsToLoad) && !break) {
                if(llGetInventoryType(llList2String(AnimationsToLoad, 0))==INVENTORY_ANIMATION) {
                    AnimationsToLoad=llDeleteSubList(AnimationsToLoad, 0, 0);
                }
                else {
                    break=TRUE;
                }
            }
            if(!llGetListLength(AnimationsToLoad)) {
                startAnimations();
            }
        }
    }
}

vector ParentPos;
rotation ParentRot;
vector ParentRootPos;
rotation ParentRootRot;


// JSON Message Format:
//    [
//         [cmd, param, param ...]
//        ...
//    ]
// the command has a 2 letter prefix: first letter is the source and the second letter is the destination
// usually SA_ (Slave->Adjuster) or AS_ (Adjuster->Slave)


debug(list message){
    llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

setAlpha() {
    if(IsAnimeshAdjuster) {
        float activeAlpha=ANIMESH_ALPHA_FOR_UNOCCUPIED_SEATS;
        if(MySitterType==SITTER_TYPE_AVATAR) {
            activeAlpha=ANIMESH_ALPHA_FOR_OCCUPIED_SEATS;
        }
        integer index;
        integer length=llGetNumberOfPrims();
        for(index=2; index<=length; index++) {
            if(index==ActiveAnimeshLinkNumber) {
                llSetLinkAlpha(index, activeAlpha, ALL_SIDES);
            }
            else {
                llSetLinkAlpha(index, ANIMESH_ALPHA_FOR_INACTIVE_ANIMESH, ALL_SIDES);
            }
        }
    }
}

stopAllAnimations() {
    list runningAnimations=llGetObjectAnimationNames();
    integer length=llGetListLength(runningAnimations);
    integer index;
    integer defaultPoseRunning;
    for(index=0; index<length; index++) {
        string animation=llList2String(runningAnimations, index);
        if(animation==DefaultPose) {
            defaultPoseRunning=TRUE;
        }
        else {
            llStopObjectAnimation(animation);
        }
    }
    if(!defaultPoseRunning) {
        llStartObjectAnimation(DefaultPose);
    }
}

startAnimations() {
    while(llGetListLength(AnimationsToStart)) {
        string animation=llList2String(AnimationsToStart, 0);
        AnimationsToStart=llDeleteSubList(AnimationsToStart, 0, 0);
        if(llGetInventoryType(animation)==INVENTORY_ANIMATION) {
            llStartObjectAnimation(animation);
        }
    }
}

getParentPos() {
    //get the information about the parent and the root of the parent
    list temp=llGetObjectDetails(MyParentId, [OBJECT_POS, OBJECT_ROT, OBJECT_ROOT]);
    ParentPos=llList2Vector(temp, 0);
    ParentRot=llList2Rot(temp, 1);
    key parentRootId=llList2Key(temp, 2);
    temp=llGetObjectDetails(parentRootId, [OBJECT_POS, OBJECT_ROT]);
    ParentRootPos=llList2Vector(temp, 0);
    ParentRootRot=llList2Rot(temp, 1);
}

setText() {
    string text="Seat" + (string)(MySlotNumber+1) + " (" + MySeatName + ")"
        + "\n" + MyNcName
        + "\n" + MyAnimations
    ;
    //Text output
    llSetText(text, TEXT_COLOR, TEXT_ALPHA);
}

string addCommand(string commands, list commandWithParamList) {
    if(commands=="") {
        return llList2Json(JSON_ARRAY, [llList2Json(JSON_ARRAY, commandWithParamList)]);
    }
    else {
        return llList2Json(JSON_ARRAY, llJson2List(commands) + [llList2Json(JSON_ARRAY, commandWithParamList)]);
    }
}

string vectorToString(vector value, integer precision) {
    return
         "<" +
        floatToString(value.x, precision) + 
        ", " +
        floatToString(value.y, precision) + 
        ", " +
        floatToString(value.z, precision) + 
        ">"
    ;
}

string floatToString(float value,  integer precision) {
    // precision: number of decimal places
    // return (string)value;
    string valueString=(string)((float)llRound(value*llPow(10,precision))/llPow(10,precision));
    string char;
    do {
        char=llGetSubString(valueString, -1, -1);
        if(char=="." || char=="0") {
            valueString=llDeleteSubString(valueString, -1, -1);
        }
    } while (char=="0");
    return valueString;
}

default {
    on_rez(integer param) {
        llSetTimerEvent(0.0);
        llSetText("", ZERO_VECTOR, 0.0);
        IsAnimeshAdjuster=llGetLinkNumber(); //a plain adjuster has only 1 prim, an animesh adjuster is a linkset of 2 prims
        ActiveAnimeshLinkNumber=2;
        MyParentId=llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        AdjusterChannel=(integer)("0x7F" + llGetSubString((string)MyParentId, 1, 6));
        llListen(AdjusterChannel, "", "", "");
        llRegionSayTo(MyParentId, AdjusterChannel, addCommand("", ["AS_UPDATE_REQUEST"]));
        getParentPos();
    }

    touch_start(integer total_number) {
        ActiveAnimeshLinkNumber++;
        if(ActiveAnimeshLinkNumber>llGetNumberOfPrims()) {
            ActiveAnimeshLinkNumber=2;
        }
        setAlpha();
    }

    listen(integer channel, string name, key id, string message) {
        if(MyParentId==id) {
            if(llJsonValueType(message, [])==JSON_ARRAY) {
                list commandLines=llJson2List(message);
                while(llGetListLength(commandLines)) {
                    list commandParts=llJson2List(llList2String(commandLines, 0));
                    commandLines=llDeleteSubList(commandLines, 0, 0);
                    string cmd=llList2String(commandParts, 0);
                    if(cmd=="SA_UPDATE") {
                        llSetTimerEvent(TIMEOUT);
                        integer setNewPosition;

                        if(MySlotNumber!=(integer)llList2String(commandParts, 1)) {
                            MySlotNumber=(integer)llList2String(commandParts, 1);
                            setNewPosition=TRUE;
                        }
                        MyAdjustRefRoot=(integer)llList2String(commandParts, 2);
                        MyQuietAdjusters=(integer)llList2String(commandParts, 3);
                        MySeatName=llList2String(commandParts, 4);
                        if(MyAnimations!=llList2String(commandParts, 5)) {
                            MyAnimations=llList2String(commandParts, 5);
                            setNewPosition=TRUE;
                        }
                        if(MyInitialNcPosition!=(vector)llList2String(commandParts, 6)) {
                            MyInitialNcPosition=(vector)llList2String(commandParts, 6);
                            setNewPosition=TRUE;
                        }
                        if(MyInitialNcRotation!=(rotation)llList2String(commandParts, 7)) {
                            MyInitialNcRotation=(rotation)llList2String(commandParts, 7);
                            setNewPosition=TRUE;
                        }
                        if(MyNcName!=llList2String(commandParts, 8)) {
                            MyNcName=llList2String(commandParts, 8);
                            setNewPosition=TRUE;
                        }
                        MySitterType=(integer)llList2String(commandParts, 9);
                        setAlpha();
                        setText();

                        if(setNewPosition) {
                            //set new pos/rot
                            if(MyAdjustRefRoot) {
                                MyCurrentGlobalPosition = ParentRootPos + MyInitialNcPosition * ParentRootRot;
                                MyCurrentGlobalRotation = MyInitialNcRotation * ParentRootRot;
                            }
                            else {
                                MyCurrentGlobalPosition = ParentPos + MyInitialNcPosition * ParentRot;
                                MyCurrentGlobalRotation = MyInitialNcRotation * ParentRot;
                            }
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, MyCurrentGlobalRotation]);
                            llSetRegionPos(MyCurrentGlobalPosition);
                            MyCurrentNcPosition=MyInitialNcPosition;
                            MyCurrentNcRotation=MyInitialNcRotation;
                        }
                        
                        //animesh stuff
                        if(IsAnimeshAdjuster) {
                            //this is a Animesh Adjuster, wich contains the Plain Adjuster as Root Prim and the Animash as link number 2
                            
                            //Animations
                            stopAllAnimations();
                            AnimationsToStart=[];

                            AnimationsToLoad=[];
                            list animations=llCSV2List(MyAnimations);
                            AnimationsToStart=animations;
                            integer index;
                            integer length=llGetListLength(animations);
                            for(index=0; index<length; index++) {
                                if(llGetInventoryType(llList2String(animations, index))!=INVENTORY_ANIMATION) {
                                    AnimationsToLoad+=llList2String(animations, index);
                                }
                            }
                            if(llGetListLength(AnimationsToLoad)) {
                                llRegionSayTo(MyParentId, AdjusterChannel, addCommand("", ["AS_INVENTORY_REQUEST"]+AnimationsToLoad));
                            }
                            else {
                                startAnimations();
                            }
                        }
                    }
                    else if(cmd=="SA_DIE") {
                        llDie();
                    }
                }
            }
        }
    }
    
    timer() {
        if(MyParentId!=NULL_KEY) {
            if (llKey2Name(MyParentId)=="") {
                //parent has died.  do likewise
                llDie();
            }
        }
        integer adjusterPosRotChanged;
        vector pos=llGetPos();
        rotation rot=llGetRot();

        if(pos!=MyCurrentGlobalPosition) {
            MyCurrentGlobalPosition=pos;
            adjusterPosRotChanged=TRUE;
        }
        if(rot!=MyCurrentGlobalRotation) {
            MyCurrentGlobalRotation=rot;
            adjusterPosRotChanged=TRUE;
        }
        if(adjusterPosRotChanged) {
            if(MyAdjustRefRoot) {
                MyCurrentNcPosition = (MyCurrentGlobalPosition - ParentRootPos) / ParentRootRot;
                MyCurrentNcRotation = MyCurrentGlobalRotation / ParentRootRot;
            }
            else {
                MyCurrentNcPosition = (MyCurrentGlobalPosition - ParentPos) / ParentRot;
                MyCurrentNcRotation = MyCurrentGlobalRotation / ParentRot;
            }
            string command=addCommand("", ["AS_POS_ROT", MyCurrentNcPosition, MyCurrentNcRotation]);

            if(!MyQuietAdjusters) {
                command=addCommand(command, ["AS_DUMP"]);
            }
            llRegionSayTo(MyParentId, AdjusterChannel, command);
        }
        
    }
    changed(integer change) {
        if(change & CHANGED_INVENTORY) {
            integer index;
            integer break;
            while(llGetListLength(AnimationsToLoad) && !break) {
                if(llGetInventoryType(llList2String(AnimationsToLoad, 0))==INVENTORY_ANIMATION) {
                    AnimationsToLoad=llDeleteSubList(AnimationsToLoad, 0, 0);
                }
                else {
                    break=TRUE;
                }
            }
            if(!llGetListLength(AnimationsToLoad)) {
                startAnimations();
            }
        }
    }
}
