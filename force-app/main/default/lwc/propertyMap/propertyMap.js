import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ADDRESS_FIELD from '@salesforce/schema/Property__c.Address__c';
import CITY_FIELD from '@salesforce/schema/Property__c.City__c';
import STATE_FIELD from '@salesforce/schema/Property__c.State__c';
import POSTAL_FIELD from '@salesforce/schema/Property__c.Postal_Code__c';
import COUNTRY_FIELD from '@salesforce/schema/Property__c.Country__c';
import NAME_FIELD from '@salesforce/schema/Property__c.Name';

const FIELDS = [
    ADDRESS_FIELD,
    CITY_FIELD,
    STATE_FIELD,
    POSTAL_FIELD,
    COUNTRY_FIELD,
    NAME_FIELD
];

export default class PropertyMap extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    property;

    get hasAddress() {
        return !!(
            this.property.data &&
            getFieldValue(this.property.data, ADDRESS_FIELD) &&
            getFieldValue(this.property.data, CITY_FIELD)
        );
    }

    get mapMarkers() {
        if (!this.hasAddress) {
            return [];
        }

        const record = this.property.data;

        return [{
            location: {
                Street: getFieldValue(record, ADDRESS_FIELD),
                City: getFieldValue(record, CITY_FIELD),
                State: getFieldValue(record, STATE_FIELD),
                PostalCode: getFieldValue(record, POSTAL_FIELD),
                Country: getFieldValue(record, COUNTRY_FIELD)
            },
            title: getFieldValue(record, NAME_FIELD),
            description: 'Property location'
        }];
    }
}
