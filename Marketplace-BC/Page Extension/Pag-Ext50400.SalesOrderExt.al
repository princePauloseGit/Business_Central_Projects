pageextension 50400 "Sales Order extension" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field("Source"; Rec.Source)
            {
                Editable = false;
                ApplicationArea = All;
                Caption = 'Source';
            }
            field(InitialSalesOrderNumber; Rec.InitialSalesOrderNumber)
            {
                Editable = false;
                ApplicationArea = All;
                Caption = 'Initial Sales Order Number';
            }
        }
    }

    trigger OnOpenPage()
    var
        cdu_CutomeNotes: Codeunit "Enquiries Custom notes";
    begin
        cdu_CutomeNotes.CopyLinksFromEnquiriesToSalesHeader(Rec."No.");
        Commit();
    end;
}
