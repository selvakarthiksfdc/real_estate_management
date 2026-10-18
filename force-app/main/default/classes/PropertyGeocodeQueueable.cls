public with sharing class PropertyGeocodeQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> propertyIds;

    public PropertyGeocodeQueueable(List<Id> propertyIds) {
        this.propertyIds = propertyIds;
    }

    public void execute(QueueableContext context) {

        Integer batchSize = Math.min(100, propertyIds.size());

        List<Id> currentIds = new List<Id>();
        List<Id> remainingIds = new List<Id>();

        for (Integer i = 0; i < propertyIds.size(); i++) {
            if (i < batchSize) {
                currentIds.add(propertyIds[i]);
            } else {
                remainingIds.add(propertyIds[i]);
            }
        }

        List<Property__c> properties = [
            SELECT Id, Address__c, City__c, State__c,
                   Postal_Code__c, Country__c
            FROM Property__c
            WHERE Id IN :currentIds
        ];

        List<Property__c> updates = new List<Property__c>();

        for (Property__c prop : properties) {

            try {
                Map<String, Decimal> coordinates =
                    GetLatAndLon.geocode(
                        prop.Address__c,
                        prop.City__c,
                        prop.State__c,
                        prop.Postal_Code__c,
                        prop.Country__c
                    );

                if (coordinates != null) {
                    updates.add(new Property__c(
                        Id = prop.Id,
                        Geocode__Latitude__s = coordinates.get('lat'),
                        Geocode__Longitude__s = coordinates.get('lon')
                    ));
                }

            } catch (Exception e) {
                System.debug(
                    'Geocoding failed for property ' +
                    prop.Id + ': ' + e.getMessage()
                );
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }

        if (!remainingIds.isEmpty()) {
            System.enqueueJob(
                new PropertyGeocodeQueueable(remainingIds)
            );
        }
    }
}