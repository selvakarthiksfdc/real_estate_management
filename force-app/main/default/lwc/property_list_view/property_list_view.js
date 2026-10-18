import { LightningElement, track } from 'lwc';
import getProperties from '@salesforce/apex/PropertyListController.getProperties';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

export default class PropertyList extends NavigationMixin(LightningElement) {

    @track properties = [];

    minRent;
    maxRent;
    status = '';
    furnishingStatus = '';
    userLatitude;
    userLongitude;
    distanceKm;

    isLoading = false;

    columns = [
        {
            label: 'Property Name',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        {
            label: 'Address',
            fieldName: 'Address__c',
            type: 'text'
        },
        {
            label: 'City',
            fieldName: 'City__c',
            type: 'text'
        },
        {
            label: 'Rent',
            fieldName: 'Rent__c',
            type: 'currency'
        },
        {
            label: 'Type',
            fieldName: 'Type__c',
            type: 'text'
        },
        {
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text'
        },
        {
            label: 'Furnishing Status',
            fieldName: 'Furnishing_Status__c',
            type: 'text'
        }
    ];

    statusOptions = [
        {
            label: 'All',
            value: ''
        },
        {
            label: 'Available',
            value: 'Available'
        },
        {
            label: 'Occupied',
            value: 'Occupied'
        }
    ];

    furnishingOptions = [
        {
            label: 'All',
            value: ''
        },
        {
            label: 'Furnished',
            value: 'Furnished'
        },
        {
            label: 'Semi Furnished',
            value: 'Semi-Furnished'
        },
        {
            label: 'Unfurnished',
            value: 'Unfurnished'
        }
    ];

    connectedCallback() {
        this.loadProperties();
        this.getUserLocation();
    }

    async loadProperties() {

        this.isLoading = true;

        console.log("data: ",this.minRent, this.maxRent, this.status, this.furnishingStatus, this.distanceKm)

        try {

            this.properties = await getProperties({
                minRent: this.minRent,
                maxRent: this.maxRent,
                availabilityStatus: this.status,
                furnishingStatus: this.furnishingStatus,
                distanceKm: this.distanceKm !== null && this.distanceKm !== ''
                    ? Number(this.distanceKm) : null,
                userLatitude: this.userLatitude,
                userLongitude: this.userLongitude
            });
            this.properties = this.properties.map(property=>({
                    ...property,recordUrl: '/'+property.Id
                })
            );

        } catch (error) {

            console.error('Error loading properties:', error);

        } finally {

            this.isLoading = false;

        }
    }

    getUserLocation() {
        if (!navigator.geolocation) {
            console.error('Geolocation is not supported by this browser.');
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (position) => {
                this.userLatitude = position.coords.latitude;
                this.userLongitude = position.coords.longitude;
                const accuracy = position.coords.accuracy;

                console.log('Latitude:', this.userLatitude);
                console.log('Longitude:', this.userLongitude);
                console.log('accuracy:', accuracy);

                if (accuracy > 1000) {
                    this.showToast(
                        "Warning",
                        "Your location accuracy is less than 1 Km, So please try switching your internet to GPS enabled mobile data",
                        "warning"
                    );
                }
            },
            (error) => {
                console.error(error.message);
            },
            {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
            }
        );
    }

    handleMinRentChange(event) {
        this.minRent = event.target.value;
    }

    handleMaxRentChange(event) {
        this.maxRent = event.target.value;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleFurnishingChange(event) {
        this.furnishingStatus = event.detail.value;
    }

    handleDistanceChange(event) {
        this.distanceKm = event.target.value;
    }

    handleApplyFilters() {
        this.loadProperties();
    }

    handleClearFilters() {

        this.minRent = null;
        this.maxRent = null;
        this.status = '';
        this.furnishingStatus = '';

        this.loadProperties();
    }

    handleNew() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Property__c',
                actionName: 'new'
            }
        });
    }

    get showNoRecords() {
        return !this.isLoading && this.properties.length === 0;
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title:title,
                message:message,
                variant:variant
            })
        )
    }
}