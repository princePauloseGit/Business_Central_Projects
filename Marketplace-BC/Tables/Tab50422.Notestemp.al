table 50422 Notes_temp
{
    Caption = 'Notes_temp';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; No; Guid)
        {
            Caption = 'No';
            DataClassification = ToBeClassified;

        }
        field(2; "Record Id"; Integer)
        {
            Caption = 'Record Id';
            DataClassification = ToBeClassified;
        }
        field(3; Notes; Text[2048])
        {
            Caption = 'Notes';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; No)
        {
            Clustered = true;
        }
    }
}
