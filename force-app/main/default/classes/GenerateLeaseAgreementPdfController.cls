public with sharing class GenerateLeaseAgreementPdfController {

    public class LeasePdfData {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String propertyName { get; set; }
        @AuraEnabled public String tenantName { get; set; }
        @AuraEnabled public String rent { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String terms { get; set; }
    }

    @AuraEnabled
    public static LeasePdfData getLeaseAgreement(
        Id leaseAgreementId
    ) {
        Lease_Agreement__c lease = [
            SELECT Id, Name, Terms__c,
                   Agreed_Monthly_Rent__c,
                   Start_Date__c, End_Date__c,
                   Property__r.Name,
                   Property__r.Tenant__r.Name
            FROM Lease_Agreement__c
            WHERE Id = :leaseAgreementId
            LIMIT 1
        ];

        LeasePdfData result = new LeasePdfData();
        result.name = lease.Name;
        result.propertyName = lease.Property__r?.Name;
        result.tenantName = lease.Property__r?.Tenant__r?.Name;
        result.rent = lease.Agreed_Monthly_Rent__c == null
            ? ''
            : String.valueOf(lease.Agreed_Monthly_Rent__c);
        result.startDate = lease.Start_Date__c == null
            ? ''
            : String.valueOf(lease.Start_Date__c);
        result.endDate = lease.End_Date__c == null
            ? ''
            : String.valueOf(lease.End_Date__c);
        result.terms = lease.Terms__c;

        return result;
    }

    @AuraEnabled
    public static void sendLeaseAgreementEmail(
        Id leaseAgreementId,
        String pdfBase64
    ) {
        if (leaseAgreementId == null || String.isBlank(pdfBase64)) {
            throw new AuraHandledException(
                'Lease agreement and PDF are required.'
            );
        }

        Lease_Agreement__c lease = [
            SELECT Id, Name, Property__r.Tenant__c, Property__r.Tenant__r.Email__c
            FROM Lease_Agreement__c
            WHERE Id = :leaseAgreementId
            LIMIT 1
        ];

        String tenantEmail = lease.Property__r?.Tenant__r?.Email__c;

        if (String.isBlank(tenantEmail)) {
            throw new AuraHandledException(
                'The tenant does not have an email address.'
            );
        }

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();

        attachment.setFileName('LeaseAgreement.pdf');
        attachment.setContentType('application/pdf');
        attachment.setBody(EncodingUtil.base64Decode(pdfBase64));

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        Id tenantId = lease.Property__r?.Tenant__c;

        email.setToAddresses(new String[] { tenantEmail });

        //Just hard coding my email address to testing purposes
        email.setBccAddresses(new String[] { 'selvakarthik.kumaran@gmail.com'});
        email.setSubject('Lease Agreement - ' + lease.Name);
        email.setPlainTextBody(
            'Dear Tenant,\n\n' +
            'Please find attached your lease agreement PDF.\n\n' +
            'Regards'
        );
        email.setFileAttachments(
            new Messaging.EmailFileAttachment[] { attachment }
        );

        Messaging.SendEmailResult[] results =
            Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { email }
            );

        if (!results[0].isSuccess()) {
            throw new AuraHandledException(
                'Unable to send email: ' +
                results[0].getErrors()[0].getMessage()
            );
        }

        Task emailTask = new Task();

        emailTask.Subject = 'Email: Lease Agreement - ' + lease.Name;
        emailTask.Status = 'Completed';
        emailTask.Priority = 'Normal';
        emailTask.Description = 'Lease agreement PDF emailed to: ' + tenantEmail;

        emailTask.WhatId = lease.Property__r.Tenant__c;

        insert emailTask;
    }
}
