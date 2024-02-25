page 50424 SettelmentPaymentIds
{
    Caption = 'Settlement Payment Ids';
    PageType = Card;
    SourceTable = SettelmentPaymentIds;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Report ID field.';
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
