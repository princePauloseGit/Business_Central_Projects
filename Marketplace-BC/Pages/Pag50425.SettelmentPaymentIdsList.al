page 50425 SettelmentPaymentIdsList
{
    ApplicationArea = All;
    Caption = 'Settlement Payment Ids List';
    PageType = List;
    SourceTable = SettelmentPaymentIds;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Report ID field.';
                }
                field("canArchived"; Rec."canArchived")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the canArchived field.';
                }
                field("Marketplace"; Rec."MarketPlace")
                {
                    Caption = 'Marketplace';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MarketPlace field.';
                }
            }
        }
    }
}
