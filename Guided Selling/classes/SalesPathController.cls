/*
 * © Palo Alto Network 2015, all rights reserved
 * 
 * Created Date: 07/24/2017
 *
 * Author: Nidheesh
 * 
 * Description: Controller class for salesPath
 * 
 */
public class SalesPathController {
   
    /**
     * Description : Constructor 
     */
    public SalesPathController() {

    }

    /**
     * Description : This method will return salespath details related to the Opportunity 
     * 
     * @param oppId : Opportunity Id to get the salespath details about Opportunity
     * 
     * Return type : SalesPathWrapper object.
     */
    @AuraEnabled
    public static SalesPathWrapper createSalesWrapper(String oppId) {
        if (oppId != null && String.isNotBlank(oppId)) {
            // get the metadata  related to the Opportunity.
            oppId = String.escapeSingleQuotes(oppId);

            Opportunity oppRecord=new OpportunityService().getOppRecord(OppId);
            if(String.isBlank(oppRecord.Sales_Process__c))
            {
              oppRecord.Sales_Process__c=OpportunityConstants.SALESPATH_PLAYBOOK_INTERNAL_DEFAULT ;
            }
            SalesPathMetadataWrapper metadataWrapper = new SalesPathMetadataWrapper();
            metadataWrapper = new SalesPathService().getMetadata(oppRecord);
            System.debug('check metadataWrapper-----' + metadataWrapper);

            // get the transactional data for the aura component.
            SalesPathWrapper objWrapper = new SalesPathWrapper();
            objWrapper = new SalesPathService().getSalesPathDataWrapper(metadataWrapper);
            //remove keyFields for 'Closed set innitially, these are meant only when opp is lost'
            if(objWrapper.mapSalesPathDataWrapper.containsKey('Closed') && objWrapper.mapSalesPathDataWrapper.get('Closed').lstKeyWrapper != null)
                objWrapper.mapSalesPathDataWrapper.get('Closed').lstKeyWrapper = null;
            System.debug('check SalesPathWrapper-----' + objWrapper);
            return objWrapper;
        }
        return null;
    }

    /** 
     * Description : This method used for insert tasks related to the salespath recomanded tasks
     * 
     * @param TaskId : to fetch the details of the salespath task details and add these values to newly creating task
     * 
     * @param value: Boolean type param: Based on the boolean value we will create task. If value is true we will create new task else nothing.
     * 
     */
    @AuraEnabled
    public static void saveTasks(String taskId, boolean value, String oppId) {
        if (taskId != null && String.isNotBlank(taskId)) {
            taskId = String.escapeSingleQuotes(taskId);
            try {
                new SalesPathService().saveTransactionTasks(taskId, value,oppId);
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }

        }
    }

    /** 
     * Description : This method used for updating Opportunity stage
     * 
     * @param stage : New value of Opportunity Stage
     * 
     * @param oppId: Id of Opportunity
     * 
     *  
     */
    @AuraEnabled
    public static String assignNewOppStage(String stage, String oppId) {
        if (oppId != null && String.isNotBlank(oppId))
            oppId = String.escapeSingleQuotes(oppId);

        Opportunity oppRecord = new OpportunityService().getOppRecord(oppId);
        if(stage.contains(SalesPathConstants.SALESPATH_STAGECLOSED))
            oppRecord.stageName = new SalesPathService().getStageValue(stage);
        else
            oppRecord.stageName = new SalesPathService().getOpptyStageForStageLabel(stage, oppRecord.RecordType.Name);
        System.debug('stage value-----'+ oppRecord.stageName);
        String messge = '';
        try {
            /* SFDCSALES 2419 (Since, these two fields are fetched in OpportunityServic and same values were getting updated,
             * as a result -> on stage change these two values were not getting updated. Clearing values fixes the issue
             */
            oppRecord.ForecastCategoryName = '';
            oppRecord.Probability = null;
            new SalesPathService().updateOpportunity(oppRecord);
            messge = SalesPathConstants.SALESPATH_SUCCESSMESSGE;
        } catch (DMLException Ex) {
            messge = Ex.getDmlMessage(0).unescapeXml();
        }
        return messge;
    }

    /**
     * Description : method to save the Oppotunity record which were edit through edit keyfield section.
     * 
     * @param oppRecordId : Id of the Opportunity
     * 
     * @param jsonRecord : data in json String form.
     * 
     * return Type : String --- success message or failure message 
     */

    @AuraEnabled
    public static String saveOpportunity(String oppRecordId, String jsonRecord, String stageValue) {
        if (oppRecordId != null && String.isNotBlank(oppRecordId))
            oppRecordId = String.escapeSingleQuotes(oppRecordId);

        SalesPathController.SalesPathEditWrapper datawrapper = new SalesPathController.SalesPathEditWrapper();
        Opportunity oppRecord = new Opportunity();
        List < SalesPathController.DynamicFieldWrapper > fieldwrapperList = new List < SalesPathController.DynamicFieldWrapper > ();

        datawrapper = (SalesPathController.SalesPathEditWrapper) JSON.deserialize(jsonRecord, SalesPathController.SalesPathEditWrapper.class);

        if (datawrapper != null) {
            if (OpprecordId != null) {
                oppRecord.Id = OpprecordId;
            }
            if (Stagevalue != null && String.isNotBlank(Stagevalue) && Stagevalue != '') {
                oppRecord.StageName = new SalesPathService().getStageValue(Stagevalue);
            }
            //assign blank value if picklist have None as selected
            System.debug('check datafieldwrapper----->'+datawrapper);
            if (datawrapper.lstFieldProperties != null && !datawrapper.lstFieldProperties.isEmpty()) {
                fieldwrapperList = datawrapper.lstFieldProperties;
                for (SalesPathController.DynamicFieldWrapper objwrap: fieldwrapperList) {
                    if (objwrap.value != null) {
                        if (objwrap.type == SalespathConstants.SALESPATH_FIELDTYPE_BOOLEAN_SMALL) {
                            oppRecord.put(objwrap.fieldPath, Boolean.valueOf(objwrap.value));
                        } else if (objwrap.type == SalespathConstants.SALESPATH_FIELDTYPE_DOUBLE_SMALL || objwrap.type == SalespathConstants.SALESPATH_FIELDTYPE_CURRENCY_SMALL || objwrap.type == SalespathConstants.SALESPATH_FIELDTYPE_PERCENT_SMALL) {
                            oppRecord.put(objwrap.fieldPath, Decimal.valueOf(objwrap.value));
                        } else if (objwrap.type == SalespathConstants.SALESPATH_FIELDTYPE_DATE_SMALL) {
                            oppRecord.put(objwrap.fieldPath, Date.valueOf(objwrap.value));
                        } else {

                            if (objwrap.value != '' && objwrap.value != '--None--' && String.isNotBlank(objwrap.value)) {
                                oppRecord.put(objwrap.fieldPath, objwrap.value);
                            } else if (objwrap.value == '' || objwrap.value == '--None--' || objwrap.value == null || String.isBlank(objwrap.value)) {
                                oppRecord.put(objwrap.fieldPath, '');
                            } else {
                                oppRecord.put(objwrap.fieldPath, '');
                            }
                        }
                    }
                }
            }
        }

        String messge = '';
        try {
            /* SFDCSALES-2419 (Since, these two fields are fetched in OpportunityServic and same values were getting updated,
             * as a result -> on stage change these two values were not getting updated. Clearing values fixes the issue
             */
            oppRecord.ForecastCategoryName = '';
            oppRecord.Probability = null;

            new SalesPathService().updateOpportunity(oppRecord);
            messge = SalespathConstants.SALESPATH_SUCCESSMESSGE;
        } catch (DMLException Ex) {
            messge = Ex.getDmlMessage(0).unescapeXml();
        }
        return messge;
    }
    
    /**
     * Description : method to save the Oppotunity record which were edit through edit keyfield section.
     * 
     * @param oppRecordId : Id of the Opportunity
     * 
     * @param jsonRecord : data in json String form.
     * 
     * return Type : String --- success message or failure message 
     */
    /*public static List < SalesPathController.SalesPathTaskWrapper > getDealDocList(String oppdId) {
        if (oppdId != null && String.isNotBlank(oppdId)) {
            oppdId = String.escapeSingleQuotes(oppdId);

            return new SalesPathService().getDealDocList(oppdId);
        }
        return null;
    }*/

    /****************************************************************************************************************************
     *
     * Wrappers
     *
     ****************************************************************************************************************************/

    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for Salespath
     * 
     */
    public class SalesPathDataWrapper {
        @AuraEnabled
        public List < SalesPathController.SalesPathKeyFieldWrapper > lstKeyWrapper ;
        @AuraEnabled
        public List < SalesPathController.SalesPathOutcomeWrapper > lstOutComeWrapper ;
        @AuraEnabled
        public List < SalesPathController.SalesPathTaskWrapper > lstTaskWrapper ;
        @AuraEnabled
        public List < SalesPathController.SalesTipWrapper > lstSalesTipWrapper ;

        @AuraEnabled
        public SalesPathEditWrapper salespathEditWrapper ;

        @AuraEnabled
        public Decimal progressValue ;
        @AuraEnabled
        public Decimal total ;
        @AuraEnabled
        public integer index ;
        @AuraEnabled
        public Boolean current ;
        @AuraEnabled
        public Boolean completed ;
        @AuraEnabled
        public Boolean incomplete ;
        @AuraEnabled
        public String stage ;
        @AuraEnabled
        public String status ;

        @AuraEnabled
        public String fieldsetName ;
        @AuraEnabled
        public Boolean completeGatedTask ;
        public SalesPathDataWrapper() {

        }
    }

    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: This Wrapper stores all the transaction records,Opportunity record and fieldset information related to the Opportunity.
     * 
     */

    public class SalesPathMetadataWrapper {
        public Opportunity oppRecord ;
        public List < Salespath_Process__c > lstSalesPathProcess ;
        public Map<String, List< Salespath_mapping__c >> mappingsByStage ;
        public Set < String > setOppStages ;
        public Map < String, String > mapFieldSet ;
        public Map < String, Lookup_Filter_Values__c > mapLookupFilterField ;
        public Map < String, String > mapDependedField ;
        public Map < Id, Salespath_transaction__c > transactionByMapping ;

        public SalesPathMetadataWrapper() {

        }
    }


    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for Salespath
     * 
     */
    public class SalesPathWrapper {
        @AuraEnabled
        public Map < String, SalesPathController.SalesPathDataWrapper > mapSalesPathDataWrapper ;
        @AuraEnabled
        public String opportunityId ;
        @AuraEnabled
        public List < String > lstStage ;
        @AuraEnabled
        public String activeStage ;
        // List of dealDoc. We need to show this in evry stage.
        @AuraEnabled
        public List < SalesPathTaskWrapper > lstDealDocWrapper ;
        // Closed stage fields.
        @AuraEnabled
        public SalesPathEditWrapper closedStageEditWrapper ;

        public SalesPathWrapper(Map < String, SalesPathController.SalesPathDataWrapper > mapSalesPathDataWrapper, String opportunityId, List < String > lstStage, String activeStage) {
            this.mapSalesPathDataWrapper = mapSalesPathDataWrapper;
            this.opportunityId = opportunityId;
            this.lstStage = lstStage;
            this.activeStage = activeStage;
        }
        public SalesPathWrapper() {

        }
    }

    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for Outcome section of salespath controller
     * 
     */
    public class SalesPathOutcomeWrapper {
        @AuraEnabled
        public String taskDescription ;
        @AuraEnabled
        public Decimal percentage ;
        @AuraEnabled
        public Boolean completed ;
        @AuraEnabled
        public id transactionId ;
        @AuraEnabled
        public Boolean isGatedTask ;

        public SalesPathOutcomeWrapper(String taskDescription, Decimal percentage, Boolean completed, id transactionId, Boolean isgatedtask) {
            this.taskDescription = taskDescription;
            this.percentage = percentage;
            this.completed = completed;
            this.transactionId = transactionId;
            this.isgatedtask = isgatedtask;
        }
        public SalesPathOutcomeWrapper() {

        }
    }

    /**
     * @author          Nidheesh N
     * @decription      Wrapper class for the DemodynamicComponent aura component.
     */
    public class SalesPathEditWrapper {
        

        @AuraEnabled
        public Opportunity opportunityRec ;

        @AuraEnabled
        public List < SalesPathController.DynamicFieldWrapper > lstFieldProperties ;

        /**
         * Constructor of EditWrapper wrapper class
         * 
         * @param   List<DynamicFieldWrapper> 
         * 
         * @param   Opportynity Record
         *
         * @return  Wrapper class objetct
         *
         * @decription  The method will accept fieldset member and create a wrapper object
         *              Which consist of filedlabel, field type, field value, field requred and list of picklist values.
         *              
         *
         */
        public SalesPathEditWrapper(Opportunity opportunityRec, List < SalesPathController.DynamicFieldWrapper > lstFieldProperties) {
            this.opportunityRec = opportunityRec;
            this.lstFieldProperties = lstFieldProperties;
        }
        public SalesPathEditWrapper() {

        }
    }

    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for salesTip  section of salespath controller
     * 
     */

    public class SalesTipWrapper {
        @AuraEnabled
        public String salesTip ;
        @AuraEnabled
        public id transactionId ;

        public SalesTipWrapper(String salesTip, id transactionId) {
            this.salesTip = salesTip;
            this.transactionId = transactionId;
        }
        public SalesTipWrapper() {

        }
    }

    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for keyfield section of salespath controller
     * 
     */
    public class SalesPathKeyFieldWrapper {
        @AuraEnabled
        public String fieldLabel ;
        @AuraEnabled
        public String fieldName ;
        @AuraEnabled
        public String fieldValue ;
        @AuraEnabled
        public String fieldType ;

        public SalesPathKeyFieldWrapper(String fieldLabel, String fieldName, String fieldValue, String fieldType) {
            this.fieldLabel = fieldLabel;
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
            this.fieldType = fieldType;
        }
        public SalesPathKeyFieldWrapper() {

        }
    }



    /*
     * © Palo Alto Network 2015, all rights reserved
     *
     * Author: Nidheesh
     * 
     * Description: wrapper class for task section of salespath controller
     * 
     */
    public class SalesPathTaskWrapper {
        @AuraEnabled
        public String recommandedTask ;
        @AuraEnabled
        public Boolean completed ;
        @AuraEnabled
        public String value ;
        @AuraEnabled
        public id transactionId ;
        @AuraEnabled
        public boolean dealDoctor ;
        @AuraEnabled
        public String link ;
        @AuraEnabled
        public List < String > AddInfo ;
        @AuraEnabled
        public String tcoBattleCard ;

        public SalesPathTaskWrapper(String recommandedTask, Boolean completed, String value, id transactionId) {
            this.recommandedTask = recommandedTask;
            this.completed = completed;
            this.value = value;
            this.transactionId = transactionId;
            this.dealDoctor = false;
        }
        public SalesPathTaskWrapper(String recommandedTask, Boolean completed, String value, id transactionId, String tcoBattleCard, String link, boolean dealDoctor) {
            this.recommandedTask = recommandedTask;
            this.completed = completed;
            this.value = value;
            this.transactionId = transactionId;
            this.tcoBattleCard = tcoBattleCard;
            this.dealDoctor = dealDoctor;
            this.link = link;

        }

        public SalesPathTaskWrapper(String recommandedTask, Boolean completed, String value, id transactionId, String tcoBattleCard, boolean dealDoctor, List < String > AddInfo) {
            this.recommandedTask = recommandedTask;
            this.completed = completed;
            this.value = value;
            this.transactionId = transactionId;
            this.tcoBattleCard = tcoBattleCard;
            this.dealDoctor = dealDoctor;
            this.AddInfo = AddInfo;

        }
    }

    /**
     * @author          Nidheesh N
     * 
     * @decription      Wrapper class to find the depended picklist .
     */
    public class PicklistEntryWrapper {
        public String active ;
        public String defaultValue ;
        public String label ;
        public String value ;
        public String validFor ;
    }

    /**
     * @author          Nidheesh N
     * @decription      Wrapper class for the DemodynamicComponent aura component.
     */
    public class FieldSelectOptions {
        /**
         * Constructor of EditWrapper wrapper class
         * 
         * @param   List<DynamicFieldWrapper> 
         * 
         * @param   Opportynity Record
         *
         * @return  Wrapper class object
         *
         * @decription  The method will accept fieldset member and create a wrapper object
         *              Which consist of filedlabel, field type, field value, field requred and list of picklist values.
         *              
         *
         */

        @AuraEnabled
        public String value ;

        @AuraEnabled
        public String label ;

        public FieldSelectOptions(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
     * @author          Nidheesh N
     * @date            06th August 2017
     * @decription      Wrapper class for the DemodynamicComponent aura component.
     */

    public class DynamicFieldWrapper {

        /**
         *  Constructor of DynamicFieldWrapper wrapper class
         *
         * @return  Wrapper class objetct
         *
         * @decription  The method will create a wrapper object
         *              Which consist of filedlabel, field type, field value, field requred and list of picklist values.
         *              
         *
         */
        public DynamicFieldWrapper() {

        }

        @AuraEnabled
        public Boolean DBRequired ;

        @AuraEnabled
        public String fieldPath ;

        @AuraEnabled
        public String label ;

        @AuraEnabled
        public Boolean required ;

        @AuraEnabled
        public String type ;

        @AuraEnabled
        public String value ;

        @AuraEnabled
        public List < SalesPathController.FieldSelectOptions > lstofOptions ;

        @AuraEnabled
        public String controllerField ;

        @AuraEnabled
        public String controllerFieldLabel ;

        @AuraEnabled
        public Boolean isdependedField ;

        @AuraEnabled
        public String controllerFieldValue ;

        @AuraEnabled
        public Map < String, List < SalesPathController.FieldSelectOptions >> mapControllingPicklistFields ;

        @AuraEnabled
        public String lookupobjectName ;

        @AuraEnabled
        public String relationName ;

        @AuraEnabled
        public String filterField ;

        @AuraEnabled
        public String filterValues ;
    }
}