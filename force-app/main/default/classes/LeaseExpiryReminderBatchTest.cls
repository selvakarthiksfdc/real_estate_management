@IsTest
private class LeaseExpiryReminderBatchTest {

    @TestSetup
    static void setupData() {

        Tenant__c tenant = new Tenant__c(
            Name = 'Test Tenant',
            Email__c = 'tenant@example.com'
        );
        insert tenant;

        List<Property__c> properties = new List<Property__c>();

        for (Integer i = 1; i <= 3; i++) {
            properties.add(new Property__c(
                Name = 'Test Property ' + i,
                Tenant__c = tenant.Id,
                Address__c = '123 Anna Salai',
                City__c = 'Chennai',
                State__c = 'Tamil Nadu',
                Postal_Code__c = '600002',
                Country__c = 'India',
                Type__c='Residential',
                Furnishing_Status__c='Furnished',
                Status__c='Available',
                Rent__c=10000
            ));
        }

        insert properties;

        List<Lease_Agreement__c> leases =
            new List<Lease_Agreement__c>();

        leases.add(new Lease_Agreement__c(
            Property__c = properties[0].Id,
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Terms__c = 'Standard lease terms',
            One_Month_Reminder_Sent__c = false,
            One_Day_Reminder_Sent__c = false
        ));

        leases.add(new Lease_Agreement__c(
            Property__c = properties[1].Id,
            Agreed_Monthly_Rent__c = 30000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1),
            Terms__c = 'Standard lease terms',
            One_Month_Reminder_Sent__c = false,
            One_Day_Reminder_Sent__c = false
        ));

        // Third property: lease not due for a reminder
        leases.add(new Lease_Agreement__c(
            Property__c = properties[2].Id,
            Agreed_Monthly_Rent__c = 20000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(60),
            Terms__c = 'Standard lease terms',
            One_Month_Reminder_Sent__c = false,
            One_Day_Reminder_Sent__c = false
        ));

        insert leases;
    }

    @IsTest
    static void testReminderScenarios() {

        Test.startTest();

        Database.executeBatch(
            new LeaseExpiryReminderBatch(),
            10
        );

        Test.stopTest();

    }
}