table 50420 AmazonConfirmShipment
{
    Caption = 'Amazon Confirm Shipment';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'ID';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; OrderId; Code[50])
        {
            Caption = 'Order ID';
            DataClassification = ToBeClassified;
        }
        field(3; ConfirmShipment; Boolean)
        {
            Caption = 'Confirm Shipment';
            DataClassification = ToBeClassified;
        }
        field(4; AmazonSettingsLookup; Code[50])
        {
            Caption = 'Amazon Settings Lookup';
            DataClassification = ToBeClassified;
            TableRelation = "Amazon Setting".CustomerCode;
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