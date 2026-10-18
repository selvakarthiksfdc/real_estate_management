
public with sharing class PropertyListController {

    public class PropertyPage {
        @AuraEnabled
        public List<Property__c> records { get; set; }

        @AuraEnabled
        public Integer totalRecords { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static PropertyPage getProperties(
        Decimal minRent,
        Decimal maxRent,
        String availabilityStatus,
        String furnishingStatus,
        Decimal distanceKm,
        Decimal userLatitude,
        Decimal userLongitude,
        Integer pageSize,
        Integer pageNumber
    ) {
        // Validate pagination inputs
        if (pageSize == null || pageSize < 1 || pageSize > 200) {
            pageSize = 25;
        }

        if (pageNumber == null || pageNumber < 1) {
            pageNumber = 1;
        }

        Integer recordOffset = (pageNumber - 1) * pageSize;

        String whereClause = ' WHERE Id != null';

        if (minRent != null) {
            whereClause += ' AND Rent__c >= :minRent';
        }

        if (maxRent != null) {
            whereClause += ' AND Rent__c <= :maxRent';
        }

        if (String.isNotBlank(availabilityStatus)) {
            whereClause += ' AND Status__c = :availabilityStatus';
        }

        if (String.isNotBlank(furnishingStatus)) {
            whereClause += ' AND Furnishing_Status__c = :furnishingStatus';
        }

        if (
            distanceKm != null &&
            userLatitude != null &&
            userLongitude != null
        ) {
            whereClause +=
                ' AND DISTANCE(Geocode__c, ' +
                'GEOLOCATION(:userLatitude, :userLongitude), \'km\') ' +
                '< :distanceKm';
        }

        // Count all records matching the filters
        String countQuery =
            'SELECT COUNT() FROM Property__c' + whereClause;

        Integer totalCount = Database.countQuery(countQuery);

        // Fetch only the current page
        String query =
            'SELECT Id, Name, Address__c, City__c, State__c, ' +
            'Country__c, Postal_Code__c, Rent__c, Status__c, ' +
            'Furnishing_Status__c, Type__c ' +
            'FROM Property__c' + whereClause +
            ' ORDER BY CreatedDate DESC, Id DESC' +
            ' LIMIT :pageSize OFFSET :recordOffset';

        List<Property__c> properties = Database.query(query);

        PropertyPage result = new PropertyPage();
        result.records = properties;
        result.totalRecords = totalCount;

        return result;
    }
}
