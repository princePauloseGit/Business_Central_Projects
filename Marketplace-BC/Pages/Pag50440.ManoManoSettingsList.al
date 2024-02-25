page 50440 ManoManoSettingsList
{
    ApplicationArea = All;
    Caption = 'ManoMano Settings';
    PageType = List;
    SourceTable = ManoManoSettings;
    UsageCategory = Administration;
    CardPageId = ManoManoSettingsPage;
    RefreshOnActivate = true;

    Permissions = TableData "Sales Invoice Header" = rimd;


    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Customer Code"; Rec.CustomerCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CustomerCode field.';
                }
                field("Vendor Code"; Rec.VendorCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the VendorCode field.';
                }
                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the API Key field.';
                }
                field("Contract ID"; Rec."Contract Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Contract Id field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ManoGetOrders)
            {
                Caption = 'ManoMano Orders Download';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_ManoOrderDownloads: Codeunit ManoOrderDownloads;
                begin
                    cu_ManoOrderDownloads.ConnectManoAPIForSalesOrders();
                end;
            }
            action(ManoAcceptOrders)
            {
                Caption = 'ManoMano Accept Orders';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_ManoAcceptOrders: Codeunit ManoAcceptOrders;
                begin
                    cu_ManoAcceptOrders.ConnectManoAcceptOrdersApi();
                end;
            }
            action(ManoShippingUpdate)
            {
                Caption = 'ManoMano Shipping Update';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_ManoShippingUpdate: Codeunit ManoShippingUpdate;
                begin
                    cu_ManoShippingUpdate.ConnectManoShipmentApi();
                end;
            }
        }
    }
}
