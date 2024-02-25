page 50443 "Amazon Stock Level"
{
    ApplicationArea = All;
    Caption = 'Amazon Stock Level';
    PageType = List;
    SourceTable = AmazonItemsStockLevel;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(ItemNo; Rec.ItemNo)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(isBlocked; Rec.isBlocked)
                {
                    ApplicationArea = All;
                }
                field(isSent; Rec.isSent)
                {
                    ApplicationArea = All;
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    ApplicationArea = All;
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
