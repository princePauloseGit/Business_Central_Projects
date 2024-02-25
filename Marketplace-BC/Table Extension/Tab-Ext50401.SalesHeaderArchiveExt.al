tableextension 50401 "Sales Header Archive Extension" extends "Sales Header Archive"
{
    fields
    {
        field(50400; Source; Enum "Order Source")
        {
            Caption = 'Source';
        }
        field(50405; ReturnOrderHistory; Text[2048])
        {
            Caption = 'Return Order History';
        }
        field(50411; IsUpdatedVersion; Integer)
        {
            Caption = 'IsUpdatedVersion';
        }
        field(50406; HistoryNotes; Text[2048])
        {
            Caption = 'History Notes';
        }
        field(50407; "Enq-Sales RecordId"; RecordId)
        {
            Caption = 'Enq-Sales RecordId';
        }
    }
}
