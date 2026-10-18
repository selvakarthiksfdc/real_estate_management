@IsTest
private class CreateNewPropertyControllerTest {

    @IsTest
    static void testCreatePropertyWithFiles() {

        Property__c prop = new Property__c(
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

        String propertyJson = JSON.serialize(prop);

        CreateNewPropertyController.FileWrapper file =
            new CreateNewPropertyController.FileWrapper();

        file.fileName = 'PropertyDocument.txt';
        file.fileContent = EncodingUtil.base64Encode(
            Blob.valueOf('Test property document content')
        );

        List<CreateNewPropertyController.FileWrapper> files =
            new List<CreateNewPropertyController.FileWrapper>{ file };

        Test.startTest();

        String propertyId =
            CreateNewPropertyController.CreateNewPropMethod(
                propertyJson,
                files
            );

        Test.stopTest();

        System.assertNotEquals(null, propertyId);

        Property__c insertedProperty = [
            SELECT Id, Name, Address__c, City__c
            FROM Property__c
            WHERE Id = :propertyId
        ];

        System.assertEquals('Test Property', insertedProperty.Name);
        System.assertEquals('123 Anna Salai', insertedProperty.Address__c);
        System.assertEquals('Chennai', insertedProperty.City__c);

        List<ContentDocumentLink> fileLinks = [
            SELECT Id, ContentDocument.Title, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :propertyId
        ];

        System.assertEquals(1, fileLinks.size());
        System.assertEquals(
            'PropertyDocument.txt',
            fileLinks[0].ContentDocument.Title
        );
    }
}