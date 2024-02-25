page 50410 OnBuySettingList
{
    ApplicationArea = All;
    Caption = 'OnBuy Setting';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Onbuy Setting";
    CardPageId = OnBuySettingPage;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(OnbuyCustomerCode; Rec.OnbuyCustomerCode)
                {
                    Editable = false;
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the OnbuyCustomerCode field.';
                }
                field(OnbuyVendorCode; Rec.OnbuyVendorCode)
                {
                    Editable = false;
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the OnbuyVendorCode field.';
                }
                field(ClientKey; Rec.ClientKey)
                {
                    Editable = false;
                    Caption = 'Client Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ClientKey field.';
                }
                field(SID; Rec.SID)
                {
                    Editable = false;
                    Caption = 'SID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SID field.';
                }
                field(URL; Rec.URL)
                {
                    Editable = false;
                    Caption = 'URL';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the URL field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(GetOnBuyAccessToken)
            {
                Caption = 'Get OnBuy Access Token';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cuOnBuy: Codeunit RefundProcess;
                begin
                    cuOnBuy.GetOnBuyAuthorziationToken(EnhIntegrationLogTypes::OnBuy);
                end;
            }
        }
    }
}
