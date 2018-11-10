({
    initData : function(component){
        var action = component.get("c.loadData");
        action.setParams({});
        action.setCallback(this, function(response){
            this.processResponse(component, response);
        });
        $A.enqueueAction(action);
    },
    loginFlow : function(component, code){
        var action = component.get("c.recentLoginFlow");
        action.setParams({
            "resCode" : code
        });
        action.setCallback(this, function(response){
            this.processResponse(component, response);
        });
        $A.enqueueAction(action);
    },
    updateMeetupList : function(component, eventId, groupUrlname, attendingEvent){
        var meetupList = component.get("v.meetupList");
        for(var i=0; i<meetupList.length; i++){
            if(meetupList[i].eventId === eventId && meetupList[i].groupUrlname === groupUrlname){
                //inverse attendingEvent flag (true->false, false->true)
                meetupList[i].attendingEvent = (attendingEvent ? false:true);
                //console.log("~~~~~ meetup: ", meetupList[i]);
                this.showToastMessage(component, "RSVP updated", "success");
                break;
            }
        }
        component.set("v.meetupList", meetupList);
    },
    doLogout : function(component){
        var action = component.get("c.logoutMeetupUser");
        action.setCallback(this, function(response){
            this.processResponse(component, response);
        });
        $A.enqueueAction(action);
    },
    processResponse : function(component, response){
        //if backend call succeeded
        if(response.getState() === "SUCCESS"){
            var responseData = response.getReturnValue();
            // if meetup response has been received
            if(responseData.state === "SUCCESS"){
                component.set("v.meetupList", responseData.displayList);
                component.set("v.showDisconnect", true);
                if(responseData.displayList.length <= 0)
                	component.set("v.showNoMeetup", true);
                else
                    this.showToastMessage(component, "Data retrieved succesfully", "success");
            }
            //first time use or invalid/expired tokens
            else if(responseData.state === "LOGIN_REQUIRED"){
                component.set("v.showLogin", true);
            }
            else if(responseData.state === "ERROR"){
               	this.showToastMessage(component, responseData.stateMsg, "error");
            }
            else{
                this.showToastMessage(component, "Internal error. Contact Admin", "error");
            }
        }
        else{
            this.showToastMessage(component, "Backend call returned with errors", "error");
        }
        this.hideSpinner(component);
    },
    hideSpinner : function(component){
        //adding this class, hides the spinner
        component.set("v.hideSpinnerClass", "slds-hide");
    },
    showSpinner : function(component){
        //assign null value to the string variable to show spinner
        component.set("v.hideSpinnerClass", "");
    },
    showToastMessage : function(component, msg, toastType) {
        var toastMsg = $A.get("e.force:showToast");
        toastMsg.setParams({
            message: msg,
            type: toastType,
        });
        toastMsg.fire();
    }    
})