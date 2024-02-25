page 50409 EbaySettingList
{
    ApplicationArea = All;
    Caption = 'eBay Setting';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "ebay Setting";
    CardPageId = ebaySettingPage;

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
                field(refresh_token; Rec.refresh_token)
                {
                    Editable = false;
                    Caption = 'Refresh Token';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(oauth_credentials; Rec.oauth_credentials)
                {
                    Editable = false;
                    Caption = 'oAuth Credentials';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(Environment; Rec.Environment)
                {
                    Editable = false;
                    Caption = 'Environment';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(APIURL; Rec.APIURL)
                {
                    Editable = false;
                    Caption = 'API URL';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIURL field.';
                }
                field(PaypalPaymentsEmailAddress; Rec.PaypalPaymentsEmailAddress)
                {
                    Editable = false;
                    Caption = 'PayPal Payments Email Address';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PaypalPaymentsEmailAddress field.';
                }
                field(About; Rec.About)
                {
                    Editable = false;
                    Caption = 'About';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the About field.';
                }
                field(Delivery; Rec.Delivery)
                {
                    Editable = false;
                    Caption = 'Delivery';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery field.';
                }
                field(Returns; Rec.Returns)
                {
                    Editable = false;
                    Caption = 'Returns';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Returns field.';
                }
                field(Template; Rec.Template)
                {
                    Editable = true;
                    Caption = 'Template';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(fulfillmentPolicyId; Rec.fulfillmentPolicyId)
                {
                    Editable = false;
                    Caption = 'Fulfillment Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(paymentPolicyId; Rec.paymentPolicyId)
                {
                    Editable = false;
                    Caption = 'Payment Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(returnPolicyId; Rec.returnPolicyId)
                {
                    Editable = false;
                    Caption = 'Return Policy Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(DigitalSignatureJWE; Rec.DigitalSignatureJWE)
                {
                    Editable = false;
                    Caption = 'Digital Signature JWE';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Template field.';
                }
                field(DigitalSignaturePrivateKey; Rec.DigitalSignaturePrivateKey)
                {
                    Editable = false;
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
                    Editable = true;
                    Caption = 'Merchant Location Key';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EbayOrders)
            {
                Caption = 'Download Orders';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_ebayOrder: Codeunit "Ebay Order Download";
                begin
                    cu_ebayOrder.ConnectEbayAPIForSalesOrders();
                end;
            }
            action(ManualEbayOrders)
            {
                Caption = 'Manual Test Orders';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_ebayOrder: Codeunit "Ebay Order Download";
                begin
                    cu_ebayOrder.ConnectEbayAPIForManualSalesOrders();
                end;

            }
            action(ShippingUpdate)
            {
                Caption = 'Shipping Update';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cuShippingUpdateEBay: Codeunit EbayShippingUpdate;
                begin
                    cuShippingUpdateEBay.ConnectEBayShipmentConfirmation();
                end;
            }
            action(EbayPayment)
            {
                ApplicationArea = All;
                Caption = 'Download Payment';
                trigger OnAction()
                var
                    cu_EbayListing: Codeunit EbayPayment;

                begin
                    cu_EbayListing.CreateEbayCashReceiptBatchEntry();
                end;
            }
            action(CreateItemBatch)
            {
                ApplicationArea = all;
                Caption = 'Get Listing Details';
                trigger OnAction()
                var
                    cu_EbayListing: Codeunit EbayGetOfferedListing;
                begin
                    cu_EbayListing.CreateOfferedBatch();
                end;
            }
            action(EbayBulkCreateSingleListing)
            {
                ApplicationArea = all;
                Caption = 'Bulk Create Single Listing';
                trigger OnAction()
                var
                    cu_EbayListing: Codeunit EbayBulkCreateSingleListing;
                begin
                    cu_EbayListing.SendToAPISingleListing('CREATE');
                end;
            }
            action(UpdateListing)
            {
                ApplicationArea = all;
                Caption = 'Update Listing';
                trigger OnAction()
                var
                    cu_EbayListing: Codeunit EbayBulkCreateSingleListing;
                begin
                    cu_EbayListing.SendToAPISingleListing('UPDATE');
                end;
            }
            action(EbayBulkCreateGroupListing)
            {
                ApplicationArea = all;
                Caption = 'Bulk Create Group Listing';
                trigger OnAction()
                var
                    cu_EbayListing: Codeunit EbayBulkCreateGroupListing;
                begin
                    cu_EbayListing.SendToAPIGroupListing();
                end;
            }
        }
    }
}
