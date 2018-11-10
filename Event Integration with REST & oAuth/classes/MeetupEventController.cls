/*
* Class:MeetupEventController
* Date: 2018-08-29
* Details: Used by Events Lightning component to show meetup events
* Upwork profile: https://www.upwork.com/freelancers/~0114d18b3a18a002da
* Freelancer profile: https://www.freelancer.com/u/mritzi
* --------------------------------------------------------------------------------------------
* *** Change Log ****
* Developer         Date            Comments
* --------------------------------------------------------------------------------------------
* Mohammed R.       2018-08-29      Original version
* Mohammed R.		2018-09-04		Improved entire code
* Mohammed R.		2018-09-07		Added 2 more API callouts for getting calendar events + RSVP
* Mohammed R.		2018-09-11		Code overhauled for better error handling
*
*/
public class MeetupEventController{
    private static Meetup_User_Detail__mdt mdt;
    private static User user = new MeetupEventService().getUserMeetupDetails(UserInfo.getUserId());
    private static MeetupWrappers.FunctionReturn internalErrorReturn = new MeetupWrappers.FunctionReturn(false, MeetupEventService.INTERNAL_ERROR);
    /** construtor(s) **/
    public MeetupEventController(){
    }
    /** public methods **/
    /* methodName : loadDate
     * description: function called when lightning component loads, will check whether access tokens exists for user or not
     * If tokens are found, callout will be made to Meetup.com to fetch upcoming events and run suggestion logic
     * else it will prompt users to grant access using OAuth
     */
	@AuraEnabled
    public static MeetupWrappers.MeetupResponse loadData(){
		//re-use recent callout response to prevent hitting API limits
        if(hasRecentResponse(user)){
			return new MeetupWrappers.MeetupResponse('SUCCESS', 'Data found internally', user.Meetup_API_response__c);
        }
        //check for access token, if found -> use it to make callout
        else if(hasAccessTokens(user)){
            MeetupWrappers.FunctionReturn dataFetched = requestAllEvents();
            if(dataFetched.isSuccess){
                return new MeetupWrappers.MeetupResponse('SUCCESS', 'Data repopulated from meetup using access token', user.Meetup_API_response__c);
            }
            else if(!dataFetched.isSuccess && dataFetched.msg == MeetupEventService.TOKEN_EXPIRED){
                MeetupWrappers.FunctionReturn functionReturn = refreshTokens(user.Meetup_oAuthRefreshToken__c);
                if(functionReturn.isSuccess){
                    MeetupWrappers.FunctionReturn dataFetchedRef  = requestAllEvents();
                    //user = new MeetupEventService().getUserMeetupDetails(UserInfo.getUserId());
                    if(dataFetchedRef.isSuccess)
                        return new MeetupWrappers.MeetupResponse('SUCCESS', 'Data repopulated from meetup using refresh token', user.Meetup_API_response__c);
                    else
                        return new MeetupWrappers.MeetupResponse('ERROR', MeetupEventService.ERROR_RESPONSE_MAP.get(dataFetchedRef.msg), null);
                }
                //if refresh token doesn't work, ask for re-login
                else{
                    clearTokens();
                    return loginRequired('Refresh token expired/revoked');
                }
            }
            else if(!dataFetched.isSuccess && String.isNotBlank(dataFetched.msg)){
                return new MeetupWrappers.MeetupResponse('ERROR', MeetupEventService.ERROR_RESPONSE_MAP.get(dataFetched.msg), null);
            }
        }
        //no access tokens, needs login
        else{
            return loginRequired('Access tokens not found');
        }
        return new MeetupWrappers.MeetupResponse('ERROR', 'Invalid operation', null);
    }
    /* methodName : recentLoginFlow
     * description: Used to get access tokens + data after user connects his/her meetup account
     */
    @AuraEnabled
    public static MeetupWrappers.MeetupResponse recentLoginFlow(String resCode){

        MeetupWrappers.MeetupResponse nullResponse = new MeetupWrappers.MeetupResponse('ERROR', 'Invalid parameters or operation', null);
        if(String.isBlank(resCode))
            return nullResponse;
        if(user.Meetup_API_response__c != NULL){
            return new MeetupWrappers.MeetupResponse('SUCCESS', 'Data found internally (page refreshed with code)', user.Meetup_API_response__c);
        }
        resCode = String.escapeSingleQuotes(resCode);
        HttpResponse res = getAccessTokens(resCode);
        if(res.getStatusCode() == 200){
			MeetupWrappers.AccessTokenResponse accessTokenResponse = new MeetupWrappers.AccessTokenResponse();
            accessTokenResponse = (MeetupWrappers.AccessTokenResponse)JSON.deserialize(res.getBody(), MeetupWrappers.AccessTokenResponse.class);
            Boolean tokensSaved = saveAccessTokens(accessTokenResponse);
            if(tokensSaved){
                MeetupWrappers.FunctionReturn dataReceived = requestAllEvents();
                if(dataReceived.isSuccess)
                    return new MeetupWrappers.MeetupResponse('SUCCESS', 'Recent Login flow', user.Meetup_API_response__c);
                else
                    return new MeetupWrappers.MeetupResponse('ERROR', MeetupEventService.ERROR_RESPONSE_MAP.get(dataReceived.msg), null);
            }
        }
        else{
            return new MeetupWrappers.MeetupResponse('ERROR', res.getStatus(), null);
        }
        return nullResponse;

    }
    /* methodName : toggleRSVP
     * description: Used to change user's RSVP status for the selected event
     */
    @AuraEnabled
    public static Boolean toggleRSVP(String eventId, String groupUrlname, String response){
        eventId = String.escapeSingleQuotes(eventId);
        groupUrlname = String.escapeSingleQuotes(groupUrlname);
        response = String.escapeSingleQuotes(response);
        if(eventId == null || groupUrlname == null || response == null)
            return false;
        Boolean attending = response == 'yes' ? true:false;

        HttpResponse res = toggleMeetupRSVP(eventId, groupUrlname, response);
        //System.debug(res.getBody());
        if(res.getStatusCode() == 201 || String.valueOf(res.getStatus()).toLowerCase() == 'created'){
            List<MeetupWrappers.DisplayData> displayList = updateDisplayList(eventId, groupUrlname, attending);
            return updateAPIResponse(displayList);
        }
        // if token has expired, get new access token and retry changing RSVP status
        else if(res.getStatus().indexOfIgnoreCase('expire') >= 0){
            MeetupWrappers.FunctionReturn functionReturn = refreshTokens(user.Meetup_oAuthRefreshToken__c);
            if(functionReturn.isSuccess){
                res = toggleMeetupRSVP(eventId, groupUrlname, response);
                if(res.getStatusCode() == 201 || String.valueOf(res.getStatus()).toLowerCase() == 'created'){
                    List<MeetupWrappers.DisplayData> displayList = updateDisplayList(eventId, groupUrlname, attending);
                    return updateAPIResponse(displayList);
                }
            }
        }
        return false;
    }
    /* methodName : logoutMeetupUser
     * description: Used to disconnect user's meetup account
     */
    @AuraEnabled
    public static MeetupWrappers.MeetupResponse logoutMeetupUser(){
        try{
            clearTokens();
            return loginRequired('Logged out of Meetup');
        }catch(Exception ex){
            System.debug(ex);
        }
        //return nullResponse in case of any failures
        return new MeetupWrappers.MeetupResponse('ERROR', 'Invalid parameters or operation', null);
    }

    /**   private methods **/

	/* methodName : requestAllEvents
     * description: To get all upcoming events created by groups that the user is member of
     */
    private static MeetupWrappers.FunctionReturn requestAllEvents(){
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('https://api.meetup.com/self/calendar?&photo-host=public&page=30&omit=description');
        req.setHeader('content-type', 'application/json');
        req.setHeader('content-length', '0');
        req.setHeader('Authorization' , 'Bearer'+' '+ user.Meetup_oAuthAccessToken__c);
        req.setTimeout(50*1000);
        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){
        	String responseStr = res.getBody();
            List<MeetupWrappers.MeetupGroupResponse> allEventsList = new List<MeetupWrappers.MeetupGroupResponse>();
            allEventsList = (List<MeetupWrappers.MeetupGroupResponse>)JSON.deserialize(res.getBody(), List<MeetupWrappers.MeetupGroupResponse>.class);
            populateGroupData(allEventsList, responseStr);

            List<MeetupWrappers.MeetupGroupResponse> attendingEventsList = requestAttendingEvents();
            markAttendingEvents(allEventsList, attendingEventsList);
            return getEventRsvps(allEventsList);
        }
        else if(res != null){
            return handleAPIError(res);
        }
        return internalErrorReturn;
    }
    /* methodName : requestAttendingEvents
     * description: To get list of upcoming events, where the current user is marked as going
     */
    private static List<MeetupWrappers.MeetupGroupResponse> requestAttendingEvents(){

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('https://api.meetup.com/self/events?&photo-host=public&page=20&status=upcoming&omit=description');
        req.setHeader('content-type', 'application/json');
        req.setHeader('Content-length', '0');
        req.setHeader('Authorization' , 'Bearer'+' '+ user.Meetup_oAuthAccessToken__c);
        req.setTimeout(50*1000);
        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() == 200){
            String responseStr = res.getBody();
            List<MeetupWrappers.MeetupGroupResponse> meetupGroupResponseList = new List<MeetupWrappers.MeetupGroupResponse>();
            meetupGroupResponseList = (List<MeetupWrappers.MeetupGroupResponse>)JSON.deserialize(res.getBody(), List<MeetupWrappers.MeetupGroupResponse>.class);
            populateGroupData(meetupGroupResponseList, responseStr);
            //System.debug(meetupGroupResponseList);
            return meetupGroupResponseList;
        }
        return null;
    }
    /* methodName : getEventRsvps
     * description: To get list of all attendees who are marked as 'going' for events
     */
    private static MeetupWrappers.FunctionReturn getEventRsvps(List<MeetupWrappers.MeetupGroupResponse> allEventsList){
        if(allEventsList == null || allEventsList.size() == 0 || user == null)
            return new MeetupWrappers.FunctionReturn(false, MeetupEventService.INVALID_PARAM);
        List<MeetupWrappers.CombinedData> combinedList = new List<MeetupWrappers.CombinedData>();
        for(Integer i=0; i<allEventsList.size(); i++){
            //no need to call, if there is only one attendee in the event
            if(allEventsList[i].yes_rsvp_count <= 0)
                continue;

            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            String endPoint = 'https://api.meetup.com/' + allEventsList[i].meetupGroup.urlname +
                '/events/' + allEventsList[i].id + '/rsvps?&photo-host=public&response=yes&omit=event,group,venue';
            req.setEndpoint(endPoint);
            req.setHeader('content-type', 'application/json');
            req.setHeader('Content-length', '0');
            req.setHeader('Authorization' , 'Bearer'+' '+ user.Meetup_oAuthAccessToken__c);
            req.setTimeout(50*1000);
            Http http = new Http();
            HttpResponse res = http.send(req);
            //System.debug(res.getBody());

            if(res.getStatusCode() == 200){
                //System.debug(allEventsList[i].meetupGroup.urlname);
                MeetupWrappers.CombinedData combinedItem = new MeetupWrappers.CombinedData();
                combinedItem.event = allEventsList[i];
                combinedItem.rsvpList = new List<MeetupWrappers.RSVP>();

                List<MeetupWrappers.RSVP> rsvpList = new List<MeetupWrappers.RSVP>();
                rsvpList = (List<MeetupWrappers.RSVP>)JSON.deserialize(res.getBody(), List<MeetupWrappers.RSVP>.class);
                if(rsvpList.size() > 0){
                    combinedItem.rsvpList.addAll(rsvpList);
                    combinedList.add(combinedItem);
                }
                //System.debug(combinedItem);
            }
            else if(res != null){
                return handleAPIError(res);
            }
        }
        //if event & attendee list has been fetched, prepare data for display
        if(combinedList.size() > 0){
            Boolean isDataUpdated = prepareDisplayList(combinedList);
            if(isDataUpdated)
                return new MeetupWrappers.FunctionReturn(true, null);
            else
                return internalErrorReturn;
        }
        else{
            //update user record with access tokens,in case there are no upcoming events
            update user;
        }
        return internalErrorReturn;
    }
    /* methodName : prepareDisplayList
     * description: To select attendees for events who are added as Contacts in Salesforce,
     * and prepare a wrapper for the front-end
     */
    private static Boolean prepareDisplayList(List<MeetupWrappers.CombinedData> combinedList){
        if(combinedList == null || combinedList.size() == 0)
            return false;
        List<MeetupWrappers.DisplayData> displayList = new List<MeetupWrappers.DisplayData>();
        Map<String, Contact> contactMap = new MeetupEventService().getContactMap();
        for(MeetupWrappers.CombinedData item: combinedList){
            MeetupWrappers.DisplayData displayItem = new MeetupWrappers.DisplayData();
            //System.debug('event data: ' + item.event);
            displayItem.eventName = item.event.name;
            displayItem.eventDate = Date.valueOf(item.event.local_date);
            Time mTime = Time.newInstance(Integer.valueOf(item.event.local_time.left(2)), Integer.valueOf(item.event.local_time.right(2)), 0, 0);
            displayItem.eventTime = DateTime.newInstance(displayItem.eventDate, mTime);
            displayItem.eventLink = item.event.link;
            displayItem.groupName = item.event.meetupGroup.name;
            displayItem.attendingEvent = item.event.attending;
            displayItem.eventId = item.event.id;
            displayItem.groupUrlname = item.event.meetupGroup.urlname;
            if(item.event.venue != null){
                displayItem.venueName = item.event.venue.name;
                displayItem.venueStreet = item.event.venue.address_1;
                displayItem.venueCity = item.event.venue.city;
                displayItem.venueCountry = item.event.venue.localized_country_name;
            }
            displayItem.attendeeList = new List<Contact>();
            for(MeetupWrappers.RSVP rsvp:item.rsvpList){
                if(contactMap.containsKey(rsvp.member.name))
                	displayItem.attendeeList.add(contactMap.get(rsvp.member.name));
            }
            //add event details to displayList only if atleast one contact is attending
            if(displayItem.attendeeList.size() > 0)
            	displayList.add(displayItem);
        }
        // even if there are no events with common contacts, operation is successfull
        return updateAPIResponse(displayList);
    }
    /* methodName : toggleMeetupRSVP
     * description: Callout to meetup to change RSVP status for an event
     */
    private static HttpResponse toggleMeetupRSVP(String eventId, String groupUrlname, String response){
        String endPoint = 'https://api.meetup.com/' + groupUrlname +
                '/events/' + eventId + '/rsvps';
        String reqBody = 'guests=0&agree_to_refund=true&response='+ response;

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(endPoint);
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setHeader('content-length', String.valueOf(reqBody.length()));
        req.setHeader('Authorization' , 'Bearer'+' '+ user.Meetup_oAuthAccessToken__c);
        req.setBody(reqBody);
        req.setTimeout(50*1000);
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res;
    }
    /* methodName : getAccessTokens
     * description: get access tokesn from Meetup.com after login
     */
    private static HttpResponse getAccessTokens(String resCode){
        mdt = new MeetupEventService().getMDT();

        String body  = 'client_id=' + mdt.key__c + '&client_secret=' + mdt.secret__c + '&grant_type=authorization_code&redirect_uri=' + mdt.redirectUri__c + '&code=' + resCode;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://secure.meetup.com/oauth2/access');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setHeader('content-length', String.valueOf(body.length()));
        req.setBody(body);
        req.setTimeout(5*1000);

        String responseStr;
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res;
    }
    /* methodName : refreshTokens
     * description: Get new access tokens after it expires using refresh token
     */
    private static MeetupWrappers.FunctionReturn refreshTokens(String refreshToken){
        refreshToken = String.escapeSingleQuotes(refreshToken);
        if(String.isEmpty(refreshToken))
            return new MeetupWrappers.FunctionReturn(false, MeetupEventService.INVALID_PARAM);
        mdt = new MeetupEventService().getMDT();

        String body  = 'client_id=' + mdt.key__c + '&client_secret=' + mdt.secret__c + '&grant_type=refresh_token&refresh_token=' + refreshToken;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://secure.meetup.com/oauth2/access');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setHeader('content-length', String.valueOf(body.length()));
        req.setBody(body);
        req.setTimeout(5*1000);

        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200){
            MeetupWrappers.RefreshTokenResponse refResponse = new MeetupWrappers.RefreshTokenResponse();
            refResponse = (MeetupWrappers.RefreshTokenResponse)JSON.deserialize(res.getBody(), MeetupWrappers.RefreshTokenResponse.class);
            user.Meetup_oAuthAccessToken__c = refResponse.access_token;
            user.Meetup_oAuthRefreshToken__c = refResponse.refresh_token;
            return new MeetupWrappers.FunctionReturn(true, null);
        }
        else if(res != null){
            return handleAPIError(res);
        }
        return new MeetupWrappers.FunctionReturn(false, MeetupEventService.INTERNAL_ERROR);
    }
    /* methodName : handleAPIError
     * description: Resuable function to handle HttpResponse errors
     */
    private static MeetupWrappers.FunctionReturn handleAPIError(HttpResponse res){
        //default error message
        MeetupWrappers.FunctionReturn functionReturn = new MeetupWrappers.FunctionReturn(false,MeetupEventService.INTERNAL_ERROR);
        if(res != null){
            if(res.getStatusCode() == 400)
                functionReturn.msg = MeetupEventService.BAD_REQUEST;
            else if(res.getStatusCode() == 429)
                functionReturn.msg = MeetupEventService.LIMIT_EXCEEDED;
            else if(res.getStatus().indexOfIgnoreCase('expire') >= 0)
                functionReturn.msg = MeetupEventService.TOKEN_EXPIRED;
        }
        return functionReturn;
    }
    /* methodName : markAttendingEvents
     * description: compare all events against events which user is attending and set appropriate flag (to be used in front-end)
     */
    private static void markAttendingEvents(List<MeetupWrappers.MeetupGroupResponse> allEventsList, List<MeetupWrappers.MeetupGroupResponse> attendingEventsList){
        if(allEventsList == null || attendingEventsList == null)
            return;
        //key -> combination of event.Id-event.name, to ensure it's unique
    	Map<String, MeetupWrappers.MeetupGroupResponse> attendingEventsMap = new Map<String, MeetupWrappers.MeetupGroupResponse>();
        for(MeetupWrappers.MeetupGroupResponse event:attendingEventsList)
            attendingEventsMap.put(event.id+'-'+event.name, event);

        for(MeetupWrappers.MeetupGroupResponse event:allEventsList){
            String key = event.id + '-' + event.name;
            // if key is found,then user is attending the event, else not attending the event
            event.attending = attendingEventsMap.containsKey(key);
        }
    }
    /* methodName : populateGroupData
     * description: populate data related to group in the wrapper
     */
    private static void populateGroupData(List<MeetupWrappers.MeetupGroupResponse> eventsList, String responseStr){
        Integer curIndex=0;
        Integer indexOfGroup = -1, indexOfClosedBrace = -1;
        for(Integer i=0; i< eventsList.size(); i++){
            indexOfGroup = responseStr.indexOf('"group":', curIndex);
            if(indexOfGroup > 0){
                indexOfGroup += 8;
                indexOfClosedBrace = responseStr.indexOf('}', indexOfGroup);
                if(indexOfClosedBrace > 0){
                    String groupStr = responseStr.subString(indexOfGroup, ++indexOfClosedBrace);
                    System.debug('groupStr : ' + groupStr);
                    //ensure that there is no other opening brace except at index 0
                    if(groupStr.indexOf('{') > 0)
                        return;
                    eventsList[i].meetupGroup = (MeetupWrappers.MeetupGroup)JSON.deserialize(groupStr, MeetupWrappers.MeetupGroup.class);

                    curIndex = indexOfClosedBrace;
                }
            }

        }

    }
    /* methodName : updateDisplayList
     * description: updates wrapper data after user toggles RSVP status
     */
    public static List<MeetupWrappers.DisplayData> updateDisplayList(String eventId, String groupUrlname, Boolean attending){
        List<MeetupWrappers.DisplayData> displayList = (List<MeetupWrappers.DisplayData>)JSON.deserialize(user.Meetup_API_response__c, List<MeetupWrappers.DisplayData>.class);
        for(MeetupWrappers.DisplayData item:displayList){
            if(item.eventId == eventId && item.groupUrlname == groupUrlname){
                item.attendingEvent = attending;
                break;
            }
        }
        return displayList;
    }
    /* methodName : loginRequired
     * description: prepare wrapper for front-end to indicate that the user needs to connect his/her Meetup account
     */
   	private static MeetupWrappers.MeetupResponse loginRequired(String msg){
        return new MeetupWrappers.MeetupResponse('LOGIN_REQUIRED', msg, null);
    }
    /* methodName : hasRecentResponse
     * description: To flag whether a user is re-visiting the component after recent callout
     * helps in re-using recent callout result to avoid hitting API limits
     */
    private static Boolean hasRecentResponse(User user){
        if(user.Meetup_API_response__c != null && user.Meetup_Last_Callout_Time__c != null &&
           user.Meetup_Last_Callout_Time__c.addHours(4) >= Datetime.now())
            return true;
        //otherwise
        return false;
    }
    /* methodName : hasAccessTokens
     * description: checks whether there is access tokens saved for the user or not
     */
    private static Boolean hasAccessTokens(User user){
        return String.isNotBlank(user.Meetup_oAuthAccessToken__c) && String.isNotBlank(user.Meetup_oAuthRefreshToken__c);
    }
    /* methodName : updateAPIResponse
     * description: save callout response in Salesforce for re-use, and thus saving API limits
     */
    private static Boolean updateAPIResponse(List<MeetupWrappers.DisplayData> displayList){
        try{
            user.Meetup_API_response__c = JSON.serialize(displayList);
            user.Meetup_Last_Callout_Time__c = Datetime.now();
        	update user;
            return true;
        }
        catch(Exception ex){
            System.debug(ex);
        }
        //return false, in case try block fails (fallback option)
        return false;
    }
    /* methodName : saveAccessTokens
     * description: save access tokens for future use
     */
    private static Boolean saveAccessTokens(MeetupWrappers.AccessTokenResponse accessTokenResponse){
        if(accessTokenResponse.access_token != null && accessTokenResponse.refresh_token != null){
            user.Meetup_oAuthAccessToken__c = accessTokenResponse.access_token;
            user.Meetup_oAuthRefreshToken__c = accessTokenResponse.refresh_token;
            return true;
        }
        return false;
    }
    /* methodName : clearTokens
     * description: Disconnect user's Meetup account and clear any saved credentials
     */
    private static void clearTokens(){
        user.Meetup_API_response__c = '';
        user.Meetup_oAuthAccessToken__c = '';
        user.Meetup_oAuthRefreshToken__c = '';
        user.Meetup_Last_Callout_Time__c = null;
        update user;
    }
}
