page 50418 "Fulfilment Policy"
{
    Caption = 'Fulfilment Policy';
    PageType = List;
    SourceTable = FulfilmentPolicy;
    UsageCategory = Administration;
    Editable = true;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Policy Name"; Rec."Policy Name")
                {
                    ApplicationArea = All;
                }
                field("Policy Id"; Rec."Policy Id")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
