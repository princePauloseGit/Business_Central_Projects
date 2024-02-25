page 50438 "Marketplace Email Alerts Setup"
{
    ApplicationArea = All;
    Caption = 'Marketplace Email Alerts Setup';
    PageType = List;
    SourceTable = "MarketPlace Email Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Alert Name"; Rec."Alert Name")
                {
                    Caption = 'Alert Name';
                }
                field(Email; Rec.Email)
                {
                    Caption = 'Email';
                }

            }
        }
    }
}
