({
    // saves the map data for persistence
    orgChart: {},
    // holds the information of the node from where add/edit/delete/redirect event was initiated
    clickEvent :{},
    //json data for view/add/edit/delete/save
    dataSource : {},
    //data to populate picklist values, country field and other info for page wide use
    metaData: {
        buyingRoleList: [],
        statusList: [],
        focusList: [],
        contactLevelList: []
    },
    // boolean value to indicate whether the script has been loaded/cached or not
    scriptLoaded : false,
    //following variables hold picklist values, used to quickly refer to values in case of Add/Edit action on the page
    buyingRoleList : {},
    statusList : {},
    focusList : {},
    contactLevelList : {},
    focusValues : [],
    focusApis : [],
    focusChars : [],
    contactLevelValues : [],
    filterList: [
        {strApi: "0", strChar: "0", strValue: "Current Account"},
        {strApi: "1", strChar: "1", strValue: "Related Accounts"},
        {strApi: "2", strChar: "2", strValue: "All Accounts"}
    ],
    chartZoom : 1,
	/* 	   **************************************************************************************************************
	 *     ########## PARAMETERS INDICATE variables/objects other than COMPONENT, EVENT passed to the FUNCTION ##########
     * 	   **************************************************************************************************************
     * function name : createMapHelper
     * parameters    : none
     * return value  : none
     * description   : Calls apex method to fetch data, passes received data to another function to render on page
     */
    createMapHelper : function(component,event){
		var action = component.get("c.getInflunceMapRecords");
        component.set("v.isInitialized", true);
        //"001W000000cabK7IAI", component.get("v.recordId"), "006W000000CMOIuIAP", "003W000000lXlnyIAC"
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log("response : ", response.getReturnValue());
                this.setHelperVariables(response.getReturnValue());
                this.setComponentVariables(component,event);
                if (!component.get("v.isScriptLoaded")) {
                    component.set("v.isScriptLoaded", true);
                    if(this.dataSource && this.dataSource.objInfluenceMap && this.dataSource.objInfluenceMap.Id){
                        this.renderMapOnPage(component);
                    }
                    else{
                        // if no nodes exists for this record, then show "+" icon to add nodes from scratch
                        this.showPlusButton(component);
                        // set Map header's height, irrespective of the fact whether data has been loaded or not
            			this.adjustMapHeaderHeight(component);
                    }
                }
            }
            else{
                //console.log("Error in getting data");
                this.showToastMessage(component, "error", "Error while getting data");
            }
            
        });
        $A.enqueueAction(action);

    },
    /*
     * function name : renderMapOnPage
     * parameters    : none
     * return value  : none
     * description   : Receives map data from createMapHelper method, renders the map on page and saves data
     *                 in a local variable for persistence
     *     **************************************************************************************************************
	 *     ########## Order of classes, attributes, inline styling has significance in following method.
	 * 				  Abrupt changes might alter/break functionality ##########
     * 	   **************************************************************************************************************
     */
    renderMapOnPage: function(component){
        //console.log("renderMap");
        var element;
        var self = this;
        setTimeout(function() {
            element = $(component.find('chart-Container').getElement());
            self.orgChart = element.orgchart({
                'data': self.dataSource,
                'draggable': true,
                'pan': true,
                'zoom': true,
                'exportButton': true,
                'exportFilename': "InfluenceMap",
                'createNode': function($node, data) {
                    //setting a unique id to every node.
                    $node[0].id = data.objInfluenceMap.Id;

                    //injecting the required HTML.
                    //for Contact Status & Contact Level Width, class have a prefix of "attr"+value to suit requirements, needs to be modified accordingly
                    $node[0].innerHTML =
                        '<div aura:id="node"  class="nodeDiv slds-box">' +
                        		'<div aria-recordId="'+ data.objInfluenceMap.Id +'">' +
                        			'<p class="emptyDiv"></p>' +
                        			'<h4 aura:id="recordLink" class="recordLink">' + (data.objContact.Name.length <= 15 ? data.objContact.Name : (data.objContact.Name.substring(0,15)+'..')) + '</h4>' +
                        			'<div><h5 class="tooltip contactTitle">' + (data.objContact.Title ? (data.objContact.Title.length <= 15 ? data.objContact.Title: (data.objContact.Title.substring(0,15)+ '..'))  : '&nbsp;')+
										'<span class="tooltiptext">' + (data.objContact.Title ? data.objContact.Title :  '') + '</span>'+
                        			'</h5></div>' +
                        '<div><h5 class="tooltip contactCompanyTitle">' + (data.objContact.Account_Name__c == '' || data.objContact.Account_Name__c == undefined ? '' : (data.objContact.Account_Name__c.length <= 15 ? data.objContact.Account_Name__c : (data.objContact.Account_Name__c.substring(0,15)+'..'))) +
                        				'<span class="tooltiptext">' + (data.objContact.Account_Name__c ? data.objContact.Account_Name__c :  '') + '</span>'+
                        			'</h5></div>' +
                        			'<div class="slds-grid indicatorsDiv">' +
                        				'<div class="slds-size--4-of-12">' +
                        					'<div aria-class="' + (data.objInfluenceMap.Buying_Role__c ? data.objInfluenceMap.Buying_Role__c : '') + '">'+
                    							'<div class="tooltip">'+
                        							(data.objInfluenceMap.Buying_Role__c ? data.objInfluenceMap.Buying_Role__c.charAt(0) : '') +
                        							'<span class="tooltiptext">' + (data.objInfluenceMap.Buying_Role__c ? data.objInfluenceMap.Buying_Role__c : '') + '</span>'+
                        						'</div>'+
                        					'</div>' +
                        				'</div>' +
                        				'<div class="slds-size--4-of-12 attr'+(data.objInfluenceMap.Status__c ? data.objInfluenceMap.Status__c : '')+'">' +
                        					'<div aria-class="' + (data.objInfluenceMap.Status__c ? data.objInfluenceMap.Status__c : '') + '">'+
                        						'<div class="tooltip">' +
                        							(data.objInfluenceMap.Status__c ? data.objInfluenceMap.Status__c.charAt(0) : '') +
                        							'<span class="tooltiptext">' + (data.objInfluenceMap.Status__c ? data.objInfluenceMap.Status__c : '') + '</span>'+
                        						'</div>'+
                        					'</div>' +
                        				'</div>' +
                        				'<div class="slds-size--4-of-12">' +
                        					'<div aria-class="' + (data.objInfluenceMap.Focus__c ? self.focusValues[self.focusApis.indexOf(data.objInfluenceMap.Focus__c)] : '') + '">'+
                        						'<div class="tooltip">' +
                        							(data.objInfluenceMap.Focus__c ? data.objInfluenceMap.Focus__c.charAt(0) : '') +
													'<span class="tooltiptext">' + (data.objInfluenceMap.Focus__c ? self.focusValues[self.focusApis.indexOf(data.objInfluenceMap.Focus__c)] : '') + '</span>'+
                        						'</div>'+
                        					'</div>' +
                        				'</div>' +
                        				'<div class="extraInfo">'+
                        					'<span>' + (data.objContact.Phone ? data.objContact.Phone : '') + '</span>'+
                        					'<span>' + (data.objContact.Email ? data.objContact.Email : '') + '</span>'+
                        				'</div>' +
                        			'</div>' +
                        			'<div class="slds-grid slds-p-top--xx-small">' +
                        				'<div class="slds-progress-bar tooltip progressBarDiv" aria-valuemin="0" aria-valuemax="100" aria-valuenow="100" role="progressbar">' +
                        					'<span aria-class="' + (data.objInfluenceMap.Level_of_Contact__c ? data.objInfluenceMap.Level_of_Contact__c : '') + '" class="slds-progress-bar__value attr'+ (data.objInfluenceMap.Level_of_Contact__c ? data.objInfluenceMap.Level_of_Contact__c : '') + '"  title="' + (data.objInfluenceMap.Level_of_Contact__c ? data.objInfluenceMap.Level_of_Contact__c : '') + '">' +
                        						'<span class="tooltiptext">Level of Interaction: ' + (data.objInfluenceMap.Level_of_Contact__c ? data.objInfluenceMap.Level_of_Contact__c : '') + '</span>'+
                        					'</span>'+
                        				'</div>'+
                        			'</div>' +
                        			'<div>' +
                        				'<div>' +
                                            '<i id="editNode" class="fa fa-pencil fa-fw editNode" aria-hidden="true"></i>&nbsp;' +
                                            '<i id="deleteNode" class="fa fa-trash fa-fw deleteNode" aria-hidden="true"></i>' +
                                            '<i id="addNode" class="fa fa-plus fa-fw addNode"  aria-hidden="true"></i>&nbsp;' +
                        				'</div>' +
                        			'</div>';
                }
            })
            self.adjustMapHeaderHeight(component);
            
        }, 100);
        
        //by default mapSpinnerClass is EMPTY -> to show spinner
        component.set("v.mapSpinnerClass", "slds-hide");
    },
    /*
     * function name : addNewNode
     * parameters    : node (wrapper object that has to be added in the map)
     * return value  : none
     * description   : Adds new node in the map
     */
    addNewNode : function(component, node){
        this.linkRecordWithAccountOpportunity(component);
        var nodeData = component.get("v.nodeData");

        //if first node on the map is being added
        if(!this.dataSource || !this.dataSource.objInfluenceMap){
            this.hidePlusButton(component);
            this.dataSource = {};
            this.dataSource.children = [];
            this.dataSource.objInfluenceMap = nodeData.objInfluenceMap;
            this.dataSource.objContact = nodeData.objContact;
            this.renderMapOnPage(component);
            return;
        }
        //Check if the focussed node already has a child or not.
        var hasChild = node.parent().attr('colspan') > 0 ? true : false;
        var orgChart = this.orgChart;
        //if not, Add a chid Node else add a sibling to the already present child Node(s).
        if(!hasChild){
            var data = {
                'children': [{
                    'objContact' : nodeData.objContact,
                    'objInfluenceMap' : nodeData.objInfluenceMap,
                    'children' : [],
                    'relationship' : "110"
                }]
            }
            orgChart.addChildren(node, data);
        }
        else{
            //console.log('--closest sibling : ', node.closest('tr').siblings('.nodes').find('.node:first'));
            orgChart.addSiblings(node.closest('tr').siblings('.nodes').find('.node:first'), {
                'siblings': [{
                    'objContact' : nodeData.objContact,
                    'objInfluenceMap' : nodeData.objInfluenceMap,
                    'children' : [],
                    'relationship': '110',
                    'Id': '12333'
                }]
            })
        }
    },
    /*
     * function name : updateNode
     * parameters    : node (wrapper object that has to be updated in the map)
     * return value  : none
     * description   : updates values captured from the Modal in relevant map node
     *     ****************************************************************************************************************
	 *     ########## Changes need to be made whenever the DOM structure/attributes are changed in createMapHelper method
	 *                For easy understanding of node structure, log & see the "node" obj in console
	 *                and then make changes to suit needs  ##########
     * 	   ****************************************************************************************************************
     */
    updateNode : function(component, node){
        //recordId & parentId will remain as it is in JSON
		var nodeData = component.get("v.nodeData");
        var contactName = nodeData.objContact.Name;
        var contactTitle = nodeData.objContact.Title;
        var contactCompanyName = nodeData.objContact.Account_Name__c;
        var contactPhone = nodeData.objContact.Phone;
        var contactEmail = nodeData.objContact.Email;
        var contactBuyingRole = nodeData.objInfluenceMap.Buying_Role__c;
        var contactStatus = nodeData.objInfluenceMap.Status__c;
        var contactFocus = nodeData.objInfluenceMap.Focus__c;
        var contactLevel = nodeData.objInfluenceMap.Level_of_Contact__c;
        //Contact Name & Account Name are mandatory fields at object level, so these fields will always have value
        node[0].childNodes[1].childNodes[0].textContent = (contactName.length <= 15 ? contactName : (contactName.substring(0,15)+'..'));

		node[0].childNodes[2].innerHTML ='<div><h5 class="contactTitle tooltip">' + (contactTitle ? (contactTitle.length <= 15 ? contactTitle: (contactTitle.substring(0,15)+ '..'))  : '&nbsp;')+
												'<span class="tooltiptext">' + (contactTitle ? contactTitle :  '') + '</span>'+
            								'</h5></div>';
        node[0].childNodes[3].innerHTML = '<div><h5 class="tooltip">' + (contactCompanyName == '' || contactCompanyName == undefined ? '' : (contactCompanyName.length <= 15 ? contactCompanyName : (contactCompanyName.substring(0,15)+'..'))) +
                        						'<span class="tooltiptext">' + (contactCompanyName ? contactCompanyName :  '') + '</span>'+
                        					'</h5></div>';
        //have to update buyingRole, Status, Focus values at three different places and change background color as well
        //changing aria-class value (used to populate modal picklists)
        node[0].childNodes[4].childNodes[0].childNodes[0].attributes[0].value = contactBuyingRole;
        node[0].childNodes[4].childNodes[1].childNodes[0].attributes[0].value = contactStatus;
        node[0].childNodes[4].childNodes[2].childNodes[0].attributes[0].value = contactFocus;

        //changing tooltip values
        node[0].childNodes[4].childNodes[0].childNodes[0].childNodes[0].childNodes[1].textContent = contactBuyingRole;
        node[0].childNodes[4].childNodes[1].childNodes[0].childNodes[0].childNodes[1].textContent = contactStatus;
        node[0].childNodes[4].childNodes[2].childNodes[0].childNodes[0].childNodes[1].textContent = this.focusValues[this.focusApis.indexOf(contactFocus)];
        //changing one alphabet
        node[0].childNodes[4].childNodes[0].childNodes[0].childNodes[0].childNodes[0].textContent = contactBuyingRole.charAt(0);
        node[0].childNodes[4].childNodes[1].childNodes[0].childNodes[0].childNodes[0].textContent = contactStatus.charAt(0);
        node[0].childNodes[4].childNodes[2].childNodes[0].childNodes[0].childNodes[0].textContent = contactFocus.charAt(0);

        //set border-color of Status value, any change in class name should be reflected here
        node[0].childNodes[4].childNodes[1].className = "slds-size--4-of-12 attr" + contactStatus;
		//extra-info
        node[0].childNodes[4].childNodes[3].childNodes[0].innerText = contactPhone ? contactPhone : '';
        node[0].childNodes[4].childNodes[3].childNodes[1].innerText = contactEmail ? contactEmail : '';

        //saving contacLevel value in aria-class attribute for re-reference, changing color & width of progress bar
        node[0].childNodes[5].childNodes[0].childNodes[0].attributes[0].textContent = contactLevel;
        node[0].childNodes[5].childNodes[0].childNodes[0].attributes[2].textContent = contactLevel;
        node[0].childNodes[5].childNodes[0].childNodes[0].childNodes[0].textContent = 'Level Of Interaction : ' + contactLevel;

        //set width of contactLevel progressbar in the node, any change in class name should be reflected here
        node[0].childNodes[5].childNodes[0].childNodes[0].className = "slds-progress-bar__value attr" + contactLevel;
    },
    /*
     * function name : getRecord
     * parameters    : recordId (of the node on which user has clicked), data (complete json), record (wrapper obj that will be populated from data based on recordId)
     * return value  : none, "record" object values are populated, no explicit return required as it's passed as reference
     * description   : Finds a record based on particular recordId in the locally stored json for updating it or to create new child under it
     */
    getRecord : function(component, recordId, data, record){
        //console.log("getRecord--data : ", data);
        if(!data)
            return;
        if(data.objInfluenceMap.Id == recordId){
            this.getRecordValues(data, record);
        	return;
        }
        else if(data.children){
            for(var i=0; i<data.children.length; i++)
                this.getRecord(component, recordId, data.children[i], record);
        }
    },
    /*
     * function name : getRecordValues
     * parameters    : record (to be populated), data (current node from which data has to be copied)
     * return value  : noned
     * description   : copies data from the current node (data) to "record"
     */
    getRecordValues : function(data,record){
        //deep copy object values
        record.objContact = data.objContact;
        record.objInfluenceMap = data.objInfluenceMap;
        record.intAccountFilter = data.intAccountFilter;
    },
    /*
     * function name : updateComponentVariables
     * parameters    : record (obj that will be copied in component variables), action ->"Add/Edit"
     * return value  : none
     * description   : updates the component variables using the record object retreived from the json
     */
    updateComponentVariables : function(component,record, action){
        if(action === "Add"){
            //parentId will be BLANK in case of first node addition
            var parentId = record.objInfluenceMap.Id;
            record.objInfluenceMap = {};
            record.objContact = {};
            record.intAccountFilter = 0;
            component.set("v.nodeData", record);
            component.set("v.nodeData.objInfluenceMap.Parent_Influencer__c", parentId);
            component.set("v.eventName", "Add");

        }
        else if(action === "Edit"){
            component.set("v.nodeData", record);
            component.set("v.eventName", "Edit");
    	}
        //console.log("nodeData before opening modal : ", component.get("v.nodeData"));
    },
    /*
     * function name : updateJSON
     * parameters    : action -> "Add/Edit"
     * return value  : none
     * description   : gets data from the component and updates json on "Save" action
     */
    updateJSON : function(component, action){
        var data = this.dataSource;
		var nodeData = component.get("v.nodeData");

        if(action === "Add"){
            // here recordId is actually parent's Id, below which new node has been created
            var recordIdNew = nodeData.objInfluenceMap.Parent_Influencer__c;
            this.addChildNode(data, nodeData, recordIdNew);
        }
        else if(action === "Edit"){
            var recordIdEdit = nodeData.objInfluenceMap.Id;
            this.updateJSONNode(data, nodeData, recordIdEdit);
        }
    },
    /*
     * function name : addChildNode
     * parameters    : data (entire json structure), nodeData (new node's data), recordId -> Id of the node for which child has to been added
     * return value  : none
     * description   : add child node data in the json after finding the parent
     */
    addChildNode : function(data, nodeData, recordId){
        if(!data)
            return;
        if(data.objInfluenceMap.Id == recordId){
            var child = {};
            child.objContact = nodeData.objContact;
            child.objInfluenceMap = nodeData.objInfluenceMap;
            child.intAccountFilter = nodeData.intAccountFilter;
            child.children = [];

            if(!data.children || data.children.length<=0)
                data.children = [];

            data.children.push(child);
            return;
        }
        else if(data.children){
            for(var i=0; i<data.children.length; i++)
                this.addChildNode(data.children[i],nodeData,recordId);
        }
    },
    /*
     * function name : updateJSONNode
     * parameters    : data (entire json structure), nodeData (updated node's data received from component) , recordId -> node's Id
     * return value  : none
     * description   : called from updateJSON function when node is edited, to update values in json
     */
    updateJSONNode : function(data, nodeData, recordId){
        if(!data)
            return;
        if(data.objInfluenceMap.Id == recordId){
            data.objContact = nodeData.objContact;
            data.objInfluenceMap = nodeData.objInfluenceMap;
            data.intAccountFilter = nodeData.intAccountFilter;
            return;
        }
        // iterates over the nested json structure to find the recordId for which data has to be updated
        else if(data.children){
            for(var i=0; i<data.children.length; i++)
                this.updateJSONNode(data.children[i],nodeData,recordId);
        }
    },
    /*
     * function name : openContactModal
     * parameters    : none
     * return value  : none
     * description   : opens the contact modal on "Add/Edit" action
     */
    openContactModal : function(component){
        //open Modal
        component.set("v.openContactModal", true);
        //make modal header override salesforce navigation bar
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
    },
    /*
     * function name : closeContactModal
     * parameters    : none
     * return value  : none
     * description   : closes contact modal on "Cancel/Save", resets standard salesforce navbar styling
     */
    closeContactModal : function(component){
        var clearedContactId = component.get("v.clearedContactId");
        if(clearedContactId){
            var contactList = component.get("v.contactList");
            if(!contactList)
                contactList = [];
            contactList.push(clearedContactId);
            component.set("v.contactList", contactList);
            //clear value in clearedContactId field, to avoid inconsistency
            component.set("v.clearedContactId", "");
        }
        component.set("v.openContactModal", false);
        component.set("v.selectedTabId", "existingContactTab");
        //reset salesforce navigation bar css settings
        component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
    },
    /*
     * function name : deleteNode
     * parameters    : none
     * return value  : none
     * description   : deletes the node from the map as well as from the json, if entire map is deleted shows plus button
     */
    deleteNode : function(component, event){
        var orgChart = this.orgChart;
        var node = this.clickEvent;

        orgChart.removeNodes(node);
        //$(event.target.parentElement).val("").data("node", "");
        this.orgChart = orgChart;
        var recordId = component.get("v.nodeData.objInfluenceMap.Id");
        component.set("v.nodeData", {});
        if(this.dataSource.objInfluenceMap.Id == recordId){
            this.dataSource = {};
        	this.showPlusButton(component);
        }
        else{
            this.deleteJSONNode(this.dataSource, recordId);
        }
        this.closeDeleteModal(component);
    },
    /*
     * function name : goBackToRecord
     * parameters    : none
     * return value  : none
     * description   : takes the user back to the record from where the map was opened
     */
    goBackToRecord : function(component){
    	var recId = this.metaData.sObjectId;
        var backEvent = $A.get("e.force:navigateToSObject");
        backEvent.setParams({
            recordId: recId,
            isRedirect: true,
            slideDevName: "detail"
        });
        backEvent.fire();
    },
    /*
     * function name : setComponentVariables
     * parameters    : none
     * return value  : none
     * description   : it populates required data in the component when the map data is received from the backend
     */
    setComponentVariables : function(component){
        if(this.metaData){
            component.set("v.metaData", this.metaData);
        }
        if(this.dataSource){
            var contactList = [];
            this.populateContactList(this.dataSource, contactList);
            component.set("v.contactList", contactList);
        }
    	//component.set("v.isInitialized", true);
    },
    /*
     * function name : setHelperVariables
     * parameters    : none
     * return value  : none
     * description   : populates helper variables using the data received from the backend for easy access at any stage
     */
    setHelperVariables : function(response){
        //populating metaData & dataSource
        this.metaData.sObjectId = response.sObjectId;
        this.metaData.accountId = response.accountId;
        this.metaData.parentAccountId = response.parentAccountId;
        this.metaData.strSObjectName = response.strSObjectName;
        this.metaData.strSObjectType = response.strSObjectType;
        this.metaData.buyingRoleList = response.listBuyingRole;
        this.metaData.statusList = response.listStatus;
        this.metaData.focusList = response.listFocus;
        this.metaData.contactLevelList = response.listContactLevel;
        this.metaData.countryList = response.listCountry;
        this.metaData.hasAccountEditAccess = response.hasAccountEditAccess;

        this.dataSource = response.data;
        // save focus picklist values in local variables for quick access during add/edit operations
        for(var i=0; i<this.metaData.focusList.length; i++){
            this.focusValues.push(this.metaData.focusList[i].strValue);
            this.focusApis.push(this.metaData.focusList[i].strApi);
            this.focusChars.push(this.metaData.focusList[i].strChar);
        }
        //change values for Contact Level list for easy access
        for(var i=0; i<this.metaData.contactLevelList.length; i++){
            if(this.metaData.contactLevelList[i].strApi == "High")
            	this.metaData.contactLevelList[i].strApi = "100%";
            else if(this.metaData.contactLevelList[i].strApi == "Medium")
            	this.metaData.contactLevelList[i].strApi = "66.67%";
            else if(this.metaData.contactLevelList[i].strApi == "Low")
            	this.metaData.contactLevelList[i].strApi = "33.33%";
        }
        this.buyingRoleList = this.metaData.buyingRoleList;
        this.statusList = this.metaData.statusList;
        this.focusList = this.metaData.focusList;
        this.contactLevelList = this.metaData.contactLevelList;
        this.metaData.filterList = this.filterList;

    },
    /*
     * function name : showPlusButton
     * parameters    : none
     * return value  : none
     * description   : if no map data is received from the backend, then show plus button
     */
    showPlusButton : function(component){
        component.set("v.showPlusButton", true);
        //hide spinner
        component.set("v.mapSpinnerClass", "slds-hide");
        //show additional button "Fetch from Account" on Opportunity object if no map data is received
        if(this.metaData.strSObjectType == "Opportunity")
            component.set("v.isOpportunityObject", "true");
        else
            component.set("v.isOpportunityObject", "false");
    },
    /*
     * function name : hidePlusButton
     * parameters    : none
     * return value  : none
     * description   : hides plus button after first node is added on the page. (plus button is hidden by default)
     */
    hidePlusButton : function(component){
        component.set("v.showPlusButton", false);
    },
    /*
     * function name : redirectToSelectedContact
     * parameters    : none
     * return value  : none
     * description   : Opens selected Contact's detail page in a new tab
     */
    redirectToSelectedContact : function(component, event){
        var recId = event.target.parentElement.parentElement.parentElement.getAttribute("id");
        //object is passed to functions as reference, variables are passed by value
        var contact = {};
        this.getContactId(this.dataSource,recId,contact);
        window.open("/"+contact.Id, "_blank");
        /*var redirect = $A.get("e.force:navigateToURL");
        redirect.setParams({
            url: "/"+contact.id
        });
        redirect.fire();
        */
        /*
        var redirectEvent = $A.get("e.force:navigateToSObject");
        redirectEvent.setParams({
            recordId: contact.id,
            isRedirect: true,
            slideDevName: "detail"
        });
        redirectEvent.fire();
        */
    },
    /*
     * function name : getContactId
     * parameters    : dataSOurce (json data), recordId (node's Id for which contact's Id is to be fetched from json), contact(object in which Id will be populated)
     * return value  : none
     * description   : retreives contact Id from the json for the node on which the user has clicked to see contact record
     */
    getContactId : function(dataSource, recordId, contact){
        if(!dataSource)
            return;
        if(dataSource.objInfluenceMap.Id == recordId){
            //console.log("objContact : ", dataSource.objContact);
            contact.Id = dataSource.objContact.Id;
            return;
        }
        else if(dataSource.children){
            for(var i=0; i<dataSource.children.length; i++)
                this.getContactId(dataSource.children[i], recordId, contact);
        }
    },
    /*
     * function name : openDeleteModal
     * parameters    : none
     * return value  : none
     * description   : open the delete modal when user clicks on any node's delete icon
     */
    openDeleteModal : function(component, event){
        component.set("v.showDeleteModal", "true");
        //get node's Id from the DOM structure
        var recordId = event.target.parentElement.parentElement.parentElement.attributes[0].textContent;
        //saving recordId for easy reference in deleteNode function
        var nodeData = {};
        nodeData.objInfluenceMap = nodeData.objContact = {};
        nodeData.objInfluenceMap.Id = recordId;
        component.set("v.nodeData", nodeData);
        //for reference in deleteNode function
        this.clickEvent = $(event.target.parentElement);
        if(recordId == this.dataSource.objInfluenceMap.Id){
            component.set("v.deleteModalMessage", "Do you want to delete entire map?");
        }
        else{
            component.set("v.deleteModalMessage", "Do you want to delete record?");
        }
    },
    /*
     * function name : closeDeleteModal
     * parameters    : none
     * return value  : none
     * description   : closes the delete modal, when a user cancels action, or confirms delete action
     */
    closeDeleteModal : function(component){
        component.set("v.showDeleteModal", "false");
        component.set("v.deleteModalMessage", "");
    },
    /*
     * function name : deleteJSONNode
     * parameters    : none
     * return value  : none
     * description   : delete node's data from the json when a user confirms delete action
     */
    deleteJSONNode : function(dataSource,recordId){
		if(!dataSource)
            return;
        if(dataSource.children){
            for(var i=0; i<dataSource.children.length; i++){
                // delete node and reindex remaining sibilings (if any)
                if(dataSource.children[i].objInfluenceMap.Id == recordId){
                    dataSource.children.splice(i,1);
                    return;
                }
                else
                    this.deleteJSONNode(dataSource.children[i], recordId);
            }
        }
    },
    /*
     * function name : validInfluenceMapData
     * parameters    : none
     * return value  : true/false
     * description   : checks for data values of the "Exiting Contact" Tab
     */
    validInfluenceMapData : function(component) {
		var contactName = component.get("v.nodeData.objContact.Name");
        var contactBuyingRole = component.get("v.nodeData.objInfluenceMap.Buying_Role__c");
        var contactStatus = component.get("v.nodeData.objInfluenceMap.Status__c");
        var contactFocus = component.get("v.nodeData.objInfluenceMap.Focus__c");
        var contactLevel = component.get("v.nodeData.objInfluenceMap.Level_of_Contact__c");

        if(!contactName || !contactBuyingRole || !contactStatus || !contactFocus || !contactLevel){

            if(!contactName)
                this.showToastMessage(component, "error", "Contact Name can't be empty");
            else if(!contactBuyingRole)
                this.showToastMessage(component, "error", "Buying Role can't be empty");
            else if(!contactStatus)
                this.showToastMessage(component, "error", "Status can't be empty");
            else if(!contactFocus)
                this.showToastMessage(component, "error", "Focus can't be empty");
            else if(!contactLevel)
                this.showToastMessage(component, "error", "Level of Interaction can't be empty");

            return false;
        }
        return true;
	},
    /*
     * function name : onModalSave
     * parameters    : none
     * return value  : none
     * description   : assigns recordId & parentId field for the newly created nodes,
     * 				   to uniquely identify nodes for edit/delete action at a later stage
     */
    onModalSave : function(component){
        if(component.get("v.eventName") == "Add"){
            var nodeData = component.get("v.nodeData");
            var recordId = nodeData.objInfluenceMap.Id;
            var parentId = "";
            if(nodeData.objInfluenceMap.Parent_Influencer__c)
                parentId = nodeData.objInfluenceMap.Parent_Influencer__c;
            //if first node is being added, then recordId & parentId both needs to be set
            if(!parentId && !recordId){
                //Id length more than 18, parentId will remain blank
                component.set("v.nodeData.objInfluenceMap.Id", "123456789123456789" + Math.floor(Math.random()*1000));
                component.set("v.nodeData.objInfluenceMap.Parent_Influencer__c", "");
            }
            else if(parentId && !recordId){
                component.set("v.nodeData.objInfluenceMap.Id", parentId + Math.floor(Math.random()*1000));
            }
        }
    },
    /*
     * function name : saveInfluenceMap
     * parameters    : none
     * return value  : none
     * description   : adds new node/ updates existing node on map as well as in the json,
     * 					when a user clicks save on the modal
     */
    saveInfluenceMap : function(component){
        //reset clearedContacId field
        component.set("v.clearedContactId", "");
        //event called by modal component & event name is add
        if(component.get("v.eventName") === "Add"){
            //adding first node
            if(!this.dataSource || !this.dataSource.objInfluenceMap){
                this.addNewNode(component,{});
            }
            else{
                //to reach div.node (the top node)
                var node = $(this.clickEvent.target.parentElement.parentElement.parentElement.parentElement.parentElement);
                this.addNewNode(component, node);
                this.updateJSON(component, "Add");
            }
        }
        else if(component.get("v.eventName") === "Edit"){
            //update Contact__c Id in objInfluence based on updated Contact
            var nodeData = component.get("v.nodeData");
            nodeData.objInfluenceMap.Contact__c = nodeData.objContact.Id;
            component.set("v.nodeData", nodeData);
            var node = $(this.clickEvent.target.parentElement.parentElement.parentElement);
            this.updateNode(component, node);
            this.updateJSON(component, "Edit");
        }
        this.closeContactModal(component);
    },
    /*
     * function name : populateContactList
     * parameters    : none
     * return value  : none
     * description   : executes after map data is received from the backend,
     *                 contactList is used to avoid duplicate contact records on the map
     */
    populateContactList : function(dataSource, contactList){
        if(!dataSource)
            return;
        if(dataSource.objContact){
            contactList.push(dataSource.objContact.Id);
            if(dataSource.children){
                for(var i=0; i<dataSource.children.length; i++)
                    this.populateContactList(dataSource.children[i], contactList);
            }
        }
    },
    /*
     * function name : clearLookupField
     * parameters    : none
     * return value  : none
     * description   : invokes lookup component method to clear the lookup field when the user changes Account Filter picklist
     */
    clearLookupField : function(component){
        component.set("v.nodeData.objContact", {});
        var lookupComponent = component.find("lookupComponent");
        lookupComponent.clearFromParent();
    },
    /*
     * function name : updateContactList
     * parameters    : none
     * return value  : none
     * description   : updates the contact list, whenever a contact is added/updated using the lookup field,
     * 					to prevent duplicate contact in lookup result
     */
    updateContactList : function(component, event){
        var contactList = component.get("v.contactList");

        if(event === "Delete"){
            //when entire map data is deleted
            if(!this.dataSource || !this.dataSource.objInfluenceMap){
                component.set("v.contactList", []);
                return;
            }
            if(!contactList)
                return;
            var recordId = component.get("v.nodeData.objInfluenceMap.Id");
            //contact obj Id field will be populated in "getContactId" function
            var contact = {};
            this.getContactId(this.dataSource, recordId, contact);
            this.removeSelectedContact(component, contact);
        }
        // called from modalSave component method, after a node has been inserted/updated
        else if(event === "Save"){
            if(!contactList)
                contactList = [];
            contactList.push(component.get("v.nodeData.objContact.Id"));
            component.set("v.contactList", contactList);
        }
        //console.log("infMap contactList : ", contactList);
    },
    /*
     * function name : prepareFinalData
     * parameters    : jsonData (old json data), hierarchyData (the hierrachy structure of current map structure)
     * 					parentId (the node that's at the top of the map)
     * return value  : none
     * description   : prepares final json structure using old json data and the current hiereachy of nodes on the map
     * 					if the user has changed the node structure, reparanting is done here,
     * 					so that same structure can be retreived on next load
     */
    prepareFinalData : function(jsonData, hierarchyData , parentId){
        if(!hierarchyData)
            return;

        this.getDataFromDataSource(this.dataSource, jsonData, hierarchyData.id, parentId);
        if(hierarchyData.children){
            for(var i=0; i<hierarchyData.children.length; i++){
                var child = {};
                jsonData.children.push(child);
                this.prepareFinalData(child, hierarchyData.children[i], hierarchyData.id);
            }
        }
    },
    /*
     * function name : getDataFromDataSource
     * parameters    : dataSource (old json data), jsonData (new json data), recordId(the current node's Id), parentId (variable to store Id of the new parent)
     * return value  : none
     * description   : copies data from old json to new json and assign new parent's Id to the current node
     */
    getDataFromDataSource : function(dataSource, jsonData, recordId, parentId){
        if(!dataSource)
            return;

        if(dataSource.objInfluenceMap.Id == recordId){
            jsonData.objInfluenceMap = dataSource.objInfluenceMap;
            jsonData.objInfluenceMap.Parent_Influencer__c = parentId;
            jsonData.objContact = dataSource.objContact;
            //no need to copy intAccountFilter variable, it's not stored in the object
            jsonData.children = [];
            return;
        }
        else if(dataSource.children){
            for(var i=0; i<dataSource.children.length; i++)
                this.getDataFromDataSource(dataSource.children[i], jsonData, recordId, parentId);
        }
    },
    /*
     * function name : finalSaveAction
     * parameters    : jsonData (new json data)
     * return value  : none
     * description   : calls apex method to save the map values in the Object, shows a success/failure message
     */
    finalSaveAction : function(component, jsonData){
        console.log("jsonData: ", jsonData);
        var action = component.get("c.saveInfluenceMapRec");
        action.setParams({
            "jsonValue" : JSON.stringify(jsonData),
            "recordId" : this.metaData.sObjectId
        });
        action.setCallback(this, function(response){
            //hide spinner
        	component.set("v.mapSpinnerClass", "slds-hide");
            var state = response.getState();
            if(state === "SUCCESS"){
                //alert("Data Saved");
                this.showToastMessage(component, "success", "Data saved successfully");
            }
            else{
                this.showToastMessage(component, "error", "Internal Error happened while saving records, please contact Administrator");
            }
        });
        $A.enqueueAction(action);
    },
    /*
     * function name : linkRecordWithAccountOpportunity
     * parameters    : none
     * return value  : none
     * description   : checks if the map has been opened from account/opportunity/contact,
     * 					updates corresponding values accordingly for correct mapping.
     * 					Critical for "Fetch from Account" scenario
     */
    linkRecordWithAccountOpportunity : function(component){
        var nodeData = component.get("v.nodeData");
        if(this.metaData.strSObjectType === "Opportunity")
        	nodeData.objInfluenceMap.Opportunity__c = this.metaData.sObjectId;
        else if(this.metaData.strSObjectType === "Account")
        	nodeData.objInfluenceMap.Account__c = this.metaData.sObjectId;
        else if(this.metaData.strSObjectType === "Contact")
        	nodeData.objInfluenceMap.Account__c = this.metaData.accountId;
		nodeData.objInfluenceMap.Contact__c = nodeData.objContact.Id;
        component.set("v.nodeData", nodeData);
    },
    /*
     * function name : showToastMessage
     * parameters    : toastType -> success/error/info/warning, toastMessage -> message to be displayed
     * return value  : none
     * description   : displays message in the event of success/failure of an action involving apex call
     */
    showToastMessage : function(component, toastType, toastMessage){
        var showToastEvent = $A.get("e.force:showToast");
        showToastEvent.setParams({
            type: toastType,
            message: toastMessage,
            mode: "dismissible"
        });
        showToastEvent.fire();
	},
    /*
     * function name : validContactData
     * parameters    : none
     * return value  : true/false
     * description   : checks for data values of the "New Contact" tab, when user clicks "Save" on the modal
     */
    validContactData: function(component){
        var contact = component.get("v.contact");
        if(!contact.FirstName || !contact.LastName || !contact.Title || !contact.Email || !contact.Phone || !contact.MailingState || !contact.MailingCountry || !contact.MailingPostalCode){
            if(!contact.FirstName)
                this.showToastMessage(component, "error", "First Name can't be empty");
            else if(!contact.LastName)
                this.showToastMessage(component, "error", "Last Name can't be empty");
            else if(!contact.Title)
                this.showToastMessage(component, "error", "Title can't be empty");
            else if(!contact.Email)
                this.showToastMessage(component, "error", "Email can't be empty");
            else if(!contact.Phone)
                this.showToastMessage(component, "error", "Phone can't be empty");
            else if(!contact.MailingState)
                this.showToastMessage(component, "error", "State can't be empty");
            else if(!contact.MailingCountry)
                this.showToastMessage(component, "error", "Country can't be empty");
            else if(!contact.MailingPostalCode)
                this.showToastMessage(component, "error", "Zip Code can't be empty");
            return false;

        }
        return true;
    },
    /*
     * function name : insertNewContact
     * parameters    : none
     * return value  : none
     * description   : inserts new contact in the Object when user clicks on "Save" on the modal.
     * 					update values in the component variables, switches tab upon success
     */
    insertNewContact : function(component){
        var contact = component.get("v.contact");
        contact.AccountId = component.get("v.metaData.accountId");
        var action = component.get("c.createContact");
        component.set("v.modalSpinnerClass", "");
        action.setParams({
            "objCon" : contact
        });
        action.setCallback(this,function(response){
           var state = response.getState();
            if(state === "SUCCESS"){
                contact = response.getReturnValue();
                //console.log("returned contact : ", contact);
                component.set("v.nodeData.objContact", contact);
                component.set("v.nodeData.objInfluenceMap.Contact__c", contact.Id);
                component.set("v.contact", {});
                //component.set("v.selectedContact", contact);
                component.set("v.selectedTabId", "existingContactTab");
                //intAccountFilter -> 0, as contact can only be added for Current Account
            	component.set("v.nodeData.intAccountFilter", 0);
                //contactList will be updated only on save action from "Existing Contact" Tab
                this.showToastMessage(component, "success", "New contact created, Please enter additional details");
            }
            else{
                this.showToastMessage(component, "error", "Contact couldn't be inserted");
            }
			component.set("v.modalSpinnerClass", "slds-hide");
        });
        $A.enqueueAction(action);
    },
    /*
     * function name : toggleLegendDiv
     * parameters    : none
     * return value  : none
     * description   : show/hide legend, change icon & text on button upon alternate button clicks
     */
    toggleLegendDiv: function(component){
        
        var legendDiv = component.find("legendDiv");
        var legendDivElem = legendDiv.elements[0];
        
        var display = $(legendDivElem).css("display");
        if(display === "none"){
            $(legendDivElem).slideDown("slow");
            jQuery("#toggleDisplayDiv>i").removeClass("fa-arrow-up").addClass("fa-arrow-down");
        }
        else{
            $(legendDivElem).slideUp("slow");
            jQuery("#toggleDisplayDiv>i").removeClass("fa-arrow-down").addClass("fa-arrow-up");

        }
		
    },
    /*
     * function name : checkSelectedValues
     * parameters    : pickList -> picklist whose value has to be set/reset
     * return value  : none
     * description   : resets other selected values if selected options includes "All"
     */
    checkSelectedValues : function(component, pickList){
        var selectedValues = pickList.get("v.value");

        //holds true if multiple values including "All" has been selected
        if(selectedValues.includes("All;"))
            pickList.set("v.value", "All");
    },
    /*
     * function name : createMapFromAccountData
     * parameters    : none
     * return value  : none
     * description   : calls backend method to get map data based on picklist values & backend records for related Account
     */
    createMapFromAccountData : function(component){
		//component.set("v.modalSpinnerClass", "");
        var buyingRoleMultiPickList = [];
        var statusMultiPickList = [];
        var focusMultiPickList = [];
        var contactLevelMultiPickList = [];
        this.populateMultiPickListValues(component, buyingRoleMultiPickList, "buyingRoleMutliPickList", "buyingRoleList");
        this.populateMultiPickListValues(component, statusMultiPickList, "statusMutliPickList", "statusList");
        this.populateMultiPickListValues(component, focusMultiPickList, "focusMutliPickList", "focusList");
        this.populateMultiPickListValues(component, contactLevelMultiPickList, "contactLevelMutliPickList", "contactLevelList");
        if(statusMultiPickList.length >0 && buyingRoleMultiPickList.length >0 && focusMultiPickList.length >0 && contactLevelMultiPickList.length >0){
			var action = component.get("c.fetchInfRecFromAccount");
			action.setParams({
				recordId: this.metaData.sObjectId,
				acctId: this.metaData.accountId,
				statusPickList : statusMultiPickList,
				buyingRolePickList : buyingRoleMultiPickList,
				focusPickList : focusMultiPickList,
				levelOfContactPicklist : contactLevelMultiPickList
			});
			action.setCallback(this, function(response){
				var state = response.getState();
				if(state === "SUCCESS"){
					console.log('fetch from account response : ', response.getReturnValue());
                    var returnValue = response.getReturnValue();
                    if(returnValue){
                        if(returnValue.data && returnValue.data.objInfluenceMap){
                            this.dataSource = returnValue.data;
                            var contactList = [];
                            this.populateContactList(this.dataSource, contactList);
                            component.set("v.contactList", contactList);
                            component.set("v.showFetchFromAccountModal", false);
                            this.hidePlusButton(component);
                            this.renderMapOnPage(component);
                        }
                        else if(returnValue && returnValue.strError){
                            this.showToastMessage(component, "error", returnValue.strError);
                        }
                        else{
                        	this.showToastMessage(component, "error", "Internal error. Please contact Administrator");
                        }
                    }
                    else{
                        this.showToastMessage(component, "error", "Internal error. Please contact Administrator");
                    }
				}
				component.set("v.modalSpinnerClass", "slds-hide");
			});
			$A.enqueueAction(action);
		}
        else{
			this.showToastMessage(component, "error", "One or more filter criteria not selected");
		}
    },
    /*
     * function name : populateMultiPickListValues
     * parameters    : none
     * return value  : none
     * description   : prepares the list to be sent to the apex method depending on all the seelcted picklist values
     */
    populateMultiPickListValues : function(component, lstValues, pickListName, picklistMetadataName){
        var pickList = component.find(pickListName);
        var pickListValuesSelected = pickList.get("v.value");

        var pickListValues = this.metaData[picklistMetadataName];

        if(pickListValuesSelected == "All"){
            if(picklistMetadataName != "contactLevelList"){
                for(var i=0; i<pickListValues.length; i++){
                    lstValues.push(pickListValues[i].strApi);
                }
            }
            //contacteLeveList -> strApi has values like 100%, 66.67% to quickly change width on the map
            else{
                for(var i=0; i<pickListValues.length; i++)
                    lstValues.push(pickListValues[i].strValue);
            }
        }
        else{
            var values = pickListValuesSelected.split(";");
			for(var i=0; i<values.length; i++){
				lstValues.push(values[i]);
			}

        }
    },
    /*
     * function name : removeSelectedContact
     * parameters    : none
     * return value  : none
     * description   : removes the Id of selected node's Contact from v.contactList,
     * 				   when a user open Contact Modal to edit record and then switched to New Contact Tab or deletes a node
     */
    removeSelectedContact : function(component, contact){
        var contactList = component.get("v.contactList");
        if(contactList){
            for(var i=0; i<contactList.length; i++){
                if(contact.Id == contactList[i]){
                    contactList.splice(i,1);
                    component.set("v.contactList", contactList);
                    break;
                }
            }
        }
    },
    /*
     * function name : adjustMapHeaderHeight
     * parameters    : none
     * return value  : none
     * description   : sets the position of the Influence Map Header immediately after Salesforce navigation bar
     */
    adjustMapHeaderHeight : function(component){
        var systemMessage = document.getElementsByClassName("system-message")[0];
        var componentDiv = component.find("componentDiv").elements[0];
        var dataSource = this.dataSource;
        var innerText;
        if(systemMessage)
            innerText = systemMessage.innerText;
        
        // when in STandav/SIT/QA/Production(logged in as another user)
        if(innerText !== undefined && innerText !== ""){
            $(componentDiv).css("top", "130px");
        	$(".oc-export-btn").css("top", "150px");
        }
        //when in Production (without additional header)
        else if(innerText === undefined  || innerText === ""){
            $(componentDiv).css("top", "90px");
        	$(".oc-export-btn").css("top", "110px");
        }    
    }
 })