page 50433 "Internal Email List"
{
    Caption = 'Internal Email List';
    PageType = List;
    SourceTable = EmailAlert;
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "Internal Email";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Email Address"; Rec."Email Address")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Add Days")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                ToolTip = 'Add Days';
                RunObject = page DayCard;
                Image = NumberGroup;
            }
        }
    }
}
