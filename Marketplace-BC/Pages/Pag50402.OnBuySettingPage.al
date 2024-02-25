page 50402 "OnBuySettingPage"
{
    PageType = XmlPort;
    Caption = 'OnBuy';
    SourceTable = "Onbuy Setting";
    RefreshOnActivate = true;
    DataCaptionExpression = 'OnBuy';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(OnBuyCustomerCode; Rec.OnbuyCustomerCode)
                {
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    TableRelation = Customer."No.";
                }
                field(OnBuyVendorCode; Rec.OnbuyVendorCode)
                {
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }
                field(ClientKey; Rec.ClientKey)
                {
                    Caption = 'Client Key';
                    ApplicationArea = All;
                }
                field(SID; Rec.SID)
                {
                    Caption = 'SID';
                    ApplicationArea = All;
                }
                field(SecretKey; Rec.SecretKey)
                {
                    Caption = 'Secret Key';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(OnBuyURL; Rec.URL)
                {
                    Caption = 'URL';
                    ApplicationArea = All;
                }
            }
        }
    }
}