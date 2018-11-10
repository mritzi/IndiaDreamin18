({
    /* 	   ***********************************************************************************************************************
	 *     ########## PARAMETERS INDICATE variables/objects other than COMPONENT, EVENT, HELPER passed to the FUNCTION ##########
     * 	   ***********************************************************************************************************************
     */
    /*
     * function name : selectedRecord
     * parameters    : none
     * return value  : none
     * description   : pass selected contacts' detail to the lookup component
     */
	selectedRecord : function(component) {
		// get the selected record from list
        var selectedContact = component.get("v.contact");
        //console.log("resultcomponentController selectedContact : ", selectedContact);
        // call the event
        var compEvent = component.getEvent("oSelectedContactEvent");
        // set the Selected sObject Record to the event attribute.
        compEvent.setParams({
            "contact" : selectedContact
        });
        // fire the event
        compEvent.fire();
	}
})