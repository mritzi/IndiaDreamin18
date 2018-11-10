({
    /* 	   **********************************************************************************************************************
	 *     ########## PARAMETERS INDICATE variables/objects other than COMPONENT, EVENT, HELER passed to the FUNCTION ##########
     * 	   ********************************************************************************************************************** 
     * 
     * function name : doInit
     * return value  : none
     * description   : Executes as soon as the components loads, will call helper method to create map 
     *                 on page if static resource is already loaded
     */ 
    doInit: function(component, event, helper) {
       if(window.jQuery && !component.get("v.isInitialized")){
           helper.createMapHelper(component, event);
       }

    },
    /* 
     * function name : createMap
     * return value  : none
     * description   : Calls helper method to create map on page, executes when static resource is loaded
     */ 
    createMap : function(component, event, helper){
        if(window.jQuery && !component.get("v.isInitialized")){
            helper.createMapHelper(component, event);
		}
    },
    /* 
     * function name : nodeClickAction
     * return value  : none
     * description   : Executes when user clicks on add/edit/delete icons or contact hyperlink, calls different helper methods based on which icon has been clicked
     */ 
    nodeClickAction: function(component, event, helper) {
        if (event.target.id == "editNode" || event.target.id == "addNode") {
            //save event's context in a variable for future use
            helper.clickEvent = event;
            var node = $(event.target.parentElement.parentElement.parentElement);
            //first attribute of node should be aria-recordId
            var recordId = node[0].attributes[0].textContent;
            //get record data from JSON data
            var record = {};
            helper.getRecord(component, recordId, helper.dataSource, record);
            if (event.target.id == "addNode") {
                //record variable of "add" has one value -> objInfluenceMap.Id -> that acts as parent Id for new node
                helper.updateComponentVariables(component,record,"Add");
            }
            else if(event.target.id == "editNode"){
                helper.updateComponentVariables(component,record,"Edit");
            }
            helper.openContactModal(component);
        }
        else if (event.target.id == "deleteNode") {
            helper.openDeleteModal(component, event);
        }
        else if(event.target.getAttribute("class") == "recordLink"){
        	helper.redirectToSelectedContact(component, event);
		}
    },
    /* 
     * function name : closeContactModal
     * return value  : none
     * description   : Calls helper method to close the contact modal when the user clicks on cancel button on the modal
     */ 
    closeContactModal : function(component, event, helper){
        helper.closeContactModal(component);
    },
    /* 
     * function name : modalSave
     * return value  : none
     * description   : i) If Existing Contact Tab is active, then save the node data, make changes on the map accordingly
     *                 ii) If New Contact Tab is active, then call apex function to insert contact, pull that value in Existing Contact Tab
     * 					& let user create new node using newly created contact record.
     */ 
    modalSave : function(component, event, helper){
    	var selectedTabId = component.get("v.selectedTabId");
        if(selectedTabId === "existingContactTab"){
            var isValidData = helper.validInfluenceMapData(component)
            if(isValidData){
                //assign values to field like Id & parentId for newly created nodes
                helper.onModalSave(component);
                //add or update nodes on map, make changes to the json data.
                helper.saveInfluenceMap(component);
                //add selected contact into to a list, to avoid duplicate contacts on the map
                helper.updateContactList(component, "Save");
            }
        }
        else if(selectedTabId === "newContactTab"){
            var isValidData = helper.validContactData(component);
            if(isValidData){
                //call apex method to insert new Contact record
                helper.insertNewContact(component);
            }
            //error message displayed from helper methods
        }
    },
    /* 
     * function name : goBack
     * return value  : none
     * description   : redirects user to the record from which Influence Map was opened
     */ 
    goBack : function(component,event,helper){
    	helper.goBackToRecord(component);
    },
    /* 
     * function name : saveMapData
     * return value  : none, shows success/failure message
     * description   : Update nodes according to the hierarchy of nodes on the page & save records using apex method
     */ 
    saveMapData : function(component, event, helper){
        //show spinner on page
        component.set("v.mapSpinnerClass", "");
        if(helper.dataSource && helper.dataSource.objInfluenceMap){
            var hierarchyData = helper.orgChart.getHierarchy();
            var jsonData = {};
            var parentId = "";
            //re-parent nodes based on latest hierarchy on the page, so that same structure can be retreived later
            helper.prepareFinalData(jsonData, hierarchyData, parentId);
			//call apex method to save the map data, spinner will be hidden in the callback
            helper.finalSaveAction(component, jsonData);
        }
        else{
            //console.log("Empty JSON will be sent to the backend");
            helper.finalSaveAction(component, {});
        }
        
    },
    /* 
     * function name : addFirstNode
     * return value  : none
     * description   : Opens Add/Edit Contact modal on click of a button that's only visible when no records exist on the page
     */ 
    addFirstNode : function(component, event, helper){
        var record = {};
        //following field is used in updateComponentVariables fn, DON'T REMOVE
        record.objInfluenceMap = {};
        record.objInfluenceMap.Id = "";
        helper.updateComponentVariables(component, record, "Add");
        helper.openContactModal(component);
        //lookup on modal will be cleared from tab onactive function
        
    },
    /* 
     * function name : closeDeleteModal
     * return value  : none
     * description   : Closes Delete modal
     */ 
    closeDeleteModal : function(component, event, helper){
        helper.closeDeleteModal(component);
    },
    /* 
     * function name : deleteContact
     * return value  : none
     * description   : Delete a node & all its children when a user confirms to delete any node
     */ 
    deleteContact : function(component, event, helper){
        helper.updateContactList(component, "Delete");
        helper.deleteNode(component, event);
        //if complete map has been deleted then change map header styling
		if(helper.dataSource === undefined || helper.dataSource.objInfluenceMap === undefined)
            helper.adjustMapHeaderHeight(component);
    },
    /* 
     * function name : selectedContactEvent
     * return value  : none
     * description   : Executes when a user selects a contact from the Lookup suggestions, or creates a new contact from New Contact Tab.
     * 				   Updates corresponding values in component variables for proper display
     */ 
    selectedContactEvent : function(component, event, helper){
        //function required to set Contact__c field of objInfluenceMap
        var contact = event.getParam("contact");
        if(contact && contact.Id){
            component.set("v.nodeData.objContact", contact);
            component.set("v.nodeData.objInfluenceMap.Contact__c", contact.Id);
        }
        //console.log("parentComponent-- selectedContactEvent fn, nodeData : ", component.get("v.nodeData"));
    },
    /* 
     * function name : changeFilter
     * return value  : none
     * description   : Executes when Account Filter picklist is modified. Clears Contact Lookup, if any contact is currently selected
     */ 
    changeFilter : function(component,event, helper){
        helper.clearLookupField(component);
    },
    /* 
     * function name : setLookupField
     * return value  : none
     * description   : Called when status of "Existing Contact Tab" changes to "active".
     *                 Clears/Populates Contact Lookup field based on Add/Edit/Insert action
     */ 
    setLookupField : function(component, event, helper){
        //hide spinner
        component.set("v.modalSpinnerClass", "slds-hide");
        var eventName = component.get("v.eventName");
        //in case of Contact Insert, objContact will be populated/updated in callback function of insertContact action
        var contact = component.get("v.nodeData.objContact");
        //console.log("**** eventName : " + eventName + ", objCOntact : ", contact);
        //no contact data exists, happens in case when user clicks on Add icon, or contact insert action fails
        if(!contact || !contact.Id){
            helper.clearLookupField(component);
        }
        //this will be true when a contact is Inserted, or user clicks on Edit icon
        else if(contact && contact.Id){
            var lookupComponent = component.find("lookupComponent");
        	//lookupComponent.set("v.selectedContact", contact);
        	lookupComponent.setContactFromParent(contact);
        }
    },
    /* 
     * function name : toggleLegendDiv
     * return value  : none
     * description   : Show/Hide Legend Div, alter button text/icon as well
     */ 
    toggleLegendDiv : function(component, event, helper){
        helper.toggleLegendDiv(component);
        
    },
    /* 
     * function name : openFetchFromAccountModal
     * return value  : none
     * description   : Show Fetch from account Modal
     */ 
    openFetchFromAccountModal : function(component, event, helper){
        component.set("v.showFetchFromAccountModal", true);
    },
    /* 
     * function name : fetchFromAccount
     * return value  : none
     * description   : Calls apex method to populate map based on selected values from the Fetch from Account Modal
     */ 
    fetchFromAccount : function(component, event, helper){
        helper.createMapFromAccountData(component);
    },
    /* 
     * function name : closeFetchFromAccountModal
     * return value  : none
     * description   : Closes fetch from account modal
     */ 
    closeFetchFromAccountModal : function(component, event, helper){
        component.set("v.showFetchFromAccountModal", false);
    },
    /* 
     * function name : onChangeBuyingRoleValues
     * return value  : none
     * description   : resets other selected values if selected options includes "All"
     */ 
    onChangeBuyingRoleValues : function(component, event, helper){
        var buyingRoleMutliPickList = component.find("buyingRoleMutliPickList");
        helper.checkSelectedValues(component, buyingRoleMutliPickList);
    },
    /* 
     * function name : onChangeStatusValues
     * return value  : none
     * description   : resets other selected values if selected options includes "All"
     */ 
    onChangeStatusValues : function(component, event, helper){
        var statusMutliPickList = component.find("statusMutliPickList");
        helper.checkSelectedValues(component, statusMutliPickList);
    },
    /* 
     * function name : onChangeFocusValues
     * return value  : none
     * description   : resets other selected values if selected options includes "All"
     */ 
    onChangeFocusValues : function(component, event, helper){
        var focusMutliPickList = component.find("focusMutliPickList");
        helper.checkSelectedValues(component, focusMutliPickList);
    },
    /* 
     * function name : onChangeContactLevelValues
     * return value  : none
     * description   : resets other selected values if selected options includes "All"
     */ 
    onChangeContactLevelValues : function(component, event, helper){
        var contactLevelMutliPickList = component.find("contactLevelMutliPickList");
        helper.checkSelectedValues(component, contactLevelMutliPickList);
    },
    /* 
     * function name : onNewContactTabActive
     * return value  : none
     * description   : resets selected Contact values if it exists, and remove the contact Id from existing contact List
     */ 
    onNewContactTabActive : function(component, event, helper){
        var contact = component.get("v.nodeData.objContact");
        if(contact && contact.Id){
            helper.removeSelectedContact(component, contact);
        }
    }
})