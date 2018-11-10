/**
*  @Class Name: InfluenceMapConstants  
*  @Description: This is a constannt class for InfluenceMapController.
*  @Company: Standav
*  @CreatedDate: 04/12/2017
*  Change Log
*  -----------------------------------------------------------
*  Developer           Modification Date           Comments
*  -----------------------------------------------------------
*  K.Prashanth kumar    04/12/2017                 Original Version
*  Mohammed Rizwan   	05/01/2017                 Added Constants for Account Filter
*/
public class InfluenceMapConstants{
    public static final String ERROR_NO_CONTACTS = 'This Record has no contacts to display.';
    public static final String MESSAGE = 'success';
    public static final String INFLUENCEMAP_STATUS = 'Status__c';
    public static final String INFLUENCEMAP_FOCUS = 'Focus__c';
    public static final String INFLUENCEMAP_BUYINGROLE = 'Buying_Role__c';
    public static final String INFLUENCEMAP_LEVELOFCONTACT = 'Level_of_Contact__c';
    public static final String INFLUENCEMAP_COUNTRY = 'Alt_Mailing_Country__c';
    public static final String INFLUENCEMAP_ERROR = 'No Influence map Records created for this Account';
    public static final String INFLUENCEMAP_FILTERMESSAGE = 'No records matching filter criteria';
    //Constants used in InfluenceMapControllerTest class..
    public static final String INFLUENCEMAP_CHAMPION = 'Champion';
    public static final String INFLUENCEMAP_BLOCKER = 'Blocker';
    public static final String INFLUENCEMAP_TECHNICAL = 'Technical';
    public static final String INFLUENCEMAP_EVALUATOR = 'Evaluator';
    public static final String INFLUENCEMAP_HIGH = 'High';
    public static final String INFLUENCEMAP_FIRSTNAME = 'Test';
    public static final String INFLUENCEMAP_TITLE = 'CEO';
    public static final String INFLUENCEMAP_ZIPCODE = '50-007';
    public static final String INFLUENCEMAP_STATE = 'Karnataka';
    
    //Current Account -> 0, Related Account -> 1, All Accounts -> 2
	public static final Integer ACCOUNT_FILTER_VALUE_0 = 0;
    public static final Integer ACCOUNT_FILTER_VALUE_1 = 1;
    public static final Integer ACCOUNT_FILTER_VALUE_2 = 2;
}