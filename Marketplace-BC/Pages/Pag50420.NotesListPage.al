page 50420 "Notes List Page"
{
    Caption = 'Notes List Page';
    PageType = List;
    CardPageId = "Notes Page";
    SourceTable = EnquiriesCustomNotes;
    UsageCategory = Administration;
    RefreshOnActivate = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(OrderNo; Rec.OrderNo)
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}
