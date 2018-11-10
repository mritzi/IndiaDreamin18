/**
*  @Class Name: InfluenceMapController  
*  @Description: This is a Controller class for InfluenceMap on Account,Opportunity and Contact.
*  @Company: Standav
*  @CreatedDate: 29/11/2017
*
*  Change Log
*  -----------------------------------------------------------
*  Developer           Modification Date           Comments
*  -----------------------------------------------------------
*  K.Prashanth kumar   29/11/2017                  Original Version
*
*/
public class InfluenceMapController{
    /**===============================================================
      Description : This is a contructor for InfluenceMapController.
      ===============================================================*/ 
    public InfluenceMapController(){
    }
    /**
    * Method Name: validateInfluenceMapComponent
    * Description : This method is to return component based on sObject,if it is Account/Opportunity or Contact. 
    * Param: recordId
    * return : String
    */
    @AuraEnabled
    public static String validateInfluenceMapComponent(Id recordId){
        if(recordId != null){
            Schema.SObjectType objectAPIName = LEXUtils.getObjectTypeById(recordId);
            if(objectAPIName == Account.SObjectType){
                List<Contact> conList = new ContactService().checkHasContacts(recordId);
                if(conList != null){
                    return InfluenceMapConstants.MESSAGE;
                }else{
                    throw new AuraHandledException(InfluenceMapConstants.ERROR_NO_CONTACTS);
                }
            }
            if(objectAPIName == Opportunity.SObjectType){
                Opportunity opp = new OpportunityService().getOppRecord(recordId);
                List<Contact> conList = new ContactService().checkHasContacts(opp.AccountId);
                if(conList != null){
                    return InfluenceMapConstants.MESSAGE;
                }else{ 
                    throw new AuraHandledException(InfluenceMapConstants.ERROR_NO_CONTACTS);
                }     
            }
            if(objectAPIName == Contact.SObjectType){
                return InfluenceMapConstants.MESSAGE;
            }
        }
        return null;
    }
    /**
    * Method Name: getInflunceMapRecords
    * Description : This is a method to return a wrapper containing data and metadata of Influnce map records for (sObject)Account/Opportunity/Contact based on recordId.
    * Param: recordId
    * return : InfluenceMapMetaData
    */
    @AuraEnabled
    public static InfluenceMapMetaData getInflunceMapRecords(Id recordId){
        if(recordId != null){
            Schema.SObjectType objectAPIName = LEXUtils.getObjectTypeById(recordId);
            List<Influence_Map__c> listOfInfluenceRec = new List<Influence_Map__c>();
            if(objectAPIName == Opportunity.SObjectType){
                Opportunity opp = new OpportunityService().getOppRecord(recordId);
                listOfInfluenceRec = new InfluenceMapService().getInfluenceMapByOpp(recordId);
            }
            if(objectAPIName == Account.SObjectType){
                Account acc = new AccountService().getAccountRecord(recordId);
                listOfInfluenceRec = new InfluenceMapService().getInfluenceMapByAcc(recordId);
            }
            if(objectAPIName == Contact.SObjectType){
                Contact con = new ContactService().getContactRecord(recordId);
                listOfInfluenceRec = new InfluenceMapService().getInfluenceMapByAcc(con.AccountId);
            }
            InfluenceMapMetaData metaData = getMetaData(recordId);
            InfluenceMapData data = getInfluenceMapData(recordId,listOfInfluenceRec);
            metaData.data = data;
            return metaData;
        }
        return null;
    }
    /**
    * Method Name: getInfluenceMapData
    * Description : This is a method to return a wrapper containing data of Influnce map records for (sObject)Account/Opportunity/Contact based on recordId.
    * Param: recordId,List<Influence_Map__c>
    * return : InfluenceMapData
    */
    @AuraEnabled
    public static InfluenceMapData getInfluenceMapData(Id recordId, List<Influence_Map__c> lstInfluenceMap){
        InfluenceMapData data = new InfluenceMapData();
        Influence_Map__c parentRec = new Influence_Map__c();
        Map<id,Influence_Map__c> mapOfInfluenceRec = new Map<Id,Influence_Map__c>();
        Map<id,List<Influence_Map__c>> mapOfInfluenceRecChildren = new Map<Id,List<Influence_Map__c>>();
        if(lstInfluenceMap != null){
            for(Influence_Map__c inf : lstInfluenceMap){
                mapOfInfluenceRec.put(inf.id,inf);
                if(inf.Parent_Influencer__c == null){    
                    parentRec = inf;                    
                }
                if(mapOfInfluenceRecChildren.containskey(inf.Parent_Influencer__c)){
                    mapOfInfluenceRecChildren.get(inf.Parent_Influencer__c).add(inf);
                }
                else{
                    List<Influence_Map__c> newInfluenceMapList = new List<Influence_Map__c>();
                    newInfluenceMapList.add(inf);
                    mapOfInfluenceRecChildren.put(inf.Parent_Influencer__c,newInfluenceMapList);
                }         
            }
            getInfluenceMapChildrenRecursive(parentRec.Id,data,mapOfInfluenceRecChildren.get(parentRec.Id),mapOfInfluenceRec,mapOfInfluenceRecChildren,recordId);
        }
        return data;
    }
    /**
    * Method Name: getInfluenceMapChildrenRecursive
    * Description : This is a method to get influnce map records for parent record. 
    * Param: infId,Influence map data wrapper,List<Influence_Map__c>,map<id,Influence_Map__c>,map<id,List<Influence_Map__c>>
    * return : void
    */
    private static void getInfluenceMapChildrenRecursive(Id infId ,InfluenceMapData node, List<Influence_Map__c> children,Map<id,Influence_Map__c> mapOfRec,Map<id,List<Influence_Map__c>> mapOfChildren,Id recordId){     
        //populate values in node from Map<Id,Influence_Map__c>
        getInfluenceMapWrapper(mapOfRec.get(infId),node);        
        node.children= new List<InfluenceMapData>();
        if(children == null){
            return;
        }
        for(Influence_Map__c child : children){
            InfluenceMapData childRecords = new InfluenceMapData();
            node.children.add(childRecords);
            getInfluenceMapChildrenRecursive(child.Id,childRecords,mapOfChildren.get(child.Id),mapOfRec,mapOfChildren,recordId);
        }
           
    }
    /**
    * Method Name : getInfluenceMapWrapper
    * Description : This is a method to populate values in InfluenceMapDetailsWrapper from Influence map Record.
    * param : Influence_Map__c,InfluenceMapWrapper
    * return : void
    */
    private static void getInfluenceMapWrapper(Influence_Map__c infRec, InfluenceMapData data){
        if(infRec == null){
            return;
        }
        data.objContact = infRec.Contact__r.clone();
        data.objContact.id= infRec.Contact__c;
        if(infRec.Account__c == infRec.Contact__r.AccountId || infRec.Opportunity__r.AccountId == infRec.Contact__r.AccountId){
            data.intAccountFilter = 0;
        }
        else if(infRec.Account__r.ApexAccountId__c == infRec.Contact__r.Account.ApexAccountId__c || infRec.Opportunity__r.Account.ApexAccountId__c == infRec.Contact__r.Account.ApexAccountId__c){
            data.intAccountFilter = 1;
        }else{
            data.intAccountFilter = 2;
        }
        infRec.Contact__r = null;
        infRec.Account__r = null;
        infRec.Opportunity__r = null;
        data.objInfluenceMap = infRec;
    }
 
    /**
    * Method Name: saveInfluenceMapRec
    * Description : This is a method for Save functionality in influence map.
    * Param: JSON String,recordId
    * return : void
    */
    @AuraEnabled
    public static void saveInfluenceMapRec(String jsonValue,Id recordId){

        Savepoint sp = Database.setSavepoint();
        
        Schema.SObjectType objectAPIName = LEXUtils.getObjectTypeById(recordId);
        List<Influence_Map__c> lstInfluenceMap = new List<Influence_Map__c>();
        if(objectAPIName == Opportunity.SObjectType){
            lstInfluenceMap = new InfluenceMapService().getInfluenceMapByOpp(recordId);
        }
        if(objectAPIName == Account.SObjectType){
            lstInfluenceMap = new InfluenceMapService().getInfluenceMapByAcc(recordId);
        }
        if(objectAPIName == Contact.SObjectType){
            Contact con = new ContactService().getContactRecord(recordId);
            lstInfluenceMap = new InfluenceMapService().getInfluenceMapByAcc(con.AccountId);
        }
        try{
            if(lstInfluenceMap != null && !lstInfluenceMap.isEmpty()){
                delete lstInfluenceMap;
            }
        }catch(exception e){
            Database.rollback(sp);
        }
        
        InfluenceMapData recordsForSave = (InfluenceMapData) JSON.deserialize(jsonValue,InfluenceMapData.class);
        
        if(recordsForSave.objInfluenceMap != null){
            List<Influence_Map__c> lstAllInfluenceMapToInsert = new List<Influence_Map__c>();
            // Getting the List of Records to Save
            getChildrenToSave(recordsForSave,lstAllInfluenceMapToInsert);
            
            Map<Id,Influence_Map__c> mapParentInfluenceMap = new Map<Id,Influence_Map__c>();
            for(Influence_Map__c inf : lstAllInfluenceMapToInsert)
                mapParentInfluenceMap.put(inf.Id, inf);
            
            Map<id,id> mapForAccountMapParentInfluencer = new Map<id,id>();
            for(Influence_Map__c inf : lstAllInfluenceMapToInsert){
                if(inf.Parent_Influencer__c != null && mapParentInfluenceMap.containsKey(inf.Parent_Influencer__c)){
                    Influence_Map__c parentInf = mapParentInfluenceMap.get(inf.Parent_Influencer__c);
                    mapForAccountMapParentInfluencer.put(inf.Contact__c, parentInf.Contact__c);
                }
                inf.Id = inf.Parent_Influencer__c = null;
            }
            try{
                if(lstAllInfluenceMapToInsert.size() > 0){
                    insert lstAllInfluenceMapToInsert;
                }
            }catch(Exception e){
                Database.rollback(sp);
            }
            // Map for the Contact and the present influence Map Id
            map<id, id> mapContactInfluenceMap = new map<id, id>();
            for(Influence_Map__c inf : lstAllInfluenceMapToInsert){
                mapContactInfluenceMap.put(inf.Contact__c, inf.id);
            }
        
            for(Influence_Map__c infRec : lstAllInfluenceMapToInsert){
                if(mapForAccountMapParentInfluencer.containsKey(infRec.Contact__c)){
                    infRec.Parent_Influencer__c = mapContactInfluenceMap.get(mapForAccountMapParentInfluencer.get(infRec.Contact__c));
                }
            }
            // Updating the Parent Influencers
            try{
                if(lstAllInfluenceMapToInsert.size() > 0){
                    update lstAllInfluenceMapToInsert;
                }
            }catch(Exception e){
                Database.rollback(sp);
            }
        }
    }
    /**
    * Method Name: getChildrenToSave
    * Description : This is a method to get influnce map records from the deserialized wrapper which is sent from the UI.
    * Param: InfluenceMapWrapper
    * return : void
    */
    private static void getChildrenToSave(InfluenceMapData data,List<Influence_Map__c> lstAllInfluenceMapToInsert){
        if(data == NULL){
            return;
        }
        Influence_Map__c infRec = new Influence_Map__c();
        infRec = data.objInfluenceMap;
        infRec.Contact__c = data.objContact.id;
        lstAllInfluenceMapToInsert.add(infRec); 
        for(InfluenceMapData child : data.children){ 
            getChildrenToSave(child,lstAllInfluenceMapToInsert);
        }
    }
    /**
    * Method Name : getMetaData
    * Description : This is a method to get all options for picklist fields and store that in a Influence map metadata wrapper.
    * Param : sObjectId
    * return : InfluenceMapMetaData
    */
    @AuraEnabled
    public static InfluenceMapMetaData getMetaData(Id recordId){
        if(recordId != null){
            Schema.SObjectType objectAPIName = LEXUtils.getObjectTypeById(recordId);
            Influence_Map__c objInf = new Influence_Map__c();       
            List<PickListData> valuesForFocus = getPickListData(objInf,InfluenceMapConstants.INFLUENCEMAP_FOCUS);
            List<PickListData> valuesForLevelOfContact = getPickListData(objInf,InfluenceMapConstants.INFLUENCEMAP_LEVELOFCONTACT);
            List<PickListData> valuesForBuyingRole = getPickListData(objInf,InfluenceMapConstants.INFLUENCEMAP_BUYINGROLE);
            List<PickListData> valuesForStatus = getPickListData(objInf,InfluenceMapConstants.INFLUENCEMAP_STATUS);
            Contact conObj = new Contact();
            List<SelectOption> countryPickList = LEXUtils.getPicklistValues(conObj,InfluenceMapConstants.INFLUENCEMAP_COUNTRY); 
            List<String> countryPickVal = new List<String>();
            for(SelectOption opt : countryPickList){
                countryPickVal.add(opt.getValue());
            }
            InfluenceMapMetaData metaData = new InfluenceMapMetaData();
            metaData.listStatus = valuesForStatus;
            metaData.listFocus = valuesForFocus;
            metaData.listContactLevel = valuesForLevelOfContact;
            metaData.listBuyingRole = valuesForBuyingRole;
            metaData.sObjectId = recordId;
            metaData.strSObjectType = objectAPIName.getDescribe().getName();
            metaData.listCountry = countryPickVal;
            Account acc = new Account();
            if(objectAPIName == Opportunity.SObjectType){
                Opportunity opp = new OpportunityService().getOppRecord(recordId);
                acc = new AccountService().getAccountRecord(opp.AccountId);
                metaData.accountId = opp.AccountId;
                metaData.strSObjectName = opp.Name;
            }
            if(objectAPIName == Account.SObjectType){
                acc = new AccountService().getAccountRecord(recordId);
                metaData.accountId = recordId;              
                metaData.strSObjectName = acc.Name;
            }
            if(objectAPIName == Contact.SObjectType){
                Contact con = new ContactService().getContactRecord(recordId);
                acc = new AccountService().getAccountRecord(con.AccountId);
                metaData.accountId = con.AccountId;
                metaData.strSObjectName = con.Account.Name;
            }
            metaData.parentAccountId = acc.ApexAccountId__c;
            Boolean userAccess = LEXUtils.getUserPermission(metaData.accountId);
            metaData.hasAccountEditAccess = userAccess;
            return metaData;
        }
        return null;
    }
    /**
    * Method Name : getPickListData
    * Description : This is a method to get Picklist values dynamically and populate them in metadatawrapper.
    * param : object,picklist field
    * return : List<PickListData>
    */
    private static List<PickListData> getPickListData(sObject obj,String fld){
        List<PickListData>lstpicklist = new List<PickListData>();
        List<SelectOption> options = LEXUtils.getPicklistValues(obj,fld);
        for(SelectOption opt : options){
            PickListData pickListVal = new PickListData();
            pickListVal.strApi = opt.getLabel();
            pickListVal.strValue = opt.getValue();
            pickListVal.strChar = opt.getLabel().substring(0,1);
            lstpicklist.add(pickListVal);
        }
        return lstpicklist;
    }
    /**
    * Method Name : createContact
    * Description : This is a method to Add Contact.
    * Param : Contact Object ,AccountId
    * return : Contact
    */
    @AuraEnabled
    public static Contact createContact(Contact objCon ){
        try{
            if(objCon != null){
                insert objCon;
                Contact contact = new Contact();
                contact = new ContactService().getContactRecord(objCon.Id); 
                return contact;
            } 
        }catch(Exception e){
            Throw new AuraHandledException(e.getMessage());
        }    
        return null;
    }
    /**
    * Method Name: fetchInfRecFromAccount
    * Description : This is a method which returns the wrapper containing data of Influnce map records fetched from account.
    * Param: recordId,acctId,statusPicklist,buyingRolePickList,focusPickList,levelOfContactPicklist.
    * return : InfluenceMapData
    */
    @AuraEnabled
    public static OpportunityInfluenceMapData fetchInfRecFromAccount(Id recordId, Id acctId, List<String> statusPickList, List<String> buyingRolePickList, List<String> focusPickList, List<String> levelOfContactPicklist){
        if(recordId != null){
            // list containing all the records related to Account of an Opportunity.
            List<Influence_Map__c> lstAllInfluenceMap = new InfluenceMapService().getInfluenceMapByAcc(acctId);
            InfluenceMapData data = new InfluenceMapData();
            OpportunityInfluenceMapData opportunityData = new OpportunityInfluenceMapData();
            if(lstAllInfluenceMap != null){
                set<String> setStatusPicklist = new set<String>();
                set<String> setBuyingRolePickList = new set<String>();
                set<String> setFocusPicklist = new set<String>();
                set<String> setlevelOfContactPicklist = new set<String>();
                if(!statusPickList.isEmpty()){
                    setStatusPicklist.addAll(statusPickList);
                }
                if(!buyingRolePickList.isEmpty()){
                    setBuyingRolePickList.addAll(buyingRolePickList);
                }
                
                if(!focusPickList.isEmpty()){
                    setFocusPicklist.addAll(focusPickList);
                }
                
                if(!levelOfContactPicklist.isEmpty()){
                    setlevelOfContactPicklist.addAll(levelOfContactPicklist);
                }
                // list containg few records based on filter conditions for account of an Opportunity.
                List<Influence_Map__c> lstFilteredInfluenceMap = new List<Influence_Map__c> ();
                // map containing all the records related to Account of an Opportunity.
                Map<Id,Influence_Map__c> mapForAccount = new Map<Id,Influence_Map__c>();
                // First Node
                Influence_Map__c objParent = new Influence_Map__c();
                // map of parentid and List<children> which contains all records for account
                Map<Id,List<Influence_Map__c>> mapChildrenFromAccount = new Map<Id,List<Influence_Map__c>>();
                // map containg few records based on filter conditions for account of an Opportunity.
                Map<Id,Influence_Map__c> mapForOpportunity = new Map<Id,Influence_Map__c>();
                for(Influence_Map__c inf : lstAllInfluenceMap){
                    inf.Account__c = null;
                    inf.Opportunity__c = recordId;
                    mapForAccount.put(inf.Id,inf);
                    if(inf.Parent_Influencer__c == null){
                        objParent = inf;
                    }
                    if(mapChildrenFromAccount.containskey(inf.Parent_Influencer__c)){
                        mapChildrenFromAccount.get(inf.Parent_Influencer__c).add(inf);
                    }
                    else{
                        List<Influence_Map__c> newInfluenceMapList = new List<Influence_Map__c>();
                        newInfluenceMapList.add(inf);
                        mapChildrenFromAccount.put(inf.Parent_Influencer__c,newInfluenceMapList);
                    }
                    
                        // Filter out the neccessary Influence Map Records
                    if(setStatusPicklist.contains(inf.Status__c) && setBuyingRolePickList.contains(inf.Buying_Role__c) && 
                    setFocusPicklist.contains(inf.Focus__c) && setlevelOfContactPicklist.contains(inf.Level_of_Contact__c)){
                        mapForOpportunity.put(inf.Id,inf);
                        lstFilteredInfluenceMap.add(inf);
                    }
                    
                }
                List<InfluenceMapNode> listNodeFromAccount = new List<InfluenceMapNode>();
                InfluenceMapNode parentNode = new InfluenceMapNode();
                parentNode.objInfluenceMap = objParent;
                listNodeFromAccount.add(parentNode);
                Integer index =0;
                Integer indexForOpp = 0;

                // Method to Populate values in InfluenceMapNode wrapper for all the records.
                getFetchedFromAcctWraper(listNodeFromAccount,index,mapChildrenFromAccount);
                // Top node is a parentNode for that particular child record.
                InfluenceMapNode topNode = new InfluenceMapNode();
                // map of parentid,List<children> containing filtered records.
                Map<Id,List<Influence_Map__c>> mapChildrenForOpportunity = new Map<Id,List<Influence_Map__c>>();
                List<InfluenceMapNode> listNodeForOpportunity = new List<InfluenceMapNode>();

                // method which gives the map<ParentId,List<children>> for filtered records.
                getchildrenRecFetchedFromAcc(listNodeFromAccount,index,mapForOpportunity,mapChildrenForOpportunity,listNodeForOpportunity,indexForOpp,topNode);
                
                // method which gives influenceMapData wrapper based on Map<ParentId,List<children>>.
                if(!listNodeForOpportunity.isEmpty()){
                    getInfluenceMapChildrenRecursive(listNodeForOpportunity[0].objInfluenceMap.Id,data,mapChildrenForOpportunity.get(listNodeForOpportunity[0].objInfluenceMap.Id),mapForOpportunity,mapChildrenForOpportunity,recordId);
                    opportunityData.data = data;
                    return opportunityData;
                }
                opportunityData.strError = InfluenceMapConstants.INFLUENCEMAP_FILTERMESSAGE;
                return opportunityData;
            }
            opportunityData.strError = InfluenceMapConstants.INFLUENCEMAP_ERROR;
            return opportunityData;
        }
        return null;
    }
    /**
    * Method Name: getFetchedFromAcctWraper
    * Description : This is a method to create InfluenceMapNode wrapper for InflunceMap records.
    * Param: List<InfluenceMapNode>,Index of list of wrapper,Map of <parentid,List<child records>>
    * return : void
    */
    private static void getFetchedFromAcctWraper(List<InfluenceMapNode> listNodeFromAccount,Integer index,Map<Id,List<Influence_Map__c>> mapChildrenFromAccount){
        if(index >= listNodeFromAccount.size()){
            return;
        }
        if(mapChildrenFromAccount.containsKey(listNodeFromAccount[index].objInfluenceMap.Id)){
            for(Influence_Map__c inf : mapChildrenFromAccount.get(listNodeFromAccount[index].objInfluenceMap.Id)){
                InfluenceMapNode newNode = new InfluenceMapNode();
                newNode.objInfluenceMap = inf;
                newNode.intParentIndex = index;
                // add to the list of wrapper
                listNodeFromAccount.add(newNode);
            }
            if(mapChildrenFromAccount.get(listNodeFromAccount[index].objInfluenceMap.Id) == null){
                listNodeFromAccount[index].intLastChildIndex = -1;
            }
            listNodeFromAccount[index].intLastChildIndex = listNodeFromAccount.size()-1;
        }
        // increase the index by 1 and call the same function again.
        index += 1;
        getFetchedFromAcctWraper(listNodeFromAccount,index,mapChildrenFromAccount);
    }
    /**
    * Method Name: getchildrenRecFetchedFromAcc
    * Description : This is a method to give map of <ParentId,child records> for records fetched from account.
    * Param: List of InfluenceMapNode ,index of influencemap records in List<InfluenceMapNode>,map of records fetched from account,map of <parentId,child records> fetched from account.
    * return : void
    */
    private static void getchildrenRecFetchedFromAcc(List<InfluenceMapNode> listNodeFromAccount, Integer index, Map<Id,Influence_Map__c> mapForOpportunity,Map<Id,List<Influence_Map__c>> mapChildrenForOpportunity,List<InfluenceMapNode> listNodeForOpportunity,Integer indexForOpp,InfluenceMapNode topNode){
        if(index >= listNodeFromAccount.size()){
            return;
        }
        if(mapForOpportunity.containsKey(listNodeFromAccount[index].objInfluenceMap.Id)){
            Integer parentInx = listNodeFromAccount[index].intParentIndex;
            // get the parentIndex for the specific record in the listNodeFromAccount wrapper.
            Integer parentInd = getParentIndex(parentInx,listNodeFromAccount,mapForOpportunity);
            if(parentInd >= 0){
                // reparent the child record
                mapForOpportunity.get(listNodeFromAccount[index].objInfluenceMap.Id).Parent_Influencer__c = listNodeFromAccount[parentInd].objInfluenceMap.Id;
                // add the records to the map<ParentId,List<children>>.
                if(mapChildrenForOpportunity.containskey(listNodeFromAccount[parentInd].objInfluenceMap.Id)){
                    mapChildrenForOpportunity.get(listNodeFromAccount[parentInd].objInfluenceMap.Id).add(listNodeFromAccount[index].objInfluenceMap);
                }
                else{
                    List<Influence_Map__c> newInfluenceMapList = new List<Influence_Map__c>();
                    newInfluenceMapList.add(listNodeFromAccount[index].objInfluenceMap);
                    mapChildrenForOpportunity.put(listNodeFromAccount[parentInd].objInfluenceMap.Id,newInfluenceMapList);
                }
            }
            else{
                // If the topnode(parent) is alreay existing before, for that indexed record. 
                if(topNode.objInfluenceMap != null){
                    mapForOpportunity.get(listNodeFromAccount[index].objInfluenceMap.Id).Parent_Influencer__c = topNode.objInfluenceMap.Id;
                    if(mapChildrenForOpportunity.containskey(topNode.objInfluenceMap.Id)){
                        mapChildrenForOpportunity.get(topNode.objInfluenceMap.Id).add(listNodeFromAccount[index].objInfluenceMap);
                    }
                    else{
                        List<Influence_Map__c> newInfluenceMapList = new List<Influence_Map__c>();
                        newInfluenceMapList.add(listNodeFromAccount[index].objInfluenceMap);
                        mapChildrenForOpportunity.put(topNode.objInfluenceMap.Id,newInfluenceMapList);
                    }
                }
                else{
                    topNode = listNodeFromAccount[index];
                    topNode.objInfluenceMap.Parent_Influencer__c = null;
                }
            }
            // add records to newlist of wrapper.
            listNodeForOpportunity.add(listNodeFromAccount[index]);
            // check the condition to change the topNode(parent) for that particular indexed record.    
            if(index >= topNode.intLastChildIndex && indexForOpp < (listNodeForOpportunity.size()-1)){
                topNode = listNodeForOpportunity[indexForOpp+1];
                indexForOpp +=1;
            } 
        }
        // increase the Index and call the same function again.
        index += 1;
        getchildrenRecFetchedFromAcc(listNodeFromAccount,index,mapForOpportunity,mapChildrenForOpportunity,listNodeForOpportunity,indexForOpp,topNode);
    }
    /**
    * Method Name: getintParentIndex
    * Description : This is a method to return the intParentIndex of a InfluenceMap record in a list fetched from Account.
    * Param: intParentIndex,List of InfluencedMapFetchedFromAccount wrapper,map of <Id ,record> fetched from account,
    * return : intParentIndex 
    */
    private static Integer getParentIndex(Integer parentInx, List<InfluenceMapNode> listNodeFromAccount,Map<Id,Influence_Map__c> mapForOpportunity){
        while(parentInx >= 0){
            if(mapForOpportunity.containsKey(listNodeFromAccount[parentInx].objInfluenceMap.Id)){
                return parentInx;
            }else{
                parentInx = listNodeFromAccount[parentInx].intParentIndex;
            }
        }
        return -1;
    }
    //==================================================================================================================
    // Description : This is a wrapperclass for InfluenceMapController.it contains the data about Influence map records.
    //==================================================================================================================
    public class InfluenceMapData{
        @AuraEnabled public Influence_Map__c objInfluenceMap;
        @AuraEnabled public Contact objContact;
        @AuraEnabled public Integer intAccountFilter; 
        @AuraEnabled public List<InfluenceMapData> children;
    }
    //====================================================================
    // Description : This is a wrapper class for storing picklist values.
    //====================================================================
    public class PickListData{
        @AuraEnabled public String strApi;
        @AuraEnabled public String strValue;
        @AuraEnabled public String strChar;
    }
    //==================================================================================================
    //Description : This is a wrapper class containing metadata and Data of influence map custom object.
    //==================================================================================================
    public class InfluenceMapMetaData{
        @AuraEnabled public Id sObjectId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public Boolean hasAccountEditAccess;
        @AuraEnabled public String strSObjectType;
        @AuraEnabled public String strSObjectName;  
        @AuraEnabled public List<PickListData> listBuyingRole;
        @AuraEnabled public List<PickListData> listFocus;
        @AuraEnabled public List<PickListData> listContactLevel;
        @AuraEnabled public List<PickListData> listStatus;
        @AuraEnabled public List<String> listCountry;
        @AuraEnabled public InfluenceMapData data;
    }
    /*
    * class name : InfluenceMapNode
    * description : This is a wrapper class used in fetchFromAccount functionality.
    *               It contains InfluenceMap record ,Parent index i,e index of parent record and 
    *               LastChildIndex i,e index of last child added to the wrapper list. 
    **/
    private class InfluenceMapNode{
        private Influence_Map__c objInfluenceMap;
        private Integer intParentIndex;
        private Integer intLastChildIndex;
        // constructor for InfluenceMapNode wrapper class.
        private InfluenceMapNode(){
            intParentIndex = -1;
            intLastChildIndex = -1;
        }
    }
    /**
    * Method Name : OpportunityInfluenceMapData
    * Description : This wrapper containg datawrapper and error message and should be used in fetch from account functionality.
    */
    public class OpportunityInfluenceMapData{
        @AuraEnabled public InfluenceMapData data;
        @AuraEnabled public String strError;
    }
}