page 50432 DayCard
{
    Caption = 'Days';
    PageType = XmlPort;
    SourceTable = ReturnDays;
    DataCaptionExpression = 'Days';
    UsageCategory = Administration;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(StartingDate; Rec.Days)
                {
                    Caption = 'Day';
                    ApplicationArea = All;
                    Editable = true;
                }
            }
        }
    }
}

