page 50437 "Return Comment"
{

    Caption = 'Add Return Comment';
    PageType = StandardDialog;
    SourceTable = "Enquiries";
    DataCaptionExpression = 'Return Comment';
    UsageCategory = Administration;
    Editable = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(general)
            {
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Return Comment';
                    Editable = true;
                }
            }
        }
    }
}
