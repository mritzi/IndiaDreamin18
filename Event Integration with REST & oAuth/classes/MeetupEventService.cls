/*
* Class:MeetupEventService
* Date: 2018-08-29
* Details: Used by MeetupEventController class to do database queries
* Upwork profile: https://www.upwork.com/freelancers/~0114d18b3a18a002da
* Freelancer profile: https://www.freelancer.com/u/mritzi
* --------------------------------------------------------------------------------------------
* ** Change Log **
* Developer         Date            Comments
* --------------------------------------------------------------------------------------------
* Mohammed R.       2018-08-29      Original version
* Mohammed R.		2018-09-04		Improved entire code
* Mohammed R.		2018-09-11		Map & String constants added for error handling
*
*/
public class MeetupEventService {
    public static final Map<String, String> ERROR_RESPONSE_MAP = new Map<String, String>{
    	'LIMIT EXCEEDED' => 'API limit reached, retry after an hour',
        'INTERNAL ERROR' => 'Internal error happened, refresh or contact Admin',
        'BAD REQUEST' => 'Corrupt data or incomplete operation',
        'INVALID PARAM' => 'Incomplete Parameters Used'
    };
    //the map and string values are tied together
    public static final String LIMIT_EXCEEDED = 'LIMIT EXCEEDED';
    public static final String INTERNAL_ERROR = 'INTERNAL ERROR';
    public static final String BAD_REQUEST = 'BAD REQUEST';
    public static final String INVALID_PARAM = 'INVALID PARAM';
    public static final String TOKEN_EXPIRED = 'TOKENS EXPIRED';
    
    public User getUserMeetupDetails(Id userId){
        if(userId != null){
            List<User> userList = new List<User>([
                Select Id, Name, Meetup_API_response__c, Meetup_oAuthAccessToken__c, 
                Meetup_oAuthRefreshToken__c, Meetup_Last_Callout_Time__c
                From User Where Id =: userId LIMIT 1 
            ]);
            if(userList.size() > 0)
                return userList[0];
        }
        return null;
    }
    //get metadata info about Meetup callout
    public Meetup_User_Detail__mdt getMDT(){
        List<Meetup_User_Detail__mdt> mdtList = new List<Meetup_User_Detail__mdt>(
            [Select Id, MasterLabel, DeveloperName, key__c, secret__c, redirectUri__c From Meetup_User_Detail__mdt Where DeveloperName = 'meetupOAuth'
        ]);
        if(mdtList.size() > 0)
            return mdtList[0];
       	return null;
    }
    //get map of Salesforce contact records
    public Map<String,Contact> getContactMap(){
        Map<String, Contact> contactMap = new Map<String, Contact>();
        List<Contact> contactList = new List<Contact>([
            Select Id, Name From Contact Order By Name LIMIT 50000
        ]);
        for(Contact contact:contactList){
            if(!contactMap.containsKey(contact.Name))
                contactMap.put(contact.Name, contact);
        }
        return contactMap;
    }
}