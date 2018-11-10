({
    fireTaskEvent : function(component, event, helper) {
 
         var getSelectTask= component.get("v.objout");

        var compEvent = component.getEvent("oSelectedTaskEvent");

         compEvent.setParams({"selectedTask" : getSelectTask });  

         compEvent.fire();
    },

    gotoURL : function (component, event, helper) {
        var getSelectTask= component.get("v.objout");
        var createPromotionEvent = $A.get("e.force:createRecord");
        createPromotionEvent.setParams({
            "entityApiName": "Promotions__c",
            "defaultFieldValues": {
                'RecordTypeId' : getSelectTask.AddInfo[2],
                'Account__c' : getSelectTask.AddInfo[0],
                'Opportunity__c' : getSelectTask.AddInfo[1]
            }
        });
        createPromotionEvent.fire();
    }
})