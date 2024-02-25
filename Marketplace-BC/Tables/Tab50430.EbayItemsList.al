table 50430 EbayItemsList
{
    Caption = 'EbayItemsList';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            AutoIncrement = true;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; Listing_ID; Text[100])
        {
            Caption = 'ListingId';
        }
        field(4; Offer_ID; Text[100])
        {
            Caption = 'OfferId';
        }
        field(5; LAST_PRICE; Decimal)
        {
            Caption = 'Last_Price';
        }
        field(6; LAST_INVENTORY; Decimal)
        {
            Caption = 'Last_Inventory';
        }
        field(7; ForceUpdate; Boolean)
        {
            Caption = 'Force Update';
        }

    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;

        }
        key("No."; "No.")
        {
            Clustered = false;
        }
    }
}
