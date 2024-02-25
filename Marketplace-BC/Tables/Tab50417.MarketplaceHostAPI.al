table 50417 MarketplaceHostAPI
{
    Caption = 'MarketplaceHostAPI';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; MarketplaceAPI; Code[50])
        {
            Caption = 'MarketplaceAPI';
            DataClassification = ToBeClassified;
        }
        field(3; "Date"; DateTime)
        {
            Caption = 'Date';
            DataClassification = ToBeClassified;
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
