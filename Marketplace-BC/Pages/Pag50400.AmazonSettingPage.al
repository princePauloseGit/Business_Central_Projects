page 50400 "AmazonSetting Page"
{
    PageType = XmlPort;
    Caption = 'Amazon';
    SourceTable = "Amazon Setting";
    DataCaptionExpression = 'Amazon';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(AmazonCustomerCode; Rec.CustomerCode)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Code';
                    TableRelation = Customer."No.";
                }
                field(AmazonVendorCode; Rec.VendorCode)
                {
                    Caption = 'Vendor Code';
                    ApplicationArea = All;
                    TableRelation = Vendor."No.";
                }

                field(APIKey; Rec.APIKey)
                {
                    ApplicationArea = All;
                    Caption = 'API Key';
                }
                field(APISecret; Rec.APISecret)
                {
                    Caption = 'API Secret';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                //Extra field added
                field(RoleArn; Rec.RoleArn)
                {
                    Caption = 'Role Arn';
                    ApplicationArea = All;
                }
                //Extra field added
                field(ClientId; Rec.ClientId)
                {
                    Caption = 'Client Id';
                    ApplicationArea = All;
                }
                //Extra field added
                field(RefreshToken; Rec.RefreshToken)
                {
                    Caption = 'Refresh Token';
                    ApplicationArea = All;
                }
                //Extra field added
                field(ClientSecret; Rec.ClientSecret)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = All;
                }

                field(ConditionNote; Rec.ConditionNote)
                {
                    Caption = 'Condition Note';
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(PostingGroupFBA; Rec.PostingGroupFBA)
                {
                    Caption = 'Posting Group FBA';
                    ApplicationArea = All;
                    //TableRelation = "Gen. Product Posting Group";
                    TableRelation = "Gen. Business Posting Group";
                }
                field(PostingGroupMFA; Rec.PostingGroupMFA)
                {
                    Caption = 'Posting Group MFA';
                    ApplicationArea = All;
                    TableRelation = "Customer Posting Group";
                }
                field(MarketplaceID; Rec.MarketplaceID)
                {
                    Caption = 'Marketplace ID';
                    ApplicationArea = All;
                }
                field(MerchantID; Rec.MerchantID)
                {
                    Caption = 'Merchant ID';
                    ApplicationArea = All;
                }
                field(ServiceURL; Rec.ServiceURL)
                {
                    Caption = 'Service URL';
                    ApplicationArea = All;
                }
                field(BankGLCode; Rec.BankGLCode)
                {
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    TableRelation = "Bank Account"."No.";
                }
                field(fbaDate; Rec.fbaDate)
                {
                    Caption = 'FBA Date';
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        PastDate: Date;
                        currentDate: Date;
                    begin
                        currentDate := System.DT2Date(CurrentDateTime);
                        PastDate := CALCDATE('-90D', DT2Date(CurrentDateTime));

                        if format(Rec.fbaDate) <> '' then begin

                            if Rec.fbaDate < PastDate then begin
                                Error('Date should be within past 90 days');
                            end;

                            if Rec.fbaDate > currentDate then begin
                                Error('Date should not be greater then today');
                            end;
                        end;
                    end;
                }
                field("FBA Invoices and Credits"; Rec."FBA Invoices and Credits")
                {
                    Caption = 'FBA Invoices and Credits';
                    ApplicationArea = All;
                }
                field(Payments; Rec.Payments)
                {
                    Caption = 'Payment';
                    ApplicationArea = All;
                }
                field(Orders; Rec.Orders)
                {
                    Caption = 'Orders';
                    ApplicationArea = All;
                }
                field("Product / Stock File"; Rec."Product / Stock File")
                {
                    Caption = 'Product / Stock File';
                    ApplicationArea = All;
                }
                field(manualTest; Rec.manualTest)
                {
                    Caption = 'Manual Test';
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                    begin
                        if Rec.manualTest then begin
                            isVisible := true;

                        end else begin
                            isVisible := false;
                            rec.Limit := 0;
                            rec.nextToken := '';
                            rec.Modify(true);
                        end;
                    end;
                }
                field(limit; Rec.limit)
                {
                    Caption = 'Limit';
                    ApplicationArea = All;
                    Editable = isVisible;
                }
                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                    Caption = 'Environment';
                }
            }

        }
    }
    var
        isVisible: Boolean;

    trigger OnOpenPage()
    var
    begin
        if Rec.manualTest then begin
            isVisible := true;
        end else begin
            isVisible := false;
        end
    end;

}