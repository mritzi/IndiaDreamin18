/**
 *  @Class Name:    customLookUpService
 *  @Company: Standav
 *  CreatedDate: 06/08/2017
 *
 *  Change Log
 *  -----------------------------------------------------------
 *  Developer           Modification Date           Comments
 *  -----------------------------------------------------------
 *  Saranya              14/08/2017              Original Version
 *  Mohammed Rizwan     27/12/2017         Added new methods for Influence Map Component
 */
public with sharing class CustomLookUpService {

    /**
     * @param   searchKeyWord : used in query
     * @param   ObjectName : query object. 
     *
     * @return  List of sobject record
     *
     * @decription  This method will query the record based param values.
     */
    public List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, string filterfield, string filtervalues) {

        String searchKey = String.escapeSingleQuotes(searchKeyWord + '%');
        ObjectName = String.escapeSingleQuotes(ObjectName);

        List < sObject > returnList = new List < sObject > ();

        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5    
        String sQuery = 'select id, Name from ' + ObjectName + ' where Name LIKE: searchKey ';

        if (filterfield != null && string.isNotBlank(filterfield) && filtervalues != null && string.isNotBlank(filtervalues)) {
            sQuery += ' AND ' + filterfield + ' =:filtervalues';
        }
        sQuery += ' order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
        System.debug('filterfield-------' + filterfield + ' filter value----' + filtervalues);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    /**
     * @param searchKeyword : keyword typed in the Influece Map Lookup field
     * @param filterField : The Contact Field for which filtervalue has to be matched 
     * @param filterValue : Value that will be compared in existing contact records
     * @param accountId : accountId linked with contact records
     * @param existingContactList : list of existing contact records on the map, prevents duplicate on map 
     * @return  List of Contact records
     *
     * @description  This method will query contact object and return top 5 contact records matching searchKeyword & filtervalue.
     */
    public List < Contact > getContacts(String searchKeyword, String filterField, Integer filterValue, String accountId, List < Id > existingContactList) {
        searchKeyword = String.escapeSingleQuotes(searchKeyword) + '%';
        filterField = String.escapeSingleQuotes(filterField);
        accountId = String.escapeSingleQuotes(accountId);
        if (existingContactList != null)
            for (Id contactId: existingContactList)
                contactId = String.escapeSingleQuotes(contactId);

        List < Contact > contactList = new List < Contact > ();
        // Create a Dynamic SOQL Query to fetch contact List with LIMIT 5    
        String sQuery = 'Select Id, Name, Title, Phone, Email, AccountId, Account.Name, Account_Name__c From Contact Where (Name LIKE:searchKeyword OR LastName LIKE:searchKeyword)';
        //if query is to be made on current account, and values exists
        if (filterValue == InfluenceMapConstants.ACCOUNT_FILTER_VALUE_0 && filterField != null && String.isNotBlank(filterField) && accountId != null && String.isNotBlank(accountId))
            sQuery += ' AND ' + filterfield + ' =:accountId';
        else if (filterField != null && String.isNotBlank(filterField)) {
            sQuery += ' AND ' + filterfield + ' !=null';
        }
        if (!existingContactList.isEmpty())
            sQuery += ' AND Id NOT IN: existingContactList';
        // Search Criteria should be ASC
        sQuery += ' Order by Name ASC Limit 5';
        contactList = Database.query(sQuery);
        if (contactList.size() > 0)
            return contactList;
        else
            return null;
    }
    /**
     * @param searchKeyword : keyword typed in the Influence Map Lookup field
     * @param accountId : accountId linked with contact records
     * @param existingContactList : list of existing contact records on the map, prevents duplicate on map 
     * @return  List of Contact records
     *
     * @description  This method will query contact object and return top 5 contact records matching searchKeyword & filtervalue.
     */
    public List < Contact > getAllContacts(String searchKeyword, String accountId, String apexAccountId, List < Id > existingContactList) {
        searchKeyword = String.escapeSingleQuotes(searchKeyword) + '%';
        accountId = String.escapeSingleQuotes(accountId);
        apexAccountId = String.escapeSingleQuotes(apexAccountId);
        //at the time of writing this logic, ApexAccountId__c field length was 15, so changing Id length here to match that value
        if (apexAccountId.length() >= 18)
            apexAccountId = apexAccountId.substring(0, 15);
        if (existingContactList != null)
            for (Id contactId: existingContactList)
                contactId = String.escapeSingleQuotes(contactId);

        List < Contact > contactList = new List < Contact > ();
        // Create a Dynamic SOQL Query to fetch contact that is related to Account other than Current Account or its related Accounts, List with LIMIT 5    
        String sQuery = 'Select Id, Name, Title, Phone, Email, AccountId, Account.Name, Account_Name__c From Contact Where (Name LIKE:searchKeyword OR LastName LIKE:searchKeyword)' +
            ' AND AccountId !=: accountId AND Account.ApexAccountId__c !=: apexAccountId';

        if (!existingContactList.isEmpty())
            sQuery += ' AND Id NOT IN: existingContactList';
        // Search Criteria should be ASC
        sQuery += ' Order by Name ASC Limit 5';
        contactList = Database.query(sQuery);
        if (contactList.size() > 0)
            return contactList;
        else
            return null;
    }
    /**
     * Name : ContactLookupController
     * Description: This is without sharing innerclass in CustomLookupService, returns contact data for "Related Account" filter value.
     */
    public without sharing class ContactLookupController {
        /**
         * method Name : getAllContacts
         * param : searchKeyword,List of ContactId.
         * return : list of Contacts.
         * Description : This method will return top 5 contacts based on serch keyword from related accounts. 
         */

        public List < Contact > getContacts(String searchKeyword, String filterField, String apexAccountId, List < Id > existingContactList) {
            searchKeyword = String.escapeSingleQuotes(searchKeyword) + '%';
            filterField = String.escapeSingleQuotes(filterField);
            apexAccountId = String.escapeSingleQuotes(apexAccountId);
            //at the time of writing this logic, ApexAccountId__c field length was 15, so changing Id length here to match that value
            if (apexAccountId.length() >= 18)
                apexAccountId = apexAccountId.substring(0, 15);

            if (existingContactList != null)
                for (Id contactId: existingContactList)
                    contactId = String.escapeSingleQuotes(contactId);

            List < Contact > contactList = new List < Contact > ();
            // Create a Dynamic SOQL Query to fetch contact List with LIMIT 5    
            String sQuery = 'Select Id, Name, Title, Phone, Email, AccountId, Account.Name, Account_Name__c From Contact Where (Name LIKE:searchKeyword OR LastName LIKE:searchKeyword)';
            //follwing 3 if blocks need to execute independent of each other, don't change it to else-if
            //filterField -> Account.ApexAccountId__c, apexAccountId -> parent's accountId
            if (filterField != null && String.isNotBlank(filterField) && apexAccountId != null && String.isNotBlank(apexAccountId))
                sQuery += ' AND ' + filterfield + ' =:apexAccountId';
            if (existingContactList != null && existingContactList.size() > 0)
                sQuery += ' AND Id NOT IN: existingContactList';
            // Search Criteria should be ASC
            sQuery += ' Order by Name ASC Limit 5';
            contactList = Database.query(sQuery);
            if (contactList.size() > 0)
                return contactList;
            else
                return null;
        }
    }
}