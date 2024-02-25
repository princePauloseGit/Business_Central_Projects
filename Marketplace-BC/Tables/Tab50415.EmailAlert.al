table 50415 EmailAlert
{
    Caption = 'Email Alert';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
            DataClassification = CustomerContent;
        }

    }
    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}

