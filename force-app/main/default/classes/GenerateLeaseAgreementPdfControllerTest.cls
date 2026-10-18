@IsTest
private class GenerateLeaseAgreementPdfControllerTest {

    @TestSetup
    static void setupData() {
        // Create Tenant
        Tenant__c tenant = new Tenant__c(
            Name = 'Test Tenant',
            Email__c = 'tenant@example.com'
        );
        insert tenant;

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
            Rent__c=10000,
            tenant__c=tenant.Id
        );
        insert propertyRecord;

        // Create Lease Agreement
        Lease_Agreement__c lease = new Lease_Agreement__c(
            Property__c = propertyRecord.Id,
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.newInstance(2026, 1, 1),
            End_Date__c = Date.newInstance(2026, 12, 31),
            Terms__c = 'Monthly rent must be paid on time.'
        );
        insert lease;
    }

    private static Lease_Agreement__c getTestLease() {
        return [
            SELECT Id, Name
            FROM Lease_Agreement__c
            LIMIT 1
        ];
    }

    @IsTest
    static void testGetLeaseAgreement() {
        Lease_Agreement__c lease = getTestLease();

        Test.startTest();

        GenerateLeaseAgreementPdfController.LeasePdfData result =
            GenerateLeaseAgreementPdfController.getLeaseAgreement(
                lease.Id
            );

        Test.stopTest();
    }

    @IsTest
    static void testSendLeaseAgreementEmail() {
        Lease_Agreement__c lease = getTestLease();

        String pdfBase64 = EncodingUtil.base64Encode(
            Blob.valueOf('Sample PDF content')
        );

        Test.startTest();

        GenerateLeaseAgreementPdfController.sendLeaseAgreementEmail(
            lease.Id,
            pdfBase64
        );

        Test.stopTest();
    }
}