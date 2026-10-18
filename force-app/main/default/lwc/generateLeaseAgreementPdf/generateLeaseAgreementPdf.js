import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import JSPDF from '@salesforce/resourceUrl/jsPDF';

import getLeaseAgreement from '@salesforce/apex/GenerateLeaseAgreementPdfController.getLeaseAgreement';
import sendLeaseAgreementEmail from '@salesforce/apex/GenerateLeaseAgreementPdfController.sendLeaseAgreementEmail';

//import savePdf from '@salesforce/apex/LeaseAgreementPdfController.savePdf';

export default class GenerateLeaseAgreementPdf extends LightningElement {
    @api recordId;

    isLoading = false;
    jsPdfLoaded = false;
    jsPdfPromise;

    async renderedCallback() {
        if (this.jsPdfLoaded) {
            return;
        }

        if (!this.jsPdfPromise) {
            this.jsPdfPromise = loadScript(this, JSPDF);
        }

        try {
            await this.jsPdfPromise;
            this.jsPdfLoaded = true;
        } catch (error) {
            this.jsPdfPromise = null;
            this.showToast('Error', 'Unable to load jsPDF.', 'error');
        }
    }

    async generatePdf() {
        if (!this.jsPdfLoaded) {
            throw new Error('PDF library is still loading. Try again.');
        }

        const lease = await getLeaseAgreement({
            leaseAgreementId: this.recordId
        });

        const { jsPDF } = window.jspdf;
        const pdf = new jsPDF();

        const left = 20;
        const width = 170;
        let y = 20;

        pdf.setFontSize(18);
        pdf.text('LEASE AGREEMENT', left, y);
        y += 15;

        pdf.setFontSize(11);

        const addField = (label, value) => {
            const text = `${label}: ${value ?? ''}`;
            const lines = pdf.splitTextToSize(text, width);

            if (y + lines.length * 6 > 275) {
                pdf.addPage();
                y = 20;
            }

            pdf.text(lines, left, y);
            y += lines.length * 6 + 4;
        };

        addField('Agreement Number', lease.name);
        addField('Property', lease.propertyName);
        addField('Tenant', lease.tenantName);
        addField('Monthly Rent', lease.rent);
        addField('Start Date', lease.startDate);
        addField('End Date', lease.endDate);

        y += 4;
        pdf.setFont(undefined, 'bold');
        pdf.text('Terms and Conditions', left, y);
        y += 8;

        pdf.setFont(undefined, 'normal');

        const terms = pdf.splitTextToSize(
            lease.terms || 'No terms provided.',
            width
        );

        for (const line of terms) {
            if (y > 280) {
                pdf.addPage();
                y = 20;
            }

            pdf.text(line, left, y);
            y += 6;
        }

        return pdf;
    }

    async handleDownload() {
        this.isLoading = true;

        try {
            const pdf = await this.generatePdf();
            pdf.save('LeaseAgreement.pdf');

            this.showToast(
                'Success',
                'PDF download initiated.',
                'success'
            );
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || error.message || 'PDF generation failed.',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    async handleSendEmail() {
        this.isLoading = true;

        try {
            const pdf = await this.generatePdf();

            const dataUri = pdf.output('datauristring');
            const pdfBase64 = dataUri.split(',')[1];

            await sendLeaseAgreementEmail({
                leaseAgreementId: this.recordId,
                pdfBase64: pdfBase64
            });

            this.showToast(
                'Success',
                'Lease agreement PDF emailed to the tenant.',
                'success'
            );
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message ||
                    error.message ||
                    'Failed to send the email.',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}
