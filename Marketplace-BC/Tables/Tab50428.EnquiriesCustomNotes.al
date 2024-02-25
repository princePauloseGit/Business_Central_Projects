table 50428 EnquiriesCustomNotes
{
    Caption = 'EnquiriesCustomNotes';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; OrderNo; Code[20])
        {
            Caption = 'OrderNo';
            DataClassification = ToBeClassified;
        }
        field(2; HasLink; Boolean)
        {
            Caption = 'HasLink';
            DataClassification = ToBeClassified;
            InitValue = false;
        }
    }
    keys
    {
        key(PK; OrderNo)
        {
            Clustered = true;
        }
    }
}
