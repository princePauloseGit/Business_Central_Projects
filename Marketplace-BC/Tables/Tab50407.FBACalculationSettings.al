table 50407 FBACalculationSettings
{
    Caption = 'FBA Calculation Settings';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; MarkupFactor; Decimal)
        {
            Caption = 'Markup Factor';
            DataClassification = ToBeClassified;
        }
        field(2; CostPerKgUK; Decimal)
        {
            Caption = 'Cost Per Kg UK';
            DataClassification = ToBeClassified;
        }
        field(3; CostPerKgEU; Decimal)
        {
            Caption = 'Cost Per Kg EU';
            DataClassification = ToBeClassified;
        }
        field(4; EURExchangeRate; Decimal)
        {
            Caption = 'EURExchange Rate';
            DataClassification = ToBeClassified;
        }
        field(5; BubbleWrapCost; Decimal)
        {
            Caption = 'Bubble Wrap Cost';
            DataClassification = ToBeClassified;
        }
        field(6; LabelCost; Decimal)
        {
            Caption = 'Label Cost';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; MarkupFactor)
        {
            Clustered = true;
        }
    }
}
