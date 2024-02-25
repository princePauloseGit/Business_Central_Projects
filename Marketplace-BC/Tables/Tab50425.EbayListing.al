table 50425 EbayListing
{
    Caption = 'EbayListing';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; sku; Text[100])
        {
            Caption = 'SKU';
            DataClassification = ToBeClassified;
        }
        field(3; listingId; Text[100])
        {
            Caption = 'Listing Id';
            DataClassification = ToBeClassified;
        }
        field(6; EbayAction; Text[100])
        {
            Caption = 'Action';
            DataClassification = ToBeClassified;
        }
        field(7; isCompleted; Boolean)
        {
            Caption = 'isCompleted';
            DataClassification = ToBeClassified;
        }
        field(8; LastAttempt; Integer)
        {
            caption = 'Last Attempt';
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
