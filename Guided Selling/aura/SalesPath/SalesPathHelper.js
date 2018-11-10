({
    /*******************************************************************************
     **** Initial function 
     **** This function will help get data from server on loading of the page.
     ********************************************************************************/
    initialfunction: function(component,event,helper){
        // show the spinner on page loading
        helper.showSldsSpinner(component);
        var checkDoInit = component.get("v.doInitCall");
        // checking the checkDoInit value.
        if (checkDoInit == true) {
            component.set("v.doInitCall", false);
            //hide the spinner
            helper.hideSldsSpinner(component);
            return;

        }
        // Calling the server side contrller to get the data
        var action = component.get("c.createSalesWrapper");
        // find the record Id to call the server side controller
        var stringId = component.get('v.recordId');
        action.setParams({
            oppId: stringId
        });
        //storing in the client cache
        //action.setStorable();
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                //  calling SetcomponentValues method to set aura attribute values
                if(a.getReturnValue() != null && a.getReturnValue() != undefined){
                    // Setting component values
                    component.set('v.SalespathWrapperNew',a.getReturnValue());
                    console.log('data------',a.getReturnValue());
                    helper.setcomponentValues(component,helper,a.getReturnValue());
                    
                    //display lastProgressButton
                    if(a.getReturnValue().lstStage !== undefined && a.getReturnValue().lstStage.length > 0)
                    	$A.util.removeClass(component.find("lastProgressButton"), 'slds-hide');
                }
                
            } else if (a.getState() === "ERROR") {
                // hide the spinner
                helper.hideSldsSpinner(component);
                console.log('Errors----');
                $A.log("Errors", a.getError());
            }

        });
        $A.enqueueAction(action);
        
    },
    /**************************End******************************************/
    /*******************************************************************************
     **** Show the Ready to move next stage button or Warning message based on the conditions.
     ********************************************************************************/
    showReadyToMoveButton : function(component,helper){
        // Fetching all the values from componenet to set the button visibility
        var activeStage = component.get('v.activeStage');
        var selectedstage = component.get('v.selectedstage');
        var indexval = component.get('v.index');
        var outcomewrapper = component.get("v.OutcomeWrapper");
        var keywrapper = component.get("v.lstKeyWrapper");
        var mapSalesPathDataWrapper = component.get("v.SalespathWrapper");
        // setting zero to calculate the progressbar value
        var progressval = 0.00;
        var total = 0.00;
        var checkfilled = false;
        if (mapSalesPathDataWrapper != undefined && mapSalesPathDataWrapper.length > 0 && mapSalesPathDataWrapper[indexval] != null && mapSalesPathDataWrapper[indexval].total != null) {
            total = mapSalesPathDataWrapper[indexval].total + total;
        }
        // checking all the keyfields were filled or not for the visibility of 'Ready to move next ' button.
        if (keywrapper != null && keywrapper.length > 0) {
            for (var j = 0; j < keywrapper.length; j++) {
                
                if (keywrapper[j].fieldValue != '' && keywrapper[j].fieldValue != null) {
                    checkfilled = true;
                } else {
                    checkfilled = false;
                    break;
                }
            }
        } else {
            checkfilled = true;
        }
        // checking the outcomes were completed or not for the visibility of 'Ready to move next ' button.
        if (outcomewrapper != null && outcomewrapper.length > 0) {
            // setting the gated task completed as false
            var isgated = false;
            var outcomeCompleted = false;
            for (var j = 0; j < outcomewrapper.length; j++) {
                if (outcomewrapper[j].isGatedTask) {
                    if (outcomewrapper[j].completed) {
                        // if gated task is completed the value of isgated changed to true
                        isgated = true;
                        outcomeCompleted = true;
                        // calculating progress value.
                        progressval = progressval + outcomewrapper[j].percentage;

                    } else {
                        outcomeCompleted = false;
                        break;
                    }
                } else {
                    if (outcomewrapper[j].completed) {
                        progressval = progressval + outcomewrapper[j].percentage;
                        outcomeCompleted = true;
                    } else {
                        outcomeCompleted = false;
                        break;
                    }
                }
            }
        }
        if(activeStage ==selectedstage ){
        // Assigning render condition for buttons based on the outcome and keyfield values.
            if (outcomeCompleted) {
                if (checkfilled) {
                    if (selectedstage.includes('Closed')) {
                        component.set("v.Messageshownot", false);
                        component.set("v.Messageshow", false);
    
                    } else {
    
                        if (activeStage == selectedstage){
                            component.set("v.Messageshownot", true);
                            component.set("v.Messageshow", false);
                             var sectiondetail = component.find("Overlay");
                            $A.util.removeClass(sectiondetail, 'slds-hide');
                            $A.util.addClass(sectiondetail, 'slds-show');
                        }
                        else{
                            component.set("v.Messageshownot", false);
                            component.set("v.Messageshow", false);
                            var sectiondetail = component.find("Overlay");
                            $A.util.removeClass(sectiondetail, 'slds-show');
                            $A.util.addClass(sectiondetail, 'slds-hide');
                        }
                    }
                } else {
                    component.set("v.Messageshownot", false);
                    component.set("v.Messageshow", true);
                }
            } else {
                component.set("v.Messageshownot", false);
                component.set("v.Messageshow", false);
            }
        }else{
            component.set("v.Messageshownot", false);
            component.set("v.Messageshow", false);
        }

    helper.hideSldsSpinner(component);
    },

    /**************************End******************************************/

    /*******************************************************************************
     **** Storing the server side data in to the aura component.
     ********************************************************************************/
    setcomponentValues : function(component,helper,data){
        
        if(data != null && data != undefined){
            component.set("v.SalespathWrapperNew", data);
            var SalespathDatawrapper = [];
            var stages = data.lstStage;
            var datamap = data.mapSalesPathDataWrapper;
            // creating List of salesPathdatawrapper value from the map.
            for (var i = 0; i < stages.length; i++) {
                SalespathDatawrapper.push(datamap[stages[i]]);
            } 
            // saving salesPath stage values to aura.
            component.set("v.lstStage", stages);
            // saving salesPathdatwrapper values to aura.
            component.set("v.SalespathWrapper", SalespathDatawrapper);
            // Saving dealdoctor values
            if(data.mapSalesPathDataWrapper != null){
                component.set("v.wrappermap", data.mapSalesPathDataWrapper);
            }
            if( data.Oppobject != null){
                component.set("v.Opportunity", data.Oppobject);
            }
            // Show the buttons on salesPath
            
            
            
            // saving the current and active stage
            if(data.activeStage != null){
                if(component.get("v.selectedstage") ==null){
                   component.set("v.selectedstage", data.activeStage);
                }
                
                component.set("v.activeStage", data.activeStage);
                
                // Saving all the keyfieldwrapper,outcomewrapper,dealdocTaskWrapper,salestipwrapper and taskwrapper for the active stage.
                if(data.lstDealDocWrapper != null){
                    component.set('v.dealdocTaskWrapper', data.lstDealDocWrapper);
                } else {
                    component.set('v.dealdocTaskWrapper', []);
                }
                var stageval = data.activeStage;
                if (stageval.includes("Closed")) {
                    stageval = '10 - Closed - Won';
                    component.set('v.showmark', false);
                    component.set('v.showclose', true);
                } else {
                    component.set('v.showmark', true);
                    component.set('v.showclose', false);
                }
                if(data.mapSalesPathDataWrapper != null && data.mapSalesPathDataWrapper[stageval] != null && stageval != null){
                    if (data.mapSalesPathDataWrapper[stageval].lstKeyWrapper != null) {
                        component.set("v.lstKeyWrapper", data.mapSalesPathDataWrapper[stageval].lstKeyWrapper);
                    }
                    if (data.mapSalesPathDataWrapper[stageval].index != null ) {
                        component.set("v.index", data.mapSalesPathDataWrapper[stageval].index);
                    }
                    if (data.mapSalesPathDataWrapper[stageval].fieldsetName != null) {
                        component.set("v.fieldset", data.mapSalesPathDataWrapper[stageval].fieldsetName);
                    }
                    if (data.mapSalesPathDataWrapper[stageval].lstOutComeWrapper != null) {
                        component.set("v.OutcomeWrapper", data.mapSalesPathDataWrapper[stageval].lstOutComeWrapper);
                    }
                    if (data.mapSalesPathDataWrapper[stageval].lstSalesTipWrapper != null) {
                        component.set("v.SalestipWrapper", data.mapSalesPathDataWrapper[stageval].lstSalesTipWrapper);
                    }

                    if (data.mapSalesPathDataWrapper[stageval].lstTaskWrapper != null) {
                        component.set("v.TaskWrapper", data.mapSalesPathDataWrapper[stageval].lstTaskWrapper);
                    }
                }
            }
            // Calling the function to check visibility of the 'Ready to move next' button.
            helper.showReadyToMoveButton(component,helper);
            
        }
    },
    /**************************End******************************************/
    
    /*******************************************************************************
     **** Storing the server side data in to the aura component.
     ********************************************************************************/
    setSelectedStageValues : function(component,helper,data){
        
        if(data != null && data != undefined){
            // setting the salesPathwrapperNew data which contains all the data.
            component.set("v.SalespathWrapperNew", data);
            var SalespathDatawrapper = [];
            var stages = data.lstStage;
            var datamap = data.mapSalesPathDataWrapper;
            // creating List of salesPathdatawrapper value from the map.
            for (var i = 0; i < stages.length; i++) {
                SalespathDatawrapper.push(datamap[stages[i]]);
            } 
            // saving salesPath stage values to aura.
            component.set("v.lstStage", stages);
            // saving salesPathdatwrapper values to aura.
            component.set("v.SalespathWrapper", SalespathDatawrapper);
            // Saving mapvalues .
            if(data.mapSalesPathDataWrapper != null){
                component.set("v.wrappermap", data.mapSalesPathDataWrapper);
            }
            if( data.Oppobject != null){
                component.set("v.Opportunity", data.Oppobject);
            }
           
            
            
            // saving the current and active stage
            if(component.get("v.selectedstage") != null){
                var stageval;
                if(component.get("v.selectedstage").includes('Closed')){
                    stageval = 'Closed';
                }else{
                    stageval = component.get("v.selectedstage");
                }
                

                // Saving all the keyfieldwrapper,outcomewrapper,dealdocTaskWrapper,salestipwrapper and taskwrapper for the active stage.
                if(data.lstDealDocWrapper != null){
                    component.set('v.dealdocTaskWrapper', data.lstDealDocWrapper);
                }
                if(data.mapSalesPathDataWrapper != null && data.mapSalesPathDataWrapper[stageval] != null && stageval != null){
                    component.set("v.lstKeyWrapper", data.mapSalesPathDataWrapper[stageval].lstKeyWrapper);
                    component.set("v.index", data.mapSalesPathDataWrapper[stageval].index);
                    component.set("v.fieldset", data.mapSalesPathDataWrapper[stageval].fieldsetName);
                    component.set("v.OutcomeWrapper", data.mapSalesPathDataWrapper[stageval].lstOutComeWrapper);
                    component.set("v.SalestipWrapper", data.mapSalesPathDataWrapper[stageval].lstSalesTipWrapper);
                    component.set("v.TaskWrapper", data.mapSalesPathDataWrapper[stageval].lstTaskWrapper);
                    
                }   
            }
            var activeStage = component.get('v.activeStage');
            var selectedstage = component.get('v.selectedstage');
            if(activeStage == selectedstage){
                // Calling the function to check visibility of the 'Ready to move next' button.
                helper.showReadyToMoveButton(component,helper);
            }else{
                component.set("v.Messageshownot", false);
                component.set("v.Messageshow", false);
            }
            
            
        }
    },
    /**************************End******************************************/

    /*******************************************************************************
     **** Showing the details of selected stage and saving the details in wrapper
     ********************************************************************************/
    selectedstageFunction : function(component,event,helper){
        var saleswrapper = component.get('v.SalespathWrapper');
        
        var src = event.srcElement.outerText;
        if (src.includes('\n')) {
            var clickedStage = src.split('\n');
            src = clickedStage[1];
        }
        var sctive = component.get('v.activeStage');
        // setting the new selected stage.
        console.log('selected stage------',src);
        component.set('v.selectedstage', src);
        if (src.includes("Closed")) {
            component.set('v.showmark', false);
            component.set('v.showclose', true);
        } else {
            component.set('v.showmark', true);
            component.set('v.showclose', false);
        }
        var acc = component.find('pathsection');
        // calling this function to change the styles of salespath stages based on the selected stage.
        helper.selectPathStyle(component);
        var array = component.get("v.lstStage");
        // Making all stages beyond selected stage incomplete and removing active style from other stages other than selected stage.
        if (array.length > 0) {
            var ele;
            var eleprevoius;
            if (event.currentTarget.nextElementSibling != null) {
                ele = event.currentTarget.nextElementSibling;
            }
            if (event.currentTarget.previousElementSibling != null) {
                eleprevoius = event.currentTarget.previousElementSibling;
            }
            for (var j = 0; j < array.length; j++) {
                if (ele != null) {
                    ele.classList.remove("slds-is-active");
                   
                    if (ele.nextElementSibling != null) {
                        ele = ele.nextElementSibling;
                    }
                }
                if (eleprevoius != null) {
                    eleprevoius.classList.remove("slds-is-active");
                    
                    if (eleprevoius.previousElementSibling != null) {
                        eleprevoius = eleprevoius.previousElementSibling;
                    }
                }
            }
        }
        event.currentTarget.classList.remove("ft-outcomes");
        event.currentTarget.classList.add("slds-is-active");
        var salesmap = component.get('v.SalespathWrapperNew');
        // Calling this function to set the new values based on the selected stage.
        helper.setSelectedStageValues(component,helper,salesmap);
    },
     /**************************End******************************************/

    /*******************************************************************************
     **** Saving The recomanded tasks
     ********************************************************************************/
    saveRecomendedTasks : function(component,event,helper){
        var taskItem = event.getParam('selectedTask');
        // finding the task id to edit the transaction record.
        var taskId = taskItem.transactionId;
        var valueoftask = true;
        var recId = component.get("v.recordId");
        //Calling the server side controller for recomended task.
        var action = component.get("c.saveTasks");
        action.setParams({
            taskId: taskId,
            value: valueoftask,
            oppId: recId
        });
        action.setCallback(this,
        function(response) {

            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Successful",
                "message": "Your Task Created Successfully"
            });
            resultsToast.fire();
            helper.removeTaskElement(component,taskId);
            //$A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
        // hide spinner
        helper.hideSldsSpinner(component);
    },
     /*********************END***************************************************/
    // function to remove the added task from the list.
    removeTaskElement: function(component,taskId){
        var selectedStage;
        var mapData = component.get("v.SalespathWrapperNew");
        if(component.get("v.selectedstage").includes('Closed')){
            selectedStage = '10 - Closed - Won';
        }else{
            selectedStage = component.get("v.selectedstage");
        }
        console.log('tasklist------>',mapData.mapSalesPathDataWrapper);
        if(mapData.mapSalesPathDataWrapper != null && mapData.mapSalesPathDataWrapper[selectedStage]!= null){
            if(mapData.mapSalesPathDataWrapper[selectedStage].lstTaskWrapper != null && mapData.mapSalesPathDataWrapper[selectedStage].lstTaskWrapper.length>0){
                var taskData = mapData.mapSalesPathDataWrapper[selectedStage].lstTaskWrapper;
                var newTaskList=[];
                for(var i=0;i<taskData.length;i++){
                    if(taskData[i].transactionId == taskId){
                    }else{
                        newTaskList.push(taskData[i]);
                    }
                }
                mapData.mapSalesPathDataWrapper[selectedStage].lstTaskWrapper = newTaskList;
                component.set("v.SalespathWrapperNew",mapData);
                component.set("v.TaskWrapper",newTaskList);
            }
        }
    },
      /*******************************************************************************
     **** Saving The recomanded tasks
     ********************************************************************************/
     saveOutcomeTasks : function(component,event,helper){
         // finding the task id for edit the recommended task id and fetching the details for create new salesforce standard task.
         var taskId = event.getSource().get("v.text");
         var valueoftask = event.getSource().get("v.value");
         var selectedstage = component.get('v.selectedstage');
         var recId = component.get('v.recordId');
         var action = component.get("c.saveTasks");
        
         action.setParams({
             taskId: taskId,
             value: valueoftask,
             oppId:recId
         });
         // calling the method to update progress bar and stagestatus
         helper.checkOutcomecompelted(component,helper);
         $A.enqueueAction(action);
        

    },
      /*********************END***************************************************/
     /******************************************************************************
     ** checking the outcomes of stage is completed 
    *******************************************************************************/
    checkOutcomecompelted : function(component,helper){
        var activeStage = component.get('v.activeStage');
        var selected = component.get('v.selectedstage');
        var indexval = component.get('v.index') - 1;
        console.log('indexval : ', indexval);
        var taskwrappervalues = component.get("v.TaskWrapper");
        var outcomewrapper = component.get("v.OutcomeWrapper");
        var keywrapper = component.get("v.lstKeyWrapper");
        var mapSalesPathDataWrapper = component.get("v.SalespathWrapper");
        var progressval = 0.00;
        var total = 0.00;
        var checkfilled = false;
        // checking all the keyfields were filled or not for the visibility of 'Ready to move next ' button.
        if (keywrapper != null && keywrapper.length > 0) {
            checkfilled = false;
            for (var j = 0; j < keywrapper.length; j++) {
                console.log('fieldvalue---->',keywrapper[j].fieldValue, 'fieldLabel---->',keywrapper[j].fieldLabel);
                if (keywrapper[j].fieldValue != undefined && keywrapper[j].fieldValue != '') {
                    checkfilled = true;
                } else {
                    checkfilled = false;
                    break;
                }
            }
        } else {
            checkfilled = true;
        }
        // checking all the outcomes were completed or not for the visibility of 'Ready to move next ' button.
        if (outcomewrapper != null && outcomewrapper.length > 0) {
            // setting the gated task completed as false.
            var isgated = false;
            var allchecked = 0;
            for (var j = 0; j < outcomewrapper.length; j++) {
                if (outcomewrapper[j].isGatedTask) {
                    if (outcomewrapper[j].completed) {
                        //Calculating the progress of the stage based on the outcome probability value.
                        progressval = progressval + outcomewrapper[j].percentage;
                        allchecked = allchecked + 1;
                        // setting the gated task completed as false.
                        isgated = true;

                    } else {
                        checkfilled = false;
                        allchecked = allchecked - 1;
                    }
                } else {
                    if (outcomewrapper[j].completed) {
                        progressval = progressval + outcomewrapper[j].percentage;
                        allchecked = allchecked + 1;
                    } else {
                        allchecked = allchecked - 1;
                    }
                }
            }
            // Calcilating progress value for the selected stage.
            if(mapSalesPathDataWrapper[indexval].stage.includes('Closed')){
                mapSalesPathDataWrapper[indexval].progressValue = 0.00;
            }else{
                if (mapSalesPathDataWrapper != undefined && mapSalesPathDataWrapper.length > 0) {
                    total = mapSalesPathDataWrapper[indexval].total + total;
                    if(total>0.00){
                        var percentage = (progressval / total) * 100;
                        mapSalesPathDataWrapper[indexval].progressValue = percentage;
                        component.set("v.SalespathWrapper", mapSalesPathDataWrapper);
                    }else{
                        var percentage = 0.00;
                        mapSalesPathDataWrapper[indexval].progressValue = percentage;
                        component.set("v.SalespathWrapper", mapSalesPathDataWrapper);
                    }
                }
            }
            
        }
        /***************************************************************
        **setting the completeGatedTask value in SalespathWrapper to help the  
        **draw correct pattern of color for salespath stages 
        ****************************************************************/
        if(isgated){
            if(mapSalesPathDataWrapper[indexval] != null){
                // setting true if gated task completed
                mapSalesPathDataWrapper[indexval].completeGatedTask = true;
                component.set("v.SalespathWrapper",mapSalesPathDataWrapper);
            }
        }else{
            if(mapSalesPathDataWrapper[indexval] != null){
                // setting false if gated task is not complted
                mapSalesPathDataWrapper[indexval].completeGatedTask = false;
                component.set("v.SalespathWrapper",mapSalesPathDataWrapper);
            }
        }
        if (allchecked == outcomewrapper.length && checkfilled) {
            if(selected.includes('Closed')){
            }else{
                // Move the stage of Opportunity to next stage and update the view
                if(selected == activeStage){
                    helper.helperMoveToNextStage(component,helper);
                }
            }
            
            
        }
        if(selected.includes('Closed')){
            
        }else{
            //change the color pattern of salesPath stages based on outcome values
            helper.selectPathStyle(component);
            if (allchecked != outcomewrapper.length || checkfilled == false) {
                // Calling the method to update the view of Ready to move next stage button or warning message.
                helper.showReadyToMoveButton(component,helper);
            }
        }
        
    },
     /*********************END***************************************************/

    /******************************************************************************
     ** Function to move the next stage.
    *******************************************************************************/
     helperMoveToNextStage : function (component,helper){
        if (component.get('v.activeStage') == component.get('v.selectedstage')){
            component.set("v.Messageshownot", false);
            component.set("v.Messageshow", false);
        }
        var value = component.get('v.index');
       
        var array1 = component.get("v.lstStage");

          
        var newstage = array1[value];
        if(newstage.includes('Closed')){
            var modalpanel = component.find('closemodalsection');
            $A.util.toggleClass(modalpanel, 'slds-show');
            $A.util.toggleClass(modalpanel, 'slds-hide');
            var mapSalesPathDataWrapper1 = component.get("v.wrappermap");
            console.log('map data--',mapSalesPathDataWrapper1);
            if( mapSalesPathDataWrapper1['Closed']!=null)
            component.set("v.TaskWrapper", mapSalesPathDataWrapper1['Closed'].lstTaskWrapper);
            else
             component.set("v.TaskWrapper", null);
             if(mapSalesPathDataWrapper1['Closed']!=null)
            component.set("v.OutcomeWrapper", mapSalesPathDataWrapper1['Closed'].lstOutComeWrapper);
            else
            component.set("v.OutcomeWrapper", null);
            if(mapSalesPathDataWrapper1['Closed']!=null)
            component.set("v.lstKeyWrapper", mapSalesPathDataWrapper1['Closed'].lstKeyWrapper);
            else
             component.set("v.lstKeyWrapper", null);
             if(mapSalesPathDataWrapper1['Closed']!=null)
            component.set("v.SalestipWrapper", mapSalesPathDataWrapper1['Closed'].lstSalesTipWrapper);
            else
             component.set("v.SalestipWrapper", null);  

        }else{
            
            
            var recrdId = component.get("v.recordId");
            // Calling the server side class to update the stage.
            var action = component.get("c.assignNewOppStage");
            console.log('newstage-----',newstage);
            action.setParams({
                stage: newstage,
                oppId: recrdId
            });
            action.setCallback(this,
                function(response) {
                    var state = response.getState();
                    var custs = [];
                    if (state === 'SUCCESS') {
                        if (response.getReturnValue() == 'Success') {
                            component.set('v.index',value);
                            component.set("v.selectedstage", newstage);
                            component.set("v.activeStage", newstage);
                            var mapSalesPathDataWrapper1 = component.get("v.wrappermap");
                            component.set("v.TaskWrapper", mapSalesPathDataWrapper1[newstage].lstTaskWrapper);
                            component.set("v.OutcomeWrapper", mapSalesPathDataWrapper1[newstage].lstOutComeWrapper);
                            component.set("v.lstKeyWrapper", mapSalesPathDataWrapper1[newstage].lstKeyWrapper);
                            component.set("v.SalestipWrapper", mapSalesPathDataWrapper1[newstage].lstSalesTipWrapper);
                            if (mapSalesPathDataWrapper1 != null && mapSalesPathDataWrapper1[newstage].fieldsetName != null) {
                                component.set("v.fieldset", mapSalesPathDataWrapper1[newstage].fieldsetName);
                            }
                            // Calling the method to set SalespathWrapper .
                            helper.setSalePathwrapper(component,newstage);
                            // calling the styling method for the salespath stages
                            helper.selectPathStyle(component);
                            $A.get('e.force:refreshView').fire();
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": "Opportunity Stage has moved to " + newstage
                            });
                            toastEvent.fire();
                        } else {
                            if (component.get('v.activeStage') == component.get('v.selectedstage')){
                                component.set("v.Messageshownot", true);
                                component.set("v.Messageshow", false);
                            }
                            component.set('v.errormessage', response.getReturnValue());
                            var errormodalnew = component.find('errormodal');
                            $A.util.toggleClass(errormodalnew, 'slds-show');
                            $A.util.toggleClass(errormodalnew, 'slds-hide');
                            //do something
                        }
                    } else {

                    }
                    
                }
            );
            $A.enqueueAction(action);
           
        }
        
    },
    /*********************END***************************************************/

    /******************************************************************************************
     ** helper function to move the next stage on click of the Mark as current stage Button.
    *******************************************************************************************/

    saveNewstage : function(component,helper){
        helper.showSldsSpinner(component);
        var selectedstage = component.get("v.selectedstage");
        var recrdId = component.get("v.recordId");
        var action = component.get("c.assignNewOppStage");
        action.setParams({
            stage: selectedstage,
            oppId: recrdId,
        });
        action.setCallback(this,
            function(response) {
                var state = response.getState();
                var custs = [];
                if (state === 'SUCCESS') {
                    helper.hideSldsSpinner(component);
                    if (response.getReturnValue() == 'Success') {
                        component.set("v.selectedstage",selectedstage);
                        component.set("v.activeStage",selectedstage);
                        helper.setSalePathwrapper(component,selectedstage);
                        helper.selectPathStyle(component);
                        helper.showReadyToMoveButton(component,helper);
                        $A.get('e.force:refreshView').fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Opportunity Stage has moved to " + selectedstage
                        });
                        toastEvent.fire();
                        
                        
                        
                    }
                    else {
                        // hide the spinner
                        helper.hideSldsSpinner(component);
                        component.set('v.errormessage', response.getReturnValue());
                        var errormodalnew = component.find('errormodal');
                        $A.util.toggleClass(errormodalnew, 'slds-show');
                        $A.util.toggleClass(errormodalnew, 'slds-hide');
                    }
                } else {

                }
                  helper.hideSldsSpinner(component);
            });

        $A.enqueueAction(action);
        //component.set("v.doInitCall", true);
        
    },

    /*********************END***************************************************/

    /******************************************************************************
     ** Function to move the next stage.
    *******************************************************************************/
    setSalePathwrapper : function(component,newstage){
        var SalespathWrapper = [];
        var datarapper = component.get("v.SalespathWrapper");
        var data = component.get("v.lstStage");
        var value = component.get('v.index');
        if (data != null && data.length > 0) {
            var stagereached = false;
            for (var k = 0; k < data.length; k++) {
                if (data[k] == newstage) {
                    stagereached = true;
                    datarapper[k].current = true;
                    datarapper[k].completed = false;
                    datarapper[k].incomplete = false;
                    
                } else {
                    if (stagereached) {
                        datarapper[k].current = false;
                        datarapper[k].completed = false;
                        datarapper[k].incomplete = true;
                        
                    } else {
                        datarapper[k].current = false;
                        datarapper[k].completed = true;
                        datarapper[k].incomplete = false;
                        
                    }
                }
            }
            component.set("v.SalespathWrapper", datarapper);

        }
    },

     /*********************END***************************************************/

    /******************************************************************************
     ** Craeting the dynamic edit field for keyfield section
    *******************************************************************************/
    getRecord: function(component) {
        //Display the edit panel for editing the keyfield components
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack, 'slds-backdrop--open');
        var fieldsetname = component.get("v.fieldset");
        console.log('fieldsetname-------',fieldsetname);
        //fetch the recordIdSalespathWrapperNew
        var recordId = component.get("v.recordId");
        // Calling serverside controller for the list of fields and values
        var activestage = component.get("v.activeStage");
        var data = component.get("v.SalespathWrapperNew");
        
        component.set("v.body", []);
        //action.setCallback(this, function(a) {
            console.log(data.mapSalesPathDataWrapper);
            /***saving the values from in server to the component.******/
            
            var sobjectrecord = data.mapSalesPathDataWrapper[activestage].salespathEditWrapper.opportunityRec;
            //component.set("v.wrapperobj", a.getReturnValue());
            component.set("v.detailRecord", sobjectrecord);
            var wrapperlist = data.mapSalesPathDataWrapper[activestage].salespathEditWrapper.lstFieldProperties;
            component.set("v.EditwrapperList", wrapperlist);
            /**********END******************************************/

            /********************************************************************************
             **Creating Dynamic edit panel for Keyfield section based on the field Type 
             *********************************************************************************/
            var count = 0;
            for (var idx in wrapperlist) {
                count++;
                console.log(wrapperlist[idx].label);
                console.log(sobjectrecord[wrapperlist[idx].fieldPath]);
                if (wrapperlist[idx].type == 'date') {
                    $A.createComponent(
                        "ui:inputDate", {
                            "label": wrapperlist[idx].label,
                            "labelClass": "slds-required",
                            "value": sobjectrecord[wrapperlist[idx].fieldPath],
                            "class": "slds-inputDate slds-m-bottom--medium slds-form-element__control slds-required",
                            "displayDatePicker": "true",
                            "blur": component.getReference("c.handlePress"),
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");

                                body.push(newCmp);
                                component.set("v.body", body);

                            }
                        }

                    );

                } else if (wrapperlist[idx].type == 'double' || wrapperlist[idx].type == 'Percent') {
                    $A.createComponent(
                        "ui:inputNumber", {
                            "label": wrapperlist[idx].label,
                            "value": sobjectrecord[wrapperlist[idx].fieldPath],
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-form-element__control slds-required",
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else if (wrapperlist[idx].type == 'boolean') {

                    $A.createComponent(
                        "ui:inputCheckbox", {

                            "label": wrapperlist[idx].label,
                            "value": sobjectrecord[wrapperlist[idx].fieldPath],
                            "class": "slds-checkbox slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-checkbox__label slds-form-element__control slds-required",
                            "options": wrapperlist[idx].lstofOptions,
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                                console.log('component--', newCmp);

                            }
                        }

                    );

                } 
                else if(wrapperlist[idx].type == 'multipicklist'){
                        var value;
                        var dependendpicklist;
                    if(wrapperlist[idx].controllerField != null){
                        var controllfieldvalue = sobjectrecord[wrapperlist[idx].controllerField];
                        dependendpicklist =  wrapperlist[idx].mapControllingPicklistFields[controllfieldvalue];
                    }else{
                        dependendpicklist = wrapperlist[idx].lstofOptions;
                    }
                        if(sobjectrecord[wrapperlist[idx].fieldPath] != null){
                            value = sobjectrecord[wrapperlist[idx].fieldPath];
                        }else{
                            value = '';
                        }
                    $A.createComponent(
                    "ui:inputSelect",
                    {   
                         "aura:id":wrapperlist[idx].label,
                        "label": wrapperlist[idx].label,
                        "value": value,
                        "multiple" :true,   
                        "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                        "labelClass": "slds-form-element__control slds-required",
                        "options": dependendpicklist,
                        "change": component.getReference("c.handlePress")
                                   
                    },
                    function(newCmp){
                        //Add the field list to the body array
                        if (component.isValid()) {
                            var body = component.get("v.body");
                            
                                body.push(newCmp);
                                component.set("v.body", body);
                            
                            console.log('component--',newCmp);
                           
                        }
                    }
                    
                );
                    }
                else if (wrapperlist[idx].type == 'picklist') {
                    var value;
                    if (sobjectrecord[wrapperlist[idx].fieldPath] != null) {
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    } else {
                        value = '';
                    }
                    var dependendpicklist;
                    if(wrapperlist[idx].controllerField != null){
                        var controllfieldvalue = sobjectrecord[wrapperlist[idx].controllerField];
                        dependendpicklist =  wrapperlist[idx].mapControllingPicklistFields[controllfieldvalue];
                    }else{
                        dependendpicklist = wrapperlist[idx].lstofOptions;
                    }
                    $A.createComponent(
                        "ui:inputSelect", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": value,
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-form-element__control slds-required",
                            "options": dependendpicklist,
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else if (wrapperlist[idx].type == 'reference') {
                    /******************************************************************
                     ** Creating custom lookup component if the field type is reference
                     ***********************************************************/
                    var filtervalues='';
                    if(wrapperlist[idx].filterValues != null ){
                        filtervalues = wrapperlist[idx].filterValues;
                    }else{
                         filtervalues = sobjectrecord[wrapperlist[idx].filterField];
                        
                    }
                    console.log('Account Id----',sobjectrecord[wrapperlist[idx].relationName]);
                    $A.createComponent(
                        "c:CustomLookupComponent", {

                            "label": wrapperlist[idx].label,
                            "objectAPIName": wrapperlist[idx].lookupobjectName,
                            "IconName": "standard:account",
                            "selectedRecord": sobjectrecord[wrapperlist[idx].relationName],
                            "filterfield" : wrapperlist[idx].filterField,
                            "filtervalue" : filtervalues
                            
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                    /*********************END***************************************************/

                } else if (wrapperlist[idx].type == 'currency') {
                    $A.createComponent(
                        "ui:inputText", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": sobjectrecord[wrapperlist[idx].fieldPath],
                            "labelClass": "slds-form-element__control slds-required",
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "change": component.getReference("c.handlePress")
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else {
                    $A.createComponent(
                        "ui:inputText", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": sobjectrecord[wrapperlist[idx].fieldPath],
                            "labelClass": "slds-form-element__control slds-required",
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "change": component.getReference("c.handlePress")
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                // Setting the dynamic edit component to the body element of Ura component
                                component.set("v.body", body);
                            }
                        }

                    );
                }

            }
            // Saving the opportunity record to the component.
            component.set("v.detailRecord", sobjectrecord);

        //});
        // Opening the modal for editing key field section
        //$A.enqueueAction(action);
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');

    },
    /*********************END***************************************************/

    /******************************************************************************
     **Saving the edited keyfield section values.
     *******************************************************************************/
    saveOpp: function(component,helper) {
        /***************************************************************
         ** Get the new opportunity values 
         ****************************************************************/
        var wrapperlist = component.get("v.EditwrapperList");
        var recordId = component.get("v.recordId");
        var oppRecord = component.get("v.detailRecord");
        var data = component.get("v.SalespathWrapperNew");
        var activestage = component.get("v.activeStage");
        if(activestage.includes('Closed')){
            data.closedStageEditWrapper.lstFieldProperties = wrapperlist;
            var wrapperobj = data.closedStageEditWrapper;
        }else{
            data.mapSalesPathDataWrapper[activestage].salespathEditWrapper.lstFieldProperties = wrapperlist;
            var wrapperobj = data.mapSalesPathDataWrapper[activestage].salespathEditWrapper;
        }
        component.set("v.SalespathWrapperNew",data);
        
        wrapperobj.lstFieldProperties = wrapperlist;
        //wrapperobj.OpportunityRec = oppRecord;
        var json = JSON.stringify(wrapperobj);
        var wrapperlist = component.set("v.EditwrapperList");
        /*******************************************************************************
         **Calling the server side class 'SaveRecord' to save updated Opportunity Record
         ********************************************************************************/
        var action = component.get("c.saveOpportunity");
        var selected = component.get("v.selectoptionValue");
        if (selected != null && selected != '') {
            action.setParams({
                oppRecordId: recordId,
                jsonRecord: json,
                stageValue: selected
            });
        } else {
            var stringval = '';
            action.setParams({
                oppRecordId: recordId,
                jsonRecord: json,
                stageValue: stringval
            });
        }
        action.setCallback(this,
            function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    if (response.getReturnValue() == 'Success') {
                        $A.get('e.force:refreshView').fire();
                        /************************************************************
                         *** Showing the success toast
                         *************************************************************/
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "message": "Opportunity record has updated successfully "
                        });
                        toastEvent.fire();
                        /************************************************************
                         *** END
                         *************************************************************/
                    } else {
                        /************************************************************
                         *** Showing the error message
                         *************************************************************/
                        component.set('v.errormessage', response.getReturnValue());
                        var errormodalnew = component.find('errormodal');
                        $A.util.toggleClass(errormodalnew, 'slds-show');
                        $A.util.toggleClass(errormodalnew, 'slds-hide');
                        /************************************************************
                         *** END
                         *************************************************************/
                    }
                } else {

                }
            }
        );
        $A.enqueueAction(action);
        helper.showReadyToMoveButton(component,helper);
    },
    /*********************END***************************************************/

     /******************************************************************************
     **Saving the edited keyfield section values to EditwrapperList
     *******************************************************************************/
    editOnchange : function(component, event, helper){
        var opparray = [];
        var oppRecord = component.get("v.detailRecord");
        console.log('check Account  ',oppRecord['AccountId']);
        var wrapperlist =  component.get("v.EditwrapperList");
        console.log('check Account  ',wrapperlist);
        var json = JSON.stringify(oppRecord);
        var fieldlabel = event.getSource().get("v.label");
        var opparray = [];
        var rerender = false;
        console.log('check  ',event.getSource().get("v.value"));
        // Updating the wrapper List
        for (var idx in wrapperlist) {
            if(wrapperlist[idx].label == fieldlabel){
                var valueoffield = event.getSource().get("v.value");
                var fieldtype = wrapperlist[idx].type;
                wrapperlist[idx].value = valueoffield;
            }
            if(wrapperlist[idx].controllerFieldLabel != null && wrapperlist[idx].controllerFieldLabel ==fieldlabel){
                rerender = true;
                wrapperlist[idx].controllerFieldValue = valueoffield;
            }
         
        }
        component.set("v.EditwrapperList",wrapperlist);
        if(rerender){
            var cmpTarget = component.find('Modalbox');
            var cmpBack = component.find('Modalbackdrop');
            $A.util.removeClass(cmpBack, 'slds-backdrop--open');
            $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
            helper.createEditModal(component,wrapperlist);
        }
    },
    /*********************END***************************************************/
    /*******************************************************************************
     **Saving the selected record of custom look component to the wrapper list
     ********************************************************************************/
    saveLookup: function(component, event) {
        // get the selected Account record from the COMPONETN event

        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        var selectedlabel = event.getParam("labelofLookup");
        var wrapperlist = component.get("v.EditwrapperList");
        if (selectedAccountGetFromEvent != null && selectedAccountGetFromEvent !== undefined) {
            var IdofRecrd = selectedAccountGetFromEvent['Id'];
            // updating wrapper based on the lookupvalue
            for (var idx in wrapperlist) {
                if (wrapperlist[idx].label == selectedlabel) {
                    wrapperlist[idx].value = IdofRecrd;
                } else {}
            }

        } else {
            for (var idx in wrapperlist) {
                if (wrapperlist[idx].label == selectedlabel) {
                    wrapperlist[idx].value = '';
                } else {

                }
            }
        }
        console.log('wrapper list----', wrapperlist);
        component.set("v.EditwrapperList", wrapperlist);
        

    },
    /*********************END***************************************************/

    /*******************************************************************************
     **Show the spinner 
    ********************************************************************************/
    showSldsSpinner : function(cmp){
        var spinner = cmp.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
     /*********************END***************************************************/

    /*******************************************************************************
     **Hide the spinner
     ********************************************************************************/
    hideSldsSpinner : function(cmp){
        var spinner = cmp.find("mySpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },
    /*********************END***************************************************/
    /*******************************************************************************
     ** Method to check the keyfields before close the opportunity
     ********************************************************************************/
    checkKeyfields : function(component,helper){
        var selected = component.find("closedLevels").get("v.value");
        var data = component.get("v.wrappermap");
        var stageList = component.get("v.lstStage");
        // initially the value of completedfields setto false. 
        // if all the fields were completed the value will be true else false.
        var completedfields = false;
        if(data != null ){
            if(stageList != null && stageList.length>0){
                for(var i=0;i<stageList.length;i++){
                    if(i>0 && completedfields == false){
                        break;
                    }
                    if (data[stageList[i]] != null && data[stageList[i]].lstKeyWrapper != null) {
                        var keywrapper = data[stageList[i]].lstKeyWrapper;
                        for (var j = 0; j < keywrapper.length; j++) {
                            if (keywrapper[j].fieldValue != undefined && keywrapper[j].fieldValue !== null) {
                                completedfields = true;
                            } else {
                                completedfields = false;
                                break;
                            }
                        }
                    } else {
                        completedfields = true;
                    }
                }
            }
        }
        if(completedfields){
            component.set("v.selectoptionValue", selected);
            helper.selectClosedStage(component);
        }else{
            var modalpanel = component.find('closemodalsection');
            $A.util.toggleClass(modalpanel, 'slds-show');
            $A.util.toggleClass(modalpanel, 'slds-hide');
            component.set('v.errormessage', 'Please fill all key fields before closing the Opportunity');
            var errormodalnew = component.find('errormodal');
            $A.util.toggleClass(errormodalnew, 'slds-show');
            $A.util.toggleClass(errormodalnew, 'slds-hide');
        }
    },
    /*******************************************************************************
     ** Method for selecting closed stage.
     ********************************************************************************/
    selectClosedStage: function(component) {
        
        var selected = component.get("v.selectoptionValue");
        var recordId = component.get("v.recordId");
        // checking all the keyfields were filled or not.
        
        /*******************************************************************************
         ** If the stage is Closed won updating Opportunity record
         ********************************************************************************/
        if (selected != '' && selected == '10 - Closed - Won') {
            var recordId = component.get("v.recordId");
            var action = component.get("c.assignNewOppStage");
            action.setParams({
                stage: selected,
                oppId: recordId
            });
            action.setCallback(this,
                function(response) {
                    var state = response.getState();
                    var custs = [];
                    if (state === 'SUCCESS') {
                        console.log('message----', response.getReturnValue());
                        if (response.getReturnValue() == 'Success') {
                            $A.get('e.force:refreshView').fire();
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": "Opportunity Stage has moved to " + selected
                            });
                            toastEvent.fire();
                        } else {
                            console.log('error--', response.getReturnValue());
                            component.set('v.errormessage', response.getReturnValue());
                            var errormodalnew = component.find('errormodal');
                            $A.util.toggleClass(errormodalnew, 'slds-show');
                            $A.util.toggleClass(errormodalnew, 'slds-hide');
                            //do something
                        }
                    } else {}
                }

            );
            var modalpanel = component.find('closemodalsection');
            $A.util.toggleClass(modalpanel, 'slds-show');
            $A.util.toggleClass(modalpanel, 'slds-hide');
            $A.enqueueAction(action);
        }
        /**************************End******************************************/

        /****************************************************************************************
         *** Show the edit panel for the keyfield section of other closed stages.
         *****************************************************************************************/
        else {
            if (selected != '' && selected != null) {
                /*************************************************************************************
                 *** Calling the server side class for keyfields of closed stage and creating a edit
                 ** panel for the keyfield section.
                 **************************************************************************************/
                
                component.set("v.body", []);
                
                    var closedData = component.get("v.SalespathWrapperNew");
                    var sobjectrecord = closedData.closedStageEditWrapper.opportunityRec;
                    var wrapperlist = closedData.closedStageEditWrapper.lstFieldProperties;
                    console.log('check wrapper----',sobjectrecord);
                    //component.set("v.wrapperobj", a.getReturnValue());
                    component.set("v.detailRecord", sobjectrecord);
                    //var wrapperlist = a.getReturnValue().lstFieldProperties;
                    component.set("v.EditwrapperList", wrapperlist);
                    var count = 0;
                    for (var idx in wrapperlist) {
                        count++;
                        console.log(wrapperlist[idx].label);
                        console.log(sobjectrecord[wrapperlist[idx].fieldPath]);
                        if (wrapperlist[idx].type == 'date') {
                            $A.createComponent(
                                "ui:inputDate", {
                                    "label": wrapperlist[idx].label,
                                    "value": sobjectrecord[wrapperlist[idx].fieldPath],
                                    "class": "slds-inputDate slds-m-bottom--medium slds-form-element__control slds-required",
                                    "displayDatePicker": "true",
                                    "blur": component.getReference("c.handlePress"),
                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");
                                        if (body != undefined) {
                                            body.push(newCmp);
                                            component.set("v.body", body);
                                        }

                                    }
                                }

                            );

                        } else if (wrapperlist[idx].type == 'double' || wrapperlist[idx].type == 'currency' || wrapperlist[idx].type == 'Percent') {
                            $A.createComponent(
                                "ui:inputNumber", {
                                    "label": wrapperlist[idx].label,
                                    "value": sobjectrecord[wrapperlist[idx].fieldPath],
                                    "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                                    "labelClass": "slds-form-element__control slds-required",
                                    "change": component.getReference("c.handlePress")

                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");

                                        body.push(newCmp);
                                        component.set("v.body", body);


                                    }
                                }

                            );
                        } else if (wrapperlist[idx].type == 'boolean') {
                            $A.createComponent(
                                "ui:inputCheckbox", {
                                    "label": wrapperlist[idx].label,
                                    "value": sobjectrecord[wrapperlist[idx].fieldPath],
                                    "class": "slds-checkbox slds-m-bottom--medium slds-form-element__control slds-required",
                                    "labelClass": "slds-checkbox__label slds-form-element__control ",
                                    "options": wrapperlist[idx].lstofOptions,
                                    "change": component.getReference("c.handlePress")

                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");
                                        if (body != undefined) {
                                            body.push(newCmp);
                                            component.set("v.body", body);
                                        }

                                    }
                                }

                            );

                        } else if (wrapperlist[idx].type == 'picklist') {
                            $A.createComponent(
                                "ui:inputSelect", {
                                    "aura:id": wrapperlist[idx].label,
                                    "label": wrapperlist[idx].label,
                                    "value": sobjectrecord[wrapperlist[idx].fieldPath],
                                    "class": "slds-input slds-m-bottom--medium slds-form-element__control slds-required",
                                    "labelClass": "slds-form-element__control ",
                                    "options": wrapperlist[idx].lstofOptions,
                                    "change": component.getReference("c.handlePress")

                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");
                                        if (body != undefined) {
                                            body.push(newCmp);
                                            component.set("v.body", body);
                                        }
                                    }
                                }

                            );
                        } else if (wrapperlist[idx].type == 'reference') {
                            var acc = [];
                            console.log('account value---', sobjectrecord[wrapperlist[idx].lookupobjectName]);
                            component.set("v.selectedLookUpRecord", sobjectrecord[wrapperlist[idx].lookupobjectName]);
                            var filtervalues='';
                            if(wrapperlist[idx].filterValues != null ){
                                filtervalues = wrapperlist[idx].filterValues;
                            }else{
                                 filtervalues = sobjectrecord[wrapperlist[idx].filterValues];
                                console.log('Account Id----',sobjectrecord['AccountId']);
                            }
                            console.log('Account Id----',wrapperlist[idx].relationName);
                            $A.createComponent(
                                "c:CustomLookupComponent", {
                                    "aura:id": wrapperlist[idx].label,
                                    "label": wrapperlist[idx].label,
                                    "objectAPIName": wrapperlist[idx].lookupobjectName,
                                    "IconName": "standard:account",
                                    "selectedRecord": sobjectrecord[wrapperlist[idx].relationName],
                                    "filterfield" : wrapperlist[idx].filterField,
                                    "filtervalue" : filtervalues
                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");
                                        if (body != undefined) {
                                            body.push(newCmp);
                                            component.set("v.body", body);
                                        }


                                    }
                                }

                            );

                        } else {
                            $A.createComponent(
                                "ui:inputText", {
                                    "aura:id": wrapperlist[idx].label,
                                    "label": wrapperlist[idx].label,
                                    "value": sobjectrecord[wrapperlist[idx].fieldPath],
                                    "labelClass": "slds-form-element__control ",
                                    "class": "slds-input slds-m-bottom--medium slds-form-element__control slds-required",
                                    "change": component.getReference("c.handlePress")
                                },
                                function(newCmp) {
                                    //Add the field list to the body array
                                    if (component.isValid()) {
                                        var body = component.get("v.body");
                                        if (body != undefined) {
                                            body.push(newCmp);
                                            component.set("v.body", body);
                                        }
                                    }
                                }

                            );
                        }

                    }


                    /**************************End******************************************/
               

               
                // Openeing the edit panel of keyfield section related to the closed stage.
                var modalpanel = component.find('closemodalsection');
                $A.util.toggleClass(modalpanel, 'slds-show');
                $A.util.toggleClass(modalpanel, 'slds-hide');
                var cmpTarget = component.find('Modalbox');
                var cmpBack = component.find('Modalbackdrop');
                $A.util.addClass(cmpTarget, 'slds-fade-in-open');
                $A.util.addClass(cmpBack, 'slds-backdrop--open');
            }
        }
        /**************************End******************************************/
    },
    /*********************END***************************************************/
    /*******************************************************************************
     **** Adding styles to the salespath stages based on the conditions
     ********************************************************************************/
    selectPathStyle: function(component) {
        var salesPathdata = component.get("v.SalespathWrapper");
        var activeStage = component.get("v.activeStage");
        var selectedstage = component.get("v.selectedstage");
        var array = component.get("v.lstStage");
        var elecomponet = component.find('pathsection').getElement().firstChild;
        console.log('check check----',elecomponet.classList);
        if (array != null && array.length > 0) {
            var currentvalue = false;
            for (var j = 0; j < array.length; j++) {
                if (elecomponet != null) {
                    var list = elecomponet.classList;
                    // for each condition -colors change - current stage  marked as light blue - slds-is-current
                    //gated task  not complete -yellow -  slds-is-incomplete , excalamtion - ft-outcomes
                    //active stage - dark blue - slds-is-active
                    // completed stage - green -  slds-is-complete
                    if (salesPathdata[j] != null && salesPathdata[j].completeGatedTask && salesPathdata[j].current == false) {
                        elecomponet.classList.remove('ft-outcomes');
                        if (currentvalue == false) {
                            if (elecomponet.classList.contains("slds-is-incomplete")) {
                                elecomponet.classList.remove("slds-is-incomplete");
                            }



                            if (elecomponet.classList.contains("slds-is-complete")) {

                            } else {
                                elecomponet.classList.add("slds-is-complete");
                            }
                        } else {
                            if (elecomponet.classList.contains("slds-is-incomplete")) {
                                elecomponet.classList.add("slds-is-incomplete");
                            }

                            if (elecomponet.classList.contains("slds-is-complete")) {

                            } else {
                                elecomponet.classList.remove("slds-is-complete");
                            }
                        }

                    } else if (salesPathdata[j] != null && salesPathdata[j].incomplete == false && salesPathdata[j].completeGatedTask == false && salesPathdata[j].current ==
                        false) {
                        if (currentvalue == false) {
                            if (elecomponet.classList.contains("ft-outcomes")) {

                            } else {
                                elecomponet.classList.add("ft-outcomes");
                            }
                        } else {
                            if (elecomponet.classList.contains("slds-is-incomplete")) {
                                elecomponet.classList.add("slds-is-incomplete");
                            }

                            if (elecomponet.classList.contains("slds-is-complete")) {

                            } else {
                                elecomponet.classList.remove("slds-is-complete");
                            }
                        }

                    } else if (salesPathdata[j] != null && salesPathdata[j].current) {
                        currentvalue = true;
                        elecomponet.classList.remove('ft-outcomes');
                        elecomponet.classList.remove("slds-is-complete");
                        elecomponet.classList.remove("slds-is-incomplete");
                        elecomponet.classList.remove("slds-is-active");
                        if (elecomponet.classList.contains("slds-is-current")) {

                        } else {
                            elecomponet.classList.add("slds-is-current");
                        }


                    } 
                        else if (salesPathdata[j] != null && salesPathdata[j].incomplete) {
                        elecomponet.classList.remove('ft-outcomes');
                        elecomponet.classList.remove("slds-is-complete");
                        if (elecomponet.classList.contains("slds-is-incomplete")) {

                        } else {
                            elecomponet.classList.add("slds-is-incomplete");
                        }

                        elecomponet.classList.remove("slds-is-current");
                    }
                    
                    if (elecomponet.nextElementSibling != null) {
                        elecomponet = elecomponet.nextElementSibling;
                    } else {
                        break;
                    }

                }
            }
        }

    },
    /**************************End******************************************/
    
    /************************************************************************
     * Create the component for keyFieldedit panel*
     * **********************************************************************/
    createEditModal : function(component,wrapperlist){
        component.set("v.body", []);
        var sobjectrecord = component.get("v.detailRecord");
        var count = 0;
            for (var idx in wrapperlist) {
                count++;
                if (wrapperlist[idx].type == 'date') {
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "ui:inputDate", {
                            "label": wrapperlist[idx].label,
                            "labelClass": "slds-required",
                            "value": value,
                            "class": "slds-inputDate slds-m-bottom--medium slds-form-element__control slds-required",
                            "displayDatePicker": "true",
                            "blur": component.getReference("c.handlePress"),
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");

                                body.push(newCmp);
                                component.set("v.body", body);

                            }
                        }

                    );

                } else if (wrapperlist[idx].type == 'double' || wrapperlist[idx].type == 'Percent') {
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "ui:inputNumber", {
                            "label": wrapperlist[idx].label,
                            "value": value,
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-form-element__control slds-required",
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else if (wrapperlist[idx].type == 'boolean') {
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "ui:inputCheckbox", {

                            "label": wrapperlist[idx].label,
                            "value": value,
                            "class": "slds-checkbox slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-checkbox__label slds-form-element__control slds-required",
                            "options": wrapperlist[idx].lstofOptions,
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                                console.log('component--', newCmp);

                            }
                        }

                    );

                } 
                else if(wrapperlist[idx].type == 'multipicklist'){
                    var value;
                    var dependendpicklist;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    if(wrapperlist[idx].controllerFieldValue != null){
                        dependendpicklist =  wrapperlist[idx].mapControllingPicklistFields[wrapperlist[idx].controllerFieldValue];
                    }else{
                        dependendpicklist = wrapperlist[idx].lstofOptions;
                    }
                    $A.createComponent(
                    "ui:inputSelect",
                    {   
                         "aura:id":wrapperlist[idx].label,
                        "label": wrapperlist[idx].label,
                        "value": value,
                        "multiple" :true,   
                        "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                        "labelClass": "slds-form-element__control slds-required",
                        "options": dependendpicklist,
                        "change": component.getReference("c.handlePress")
                                   
                    },
                    function(newCmp){
                        //Add the field list to the body array
                        if (component.isValid()) {
                            var body = component.get("v.body");
                            
                                body.push(newCmp);
                                component.set("v.body", body);
                            
                            console.log('component--',newCmp);
                           
                        }
                    }
                    
                );
                    }
                else if (wrapperlist[idx].type == 'picklist') {
                    var value;
                    var dependendpicklist;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    
                    if(wrapperlist[idx].controllerFieldValue != null){
                        dependendpicklist =  wrapperlist[idx].mapControllingPicklistFields[wrapperlist[idx].controllerFieldValue];
                    }else{
                        dependendpicklist = wrapperlist[idx].lstofOptions;
                    }
                    
                    
                    $A.createComponent(
                        "ui:inputSelect", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": value,
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "labelClass": "slds-form-element__control slds-required",
                            "options": dependendpicklist,
                            "change": component.getReference("c.handlePress")

                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else if (wrapperlist[idx].type == 'reference') {
                    /******************************************************************
                     ** Creating custom lookup component if the field type is reference
                     ***********************************************************/
                    var filtervalues='';
                    if(wrapperlist[idx].filterValues != null ){
                        filtervalues = wrapperlist[idx].filterValues;
                    }else{
                         filtervalues = sobjectrecord[wrapperlist[idx].filterField];
                    }
                    //  values after the rerender of modal
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "c:CustomLookupComponent", {

                            "label": wrapperlist[idx].label,
                            "objectAPIName": wrapperlist[idx].lookupobjectName,
                            "IconName": "standard:account",
                            "selectedRecord": sobjectrecord[wrapperlist[idx].relationName],
                            "filterfield" : wrapperlist[idx].filterField,
                            "filtervalue" : filtervalues
                            
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                    /*********************END***************************************************/

                } else if (wrapperlist[idx].type == 'currency') {
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "ui:inputText", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": value,
                            "labelClass": "slds-form-element__control slds-required",
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "change": component.getReference("c.handlePress")
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                component.set("v.body", body);
                            }
                        }

                    );
                } else {
                    var value;
                    if(wrapperlist[idx].value != null){
                        value = wrapperlist[idx].value;
                        
                    }else{
                        value = sobjectrecord[wrapperlist[idx].fieldPath];
                    }
                    $A.createComponent(
                        "ui:inputText", {
                            "aura:id": wrapperlist[idx].label,
                            "label": wrapperlist[idx].label,
                            "value": value,
                            "labelClass": "slds-form-element__control slds-required",
                            "class": "slds-input slds-m-bottom--medium slds-form-element__control ",
                            "change": component.getReference("c.handlePress")
                        },
                        function(newCmp) {
                            //Add the field list to the body array
                            if (component.isValid()) {
                                var body = component.get("v.body");
                                body.push(newCmp);
                                // Setting the dynamic edit component to the body element of Ura component
                                component.set("v.body", body);
                            }
                        }

                    );
                }

            }
            // Saving the opportunity record to the component.
            component.set("v.detailRecord", sobjectrecord);

        // Opening the modal for editing key field section
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');
    },
    /**************************End******************************************/


})