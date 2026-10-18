public with sharing class LeaseExpiryReminderBatch
    implements Database.Batchable<SObject>, Schedulable {

    private static final String TEMPLATE_DEVELOPER_NAME =
        'Lease_Expiry_Reminder';

    private static final String BCC_EMAIL =
        'selvakarthik.kumaran@gmail.com';

    // Find lease agreements requiring a reminder.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date thirtyDaysFromNow = Date.today().addDays(30);
        Date oneDayFromNow = Date.today().addDays(1);

        return Database.getQueryLocator([
            SELECT Id, Name, End_Date__c,
                   Agreed_Monthly_Rent__c,
                   One_Month_Reminder_Sent__c,
                   One_Day_Reminder_Sent__c,
                   Property__r.Name,
                   Property__r.Tenant__r.Name,
                   Property__r.Tenant__r.Email__c
            FROM Lease_Agreement__c
            WHERE
                (
                    End_Date__c = :thirtyDaysFromNow
                    AND One_Month_Reminder_Sent__c = false
                )
                OR
                (
                    End_Date__c = :oneDayFromNow
                    AND One_Day_Reminder_Sent__c = false
                )
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Lease_Agreement__c> scope
    ) {
        EmailTemplate template = [
            SELECT Subject, Body, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = :TEMPLATE_DEVELOPER_NAME
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        // Keep the corresponding lease for each email result.
        List<Lease_Agreement__c> emailLeases =
            new List<Lease_Agreement__c>();

        List<Boolean> isMonthReminder = new List<Boolean>();

        for (Lease_Agreement__c lease : scope) {
            String tenantEmail =
                lease.Property__r?.Tenant__r?.Email__c;

            if (String.isBlank(tenantEmail)) {
                continue;
            }

            Integer daysRemaining =
                Date.today().daysBetween(lease.End_Date__c);

            Boolean monthReminder = daysRemaining == 30;

            String reminderType = monthReminder
                ? 'Lease expiry reminder'
                : 'Final lease expiry reminder';

            String subject = replaceMergeFields(
                template.Subject, lease,
                reminderType, daysRemaining, false
            );

            String body = replaceMergeFields(
                template.Body, lease,
                reminderType, daysRemaining, false
            );

            String htmlBody = String.isBlank(template.HtmlValue)
                ? null
                : replaceMergeFields(
                    template.HtmlValue, lease,
                    reminderType, daysRemaining, true
                );

            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();

            email.setToAddresses(new String[] { tenantEmail });
            email.setBccAddresses(new String[] { BCC_EMAIL });
            email.setSubject(subject);
            email.setPlainTextBody(body);

            if (htmlBody != null) {
                email.setHtmlBody(htmlBody);
            }

            emails.add(email);
            emailLeases.add(lease);
            isMonthReminder.add(monthReminder);
        }

        if (emails.isEmpty()) {
            return;
        }

        Messaging.SendEmailResult[] results =
            Messaging.sendEmail(emails, false);

        List<Lease_Agreement__c> updates =
            new List<Lease_Agreement__c>();

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                continue;
            }

            Lease_Agreement__c updatedLease =
                new Lease_Agreement__c(
                    Id = emailLeases[i].Id
                );

            if (isMonthReminder[i]) {
                updatedLease.One_Month_Reminder_Sent__c = true;
            } else {
                updatedLease.One_Day_Reminder_Sent__c = true;
            }

            updates.add(updatedLease);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    // Replace merge-field strings manually in the template.
    private static String replaceMergeFields(
        String content,
        Lease_Agreement__c lease,
        String reminderType,
        Integer daysRemaining,
        Boolean isHtml
    ) {
        if (content == null) {
            return '';
        }

        String tenantName =
            lease.Property__r?.Tenant__r?.Name ?? '';

        String propertyName =
            lease.Property__r?.Name ?? '';

        String endDate = String.valueOf(lease.End_Date__c);

        String rent = lease.Agreed_Monthly_Rent__c == null
            ? ''
            : String.valueOf(lease.Agreed_Monthly_Rent__c);

        if (isHtml) {
            tenantName = tenantName.escapeHtml4();
            propertyName = propertyName.escapeHtml4();
            endDate = endDate.escapeHtml4();
            rent = rent.escapeHtml4();
            reminderType = reminderType.escapeHtml4();
        }

        content = content.replace(
            '{!Lease_Agreement__c.Name}', lease.Name
        );
        content = content.replace(
            '{!Lease_Agreement__c.End_Date__c}', endDate
        );
        content = content.replace(
            '{!Lease_Agreement__c.Agreed_Monthly_Rent__c}', rent
        );
        content = content.replace(
            '{!Lease_Agreement__c.Property__r.Name}', propertyName
        );
        content = content.replace(
            '{!Lease_Agreement__c.Property__r.Tenant__r.Name}',
            tenantName
        );

        // Custom placeholders for the reminder message.
        content = content.replace(
            '{{ReminderType}}', reminderType
        );
        content = content.replace(
            '{{DaysUntilExpiry}}', String.valueOf(daysRemaining)
        );

        return content;
    }

    public void finish(Database.BatchableContext bc) {
        
    }

    // Run the batch every day through the scheduler.
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeaseExpiryReminderBatch(), 10);
    }
}