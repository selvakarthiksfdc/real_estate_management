trigger PropertyTrigger on Property__c (after insert, after update) {
    if(trigger.isafter && trigger.isInsert){
        PropertyTriggerHandler.afterInsertMethod(trigger.new);
    }
    
    if(trigger.isafter && trigger.isUpdate){
        PropertyTriggerHandler.afterUpdateMethod(trigger.oldMap,trigger.new);
    } 

}