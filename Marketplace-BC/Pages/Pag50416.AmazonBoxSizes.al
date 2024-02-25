page 50416 AmazonBoxSizes
{
    Caption = 'AmazonBoxSizes';
    PageType = Card;
    SourceTable = AmazonBoxSizes;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field.';
                }
                field(UsedFor; Rec.UsedFor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the UsedFor field.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Length field.';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Width field.';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Height field.';
                }
                field("Packaging Weight"; Rec."Packaging Weight")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Weight field.';
                }
                field("Max box weight"; Rec."Max box weight")
                {
                    ApplicationArea = All;
                }
                field(isFBA; Rec.isFBA)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the isFBA field.';
                }
                field(Fee; Rec.Fee)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Fee field.';
                }
            }
        }
    }
}
