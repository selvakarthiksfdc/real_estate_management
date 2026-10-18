public class MaintenanceRequestHelper {

    public static void assignVendors(List<Maintenance_Request__c> requests) {
        // Get all vendors in a consistent order
        List<Vendor__c> vendors = [SELECT Id, Name FROM Vendor__c ORDER BY Name ASC, Id ASC];

        if (vendors.isEmpty()) {
            return;
        }

        // Initialize workload for every vendor
        Map<Id, Integer> workloadByVendor = new Map<Id, Integer>();

        for (Vendor__c vendor : vendors) {
            workloadByVendor.put(vendor.Id, 0);
        }

        // Count active maintenance requests
        for (AggregateResult result : [SELECT Vendor__c vendorId, COUNT(Id) total FROM Maintenance_Request__c 
                                       WHERE Vendor__c != null AND Status__c IN ('Open', 'In Progress')
                                       GROUP BY Vendor__c]) 
        {
            Id vendorId = (Id) result.get('vendorId');

            if (workloadByVendor.containsKey(vendorId)) {
                workloadByVendor.put(vendorId,(Integer) result.get('total'));
            }
        }

        // Assign requests to the least-loaded vendor
        for (Maintenance_Request__c request : requests) {

            // Preserve a manually selected vendor
            if (request.Vendor__c != null) {
                continue;
            }

            Id selectedVendorId;
            Integer lowestWorkload;

            for (Vendor__c vendor : vendors) {
                Integer currentWorkload = workloadByVendor.get(vendor.Id);

                if (selectedVendorId == null || currentWorkload < lowestWorkload) {
                    selectedVendorId = vendor.Id;
                    lowestWorkload = currentWorkload;
                }
            }

            request.Vendor__c = selectedVendorId;

            // Update workload for subsequent requests in this batch
            if (selectedVendorId != null) {
                workloadByVendor.put(selectedVendorId,workloadByVendor.get(selectedVendorId) + 1);
            }

            // Default status to Open
            if (String.isBlank(request.Status__c)) {
                request.Status__c = 'Open';
            }
        }
    }
}