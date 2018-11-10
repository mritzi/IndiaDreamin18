({
	/*******************************************************************************
     **** Intialization function to get the data.
     ********************************************************************************/
	doInit: function(component, event, helper) {
		helper.initialfunction(component,event,helper);
        
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Hide and show the details section of stage.
     ********************************************************************************/
	sectionOne: function(component, event, helper) {

		var acc = component.find('articleOne');
		var sectiondetails = component.find('sectiondetails');
		for (var cmp in acc) {
			$A.util.toggleClass(acc[cmp], 'slds-show');
			$A.util.toggleClass(acc[cmp], 'slds-hide');
		}
		$A.util.toggleClass(sectiondetails, 'slds-hide');
		$A.util.toggleClass(sectiondetails, 'slds-show');

		if (component.get('v.activeStage') != component.get('v.selectedstage')) {
            var sectiondetail = component.find("Overlay");
            $A.util.removeClass(sectiondetail, 'slds-hide');
            $A.util.addClass(sectiondetail, 'slds-show');
        } else {
            var sectiondetail = component.find("Overlay");
            $A.util.removeClass(sectiondetail, 'slds-show');
            $A.util.addClass(sectiondetail, 'slds-hide');
        }
	},


	/**************************End******************************************/

	/*******************************************************************************
     **** Select a stage and show the details of the stage 
     ********************************************************************************/
	selectstage: function(component, event, helper) {
		helper.selectedstageFunction(component, event, helper);
	},
	/**************************End******************************************/
	/*******************************************************************************
     **** Save the Recomende task 
     ********************************************************************************/

	saveTask: function(component, event, helper) {
        helper.showSldsSpinner(component);
		helper.saveRecomendedTasks(component,event,helper);
	},
	/**************************End******************************************/

	/*******************************************************************************
     **** Save the outcome value and update the stage details.
     ********************************************************************************/

	savecheckbox: function(component, event, helper) {
		helper.saveOutcomeTasks(component, event, helper);
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** function to move the next stage on click of the Mark as current stage Button.
     ********************************************************************************/

	
	markOppstage: function(component, event, helper) {
		
		helper.saveNewstage(component,helper);
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** function to move the next stage on click of the ready to move next stage button
     ********************************************************************************/
	markNewstage: function(component, event, helper) {
		 helper.helperMoveToNextStage(component,helper);
    
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Function to close the ClosedStageModal
     ********************************************************************************/
	closemodal: function(component, event, helper) {
		var modalpanel = component.find('closemodalsection');
		$A.util.removeClass(modalpanel, 'slds-show');
		$A.util.addClass(modalpanel, 'slds-hide');
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Function to close the errormodal
     ********************************************************************************/
	closeErrormodal: function(component, event, helper) {
		var errormodalnew = component.find('errormodal');
		$A.util.toggleClass(errormodalnew, 'slds-show');
		$A.util.toggleClass(errormodalnew, 'slds-hide');
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** On selcting of the closed stage this function will be called.
     ********************************************************************************/
	chooseclosestage: function(component, event, helper) {
		var modalpanel = component.find('closemodalsection');
		$A.util.toggleClass(modalpanel, 'slds-show');
		$A.util.toggleClass(modalpanel, 'slds-hide');
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Modal to close the edit panel
     ********************************************************************************/
	closeEditModal: function(component, event, helper) {
		var cmpTarget = component.find('Modalbox');
		var cmpBack = component.find('Modalbackdrop');
		$A.util.removeClass(cmpBack, 'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Open the edit panel of key field 
     ********************************************************************************/
	openEditmodal: function(component, event, helper) {
		helper.getRecord(component);
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** Save the new Opportunity values updated through Edit key field section
     ********************************************************************************/
	saveOpportunityData: function(component, event, helper) {
		helper.saveOpp(component,helper);
		var cmpTarget = component.find('Modalbox');
		var cmpBack = component.find('Modalbackdrop');
		$A.util.removeClass(cmpBack, 'slds-backdrop--open');
		$A.util.removeClass(cmpTarget, 'slds-fade-in-open');
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** onchange function to catch the new values of edit field section
     ********************************************************************************/
	handlePress : function(component, event, helper) {
         helper.editOnchange(component, event, helper);
    },
    /**************************End******************************************/
	
	/*******************************************************************************
     **** Catch the new value of custom lookup component
     ********************************************************************************/
	handleComponentEvent: function(component, event, helper) {
		// Method to catch lookupsave
		helper.saveLookup(component, event);
	},
	/**************************End******************************************/
	
	/*******************************************************************************
     **** On select of the closed stage picklist
     ********************************************************************************/
	onSelectChange: function(component, event, helper) {
		helper.checkKeyfields(component,helper);
	},
    /**************************End******************************************/
    
    
	/*******************************************************************************
     **** To change the style on hover of the outcome value.
     ********************************************************************************/
	highliteText: function(component, event, helper) {
		event.currentTarget.classList.add("hightliteText");

	},



})