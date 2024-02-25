page 50426 "B&QSettingList"
{
    ApplicationArea = All;
    Caption = 'B&&Q Setting';
    DataCaptionExpression = 'B&&Q Setting';
    CardPageId = "B&QSettingPage";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "B&Q Settings";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(CustomerCode; Rec.CustomerCode)
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field(VendorCode; Rec.VendorCode)
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field(APIKey; Rec.APIKey)
                {
                    Editable = false;
                    ApplicationArea = All;
                }

                field(Limit; Rec.Limit)
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field(manualTest; Rec.manualTest)
                {
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BQOrdersDownload)
            {
                Caption = 'B&&Q Orders Download';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_BQOrdersDownload: Codeunit BQOrdersDownload;
                begin
                    cu_BQOrdersDownload.ConnectBQAPIForSalesOrders();
                end;
            }
            action(BQPaymentDownload)
            {
                Caption = 'B&&Q Payment Download';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_BQPaymentDownload: Codeunit "B&QPaymentDownload";
                begin
                    cu_BQPaymentDownload.CreateBQCashReceiptBatchEntry();
                end;
            }
            action(ShippingUpdate)
            {
                Caption = 'Shipping Update';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    PostDate: Date;
                    Day: Integer;
                    cu_BQShippingUpdate: Codeunit "B&QShippingUpdate";
                begin
                    cu_BQShippingUpdate.CreatePostedSalesInvoiceShipment();
                end;
            }
            action(ManualTestBQ)
            {
                Caption = 'Manual Test Orders';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_BQOrdersDownload: Codeunit BQOrdersDownload;
                begin
                    cu_BQOrdersDownload.ConnectBQAPIForManualSalesOrders();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        MyPage: Page "B&QSettingList";
    begin
        MyPage.Caption := 'B&&Q';
    end;
}
