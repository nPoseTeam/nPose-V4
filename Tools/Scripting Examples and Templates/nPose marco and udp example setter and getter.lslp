integer DO=220; //this can be used to send commands to the core
integer UPDATE_UDP=-808; //the core sends a 3-strided list udpName|udpType|udpValue each time a UDP is updated
integer UPDATE_MACRO=-809; //the core sends a 3-strided list macroName|macroType|macroValue each time a macro is updated

string UDP_TYPE_LIST="l";
string UDP_TYPE_BOOL="b";
string MACRO_TYPE="m";

string SEPARATOR="|";

list UdpList;
list MacroList;

string getMacroValue(string macroName) {
	// returns the value of the macro with the name macroName
	integer index=llListFindList(MacroList, [macroName, MACRO_TYPE]);
	if(~index) {
		return llList2String(MacroList, index + 2);
	}
	return "";
}

integer getUdpBoolValue(string udpName) {
	// returns the value of the udpBool with the name udpName
	integer index=llListFindList(UdpList, [udpName, UDP_TYPE_BOOL]);
	if(~index) {
		return (integer)llList2String(UdpList, index + 2);
	}
	return FALSE;
}

string getUdpListValue(string udpName) {
	// returns the value of the udpList with the name udpName
	integer index=llListFindList(UdpList, [udpName, UDP_TYPE_LIST]);
	if(~index) {
		return llList2String(UdpList, index + 2);
	}
	return "";
}

setMacroValue(string macroName, string macroValue) {
	if(macroName) {
		//sets the macro with the name macroName to the value macroValue
		llMessageLinked(LINK_SET, DO, "MACRO|" + macroName + "=" + macroValue, "");
		// We will get the updated list in a second via a link message
		// but if we want to use the new Value right now
		// we have to manipulate the list ourself
		integer index=llListFindList(MacroList, [macroName, MACRO_TYPE]);
		if(~index) {
			MacroList=llListReplaceList(MacroList, [macroValue], index+2, index+2);
		}
		else {
			MacroList+=[macroName, MACRO_TYPE, macroValue];
		}
	}
}

setUdpBoolValue(string udpName, integer udpValue) {
	if(udpName) {
		//sets the udpBool with the name udpName to the value udpValue
		llMessageLinked(LINK_SET, DO, "UDPBOOL|" + udpName + "=" + (string)udpValue, "");
		// We will get the updated list in a second via a link message
		// but if we want to use the new Value right now
		// we have to manipulate the list ourself
		integer index=llListFindList(UdpList, [udpName, UDP_TYPE_BOOL]);
		if(~index) {
			UdpList=llListReplaceList(UdpList, [(string)udpValue], index+2, index+2);
		}
		else {
			UdpList+=[udpName, UDP_TYPE_BOOL, udpValue];
		}
	}
}

setUdpListValue(string udpName, string udpValue) {
	if(udpName) {
		//sets the udpList with the name udpName to the value udpValue
		llMessageLinked(LINK_SET, DO, "UDPLIST|" + udpName + "=" + udpValue, "");
		// We will get the updated list in a second via a link message
		// but if we want to use the new Value right now
		// we have to manipulate the list ourself
		integer index=llListFindList(UdpList, [udpName, UDP_TYPE_LIST]);
		if(~index) {
			UdpList=llListReplaceList(UdpList, [udpValue], index+2, index+2);
		}
		else {
			UdpList+=[udpName, UDP_TYPE_LIST, udpValue];
		}
	}
}

forceUdpUpdate() {
	//you usually don't need this
	//Instruct the core to send the current UDPs (which contains both udpBool and udpList)
	llMessageLinked(LINK_SET, DO, "UDPBOOL", "");
}

forceMacroUpdate() {
	//you usually don't need this
	//Instruct the core to send the current macros
	llMessageLinked(LINK_SET, DO, "MACRO", "");
}

default {
	link_message(integer sender_num, integer num, string str, key id) {
		if(num==UPDATE_UDP) {
			// get the (updated) list from the core
			UdpList=llParseStringKeepNulls(str, [SEPARATOR], []);
		}
		if(num==UPDATE_MACRO) {
			// get the (updated) list from the core
			MacroList=llParseStringKeepNulls(str, [SEPARATOR], []);
		}
	}
}