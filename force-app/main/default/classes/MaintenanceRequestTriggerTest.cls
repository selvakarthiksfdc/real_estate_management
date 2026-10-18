@IsTest
private class MaintenanceRequestTriggerTest {

    @TestSetup
    static void setupData() {

        // Create Property
        Property__c propertyRecord = new Property__c(
            Name = 'Test Property',
            Address__c = '123 Anna Salai',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Postal_Code__c = '600002',
            Country__c = 'India',
            Type__c='Residential',
            Furnishing_Status__c='Furnished',
            Status__c='Available',
            Rent__c=10000
        );
        insert propertyRecord;

        // Create Vendors
        insert new List<Vendor__c>{
            new Vendor__c(Name = 'Vendor A'),
            new Vendor__c(Name = 'Vendor B'),
            new Vendor__c(Name = 'Vendor C')
        };
    }

    private static Property__c getProperty() {
        return [
            SELECT Id
            FROM Property__c
            LIMIT 1
        ];
    }

    private static List<Vendor__c> getVendors() {
        return [
            SELECT Id, Name
            FROM Vendor__c
            ORDER BY Name ASC, Id ASC
        ];
    }

    private static Maintenance_Request__c newRequest(
        String requestName,
        Id propertyId,
        Id vendorId,
        String status
    ) {
        return new Maintenance_Request__c(
            Name = requestName,
            Property__c = propertyId,
            Vendor__c = vendorId,
            Status__c = status
        );
    }

    @IsTest
    static void testAutomaticVendorAssignment() {

        Property__c prop = getProperty();

        List<Maintenance_Request__c> requests =
            new List<Maintenance_Request__c>{
                newRequest('Request 1', prop.Id, null, null),
                newRequest('Request 2', prop.Id, null, null),
                newRequest('Request 3', prop.Id, null, null)
            };

        Test.startTest();
        insert requests;
        Test.stopTest();

        List<Maintenance_Request__c> results = [
            SELECT Vendor__c, Status__c
            FROM Maintenance_Request__c
            WHERE Id IN :requests
        ];

        System.assertEquals(3, results.size());

        Set<Id> assignedVendorIds = new Set<Id>();

        for (Maintenance_Request__c req : results) {
            System.assertNotEquals(
                null,
                req.Vendor__c,
                'A vendor should be assigned.'
            );

            System.assertEquals('Open', req.Status__c);
            assignedVendorIds.add(req.Vendor__c);
        }

        System.assertEquals(
            3,
            assignedVendorIds.size(),
            'Requests should be distributed across all three vendors.'
        );
    }
}