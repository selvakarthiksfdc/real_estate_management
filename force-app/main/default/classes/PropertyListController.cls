public with sharing class PropertyListController {

    @AuraEnabled(cacheable=true)
    public static List<Property__c> getProperties(
        Decimal minRent,
        Decimal maxRent,
        String availabilityStatus,
        String furnishingStatus,
        Decimal distanceKm,
        Decimal userLatitude,
        Decimal userLongitude
    ) {
        String query = 
            'SELECT Id, Name, Address__c, City__c, State__c, ' +
            'Country__c, Postal_Code__c, Rent__c, Status__c, ' +
            'Furnishing_Status__c, Type__c ' +
            'FROM Property__c WHERE Id != null';

        if (minRent != null) {
            query += ' AND Rent__c >= :minRent';
        }

        if (maxRent != null) {
            query += ' AND Rent__c <= :maxRent';
        }

        if (String.isNotBlank(availabilityStatus)) {
            query += ' AND Status__c = :availabilityStatus';
        }

        if (String.isNotBlank(furnishingStatus)) {
            query += ' AND Furnishing_Status__c = :furnishingStatus';
        }

        if (
            distanceKm != null &&
            userLatitude != null &&
            userLongitude != null
        ) {
            query += ' AND DISTANCE(Geocode__c, ' +
                    'GEOLOCATION(:userLatitude, :userLongitude), ' +
                    '\'km\') < :distanceKm';
        }

        query += ' ORDER BY CreatedDate DESC LIMIT 500';

        return Database.query(query);
    }
}