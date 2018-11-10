/**
* @author          Nidheesh N
* @date            05th August 2017
* @description      Controller Class for DemoDynamicComponent aura component ; This is a custom Controller.
*  ------------------------------------------------------------------------
*  Developer           Modification Date           Comments
*  ------------------------------------------------------------------------
*  Mohammed Rizwan    22/12/2017          Methods added to handle Influence Map component actions
*
*/
public class CustomLookUpController {
    
    /**
    * @param   searchKeyWord : used in query
    * @param   ObjectName : query object. 
    *
    * @return  List of sobject record
    *
    * @decription  This method will query the record based param values.
    */
    @AuraEnabled
    public static List <sObject> fetchLookUpValues(String searchKeyWord, String ObjectName,string filterfield,string filtervalues) {
        try{
            
            return new CustomLookUpService().fetchLookUpValues(searchKeyWord, ObjectName,filterfield,filtervalues);
            
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            
        }
    }
    /**
    * method Name : getContacts
    * param : searchKeyword,filterfield,accountId,list of ContactId
    * return : list of Contacts.
    * Description : This method will return top 5 contacts based on serch keyword,filterfield from an account. 
    */
    @AuraEnabled
    public static List<Contact> getContacts(String searchKeyword, String filterField, String filterValue, String accountId, String apexAccountId, List<Id> existingContactList){
        
        try{
            Integer filterVal = Integer.valueOf(filterValue);
            // Current Account
            if(filterVal == InfluenceMapConstants.ACCOUNT_FILTER_VALUE_0){
              return  preventDuplicatesbyEmail( new CustomLookupService().getContacts(searchKeyword, filterField, filterVal, accountId, existingContactList));
            }
            // Related Accounts
            else if(filterVal == InfluenceMapConstants.ACCOUNT_FILTER_VALUE_1){
                CustomLookupService.ContactLookupController contactLookup = new CustomLookupService.ContactLookupController();
                return preventDuplicatesbyEmail(contactLookup.getContacts(searchKeyword, filterField, apexAccountId, existingContactList));
            }
            // All Accounts
            else if(filterVal == InfluenceMapConstants.ACCOUNT_FILTER_VALUE_2){
                return preventDuplicatesbyEmail( new CustomLookupService().getAllContacts(searchKeyword, accountId, apexAccountId, existingContactList));
            }
        }catch(Exception ex){
            System.debug('error : ' + ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return null;
    }
    
    /**
    * method Name : preventDuplicatesbyEmail
    * param : List<Contact>
    * return : List<Contact>.
    * Description : This method will return deduplicated Contacts  
    */
    private static List<Contact> preventDuplicatesbyEmail(List <Contact> lstContact){
        
        List<Contact> lstContactFiltered = new List<Contact>();
        set<String> setEmails = new set<String>();
        if(lstContact != null && !lstContact.isEmpty()){
            for(Contact objContact: lstContact){
                // Filtering based on Contact
                if(!String.isBlank(objContact.Email)){
                    if(!setEmails.contains(objContact.Email)){
                        // Filtered Contacts
                        lstContactFiltered.add(objContact);
                        setEmails.add(objContact.Email);
                    }
                }else{
					lstContactFiltered.add(objContact);
				}
                
            }
            
        }
        return lstContactFiltered;
    }
}