table 50409 FulfilmentPolicy
{
    Caption = 'FulfilmentPolicy';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Policy Name"; Text[2048])
        {
            Caption = 'Policy Name';
            DataClassification = ToBeClassified;
        }
        field(2; "Policy Id"; Text[2048])
        {
            Caption = 'Policy Id';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Policy Name")
        {
            Clustered = true;
        }
    }
}
