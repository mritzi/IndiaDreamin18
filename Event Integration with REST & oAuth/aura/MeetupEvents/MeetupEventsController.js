({
    /* method: doInit
     * description: called when the component loads/refreshes, 
     * loads meetup data or shows other options (login/no upcoming meetups) 
     */
	doInit : function(component, event, helper) {
		
        var resp = window.location.href;
        var code = "code=";
        //if access code has been received from Meetup.com, init callout
        if(resp.indexOf(code) > 0){
            //show spinner
            resp = resp.substr(resp.indexOf(code)+code.length, resp.length);
            //console.log("resp if: ", resp);
            helper.loginFlow(component, resp);
        }
        else{
            helper.initData(component);
        }
	},
    beginOAuthFlow : function(component, event, helper){
        
        window.open("https://secure.meetup.com/oauth2/authorize?client_id=94hikn0p8pe9oo6n1mp17k2ssg&response_type=code&redirect_uri=https://testframeworkio-dev-ed.lightning.force.com/lightning/n/Meetup_Events&scope=basic+rsvp", "_top");
    },
    changeRsvp : function(component, event, helper){
        var eventId = event.getParam("eventId");
        var groupUrlname = event.getParam("groupUrlname");
        var attendingEvent = event.getParam("attendingEvent");
        
        var action = component.get("c.toggleRSVP");
        action.setParams({
            "eventId": eventId,
            "groupUrlname": groupUrlname,
            "response": attendingEvent ? "no":"yes"
        });
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                //so far attendingEvent has been unchanged, it will be changed only when back-end call succeeds
                if(response.getReturnValue() === true)
                	helper.updateMeetupList(component, eventId, groupUrlname, attendingEvent);
                else
                    helper.showToastMessage(component, "RSVP couldn't be updated", "error");
            }
            else
                helper.showToastMessage(component, "BackEnd call interrupted, refresh or contact admin", "error");
        });
        $A.enqueueAction(action);
    },
    logout : function(component, event, helper){
        helper.showSpinner(component);
        component.set("v.meetupList", []);
        component.set("v.showNoMeetup", false);
        helper.doLogout(component);
    }
})