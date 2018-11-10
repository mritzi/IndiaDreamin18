/**
*  @Class Name:    InfluenceMapService
*  @Description:   This is a service class for InfluenceMapController.
*  @Company:       Standav
*  CreatedDate:    04/12/2017
*
*  Modification Log
*  -----------------------------------------------------------
*  Developer           Modification Date           Comments
*  -----------------------------------------------------------
*  K.Prashanth kumar   04/12/2017                  Original version
*/ 
public class InfluenceMapService{
    //selector class for Influence Map.
    public class InfluenceSelector extends BaseSelector{
        private List<String> INFLUENCE_MAP_SELECT_FIELDS = new List<String>{
            'Id',
            'Name',
            'Account__c',
            'Buying_Role__c',
            'Contact__c',
            'Focus__c',
            'Hierarchy__c',
            'Level_of_Contact__c',
            'Notes__c',
            'Opportunity__c',
            'Parent_Influencer__c',
            'Status__c',
            'Opportunity__r.AccountId',
            'Opportunity__r.Account.ApexAccountId__c',
            'Contact__r.Name',
            'Contact__r.Title',
            'Contact__r.Phone',
            'Contact__r.Email',
            'Contact__r.Account.Name',
            'Contact__r.Account_Name__c',
            'Contact__r.Account.ApexAccountId__c',
            'Account__r.Name',
            'Account__r.ApexAccountId__c'
        };
        /**
        *Default Constructor
        */
        public InfluenceSelector (){

        }
        /********************************************************************************************************
        *
        *Public methods
        *
        *********************************************************************************************************/
        /**
        * This method returns the List<Influence_Map__c> objects. The fields retrieved are Listed above.
        * param: oppId
        * return : List<Influence_Map__c>
        */
        public List<Influence_Map__c> getInfluenceMapByOppId(Id oppId){
            List<String> whereClause = new List<String>{'Opportunity__c =:oppId', 'Contact__c != null'};
            List<String> orderByClause = new List<String> {'Hierarchy__c'};
            String soql = super.soqlBuilder('Influence_Map__c',INFLUENCE_MAP_SELECT_FIELDS,whereClause,true,orderByClause);
            return Database.query(soql); 
        }
        /**
        * This method returns the List<Influence_Map__c> object. The fields retrieved are Listed above.
        * param: acctId
        * return : List<Influence_Map__c>
        */
        public List<Influence_Map__c> getInfluenceMapByAccountId(Id acctId){
            List<String> whereClause = new List<String>{'Account__c =:acctId', 'Contact__c != null'};
            List<String> orderByClause = new List<String> {'Hierarchy__c'};
            String soql = super.soqlBuilder('Influence_Map__c',INFLUENCE_MAP_SELECT_FIELDS,whereClause,true,orderByClause);
            return Database.query(soql); 
        }
        
        
    }
    /**
    * method Name:getInfluenceMap
    * Description: Method to get Influence Map records based on Opportunity.
    * Param : Id
    * return : list of Influence Map records.
    */
    public List<Influence_Map__c> getInfluenceMapByOpp(Id oppId){
        if(oppId != null){
            //Query to retrieve Influence_Map__c records.
            List<Influence_Map__c> influenceMapRec = new InfluenceSelector().getInfluenceMapByOppId(oppId);
            if(influenceMapRec != null && influenceMapRec.size() > 0){
                return influenceMapRec;
            }
        }
        return null;
    }
    /**
    * method Name:getInfluenceMap
    * Description: This Method is to get Influence Map records based on AccountId.
    * Param : Id
    * return : list of Influence Map records.
    */
    public List<Influence_Map__c> getInfluenceMapByAcc(Id acctId){
        if(acctId != null){
            //Query to retrieve Influence_Map__c records.
            List<Influence_Map__c> influenceMapList = new InfluenceSelector().getInfluenceMapByAccountId(acctId);
            if(influenceMapList != null && influenceMapList.size() > 0){
                return influenceMapList;
            }    
        }
        return null;
    }
}