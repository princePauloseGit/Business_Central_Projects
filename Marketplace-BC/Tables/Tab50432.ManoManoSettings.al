table 50432 ManoManoSettings
{
    Caption = 'ManoMano Settings';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'ID';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; CustomerCode; Code[50])
        {
            Caption = 'Customer Code';
            DataClassification = ToBeClassified;
            TableRelation = Customer."No.";
        }
        field(3; VendorCode; Code[50])
        {
            Caption = 'Vendor Code';
            DataClassification = ToBeClassified;
            TableRelation = Vendor."No.";
        }
        field(4; "API Key"; Text[500])
        {
            DataClassification = ToBeClassified;
            Caption = 'API Key';
        }
        field(5; "Contract Id"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract ID';
        }
        field(6; Environment; Enum "Environment Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Environment';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
