table 50406 AppeagleRates
{
    Caption = 'Appeagle Rates';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Code"; Text[20])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
        }
        field(2; Rate; Decimal)
        {
            Caption = 'Rate';
            DataClassification = ToBeClassified;
        }
        field(3; AmazonCarrierMapping; Text[30])
        {
            Caption = 'Amazon Carrier Mapping';
            DataClassification = ToBeClassified;
        }
        field(4; EbayRate; Decimal)
        {
            Caption = 'ebay Rate';
            DataClassification = ToBeClassified;
        }
        field(5; MarkupRate; Decimal)
        {
            Caption = 'Markup Rate';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
