//==========================================================================
// Component: SalesPathService

// Author: Nidheesh N

// Copyright: 2017 by Palo Alto Networks

// Purpose: Service class for SalesPathController. Will 

//

//=================================================================================================
// ChangeLog:  07/24/2017 Initial version.
//             11/23/2017 Nidheesh N made chenges to reduce number of salesPath Transaction records.
//		Aug-03-18 made changes to hide values which are 'Inactive'
//      Aug-14-18 made changes to consolidate stage names (EPIC - SFDCSALES-2219)
//=================================================================================================

public class SalesPathService {
    //======================
    // Default Consructor.
    // @return  None
    //========================
    
    public SalesPathService() {}

    //=========================================================================================================================
    //================================ Start  Creating SalesPathController.SalesPathMetadataWrapper =========================== 
    //=========================================================================================================================
    



    //====================================================================================================================================================
    // @description: get all the metadata (1. Map of SalesPathMapping by stage and recordType 2.Cutomsettings mapping to stage to fieldset of Opportunity.
    // 3.SalespathProcess Record based * on the RecordType of Opporunity.) and create SalesPathController.SalesPathMetadataWrapper.
    // @param oppId --- oppRecord ---> Opportunity Record.
    // @exception None 
    // @returns   SalesPathController.SalesPathMetadataWrapper 
    // ====================================================================================================================================================

    public SalesPathController.SalesPathMetadataWrapper getMetadata(Opportunity  oppRecord) {
        // Create the SalesPathController.SalesPathMetadataWrapper
        SalesPathController.SalesPathMetadataWrapper metadataWrapper = new SalesPathController.SalesPathMetadataWrapper();

        if (oppRecord != null && oppRecord.Sales_Process__c != null &&String.isNotBlank(oppRecord.Sales_Process__c)) {
            // assign the oppRecord to metadataWrapper
            metadataWrapper.oppRecord = oppRecord;
            // get the SalesPath mapping records by stage and recordType
            metadataWrapper.mappingsByStage = getSalesMappingStages(oppRecord); 
            // get the list of CONSOLIDATED CHANGES related to this Opportunity.
            metadataWrapper.setOppStages = getSalesStages(oppRecord);
            // get the transaction list mapped by salespath mapping Id.
            metadataWrapper.transactionByMapping = getTransactionByMapId(oppRecord);
            // get all the fieldset mapping to Opportunity stages from custom settings.
            metadataWrapper.mapFieldSet = getFieldSetMap(oppRecord);
            // get the Lookup filter map.
            metadataWrapper.mapLookupFilterField = getLookupFilterValues();
            // get the map of dependend field and its controlling field.
            metadataWrapper.mapDependedField = getFieldDependencyMap(SalespathConstants.SALESPATH_SOBJECTNAME_OPPORTUNITY);
           
        }
        return metadataWrapper;
        
            
    }
    
    //=========================================================================================
    // Method : getSalesMappings
    // Description: Method to get the stage names for the opportunity.
    // Param : OppId -- Opoortunity 
    // return :  Map< String, List< Salespath_mapping__c>> -- List of Mapping records by stage
    //=========================================================================================

    public Map<String, List< Salespath_mapping__c >>  getSalesMappingStages(Opportunity oppRec){
        if(oppRec != null && oppRec.Sales_Process__c != null && oppRec.RecordTypeId != null){
            // get the List of mapping records based on the salesmotion value of Opportunity.
            List < Salespath_mapping__c > salesmappingList = [Select Id, Name, value_long_text__c, Sales_Process__r.Name, Sales_Process__r.Stage_Order__c,
                                                                Sales_Process__r.Consolidated_Stage_Name__c, RecordTypeId, RecordType.Name,  Sales_Process__c, Probability__c, Stage__c,
                                                                Gated__c, Type__c, Status__c FROM Salespath_mapping__c
                                                                WHERE Sales_Process__r.Name =:oppRec.Sales_Process__c AND 
                                                                Sales_Process__r.Opportunity_RecordType__c = :oppRec.RecordType.Name 
                                                                ORDER BY Sales_Process__r.Stage_Order__c ASC NULLS FIRST];
            
            Map< String, List< Salespath_mapping__c>>salesmapByStage = new Map< String, List< Salespath_mapping__c>>();
            // create a map where List of maaping records mapped by consolidated stageName.
            if(!salesmappingList.isEmpty()){
                for(Salespath_mapping__c mapObj : salesmappingList){
                    if(mapObj.Sales_Process__r.Consolidated_Stage_Name__c != null && String.isNotBlank(mapObj.Sales_Process__r.Consolidated_Stage_Name__c)){
                        if(salesmapByStage.containsKey(mapObj.Sales_Process__r.Consolidated_Stage_Name__c)){
                            salesmapByStage.get(mapObj.Sales_Process__r.Consolidated_Stage_Name__c).add(mapObj);
                        }else{
                            List< Salespath_mapping__c > listSalesmap = new List< Salespath_mapping__c >();
                            listSalesmap.add(mapObj);
                            salesmapByStage.put(mapObj.Sales_Process__r.Consolidated_Stage_Name__c,listSalesmap);
                        }
                    }
                }
            }
            return salesmapByStage;
        }else{
            return null;
        }
    }
    
    //=========================================================================================
    // Method : getSalesStages
    // Description: Method to get the stage names for the opportunity.
    // Param : OppId -- Opoortunity 
    // return :  Map< String, List< Salespath_mapping__c>> -- List of Mapping records by stage
    //=========================================================================================

    public Set< String >  getSalesStages(Opportunity oppRec){
        if(oppRec != null && oppRec.Sales_Process__c != null && oppRec.RecordTypeId != null){
            // get the List of mapping records based on the salesmotion value of Opportunity.
            List < Salespath_Process__c > salespathList = new List<Salespath_Process__c>(
                [Select Id, Stage__c, Consolidated_Stage_Name__c FROM Salespath_Process__c where Name =:oppRec.Sales_Process__c AND Opportunity_RecordType__c =: oppRec.RecordType.Name ORDER BY Stage_Order__c ASC NULLS FIRST]);
            Set< String > setOppStages = new Set< String >();
            if(!salespathList.isEmpty()){
                for(Salespath_Process__c objSalespath : salespathList){
                    if(objSalespath.Consolidated_Stage_Name__c != null && String.isNotBlank(objSalespath.Consolidated_Stage_Name__c)){
                        setOppStages.add(objSalespath.Consolidated_Stage_Name__c);
                    }
                }
            System.debug('check Opp stages-----'+setOppStages);
            return setOppStages;
            }
        }
        return null;
    }
    
    //======================================================================================================================
    // Description : get the map of transaction records ---> Map by salespath mapping id to transaction record.
    // @param lstSalesPathProcess : Opprecord---- Opportunity Record
    // @exception None
    // @returnType : Map<Id,Salespath_transaction__c> key :Maaping Id Value:Salespath_transaction__c
    //======================================================================================================================
    
    public Map < Id,Salespath_transaction__c > getTransactionByMapId(Opportunity oppRecord) {
        if(oppRecord != null && oppRecord.Sales_Process__c != null && oppRecord.RecordTypeId != null){
            List< Salespath_transaction__c > lstTransaction = new List< Salespath_transaction__c >();
            Map< Id, Salespath_transaction__c > transactionByMapId = new Map < Id, Salespath_transaction__c >();
            // Querying all the transaction related to the Opportunity.
            lstTransaction = [SELECT Id, PANW_mapping__c,Opportunity__c  FROM Salespath_transaction__c WHERE Opportunity__c =: oppRecord.Id AND PANW_mapping__r.Sales_Process__r.Name = : oppRecord.Sales_Process__c];
            // create map of mapping id to transaction record.
            if(!lstTransaction.isEmpty()){
                for(Salespath_transaction__c transobj : lstTransaction){
                    if(transobj.PANW_mapping__c != null){
                        transactionByMapId.put(transobj.PANW_mapping__c,transobj);
                    }
                }
            }
            return transactionByMapId;
        }else{
            return null;
        }
    }
    
    //===================================================================================================================================================================================================
    // @description: Get all the Fieldsets related to Opportunity stages through custom setting called  SalesPath FieldSet Map and cretae a map with key is *  stagename and value is fieldset Api Name.
    // @param oppRecord
    // @exception None 
    // @returns   Map<String,String>
    // ==================================================================================================================================================================================================

    public Map <String, String> getFieldSetMap(Opportunity oppRecord) {

        if (oppRecord != null && oppRecord.Sales_Process__c != null) {
            // Intialize Map
            Map <String, String> mapFieldSetName = new Map <String, String> ();
            // get all values in custom setting stage_To_salesProcess__c
            Map <String, stage_To_salesProcess__c> mapStageFieldsetMapping = stage_To_salesProcess__c.getAll();
            if (mapStageFieldsetMapping != null && !mapStageFieldsetMapping.isEmpty()) {
                for (stage_To_salesProcess__c stagesalesObj: mapStageFieldsetMapping.values()) {
                    if (stagesalesObj.sales_Process_Name__c == oppRecord.Sales_Process__c) {
                        if (!mapFieldSetName.containsKey(stagesalesObj.stageName__c)) {
                            mapFieldSetName.put(stagesalesObj.stageName__c, stagesalesObj.Fieldset_Name__c);
                        }
                    }

                }
            }
            return mapFieldSetName;

        } else {
            return null;
        }
    }

    //==============================================================================================================================================
    // @description: Get the mapping of Lookup field to its custom setting record which contains its filter field, filter field value and conditions.
    // @exception None 
    // @returns   Map<String,Lookup_Filter_Values__c>
    //==============================================================================================================================================

    public Map <String, Lookup_Filter_Values__c> getLookupFilterValues() {
        try {
            //Retrieve lookup filter value based on the SALESPATH_SOBJECTNAME_OPPORTUNITY
            List <Lookup_Filter_Values__c> lstLookupFilter = new List <Lookup_Filter_Values__c> ();
            lstLookupFilter = Lookup_Filter_Values__c.getall().values();
            // Initailize map
            Map <String, Lookup_Filter_Values__c> mapLookupFilterField = new Map <String, Lookup_Filter_Values__c> ();
            // create the map of lookup filter and fieldname.
            if (!lstLookupFilter.isEmpty()) {
                for (Lookup_Filter_Values__c lookupObj: lstLookupFilter) {
                    if (!mapLookupFilterField.ContainsKey(lookupObj.fieldName__c)) {
                        mapLookupFilterField.put(lookupObj.fieldName__c, lookupObj);
                    }
                }
            }
            return mapLookupFilterField;

        } catch (Exception e) {
            return null;
        }

    }

    //============================================================================================================================= 
    // Description : create map of dependend field and its controlling field with the custom setting SalesPath Field Dependency Map
    // @param stage : Name of the sobject.
    // @exception None
    // @returnType : Map<String,String> key :depended field Value controlling field.
    //=============================================================================================================================

    public Map <String, String> getFieldDependencyMap(String sobjectName) {
        try {
            Map <String, String> mapDependedField = new Map <String, String> ();
            List <Depended_Picklist__c> lstofDependedPicklistNames = new List <Depended_Picklist__c> ();
            // query all the custom setting data based on the SALESPATH_SOBJECTNAME_OPPORTUNITY__c field value.
            lstofDependedPicklistNames = Depended_Picklist__c.getall().values();
            if (!lstofDependedPicklistNames.isEmpty()) {
                for (Depended_Picklist__c dependObject: lstofDependedPicklistNames) {
                    if (dependObject.sobjectName__c == sobjectName) {
                        if (!mapDependedField.containsKey(dependObject.fieldName__c)) {
                            mapDependedField.put(dependObject.fieldName__c, dependObject.controlling_Field__c);
                        }
                    }
                }
            }
            return mapDependedField;

        } catch (Exception e) {
            return null;

        }

    }

    //================================END SalesPathController.SalesPathMetadataWrapper Creation================================================//



    //==============================================================================================================================
    //=================================Start  Creating SalesPathdataWrapper ========================================================
    //==============================================================================================================================

    //============================================================================= 
    // Description : create SalesPathWrapper
    // @param metadataWrapper : SalesPathController.SalesPathMetadataWrapper object.
    // @exception None
    // @returnType : SalesPathWrapper
    //=============================================================================
    public SalesPathController.SalesPathWrapper getSalesPathDataWrapper(SalesPathController.SalesPathMetadataWrapper metadataWrapper) {
        if (metadataWrapper != null) {
            Map <String, SalesPathController.SalesPathDataWrapper> mapSalesPathDataWrapper = new Map <String, SalesPathController.SalesPathDataWrapper> ();
            
            //get Opportunity Record
            Opportunity opportunityRec = getOppInfo(metadataWrapper);
            //Initialize SalesPathTransactionDataWrapper 

            mapSalesPathDataWrapper = getSalePathDataWrapperMap(metadataWrapper,opportunityRec);
            List <string> lstStageNames = new List <String> ();
            if(metadataWrapper.setOppStages!= null && !metadataWrapper.setOppStages.isEmpty()){
                for(string s :metadataWrapper.setOppStages){
                    //lstStageNames.add(getStageLabel(s));
                    lstStageNames.add(s);
                }
            }
            
            String stageName =  metadataWrapper.oppRecord.Consolidated_Stage_Name__c;

            SalesPathController.SalesPathWrapper dataWrapper = new SalesPathController.SalesPathWrapper(mapSalesPathDataWrapper, string.valueOf(metadataWrapper.oppRecord.Id), lstStageNames, stageName);
            if (metadataWrapper.oppRecord.Id != null) {
                dataWrapper.lstDealDocWrapper = getDealDocList(string.valueOf(metadataWrapper.oppRecord.Id), metadataWrapper.mappingsByStage.get(metadataWrapper.oppRecord.Consolidated_Stage_Name__c));
            }
            dataWrapper.closedStageEditWrapper = getSalesPathEditObject(metadataWrapper,SalesPathConstants.SALESPATH_STAGECLOSED, opportunityRec);
            
           
            return dataWrapper;
        }

        return null;
    }
    //================================================================================================================
    // Description : get all information of Opportunity including the fields mentioned in the custom setting fieldset.
    // @param metadataWrapper : LSalesPathMetadataWrapper object.
    // @exception None
    // @returnType : SalesPathTransactionDataWrapper
    //================================================================================================================
    public Opportunity getOppInfo(SalesPathController.SalesPathMetadataWrapper metadataWrapper) {
        String query = getDynamicOpportunityQuery(metadataWrapper);
        String oppId = String.valueOf(metadataWrapper.oppRecord.Id);
        Opportunity OppRecord = Database.query(query);
        return OppRecord;
    }

    //================================================================================================================= 
    // Description : get all information of Opportunity including the fields mentioned in the custom setting fieldset.
    // @param createDynamicOpportunityQuery : LSalesPathMetadataWrapper object.
    // @exception None
    // @returnType : String
    //=================================================================================================================

    public String getDynamicOpportunityQuery(SalesPathController.SalesPathMetadataWrapper metadataWrapper)

    {
        //Finding the fieldsets of Oppotunity Object using schema class
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(SalespathConstants.SALESPATH_SOBJECTNAME_OPPORTUNITY);
        Schema.DescribesObjectResult describe = targetType.getDescribe();
        Map <String, Schema.FieldSet> fsmap = describe.fieldSets.getmap();
        set <String> setoffields = new set <String> ();

        // query string 
        String query = 'SELECT ';

        if (metadataWrapper != null && metadataWrapper.mapFieldSet != null && !metadataWrapper.mapFieldSet.isEmpty()) {
            for (String stageName: metadataWrapper.mapFieldSet.keySet()) {
                if (fsmap.ContainsKey(metadataWrapper.mapFieldSet.get(stageName))) {
                    //loop through all fields
                    for (Schema.FieldSetMember f: fsmap.get(metadataWrapper.mapFieldSet.get(stageName)).getFields()) {
                       
                        if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_REFERNCE) {
                            
                            // Remove __c for reference fields and change to __r.name to get the relatedr ecord name
                            //ex: custom lookup xyz__c will be xyz__r.name
                            if (!setOfFields.contains(String.valueOf(f.getFieldPath()))) {
                                if (f.getFieldPath().contains('__c')) {

                                    String fieldnaming = f.getFieldPath().removeEnd('c');
                                    fieldnaming = fieldnaming + 'r.name';
                                    setOfFields.add(String.valueOf(f.getFieldPath()));
                                    if (!setOfFields.contains(fieldnaming)) {
                                        query += fieldnaming + ', ';
                                    }
                                    setOfFields.add(fieldnaming);
                                    
                                    query += f.getFieldPath() + ', ';
                                } else {
                                    //for standard fields remove id from end and replace with name. ex: accountid will be account.name
                                    String fieldnaming = f.getFieldPath().removeEnd('Id');
                                    fieldnaming = fieldnaming + '.Name';
                                    setOfFields.add(String.valueOf(f.getFieldPath()));
                                    if (!setOfFields.contains(fieldnaming)) {
                                        query += fieldnaming + ', ';
                                    }
                                    setOfFields.add(fieldnaming);
                                    
                                    query += f.getFieldPath() + ', ';
                                }
                                if (metadataWrapper.mapLookupFilterField.containsKey(String.valueOf(f.getFieldPath()))) {
                                    if (metadataWrapper.mapLookupFilterField.get(String.valueOf(f.getFieldPath())).filterField__c != null) {
                                        if (!query.contains(metadataWrapper.mapLookupFilterField.get(String.valueOf(f.getFieldPath())).filterField__c)) {
                                            query += metadataWrapper.mapLookupFilterField.get(String.valueOf(f.getFieldPath())).filterField__c + ', ';
                                            setOfFields.add(metadataWrapper.mapLookupFilterField.get(String.valueOf(f.getFieldPath())).filterField__c);
                                        }

                                    }

                                }
                            }
                        } else {
                            if (!setOfFields.contains(String.valueOf(f.getFieldPath()))) {
                                setOfFields.add(String.valueOf(f.getFieldPath()));
                                query += f.getFieldPath() + ', ';
                            }

                        }
                    }
                }
            }
        }
        if(!setOfFields.contains('StageName') ){
            query += 'StageName,';
        }
        query += 'Id,RecordTypeId,RecordType.Name, Consolidated_Stage_Name__c FROM Opportunity WHERE Id=: oppId LIMIT 1';
        return query;
    }
    
    //===========================================================
    // Description : Create the SalesPathDataWrapper
    // @param metadataWrapper : LSalesPathMetadataWrapper object.
    // @exception None
    // @returnType : SalesPathTransactionDataWrapper
    //===========================================================

    public Map <String, SalesPathController.SalesPathDataWrapper> getSalePathDataWrapperMap(SalesPathController.SalesPathMetadataWrapper metadataWrapper,Opportunity opportunityRec) {
        String activeStage = '';
        //Integer count = 0;
        Boolean isActiveStageSelected = false;
        
        // Initializing the mapofSalesPathDataWrapper
        Map <String, SalesPathController.SalesPathDataWrapper> SalesPathdatWrappermap = new Map <String, SalesPathController.SalesPathDataWrapper> ();
        //Creating map of SalesPathDataWrapper and Opportunity stage
        System.debug('stages-------'+metadataWrapper.setOppStages);
        if (metadataWrapper != null && metadataWrapper.setOppStages != null && !metadataWrapper.setOppStages.isEmpty()) {
            for (String stageName: metadataWrapper.setOppStages) {
                if (!SalesPathdatWrappermap.containsKey(stageName)) {
                    //===============================================================================
                    // Initialize the new wrapper object and Assigning values to wrapper starts here.
                    //===============================================================================
                    SalesPathController.SalesPathDataWrapper objwrapper = new SalesPathController.SalesPathDataWrapper();
                    
                    //Assigning the wrapperlist for outcome,keyfield,salestip and task for each stages to SalesPathDataWrapper.

                    if (metadataWrapper.mappingsByStage.containsKey(stageName)) {
                        objwrapper.completeGatedTask = getGatedTaskValue(metadataWrapper.mappingsByStage.get(stageName),metadataWrapper.transactionByMapping);
                        objwrapper.fieldSetName = metadataWrapper.mapFieldSet.get(stageName);
                        objwrapper.lstOutComeWrapper = getOutComeWrapper(metadataWrapper.mappingsByStage.get(stageName),metadataWrapper.transactionByMapping);
                        objwrapper.lstTaskWrapper = getTaskwrapperList(metadataWrapper.mappingsByStage.get(stageName),metadataWrapper.transactionByMapping);
                        objwrapper.lstSalesTipWrapper = getSalesTipWrapper(metadataWrapper.mappingsByStage.get(stageName));
                        objwrapper.salespathEditWrapper = getSalesPathEditObject(metadataWrapper, stageName, opportunityRec);
                        // checking the stage is closed or not, we don't need progress value for close stage.
                        if (stageName == SalespathConstants.SALESPATH_STAGECLOSED) {
                            objwrapper.progressValue = 0.00;
                        }else{
                            objwrapper.progressValue = getProgressValue(metadataWrapper.mappingsByStage.get(stageName),metadataWrapper.transactionByMapping);
                        }
                        objwrapper.total = getProgressTotal(metadataWrapper.mappingsByStage.get(stageName));
                    }else{
                        objwrapper.lstOutComeWrapper =new List <SalesPathController.SalesPathOutcomeWrapper>();
                        objwrapper.lstTaskWrapper =new List <SalesPathController.SalesPathTaskWrapper>();
                        objwrapper.lstSalesTipWrapper = new List<SalesPathController.SalesTipWrapper>();
                        objwrapper.completeGatedTask = false;
                        objwrapper.progressValue = 0.00;
                        objwrapper.total = 0.00;
                    }
                    objwrapper.lstKeyWrapper = getKeyFieldWrapper(metadataWrapper, opportunityRec, stageName);
                    /**
                     *Assigning wrapperlist end here.
                     */
                    objwrapper.stage = stageName;
                    /**
                     * Assigning stagestaus,stageindex,progressValue and totalProgressvalue to each stage 
                     * 
                     */
                    if (stageName == opportunityRec.Consolidated_Stage_Name__c) {
                        /** 
                         * If stage name equals to Opportunity StageName the make the stage staus active
                         */
                        isActiveStageSelected = true;
                        objwrapper.current = true;
                        objwrapper.index = getConsolidatedSatgeOrder(stageName, opportunityRec.RecordType.Name);
                        objwrapper.incomplete = false;
                        objwrapper.Completed = false;
                        objwrapper.status = SalespathConstants.SALESPATH_ACTIVE;
                        activeStage = stageName;
                    } else if (opportunityRec.Consolidated_Stage_Name__c == SalespathConstants.SALESPATH_STAGECLOSED && stageName == SalespathConstants.SALESPATH_STAGECLOSED ) {
                        /**
                         *if the stage is closed set SalesPathDataWrapper variables
                         */
                        isActiveStageSelected = true;
                        objwrapper.current = true;
                        objwrapper.index = getConsolidatedSatgeOrder(stageName, opportunityRec.RecordType.Name);
                        objwrapper.incomplete = false;
                        objwrapper.Completed = false;
                        objwrapper.lstKeyWrapper = getKeyFieldWrapper(metadataWrapper, opportunityRec, opportunityRec.stageName);
                        if(opportunityRec.stageName != SalespathConstants.SALESPATH_STAGECLOSEDWON){
                            objwrapper.lstOutComeWrapper =new List <SalesPathController.SalesPathOutcomeWrapper>();
                            objwrapper.lstSalesTipWrapper =new List <SalesPathController.SalesTipWrapper>();
                            objwrapper.lstTaskWrapper =new List <SalesPathController.SalesPathTaskWrapper>();
                            objwrapper.completeGatedTask = false;
                            objwrapper.progressValue = 0.00;
                            objwrapper.total = 0.00;
                        }
                        objwrapper.status = SalespathConstants.SALESPATH_ACTIVE;
                        activeStage = stageName;

                    } else {

                        if (isActiveStageSelected) {
                            /**
                             * if activeStage is true, status of the remaining stages are incomplete
                             */
                            objwrapper.index = getConsolidatedSatgeOrder(stageName, opportunityRec.RecordType.Name);
                            objwrapper.current = false;
                            objwrapper.incomplete = true;
                            objwrapper.Completed = false;
                            objwrapper.status = SalespathConstants.SALESPATH_SALESPATHDATAWRAPPER_INCOMPLETEVALUE;
                            
                        } else {
                            /**
                             * if activeStage is true, status of the remaining stages are complete
                             */
                            objwrapper.index = getConsolidatedSatgeOrder(stageName, opportunityRec.RecordType.Name);
                            objwrapper.current = false;
                            objwrapper.incomplete = false;
                            objwrapper.Completed = true;
                            objwrapper.status = SalespathConstants.SALESPATH_SALESPATHDATAWRAPPER_COMPLETEVALUE;
                        }
                    }
                    /**************************  End ******************************************************************************************/
                    SalesPathdatWrappermap.put(stageName, objwrapper);

                }

            }
        }
        return salesPathdatWrappermap;
    }

    //=============================================================================
    // Description : get getGatedTaskValue of stage.
    // @param lstTransaction : List<Salespath_mapping__c>
    // @param2 map of transaction by salesmapping Id : Map<id,Salespath_mapping__c>
    // @exception None
    // @returnType :Boolean
    //=============================================================================

    public Boolean getGatedTaskValue(List <Salespath_mapping__c> salesmappingList,Map<id,Salespath_transaction__c> transactionMapById) {
        if (salesmappingList != null && !salesmappingList.isEmpty()) {
            boolean completion = false;
            for (Salespath_mapping__c mappingObj: salesmappingList) {
                if (mappingObj.RecordTypeId != null && String.isNotBlank(mappingObj.RecordTypeId)) {
                    if (mappingObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_OUTCOME) {
                        if (mappingObj.Gated__c) {
                            if(transactionMapById.containsKey(mappingObj.Id))
                            completion = true;
                            else
                            completion = false;
                        }
                    }
                }
            }
            return completion;
        }else{
            return false;
        }
        
    }

    //=============================================================================
    // Description : get all List outcomeWrapper with respect to stage
    // @param lstTransaction : List<Salespath_mapping__c>
    // @param2 map of transaction by salesmapping Id : Map<id,Salespath_mapping__c>
    // @exception None
    // @returnType : List<SalesPathController.SalesPathOutcomeWrapper>
    //==============================================================================

    public List <SalesPathController.SalesPathOutcomeWrapper> getOutComeWrapper(List <Salespath_mapping__c> salesmappingList,Map<id,Salespath_transaction__c> transactionMapById) {
        //Initialize List
        List <SalesPathController.SalesPathOutcomeWrapper> lstOutcomeWrapper = new List <SalesPathController.SalesPathOutcomeWrapper> ();
        if (salesmappingList != null && !salesmappingList.isEmpty()) {
           for (Salespath_mapping__c mappingObj: salesmappingList) {

                if (mappingObj.RecordTypeId != null && String.isNotBlank(mappingObj.RecordTypeId)) {
                    //check the RecordType
                    if (mappingObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_OUTCOME) {
                        //skip outcome if it's Inactive
                        if(mappingObj.Status__c == SalespathConstants.SALESPATH_MAPPING_STATUS_INACTIVE)
                            continue;
                        // check the outcome value is completed
                        boolean completion = false;
                        // the outcome value will be true if transaction record created for the mapping record, else false.
                        if (transactionMapById.containsKey(mappingObj.Id)) {
                            completion = true;
                        } else {
                            completion = false;
                        }
                        SalesPathController.SalesPathOutcomeWrapper outcomeObj = new SalesPathController.SalesPathOutcomeWrapper(mappingObj.value_long_text__c, mappingObj.Probability__c, completion, mappingObj.Id, mappingObj.Gated__c);
                        lstOutcomeWrapper.add(outcomeObj);
                    }
                }
            }
            return lstOutcomeWrapper;
        }

        return null;

    }
    
    //==================================================================== 
    // Description : get the Value of stgaeName for saving salesPath stage
    // @param stageName : stageName picklist Label
    // @exception None
    // @returnType : string : stageName picklist Value
    //====================================================================
    Public string getStageValue(string stageName){
        Schema.DescribeFieldResult F = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        Map<String, String> mapMyFieldTranslation = new Map<String, String>();
        for(Schema.PicklistEntry e : P)
        {
            mapMyFieldTranslation.put(e.Label, e.Value);
        }
 
        if(mapMyFieldTranslation.containsKey(stageName)){
            return mapMyFieldTranslation.get(stageName);
        }else{
            return null;
        }
    }
    
    //================================================================== 
    // Description : get the label of stgaeName for diaplay in salespath
    // @param stageName : stageName picklist value
    // @exception None
    // @returnType : string : stageName picklist Label
    //==================================================================
    /*
    Public string getStageLabel(string stageName){
        Schema.DescribeFieldResult F = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        Map<String, String> mapMyFieldTranslation = new Map<String, String>();
        for(Schema.PicklistEntry e : P)
        {
            mapMyFieldTranslation.put(e.value, e.label);
        }
 
        if(mapMyFieldTranslation.containsKey(stageName)){
            return mapMyFieldTranslation.get(stageName);
        }else{
            return null;
        }
    }
*/
    //=================================================================== 
    // Description : get all List salesTipWrapper with respect to stage
    // @param lstTransaction : List<Salespath_Mapping__c>
    // @exception None
    // @returnType : List<SalesPathController.SalesTipWrapper>
    //===================================================================

    public List <SalesPathController.SalesTipWrapper> getSalesTipWrapper(List <Salespath_Mapping__c> listSalestip) {
        //Initialize List
        List <SalesPathController.SalesTipWrapper> lstSalesTipWrapper = new List <SalesPathController.SalesTipWrapper> ();
        if (listSalestip != null && !listSalestip.isEmpty()) {
            for (Salespath_Mapping__c mappObj: listSalestip) {
                if (mappObj.RecordTypeId != null && String.isNotBlank(mappObj.RecordTypeId)) {
                    if (mappObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_SALESTIP) {
                        SalesPathController.SalesTipWrapper salesTipObj = new SalesPathController.SalesTipWrapper(mappObj.value_long_text__c, mappObj.Id);
                        lstSalesTipWrapper.add(salesTipObj);

                    }
                }
            }
            return lstSalesTipWrapper;
        }

        return null;
    }



    //===============================================================
    // Description : Get the SalesPathTaskWrapper list for the stage
    // @param lstTransaction : List<Salespath_mapping__c>
    // @param2 map of transaction by salesmapping Id : Map<id,Salespath_mapping__c>
    // @exception None
    // @returnType : List<SalesPathController.SalesPathTaskWrapper>
    //===============================================================

    public List <SalesPathController.SalesPathTaskWrapper> getTaskwrapperList(List <Salespath_mapping__c> salesmappingList,Map<id,Salespath_transaction__c> transactionMapById) {
        if (salesmappingList != null && !salesmappingList.isEmpty()) {
            //Initailize List
            List <SalesPathController.SalesPathTaskWrapper> lstTaskWrapper = new List <SalesPathController.SalesPathTaskWrapper> ();
            for (Salespath_mapping__c mappingObj: salesmappingList) {
                if (mappingObj.RecordTypeId != null && String.isNotBlank(mappingObj.RecordTypeId)) {
                    if (mappingObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_TASK ) {
                        // if task is already created it won't added to the wrapper list.
                        if(!transactionMapById.containsKey(mappingObj.Id)){
                            SalesPathController.SalesPathTaskWrapper taskObj = new SalesPathController.SalesPathTaskWrapper(mappingObj.value_long_text__c, false, CoreConstants.SALESPATH_FALSEString, mappingObj.Id);
                            lstTaskWrapper.add(taskObj);
                        }
                    }
                }
            }
            return lstTaskWrapper;
        }

        return null;
    }

    //================================================================================
    // Description : Description: Query for all Deal Doctor Related Activities
    // @param : OppId ---- Opoortunity id
    // return Type : The List<SalesPathTaskWrapper>  -  mapping to the Deal Doc values
    //================================================================================

    public List <SalesPathController.SalesPathTaskWrapper> getDealDocList(String oppId, List<Salespath_Mapping__c> salesMappingList) {
        List<Salespath_transaction__c> lstDealdoc = new List<Salespath_transaction__c> ();
        List<SalesPathController.SalesPathTaskWrapper> dealDocWrapperList = new List<SalesPathController.SalesPathTaskWrapper> ();
        List<String> addInfo = new List<String> ();
        List<String> lstTypeToConsider = getTypeListFromMapping(salesMappingList);
        // get the deal doctor tasks and from the transactions.
        lstDealdoc = [SELECT Id, Name, value__c, type__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.CampaignId FROM Salespath_transaction__c
            WHERE Opportunity__c =: oppId AND Type__c IN :lstTypeToConsider and isactive__c = true
        ];
        // get the custom label value of deal doctor.
        string dealDocDataLabel = System.Label.Deal_Doctor_Values;
        // convert the string into list of string .
        List <String> stringList = dealDocDataLabel.split(',');
        //List<String> StringList = new List<String> {
          //  'Generate a TCO and send it to Customer',
          //  'Provide a Training Voucher to the Customer',
          //  'Provide a free PA-220 to the Customer',
          //  'Generate a Battle card against'
          //  };
        for (Salespath_transaction__c transObject: lstDealdoc) {
            //String link,
            String dataVal;
            if (transObject.type__c == SalespathConstants.SALESPATH_MAPPING_VOUCHER) {
                //link = URL.getSalesforceBaseUrl().toExternalForm() + SalespathConstants.DEAL_DOCTOR_CLAIM_URL_BASE_PATH+ PromotionConstants.RECORD_TYPE_VOUCHER_REQUESTS;
                dataVal = StringList[1];
                addInfo = new List <String> {
                    transObject.Opportunity__r.Accountid,
                    transObject.Opportunity__c,
                    PromotionConstants.RECORD_TYPE_VOUCHER_REQUESTS
                };
            } else if (transObject.type__c == SalespathConstants.SALESPATH_MAPPING_PA) {
                //link = URL.getSalesforceBaseUrl().toExternalForm() + SalespathConstants.DEAL_DOCTOR_CLAIM_URL_BASE_PATH+ PromotionConstants.RECORD_TYPE_PA_SEEDING;
                dataVal = StringList[2];
                addInfo = new List <String> {
                    transObject.Opportunity__r.Accountid,
                    transObject.Opportunity__c,
                    PromotionConstants.RECORD_TYPE_PA_SEEDING
                };
            } /*else if (transObject.type__c == SalespathConstants.SALESPATH_MAPPING_BATTLECARD) {
                //link =  URL.getSalesforceBaseUrl().toExternalForm() + '/a0g/e';
                dataVal = stringList[3] + ' ' + transObject.value__c;
                addInfo = new List <String> {
                    transObject.Opportunity__r.Accountid,
                    transObject.Opportunity__c
                    //PromotionConstants.RECORD_TYPE_VOUCHER_REQUESTS
                };

            }*/ else if (transObject.type__c == SalespathConstants.SALESPATH_MAPPING_VM100) {
                //link =  URL.getSalesforceBaseUrl().toExternalForm() + SalespathConstants.DEAL_DOCTOR_CLAIM_URL_BASE_PATH+ PromotionConstants.RECORD_TYPE_VM_SERIES_SEEDING_PROGRAM;
                dataVal = stringList[4] + ' ' + transObject.value__c;
                addInfo = new List <String> {
                    transObject.Opportunity__r.Accountid,
                    transObject.Opportunity__c,
                    PromotionConstants.RECORD_TYPE_VM_SERIES_SEEDING_PROGRAM
                };

            }

            dealDocWrapperList.add(new SalesPathController.SalesPathTaskWrapper(dataVal, false, ' Deal Doctor - ' + transObject.type__c, transObject.id, transObject.type__c, true, addInfo));

        }
        return dealDocWrapperList;
    }

    //=======================================================================
    // Description : Get the SalesPathKeyFieldWrapper list for the stage
    // @param metadataWrapper : SalesPathController.SalesPathMetadataWrapper
    // @param opportunityRec : Opportunity Record
    // @exception None
    // @returnType : List<SalesPathController.SalesPathKeyFieldWrapper>
    //=======================================================================

    public List <SalesPathController.SalesPathKeyFieldWrapper> getKeyFieldWrapper(SalesPathController.SalesPathMetadataWrapper metadataWrapper, Opportunity opportunityRec, string stageName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(SalespathConstants.SALESPATH_SOBJECTNAME_OPPORTUNITY);
        Schema.DescribesObjectResult describe = targetType.getDescribe();
        Map <String, Schema.FieldSet> fsmap = describe.fieldSets.getmap();
        Map <String, Schema.SObjectType> schemamap = Schema.getGlobalDescribe();
        Schema.SObjectType ObjectSchema = schemamap.get(SalespathConstants.SALESPATH_SOBJECTNAME_OPPORTUNITY);
        Map <String, Schema.sObjectField> fieldmap = ObjectSchema.getDescribe().fields.getmap();
        if (metadataWrapper != null && metadataWrapper.mapFieldSet != null && !metadataWrapper.mapFieldSet.isEmpty() && metadataWrapper.mapFieldSet.ContainsKey(stageName)) {
            List <SalesPathController.SalesPathKeyFieldWrapper> lstKeyWrapper = new List <SalesPathController.SalesPathKeyFieldWrapper> ();
            integer count = 0;
            if( fsmap!=null && metadataWrapper.mapFieldSet!=null && metadataWrapper.mapFieldSet.containskey(stageName) && fsmap.get(metadataWrapper.mapFieldSet.get(stageName))!=null)
            {
                for (Schema.FieldSetMember f: fsmap.get(metadataWrapper.mapFieldSet.get(stageName)).getFields()) {
                    if (String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_DATE && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_DATETIME && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_BOOLEAN && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_REFERNCE && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_DOUBLE && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_CURRENCY && String.valueOf(f.getType()) != SalespathConstants.SALESPATH_FIELDTYPE_PERCENT) {
                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(f.getLabel(), f.getFieldPath(), (String) opportunityRec.get(f.getFieldPath()), String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);
                    } else if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_REFERNCE) {
                        String namevalue = '';
                        String objectname = '';
                        if (f.getFieldPath().contains('__c')) {
                            // finding the refernce object if the field is a custom field
                            String fieldnaming = f.getFieldPath().removeEnd('c');
                            fieldnaming = fieldnaming + 'r';
                            if (f.getFieldPath() != null && opportunityRec.getSobject(fieldnaming) != null) {
                                namevalue = (String) opportunityRec.getSobject(fieldnaming).get('name');
                            }
                            objectname = f.getLabel();
                        } else {
                            // finding the refernce object if the field is a standard field
                            List <Schema.SObjectType> reference = fieldmap.get(f.getFieldPath()).getDescribe().getReferenceTo();
                            objectname = reference[0].getDescribe().getName();
                            if (f.getFieldPath() != null && opportunityRec.getSobject(objectname) != null) {
                                namevalue = (String) opportunityRec.getSobject(objectname).get('name');
                            }
                        }

                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(objectname, f.getFieldPath(), namevalue, String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);
                    } else if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_DATE) {
                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(f.getLabel(), f.getFieldPath(), String.valueOf((Date) opportunityRec.get(f.getFieldPath())), String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);
                    } else if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_DATETIME) {
                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(f.getLabel(), f.getFieldPath(), String.valueOf((DateTime) opportunityRec.get(f.getFieldPath())), String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);
                    } else if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_BOOLEAN) {
                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(f.getLabel(), f.getFieldPath(), String.valueOf((boolean) opportunityRec.get(f.getFieldPath())), String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);

                    } else if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_PERCENT || String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_CURRENCY || String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_DOUBLE) {
                        SalesPathController.SalesPathKeyFieldWrapper keyfieldObj = new SalesPathController.SalesPathKeyFieldWrapper(f.getLabel(), f.getFieldPath(), String.valueOf((Decimal) opportunityRec.get(f.getFieldPath())), String.valueOf(f.getType()));
                        lstKeyWrapper.add(keyfieldObj);

                    }
                }
            }
            return lstKeyWrapper;
        }

        return null;
    }

    //===========================================================
    // Description : Get the total probability value for a stage
    // @param lstTransaction : List<Salespath_transaction__c>
    // @exception None
    // @returnType : decimal
    //===========================================================

    public decimal getProgressTotal(List <Salespath_mapping__c> salesmappingList) {
        Decimal totalValue = 0.00;
        if (salesmappingList != null && !salesmappingList.isEmpty()) {
            for (Salespath_mapping__c mapObject: salesmappingList) {
                if (mapObject.RecordTypeId != null && String.isNotBlank(mapObject.RecordTypeId)) {
                    // populating the map for outcomes progress total
                    if (mapObject.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_OUTCOME) {
                        if (mapObject.Probability__c != null) {
                            totalValue = totalValue + mapObject.Probability__c;
                        }
                    }
                }
            }

        }
        return totalValue;

    }

    //=================================================================
    // Description : Get the  progress value in percentage for a stage
    // @param lstTransaction : List<Salespath_transaction__c>
    // @exception None
    // @returnType : decimal
    //=================================================================

    public decimal getProgressValue(List <Salespath_mapping__c> salesmappingList,Map<id,Salespath_transaction__c> transactionMapById) {
        Decimal totalValue = 0.00;
        Decimal completedValue = 0.00;
        Decimal percentageValue;
        if (salesmappingList != null && !salesmappingList.isEmpty()) {
            for (Salespath_mapping__c mappingObj: salesmappingList) {
                if (mappingObj.RecordTypeId != null && String.isNotBlank(mappingObj.RecordTypeId)) {
                    // populating the map for outcomes progress total
                    if (mappingObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_OUTCOME) {
                        if (mappingObj.Probability__c != null) {
                            totalValue = totalValue + mappingObj.Probability__c;
                            // if transaction record created for the outcome, it means the user completed the outcome.
                            if (transactionMapById.containsKey(mappingObj.Id)) {
                                completedValue = completedValue + mappingObj.Probability__c;
                            }
                        }

                        
                    }
                }
            }
            if (totalValue> 0.00) {
                decimal percentage = completedValue / totalValue;
                percentageValue = (percentage * 100).setScale(2);
            }

        }

        return percentageValue;
    }

    //=============================================================
    // Description : Get the  SalesPathEditWrapper for the stage.
    // @param1 metadataWrapper : SalesPathController.SalesPathMetadataWrapper
    // @param2 stageName : Opportunity stagename.
    // @param3 oppRecord : Opportunity record contains all the information including fieldset fields information.
    // @exception None
    // @returnType : SalesPathController.SalesPathEditWrapper 
    //=============================================================
    public SalesPathController.SalesPathEditWrapper getSalesPathEditObject(SalesPathController.SalesPathMetadataWrapper metadataWrapper, string stageName, Opportunity oppRecord) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(SalespathConstants.SALESPATH_SOBJECTNAME_OPPORTUNITY);
        Schema.DescribesObjectResult describe = targetType.getDescribe();
        Map <String, Schema.FieldSet> fsmap = describe.fieldSets.getmap();
        Map <String, Lookup_Filter_Values__c> mapLookupFilterValues = metadataWrapper.mapLookupFilterField;

        if (fsmap!=null && metadataWrapper.mapFieldSet!=null && fsmap.ContainsKey(metadataWrapper.mapFieldSet.get(stageName))) {
            Schema.FieldSet fs = fsmap.get(metadataWrapper.mapFieldSet.get(stageName));
            List <Schema.FieldSetMember> fieldSet = fs.getFields();
            List <SalesPathController.DynamicFieldWrapper> listDnamicWrapper = new List <SalesPathController.DynamicFieldWrapper> ();
            if (!fieldSet.isEmpty()) {

                // get the listof listofDnamicWrapper by calling createDFWrapperList
                listDnamicWrapper = createDFWrapperList(fieldSet, OppRecord, metadataWrapper);

            }

            SalesPathController.SalesPathEditWrapper editobj = new SalesPathController.SalesPathEditWrapper(OppRecord, listDnamicWrapper);
            return editobj;
        }

        return null;
    }

    //======================================================================
    // Description : Creating List of Dynamic wrapper based on the fieldset.
    // @param1 fieldSet : List<Schema.FieldSetMember>
    // @param2 OppRecord : Opportunity Record
    // @param3 metadataWrapper: SalesPathController.SalesPathMetadataWrapper
    // Returntype :List<SalesPathController.DynamicFieldWrapper>
    //======================================================================

    public List <SalesPathController.DynamicFieldWrapper> createDFWrapperList(List <Schema.FieldSetMember> fieldSet, Opportunity OppRecord, SalesPathController.SalesPathMetadataWrapper metadataWrapper) {
        List <SalesPathController.DynamicFieldWrapper> listDnamicWrapper = new List <SalesPathController.DynamicFieldWrapper> ();
        Schema.sObjectType sObject_type1 = Opportunity.getsObjectType(); //grab the sobject that was passed
        Schema.DescribesObjectResult sobject_describe1 = sObject_type1.getDescribe(); //describe the sobject
        Map <String, Schema.sObjectField> oppFieldMap = sobject_describe1.fields.getmap(); //get a map of fields for the passed sobject
        for (Schema.FieldSetMember f: fieldSet) {
            SalesPathController.DynamicFieldWrapper dynamicWraperObject = new SalesPathController.DynamicFieldWrapper();
            Schema.DescribeFieldResult Fd = oppFieldMap.get(String.valueOf(f.fieldPath)).getDescribe();
            Schema.sObjectField objsObjectField = Fd.getsObjectField();
            if (objsObjectField.getDescribe().getReferenceTo() != null && objsObjectField.getDescribe().getReferenceTo().size()> 0 && objsObjectField.getDescribe().isNamePointing() == false) {
                if (objsObjectField.getDescribe().isNamePointing() == false) {
                    if (f.getFieldPath().contains('__c')) {
                        // find the refernce object and relation name from a custom field
                        List <Schema.SObjectType> lstofSobject = objsObjectField.getDescribe().getReferenceTo();
                        String fieldnaming = f.getFieldPath().removeEnd('c');
                        fieldnaming = fieldnaming + 'r';
                        dynamicWraperObject.lookupobjectName = lstofSobject[0].getDescribe().getName();
                        dynamicWraperObject.relationName = fieldnaming;
                    } else {
                        // find the refernce object and relation name from a standard field
                        List <Schema.SObjectType> lstofSobject = objsObjectField.getDescribe().getReferenceTo();
                        dynamicWraperObject.lookupobjectName = lstofSobject[0].getDescribe().getName();
                        dynamicWraperObject.relationName = lstofSobject[0].getDescribe().getName();
                    }

                }
            }

            dynamicWraperObject.DBRequired = f.DBRequired;
            dynamicWraperObject.fieldPath = f.fieldPath;
            dynamicWraperObject.label = f.label;
            dynamicWraperObject.required = f.required;
            dynamicWraperObject.type = '' + f.getType();
            dynamicWraperObject.type = dynamicWraperObject.type.toLowerCase();
            List <SalesPathController.FieldSelectOptions> optionpicklist = new List <SalesPathController.FieldSelectOptions> ();
            if (String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_PICKLIST || String.valueOf(f.getType()) == SalespathConstants.SALESPATH_FIELDTYPE_MULTIPICKLIST) {
                // passing recordtype name to restrict the playbook picklist based on recordtype.
                String recordname = '';
                if (OppRecord != null && OppRecord.RecordTypeId != null) {
                    recordname = OppRecord.RecordType.Name;
                }
                optionpicklist = CreateselectoptionList(f, recordname);
            }
            dynamicWraperObject.lstofOptions = optionpicklist;
            // get the custom setting map
            Map <String, Lookup_Filter_Values__c> mapLookupFilterValues = metadataWrapper.mapLookupFilterField;
            // checking the field is a filtere lookup or not
            if (mapLookupFilterValues.ContainsKey(f.fieldPath)) {
                if (mapLookupFilterValues.get(f.fieldPath).filterField__c != null) {
                    dynamicWraperObject.filterField = mapLookupFilterValues.get(f.fieldPath).filterField__c;
                }
                if (mapLookupFilterValues.get(f.fieldPath).filtervalue__c != null) {
                    dynamicWraperObject.filterValues = mapLookupFilterValues.get(f.fieldPath).filtervalue__c;
                }
            }
            // finding dependent picklist value
            dynamicWraperObject = updateDFWrapper(f, dynamicWraperObject, OppRecord, metadataWrapper.mapDependedField);
            // adding values to the list
            listDnamicWrapper.add(dynamicWraperObject);

        }
        return listDnamicWrapper;
    }

    //====================================================================================================================
    // Description : Update the DynamicFieldWrapper if the field is a dependend picklist.Thsi method will help you to find 
    // controlling field and its value.
    // @param1 : List<Schema.FieldSetMember> 
    // Returntype : Opportunity Record.
    //====================================================================================================================

    public SalesPathController.DynamicFieldWrapper updateDFWrapper(Schema.FieldSetMember fieldsetmemeber, SalesPathController.DynamicFieldWrapper dynamicWraperObject, Opportunity OppRecord, Map <String, String> mapDependedPicklist) {
        Schema.sObjectType sObject_type1 = Opportunity.getsObjectType(); //grab the sobject that was passed
        Schema.DescribesObjectResult sobject_describe1 = sObject_type1.getDescribe(); //describe the sobject
        Map <String, Schema.sObjectField> oppFieldMap = sobject_describe1.fields.getmap(); //get a map of fields for the passed sobject
        if (!mapDependedPicklist.isEmpty()) {

            if (mapDependedPicklist.containsKey(fieldsetmemeber.fieldPath)) {

                Schema.DescribeFieldResult controllfieldResult = oppFieldMap.get(String.valueOf(mapDependedPicklist.get(fieldsetmemeber.fieldPath))).getDescribe();
                Schema.sObjectField controllfield = controllfieldResult.getsObjectField();
                Schema.DescribeFieldResult objsObjectFieldResult = oppFieldMap.get(String.valueOf(fieldsetmemeber.fieldPath)).getDescribe();
                Schema.sObjectField objsObjectField = objsObjectFieldResult.getsObjectField();
                if (getDependentOptionsImpl(objsObjectField, controllfield) != null) {
                    dynamicWraperObject.isdependedField = true;
                    dynamicWraperObject.mapControllingPicklistFields = getDependentOptionsImpl(objsObjectField, controllfield);
                    if (!dynamicWraperObject.mapControllingPicklistFields.isEmpty()) {
                        for (List <SalesPathController.FieldSelectOptions> objectfield: dynamicWraperObject.mapControllingPicklistFields.values()) {
                            objectfield.add(new SalesPathController.FieldSelectOptions('', '--None--'));
                        }
                    }
                    dynamicWraperObject.controllerField = mapDependedPicklist.get(fieldsetmemeber.fieldPath);
                    dynamicWraperObject.controllerFieldLabel = controllfield.getDescribe().getLabel();
                    if (OppRecord.get(fieldsetmemeber.fieldPath) != null) {
                        dynamicWraperObject.controllerFieldValue = (String) OppRecord.get(mapDependedPicklist.get(fieldsetmemeber.fieldPath));
                    }
                }
            } else {
                dynamicWraperObject.isdependedField = true;
            }

        }
        return dynamicWraperObject;
    }
    
   

    //=========================================================
    //                 Utility Methods
    //=========================================================

    //====================================================================
    // Description : Create List<FieldSelectOptions> for a picklist field 
    // @param1: Schema.FieldSetMember to get the picklist field values
    // ReturnType : List<FieldSelectOptions>
    //====================================================================

    public List <SalesPathController.FieldSelectOptions> createselectoptionList(Schema.FieldSetMember fieldsetmemeber, String recordname) {
        List <SalesPathController.FieldSelectOptions> optionpicklist = new List <SalesPathController.FieldSelectOptions> ();
        Schema.sObjectType sObject_type = Opportunity.getsObjectType(); //grab the sobject that was passed
        Schema.DescribesObjectResult sobject_describe = sObject_type.getDescribe(); //describe the sobject
        Map <String,
            Schema.sObjectField> field_map = sobject_describe.fields.getmap(); //get a map of fields for the passed sobject
        List <Schema.PicklistEntry> pick_list_values = field_map.get(String.valueOf(fieldsetmemeber.fieldPath)).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        if (!pick_list_values.isEmpty()) {
            SalesPathController.FieldSelectOptions newobj = new SalesPathController.FieldSelectOptions('', '--None--');
            optionpicklist.add(newobj);
            if (fieldsetmemeber.getLabel() != null && fieldsetmemeber.getLabel() == OpportunityConstants.SALESPATH_PLAYBOOK_LABEL) {
                for (Schema.PicklistEntry a: pick_list_values) {
                    if (recordname != null && String.isNotBlank(recordname) && recordname == OpportunityConstants.SALESPATH_OPPORTUNITY_RECORDTYPE_RENEWAL) {
                        if (a.getValue() == OpportunityConstants.SALESPATH_PLAYBOOK_RENEWAL) {
                            SalesPathController.FieldSelectOptions newobj1 = new SalesPathController.FieldSelectOptions(a.getValue(), a.getLabel());
                            optionpicklist.add(newobj1);
                        }
                    } else {
                        if (a.getLabel() != OpportunityConstants.SALESPATH_PLAYBOOK_RENEWAL) {
                            SalesPathController.FieldSelectOptions newobj1 = new SalesPathController.FieldSelectOptions(a.getValue(), a.getLabel());
                            optionpicklist.add(newobj1);
                        }
                    }

                }
            } else {
                for (Schema.PicklistEntry a: pick_list_values) {
                    SalesPathController.FieldSelectOptions newobj1 = new SalesPathController.FieldSelectOptions(a.getValue(), a.getLabel());
                    optionpicklist.add(newobj1);
                }
            }


        } else {
            SalesPathController.FieldSelectOptions newobj = new SalesPathController.FieldSelectOptions('', '--None--');
            optionpicklist.add(newobj);
        }
        return optionpicklist;
    }

    //=======================================================================================================================
    //  * Apex doesn't expose dependent picklist info directly, but it's possible to expose.
    //    Approach:
    //  * Schema.PicklistEntry doesn't expose validFor tokens, but they are there, and can be accessed by serializing to JSON
    //    (and then for convenience, deserializing back into an Apex POJO)
    //  * validFor tokens are converted from base64 representations (e.g. gAAA) to binary (100000000000000000000)
    //    each character corresponds to 6 bits, determined by normal base64 encoding rules.
    //  * The binary bits correspond to controlling values that are active - e.g. in the example above, this dependent option
    //    is available for the first controlling field only.
    //========================================================================================================================

    public Map <String, List <SalesPathController.FieldSelectOptions>> getDependentOptionsImpl(Schema.SObjectField theField, Schema.SObjectField ctrlField) {
        // validFor property cannot be accessed via a method or a property,
        // so we need to serialize the PicklistEntry object and then deserialize into a wrapper.
        List <Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List <SalesPathController.PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());

        // Set up the return container - Map<ControllingValue, List<DependentValues>>
        Map <String,
            List <SalesPathController.FieldSelectOptions>> objResults = new Map <String,
            List <SalesPathController.FieldSelectOptions>> ();
        List <String> controllingValues = new List <String> ();
        for (Schema.PicklistEntry ple: contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List <SalesPathController.FieldSelectOptions> ());
            controllingValues.add(label);
        }

        for (SalesPathController.PicklistEntryWrapper plew: depEntries) {
            String label = plew.label;
            String validForBits = SalesforceUtils.base64ToBits(plew.validFor);
            for (Integer i = 0; i <validForBits.length(); i++) {
                // For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    SalesPathController.FieldSelectOptions newobj = new SalesPathController.FieldSelectOptions(label, label);
                    objResults.get(controllingValues.get(i)).add(newobj);
                }
            }
        }

        return objResults;
    }



    //================================================
    // serialize the picklist values and deserialize
    // Return Type : List<PicklistEntryWrapper>
    //================================================
    private List <SalesPathController.PicklistEntryWrapper> wrapPicklistEntries(List <Schema.PicklistEntry> PLEs) {
        return (List <SalesPathController.PicklistEntryWrapper> ) JSON.deserialize(JSON.serialize(PLEs), List <SalesPathController.PicklistEntryWrapper> .class);
    }


    //============================================
    // DML Functions
    //============================================

    //===========================================================================================================================================
    // Description : this method used for insert tasks related to the salespath recomanded tasks
    // @param TaskId : to fetch the details of the salespath task details and add these values to newly creating task
    // @param value: Boolean type param: Based on the boolean value we will create task. If value is true we will create new task else nothing.
    //===========================================================================================================================================

    public void saveTransactionTasks(String taskId, boolean value, String oppId) {
        // if value is true then create transaction record else delete exosting transaction record.
        if(value){
            if (taskId != null && String.isNotBlank(taskId)) {
                Salespath_Mapping__c mapObj = [select id, value_long_text__c,RecordTypeId, RecordType.Name from Salespath_Mapping__c where Id =: taskId];
                if (mapObj != null && mapObj.RecordTypeId != null && mapObj.RecordType.Name == SalespathConstants.SALESPATH_MAPPING_RECORDTYPE_TASK ) {
                    Task newtask = new Task();
                    newtask.OwnerId = UserInfo.getUserId();
                    newtask.WhatId = oppId;
                    newtask.ActivityDate = System.today();
                    newtask.Subject = mapObj.value_long_text__c;
                    newtask.Status = SalespathConstants.SALESPATH_STATUS_NOTSTARTED;
                    // update task record
                    insert newtask;

                }
                Salespath_transaction__c transobj = new Salespath_transaction__c();
                transobj.Opportunity__c = oppId;
                transobj.PANW_mapping__c = taskId;
                insert transobj;
            }
            
        }else{
            
            Salespath_transaction__c transobj = [select id, value__c, Opportunity__c, type__c, Opportunity__r.Account.Id, PANW_mapping__r.value_long_text__c, PANW_mapping__r.RecordType.Name from Salespath_transaction__c where PANW_mapping__c =: taskId AND Opportunity__c=:oppId];
            System.debug('check transobject------>'+transobj);
            delete transobj;
        }
    }



    //===============================================================
    // Description : this method used for updating Opportunity stage
    // @param stage : New value of Opportunity record
    //===============================================================

    public void updateOpportunity(Opportunity oppRecord) {
        if (oppRecord != null)
            update oppRecord;
    }
    //===============================================================
    // Description : this method used to get Default Stage name for given oppty record type & Salespath selected stage name label
    // @param stage : stage name (from Salespath component), recordType of the opportunity
    //===============================================================
    public String getOpptyStageForStageLabel(String stageLabel, String recordTypeName){
        if(String.isNotBlank(stageLabel) && String.isNotBlank(recordTypeName)){
            List<Salespath_to_Stage_Mapping__mdt> mappingList = getSalesPathToStageMetadata();
            for(Salespath_to_Stage_Mapping__mdt item:mappingList){
                if(item.MasterLabel == stageLabel && item.Record_Type__c == recordTypeName)
                    return item.Default_Stage_API__c;
            }
        }
        return null;
    }
    //===============================================================
    // Description : this method used to get Display order for given oppty record type & stage name label
    // @param stage : stage name (from Salespath component), recordType of the opportunity
    //===============================================================
    public Integer getConsolidatedSatgeOrder(String stageLabel, String recordTypeName){
        if(String.isNotBlank(stageLabel) && String.isNotBlank(recordTypeName)){
            List<Salespath_to_Stage_Mapping__mdt> mappingList = getSalesPathToStageMetadata();
            for(Salespath_to_Stage_Mapping__mdt item:mappingList){
                if(item.MasterLabel == stageLabel && item.Record_Type__c == recordTypeName)
                    return Integer.valueOf(item.Display_Order__c);
            }
        }
        return null;
    }
    //===============================================================
    // Description : this method used to get List of Salespath_to_Stage_Mapping__mdt records
    // @param stage : none
    //===============================================================
    private List<Salespath_to_Stage_Mapping__mdt> getSalesPathToStageMetadata(){
        return new List<Salespath_to_Stage_Mapping__mdt>(
            [Select MasterLabel,DeveloperName, Default_Stage_API__c, Display_Order__c, Record_Type__c From Salespath_to_Stage_Mapping__mdt]
        );
    }

    /**
     * 
     * @param  salesMappingList [description]
     * @return                  [description]
     */
    private List<String> getTypeListFromMapping(List<Salespath_mapping__c> salesMappingList) {
        List<String> typeList = new List<String>();
        if (salesMappingList != null && salesMappingList.isEmpty() == false) {
            for (Salespath_mapping__c salesMapping : salesMappingList) {
                typeList.add(salesMapping.Type__c);
            }
        }
        return typeList;
    }
}