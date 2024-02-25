page 50411 PaypalSettingList
{
    ApplicationArea = All;
    Caption = 'PayPal Setting';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Paypal Setting";
    CardPageId = PaypalSettingPage;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(CustomerCode; Rec.CustomerCode)
                {
                    Editable = false;
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CustomerCode field.';
                }
                field(VendorCode; Rec.VendorCode)
                {
                    Editable = false;
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the VendorCode field.';
                }
                field(BankGLCode; Rec.BankGLCode)
                {
                    Editable = false;
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the BankGLCode field.';
                }
                field(URL; Rec.URL)
                {
                    Editable = false;
                    Caption = 'SFTP Host';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the URL field.';
                }
                field(APIUser; Rec.APIUser)
                {
                    Editable = false;
                    Caption = 'SFTP User';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIUser field.';
                }
                field(Signature; Rec.Signature)
                {
                    Editable = false;
                    Caption = 'Signature';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Signature field.';
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
    actions
    {
        area(Processing)
        {
            action(PaypalPaymentDownload)
            {
                Caption = 'PayPal Payment Download';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_PaypalPaymentDownload: Codeunit PaypalPaymentDownload;
                begin
                    cu_PaypalPaymentDownload.CreateCashReceiptBatchEntry();
                end;
            }
        }
    }
}