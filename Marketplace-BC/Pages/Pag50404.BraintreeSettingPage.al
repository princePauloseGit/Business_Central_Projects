page 50404 "BraintreeSettingPage"
{
    PageType = XmlPort;
    Caption = 'Braintree';
    SourceTable = "Braintree Setting";
    RefreshOnActivate = true;
    DataCaptionExpression = 'Braintree';

    layout
    {
        area(Content)
        {
            group(General)
            {

                field(BraintreeCustomerCode; Rec.CustomerCode)
                {
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    TableRelation = Customer."No.";

                }
                field(BraintreeVendorCode; Rec.VendorCode)
                {
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }
                field(BraintreeMerchantID; Rec.MerchantID)
                {
                    Caption = 'Merchant ID';
                    ApplicationArea = All;
                }
                field(PublicKey; Rec.PublicKey)
                {
                    Caption = 'Public Key';
                    ApplicationArea = All;
                }
                field(PrivateKey; Rec.PrivateKey)
                {
                    Caption = 'Private Key';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(BraintreeBankGLCode; Rec.BankGLCode)
                {
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    TableRelation = "Bank Account"."No.";
                }
                field(Refund; Rec.Refund)
                {
                    Caption = 'Post Refunds to Provider';
                    ApplicationArea = All;
                }
                field(StartDate; Rec.StartDate)
                {
                    Caption = 'Start Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        currentDate: Date;
                    begin
                        Rec.EndDate := 0D;
                        currentDate := System.DT2Date(CurrentDateTime);

                        if Rec.StartDate > currentDate then begin
                            Error('The start date should be less than today');
                        end;

                        if (format(Rec.StartDate) <> '') and (format(Rec.EndDate) <> '') then begin

                            if Rec.StartDate > Rec.EndDate then begin
                                Error('The start date should be less than the End date');
                            end;

                            if ((Rec.EndDate - Rec.StartDate) > 2) then begin
                                Error('Please provide the start date and end date within three days.');
                            end
                        end;
                    end;
                }
                field(EndDate; Rec.EndDate)
                {
                    Caption = 'End Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        currentDate: Date;
                    begin
                        currentDate := System.DT2Date(CurrentDateTime);

                        if Rec.EndDate > currentDate then begin
                            Error('The end date should be less than today');
                        end;

                        if (format(Rec.EndDate) <> '') and (format(Rec.StartDate) <> '') then begin

                            if Rec.EndDate < Rec.StartDate then begin
                                Error('The end date should be greater than the start date');
                            end;

                            if ((Rec.EndDate - Rec.StartDate) > 2) then begin
                                Error('Please provide the start date and end date within three days.');
                            end

                        end;
                    end;
                }
            }
        }
    }
}