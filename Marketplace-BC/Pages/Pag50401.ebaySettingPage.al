page 50401 "ebaySettingPage"
{
    PageType = XmlPort;
    Caption = 'eBay';
    SourceTable = "ebay Setting";
    RefreshOnActivate = true;
    DataCaptionExpression = 'ebay';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(eBayCustomerCode; Rec.CustomerCode)
                {
                    Caption = 'Customer Code';
                    ApplicationArea = All;
                    TableRelation = Customer."No.";
                }
                field(eBayVendorCode; Rec.VendorCode)
                {
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }
                field(BankGLCode; Rec.BankGLCode)
                {
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    TableRelation = "Bank Account"."No.";
                }
                field(APIURL; Rec.APIURL)
                {
                    Caption = 'API URL';
                    ApplicationArea = All;
                }
                field(refresh_token; Rec.refresh_token)
                {

                    Caption = 'Refresh Token';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(oauth_credentials; Rec.oauth_credentials)
                {

                    Caption = 'oAuth Credentials';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(Environment; Rec.Environment)
                {

                    Caption = 'Environment';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(eBayAPIKey; Rec.APIKey)
                {
                    Caption = 'API Key';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(PaypalPaymentsEmailAddress; Rec.PaypalPaymentsEmailAddress)
                {
                    Caption = 'PayPal Payments Email Address';
                    ApplicationArea = All;
                }
                field(About; Rec.About)
                {
                    Caption = 'About';
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(Delivery; Rec.Delivery)
                {
                    Caption = 'Delivery';
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(Returns; Rec.Returns)
                {
                    Caption = 'Returns';
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(HtmlTemplate; HtmlTemplate)
                {
                    ApplicationArea = All;
                    Caption = 'Template';
                    Importance = Additional;
                    MultiLine = true;
                    ToolTip = 'Specifies the products or service being offered.';

                    trigger OnValidate()
                    begin
                        Rec.SetWorkDescription(HtmlTemplate);
                    end;
                }
                field(fulfillmentPolicyId; Rec.fulfillmentPolicyId)
                {

                    Caption = 'Fulfillment Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(paymentPolicyId; Rec.paymentPolicyId)
                {

                    Caption = 'Payment Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(returnPolicyId; Rec.returnPolicyId)
                {

                    Caption = 'Return Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(DigitalSignatureJWE; Rec.DigitalSignatureJWE)
                {

                    Caption = 'Digital Signature JWE';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(DigitalSignaturePrivateKey; Rec.DigitalSignaturePrivateKey)
                {

                    Caption = 'Digital Signature Private Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(categoryId; Rec.categoryId)
                {

                    Caption = 'Category Id';
                    ApplicationArea = All;
                }
                field(MerchantLocationKey; Rec.MerchantLocationKey)
                {
                    Caption = 'Merchant Location Key';
                    ApplicationArea = All;
                }
                field("Manual Test"; Rec.ManualTest)
                {
                    Caption = 'Manual Test';
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                    begin
                        if Rec.ManualTest then begin
                            isVisible := true;

                        end else begin
                            isVisible := false;
                            rec.Limit := 0;
                            rec.nextpage := '';
                            rec.Modify(true);
                        end;
                    end;
                }
                field(Limit; Rec.limit)
                {
                    Caption = 'Limit';
                    ApplicationArea = All;
                    Editable = isVisible;
                }
                field(BatchSize; rec.BatchSize)
                {
                    applicationarea = all;
                }
                field(RecordsPerRun; rec.RecordsPerRun)
                {
                    applicationarea = all;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
    begin
        HtmlTemplate := Rec.GetWorkDescription();
    end;

    var
        HtmlTemplate: Text;
        isVisible: Boolean;

}