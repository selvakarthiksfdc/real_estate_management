public class MaintenanceRequestTriggerHandler {

    public static void handleBeforeInsert(
        List<Maintenance_Request__c> requests
    ) {
        MaintenanceRequestHelper.assignVendors(requests);
    }
}