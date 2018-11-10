({
	fireEvent : function(component, event, helper) {
		var event = component.getEvent("meetupRsvpEvent");
        var meetup = component.get("v.meetup");
        //if currently event is marked as attending -> then send 'no' & vice-versa(i.e reverse to toggle rsvp)
        event.setParams({
            "eventId": meetup.eventId,
            "groupUrlname": meetup.groupUrlname,
            "attendingEvent": meetup.attendingEvent
        });
        event.fire();
	}
})