({
   selectRecord : function(component, event, helper){      
    // get the selected record from list  
      var getSelectRecord = component.get("v.oRecord");
    // call the event   
      var compEvent = component.getEvent("oSelectedRecordEvent");
       var labelname = component.get("v.label");
    // set the Selected sObject Record to the event attribute.  
         compEvent.setParams({
             "recordByEvent" : getSelectRecord,
             "labelofLookup" : labelname
         });  
    // fire the event  
         compEvent.fire();
    },
})