public with sharing class CreateNewPropertyController {
    @AuraEnabled
    public static void CreateNewPropMethod(string propertyJson){
        property__c propertyRecord=(property__c) JSON.deserialize(propertyJson, property__c.class);
        system.debug(propertyRecord);
    }
}