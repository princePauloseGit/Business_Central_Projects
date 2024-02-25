table 50419 LegacyOrders
{
    Caption = 'LegacyOrders';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'ID';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; MarketplaceName; Text[50])
        {
            Caption = 'Marketplace Name';
            DataClassification = ToBeClassified;
        }
        field(3; OrderId; Code[50])
        {
            Caption = 'Order ID';
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
