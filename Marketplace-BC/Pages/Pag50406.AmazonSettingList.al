page 50406 AmazonSettingList
{
    ApplicationArea = All;
    Caption = 'Amazon Setting';
    CardPageId = "AmazonSetting Page";
    //Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Amazon Setting";
    UsageCategory = Administration;

    Permissions = TableData "Value Entry" = rimd;

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
                field(APIKey; Rec.APIKey)
                {
                    Editable = false;
                    Caption = 'API Key';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the APIKey field.';
                }
                field(ConditionNote; Rec.ConditionNote)
                {
                    Editable = false;
                    Caption = 'Condition Note';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ConditionNote field.';
                }
                field(PostingGroupFBA; Rec.PostingGroupFBA)
                {
                    Editable = false;
                    Caption = 'Posting Group FBA';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PostingGroupFBA field.';
                }
                field(PostingGroupMFA; Rec.PostingGroupMFA)
                {
                    Editable = false;
                    Caption = 'Posting Group MFA';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PostingGroupMFA field.';
                }
                field(BankGLCode; Rec.BankGLCode)
                {
                    Editable = false;
                    Caption = 'Bank GL Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the BankGLCode field.';
                }
                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Environment field.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AmazonFBAInvoicesandCredits)
            {
                Caption = 'Amazon FBA Invoices and Credits';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_OrdersFromAmazonAPI: Codeunit "Amazon FBA Invoices & Credits";
                    cuAmazonPaymentForCredits: Codeunit AmazonPaymentForCredits;
                begin
                    cuAmazonPaymentForCredits.ConnectAmazonPaymentApi();
                    cu_OrdersFromAmazonAPI.GetOrdersFromAmazonAPI();
                end;

            }
            action(SalesOrdersFromAmazonAPI)
            {
                Caption = 'Create Sales Orders From AmazonAPI';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_AmazonOrdersDownload: Codeunit AmazonOrdersDownload;
                begin
                    cu_AmazonOrdersDownload.ConnectAmazonAPIForSalesOrders();
                end;
            }
            action(AmazonTestOrders)
            {
                Caption = 'Manual Test Orders';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_AmazonOrdersDownload: Codeunit AmazonOrdersDownload;
                begin
                    cu_AmazonOrdersDownload.ConnectManualAmazonAPIForSalesOrders();
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
                    cu_ShippingUpdateAmazonOrders: Codeunit "ShippingUpdate-AmazonOrders";
                begin
                    cu_ShippingUpdateAmazonOrders.ConnectAmazonShipmentConfirmation();
                end;

            }
            action(AmazonPaymentDownload)
            {
                Caption = 'Amazon Payment Download';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_AmazonPaymentDownload: Codeunit AmazonPaymentDownload;
                begin
                    cu_AmazonPaymentDownload.CreateCashReceiptBatchEntry();
                end;
            }
            action(SendProductTextFile)
            {
                Caption = 'Send Product Text File';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_AmazonProductFeeds: Codeunit AmazonProductFeeds;
                begin
                    cu_AmazonProductFeeds.SendToApiProductFileData();
                end;
            }
            action(SendStockTextFile)
            {
                Caption = 'Send Stock Text File';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_AmazonProductFeeds: Codeunit AmazonProductFeeds;
                begin
                    cu_AmazonProductFeeds.SendToApiStockLevelFeedData();
                end;
            }
            action(addItemsforAmazon)
            {
                Caption = 'Add Amazon Items';
                Promoted = true;
                PromotedCategory = Process;
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    recItem: Record Item;
                    recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
                begin
                    recAmazonItemsStockLevel.DeleteAll();

                    recItem.Reset();
                    if recItem.FindSet() then begin
                        repeat
                            recAmazonItemsStockLevel.Reset();
                            recAmazonItemsStockLevel.SetRange(ItemNo, recItem."No.");
                            if not recAmazonItemsStockLevel.FindSet() then begin
                                recAmazonItemsStockLevel.Init();
                                recAmazonItemsStockLevel.Id := CreateGuid();
                                recAmazonItemsStockLevel.ItemNo := recItem."No.";
                                recAmazonItemsStockLevel.isSent := false;
                                recAmazonItemsStockLevel.Insert(true);
                            end;
                        until recItem.Next() = 0;
                    end;
                end;
            }
        }
    }
}