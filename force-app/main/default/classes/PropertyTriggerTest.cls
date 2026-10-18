@IsTest
private class PropertyTriggerTest {

    private class GeoapifyMock implements HttpCalloutMock {
        private Integer statusCode;

        GeoapifyMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);

            if (statusCode == 200) {
                res.setBody(
                    '{"results":[{"lat":13.0827,"lon":80.2707}]}'
                );
            } else {
                res.setBody('{"error":"Geocoding failed"}');
            }

            return res;
        }
    }

    private static Property__c createProperty() {
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

        return prop;
    }

    @IsTest
    static void testAfterInsert() {
        Test.setMock(
            HttpCalloutMock.class,
            new GeoapifyMock(200)
        );

        Property__c prop = createProperty();

        Test.startTest();
        insert prop;
        Test.stopTest();

        Property__c result = [
            SELECT Id, Geocode__Latitude__s,
                   Geocode__Longitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals(
            Decimal.valueOf('13.0827'),
            result.Geocode__Latitude__s
        );
        System.assertEquals(
            Decimal.valueOf('80.2707'),
            result.Geocode__Longitude__s
        );
    }

    @IsTest
    static void testAfterUpdateAddressChanged() {
        Test.setMock(
            HttpCalloutMock.class,
            new GeoapifyMock(200)
        );

        Property__c prop = createProperty();
        insert prop;

        Test.startTest();

        prop.Address__c = '456 Mount Road';
        update prop;

        Test.stopTest();

        Property__c result = [
            SELECT Address__c, Geocode__Latitude__s,
                   Geocode__Longitude__s
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals('456 Mount Road', result.Address__c);
        System.assertEquals(
            Decimal.valueOf('13.0827'),
            result.Geocode__Latitude__s
        );
    }
}