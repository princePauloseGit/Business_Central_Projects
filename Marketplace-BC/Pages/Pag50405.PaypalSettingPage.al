page 50405 "PaypalSettingPage"
{
    PageType = XmlPort;
    Caption = 'PayPal';
    SourceTable = "Paypal Setting";
    RefreshOnActivate = true;
    DataCaptionExpression = 'PayPal';

    layout
    {
        area(Content)
        {
            group(General)
            {

                field(PaypalCustomerCode; Rec.CustomerCode)
                {
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    TableRelation = Customer."No.";

                }
                field(PaypalVendorCode; Rec.VendorCode)
                {
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }
                field(PaypalBankGLCode; Rec.BankGLCode)
                {
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    TableRelation = "Bank Account"."No.";
                }
                field(PaypalURL; Rec.URL)
                {
                    Caption = 'SFTP Host';
                    ApplicationArea = All;
                }
                field(APIUser; Rec.APIUser)
                {
                    Caption = 'SFTP User';
                    ApplicationArea = All;
                }
                field(APIPassword; Rec.APIPassword)
                {
                    Caption = 'SFTP Password';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(Signature; Rec.Signature)
                {
                    Caption = 'Signature';
                    ApplicationArea = All;
                }
                field(sftpPort; Rec.sftpPort)
                {
                    Caption = 'SFTP Port';
                    ApplicationArea = All;
                }
                field(SftpDestinationPath; Rec.SftpDestinationPath)
                {
                    Caption = 'SFTP Path';
                    ApplicationArea = All;
                }

            }
        }
    }
}