/*
* Class:MeetupWrappers
* Date: 2018-08-29
* Details: Used by MeetupEventController class to create/handle custom data structures
* Upwork profile: https://www.upwork.com/freelancers/~0114d18b3a18a002da
* Freelancer profile: https://www.freelancer.com/u/mritzi
* --------------------------------------------------------------------------------------------
* ** Change Log **
* Developer         Date            Comments
* --------------------------------------------------------------------------------------------
* Mohammed R.       2018-08-29      Original version
* Mohammed R.		2018-09-04		Improved entire code
* Mohammed R.		2018-09-11		New Wrapper classes added
*
*/
public class MeetupWrappers {
    public MeetupWrappers(){

    }
    public class FunctionReturn{
        public Boolean isSuccess;
        public String msg;
        public FunctionReturn(Boolean isSuccess, String msg){
            this.isSuccess = isSuccess;
            this.msg = msg;
        }
    }
	// the format in which data will be sent to Lightning component
    public class MeetupResponse{
        @AuraEnabled public String state;
        @AuraEnabled public String stateMsg;
        @AuraEnabled public List<MeetupWrappers.DisplayData> displayList;
        public MeetupResponse(){
            state = stateMsg = '';
            displayList = new List<MeetupWrappers.DisplayData>();
        }
        public MeetupResponse(String state, String stateMsg, String responseString){
            this.state = state;
            this.stateMsg = stateMsg;
            this.displayList = responseString != null ? (List<MeetupWrappers.DisplayData>)JSON.deserialize(responseString, List<MeetupWrappers.DisplayData>.class) : new List<MeetupWrappers.DisplayData>();
        }
    }
    //to parse API response to get events that user is attending
    public class MeetupGroupResponse{
        //in UTC
        public Long created;
        public Long duration;
        public String id;
        public String name;
        public String status;
        // yyyy-mm-dd
        public Date local_date;
        //hh:mm
        public String local_time;
        //in UTC
        public Long updated;
        public Long utc_offset;
        public Integer waitlist_count;
        public Integer yes_rsvp_count;
        //url
        public String link;
        public String description;
		public String visibility;
        public Boolean attending;
        public MeetupWrappers.MeetupVenue venue;
        public MeetupWrappers.MeetupGroup meetupGroup;
    }
    //to parse list of people attending any given event
    public class RSVP{
        public Long created;
        public Long updated;
        public String response;
        public Integer guests;
        public MeetupWrappers.MeetupEvent event;
        public MeetupWrappers.MeetupGroup meetupGroup;
        public MeetupWrappers.Member member;
        public MeetupWrappers.MeetupVenue venue;
    }
    //used to club event detail and rsvp list
    public class CombinedData{
        public MeetupWrappers.MeetupGroupResponse event;
        public List<MeetupWrappers.RSVP> rsvpList;
    }
    //Wrapper that will contain info related to events and venue to be sent to Lightning component
    public class DisplayData{
        @AuraEnabled public String eventName;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public DateTime eventTime;
        @AuraEnabled public String eventLink;
        @AuraEnabled public String venueName;
        @AuraEnabled public String venueStreet;
        @AuraEnabled public String venueCity;
        @AuraEnabled public String venueCountry;
        @AuraEnabled public String groupName;
        @AuraEnabled public String eventId;
        @AuraEnabled public String groupUrlname;
        @AuraEnabled public Boolean attendingEvent;
        @AuraEnabled public List<Contact> attendeeList;
    }
    /*
    public class Attendee{
        public String name;
        public String thumbnailLink;
    }
    */
    //To parse venue details of the event
    public class MeetupVenue{
        public String id;
        public String name;
        public String lat;
        public String lon;
        public String repinned;
        public String address_1;
        public String city;
        public String country;
        public String localized_country_name;
        public String phone;
        public String zip;
        public String state;
    }
    //to parse group detail of any group
    public class MeetupGroup{
        public Long created;
        public String name;
        public String id;
        public String join_mode;
        public String lat;
        public String lon;
        public String urlname;
        public String who;
        public String localized_location;
        public String region;
        public String timezone;
    }
    public class MeetupEvent{
        public String id;
        public String name;
        public Integer yes_rsvp_count;
        public Long meetupTime;
        public Long utc_offset;
    }
    public class Member{
        public Long id;
        public String name;
        public String bio;
        public MeetupWrappers.Photo photo;        
        public MeetupWrappers.EventContext event_context;
    }
    public class Photo{
        public Long id;
        public String highres_link;
        public String photo_link;
        public String thumb_link;
        public String type;
        public String base_url;
    }
    public class EventContext{
        public String host;
    }
    public class AccessTokenResponse{
        public String access_token;
        public String id_token;
        public String expires_in;
        public String token_type;
        public String refresh_token;
    }
    public class RefreshTokenResponse{
        public String access_token;
        public String token_type;
        public String expires_in;
        public String refresh_token;
        
    }
}