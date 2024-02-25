table 50423 eBayConfirmShipment
{
    Caption = 'eBay Confirm Shipment';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = ToBeClassified;
        }
        field(2; OrderId; Code[50])
        {
            Caption = 'Order Id';
            DataClassification = ToBeClassified;
        }
        field(3; ConfirmShipment; Boolean)
        {
            Caption = 'Confirm Shipment';
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
