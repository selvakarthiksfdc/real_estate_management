import { LightningElement, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

import PROPERTY_OBJECT from '@salesforce/schema/Property__c';
import TYPE_FIELD from '@salesforce/schema/Property__c.Type__c';
import FURNISHING_STATUS_FIELD from '@salesforce/schema/Property__c.Furnishing_Status__c';
import STATUS_FIELD from '@salesforce/schema/Property__c.Status__c';

import CreateNewPropMethod from "@salesforce/apex/CreateNewPropertyController.CreateNewPropMethod"

export default class Create_new_property extends NavigationMixin(LightningElement) {
    typeOptions = [];
    furnishingOptions = [];
    statusOptions = [];
    propertyValues={
        "Name":null,
        "Address__c":null,
        "City__c":null,
        "State__c":null,
        "Postal_Code__c":null,
        "Country__c":null,
        "Type__c":null,
        "Furnishing_Status__c":null,
        "Status__c":null,
        "Rent__c":null,
        "Description__c":null,
        "Tenant__c":null
    }


    //Getting picklist values
    @wire(getObjectInfo, { objectApiName: PROPERTY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredTypeValues({ data, error }) {
        if (data) {
            this.typeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            this.showToast(
                "Error",
                "Something went wrong while loading the type values",
                "error"
            );
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: FURNISHING_STATUS_FIELD
    })
    wiredFurValues({ data, error }) {
        if (data) {
            this.furnishingOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            this.showToast(
                "Error",
                "Something went wrong while loading the Furnishing status values",
                "error"
            );
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredStatusValues({ data, error }) {
        if (data) {
            this.statusOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            this.showToast(
                "Error",
                "Something went wrong while loading the status values",
                "error"
            );
        }
    }

    handleOnInputChange(event){
        const fieldName=event.target.name
        const fieldValue=event.target.value

        this.propertyValues={
            ...this.propertyValues,
            [fieldName]:fieldValue
        }
    }

    handleTenantChange(event){
        this.propertyValues={
            ...this.propertyValues,
            ["Tenant__c"]:event.detail.recordId
        }

    }

    //Go back on cancel
    handleCancel() {
        window.history.back();
    }

    fileData=[]
    allowedExtensions = ['png', 'jpg', 'jpeg']

    handleOnFileUpload(event){
        const files=Array.from(event.target.files);

        files.forEach((file) =>{

            const fileFormat=file.name.split('.').pop().toLowerCase();
            if (this.allowedExtensions.includes(fileFormat) != true){
                this.showToast(
                    "Error",
                    "Ignored "+file.name+" as it is in unsupported file format",
                    "warning"
                );
                return;
            }

            const reader = new FileReader();

            reader.onload = () => {
                this.fileData = [
                    ...this.fileData,
                    {
                        fileName: file.name,
                        fileContent: reader.result.split(',')[1]
                    }
                ];

                console.log('fileData', this.fileData);
            }

            reader.onerror = () => {
                this.showToast(
                    "Error",
                    "Not able to read the file",
                    "error"
                )
            }

            reader.readAsDataURL(file);
        })
    }

    handleRemoveFile(event){
        const removedfileName=event.target.name
        this.fileData=this.fileData.filter(file=> file.fileName !== removedfileName)
    }

    //Save Prop along with its images
    handleSave() {

        const inputs=[...this.template.querySelectorAll('lightning-combobox , lightning-input, lightning-textarea, lightning-record-picker')]

        const isValid=inputs.reduce((valid,input) => {
            input.reportValidity();
            return input.checkValidity() && valid;
        },true)

        if(!isValid){
            this.showToast(
                "Error",
                "Please check the error messsage and take action accordingly",
                "error"
            )
            return;
        }

        if (!this.fileData || this.fileData.length==0){
            this.showToast(
                "Error",
                "Atleast 1 image of the property is needed to create a property",
                "error"
            )
            return;
        }

        try{
            CreateNewPropMethod({
                propertyJson: JSON.stringify(this.propertyValues),
                files: this.fileData
            })
            .then(recordId => {
                this.showToast(
                    "Success",
                    "The new property got creatded successfully!",
                    "success"
                );

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes:{
                        recordId:recordId,
                        objectApiName: 'Property__c',
                        actionName: 'view'
                    }
                })
            })
        }
        catch(error){
            this.showToast(
                "Error",
                error.body ? error.body.message : error.message,
                "error"
            );
        }
        
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