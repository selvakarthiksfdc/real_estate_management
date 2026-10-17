public with sharing class GetLatAndLon {

    public static Map<String, Decimal> geocode(
        String address,
        String city,
        String state,
        String postcode,
        String country
    ) {
        String endpoint =
            'callout:Geoapify/v1/geocode/search' +
            '?street=' + EncodingUtil.urlEncode(address, 'UTF-8') +
            '&city=' + EncodingUtil.urlEncode(city, 'UTF-8') +
            '&state=' + EncodingUtil.urlEncode(state, 'UTF-8') +
            '&postcode=' + EncodingUtil.urlEncode(postcode, 'UTF-8') +
            '&country=' + EncodingUtil.urlEncode(country, 'UTF-8') +
            '&format=json&limit=1';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(20000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            List<Object> results =
                (List<Object>) response.get('results');

            if (results == null || results.isEmpty()) {
                return null;
            }

            Map<String, Object> firstResult =
                (Map<String, Object>) results[0];

            Map<String, Decimal> coordinates = new Map<String, Decimal>();
            coordinates.put('lat', (Decimal) firstResult.get('lat'));
            coordinates.put('lon', (Decimal) firstResult.get('lon'));

            return coordinates;
        }

        throw new CalloutException(
            'Geoapify API failed. Status: ' +
            res.getStatusCode() + ', Response: ' + res.getBody()
        );
    }
}