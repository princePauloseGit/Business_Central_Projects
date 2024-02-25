page 50419 "Notes Page"
{
    Caption = 'Notes Page';
    PageType = Card;
    SourceTable = EnquiriesCustomNotes;
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(OrderNo; Rec.OrderNo)
                {
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(3),
                              "No." = FIELD(OrderNo);
            }
            systempart(PyamentTermsLinks; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(PyamentTermsNotes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }
}
