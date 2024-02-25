page 50408 BraintreeSettingList
{
    ApplicationArea = All;
    Caption = 'Braintree Setting';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Braintree Setting";
    CardPageId = BraintreeSettingPage;

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
                field(MerchantID; Rec.MerchantID)
                {
                    Editable = false;
                    Caption = 'Merchant ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MerchantID field.';
                }
                field(PublicKey; Rec.PublicKey)
                {
                    Editable = false;
                    Caption = 'Public Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PublicKey field.';
                }

                field(BankGLCode; Rec.BankGLCode)
                {
                    Editable = false;
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the BankGLCode field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(BraintreePaymentDownload)
            {
                Caption = 'Braintree Payment Download';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_BrainTreePaymentDownload: Codeunit BrainTreePaymentDownload;
                    TaskParameters: Dictionary of [Text, Text];
                    WaitTaskId: Integer;
                begin
                    cu_BrainTreePaymentDownload.CreateBraintreeCashReceiptBatchEntry();
                end;
            }
        }
    }
}
