public class PropertyTriggerHandler {
    public static void afterInsertMethod(list<property__c> propList){

        list<id>propIds=new list<id>();
        for (Property__c prop : propList) {
            propIds.add(prop.id);
        }

        if (!propIds.isEmpty()) {
            System.enqueueJob(
                new PropertyGeocodeQueueable(propIds)
            );
        }
        
    }
    
    public static void afterUpdateMethod(map<id,property__c>oldPropMap,list<property__c> propList){

        list<id> valid_prop_ids=new list<id>();

        for (Property__c prop : propList) {
            property__c oldProp =oldPropMap.get(prop.id);
            if(prop.Address__c != oldProp.Address__c || prop.City__c != oldProp.City__c 
            || prop.State__c != oldProp.State__c || prop.Postal_Code__c != oldProp.Postal_Code__c || 
            prop.Postal_Code__c != oldProp.Postal_Code__c || prop.Country__c != oldProp.Country__c)
            {
                valid_prop_ids.add(prop.id);
            }
        }

        if (!valid_prop_ids.isEmpty()) {
            System.enqueueJob(
                new PropertyGeocodeQueueable(valid_prop_ids)
            );
        }
        
    }
}