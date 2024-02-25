table 50414 ReturnItem
{
    Caption = 'ReturnItem';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; id; Integer)
        {
            Caption = 'id';
            DataClassification = ToBeClassified;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'id';
            DataClassification = ToBeClassified;
        }
        field(2; ItemName; Text[50])
        {
            Caption = 'Item Name';
            DataClassification = ToBeClassified;
        }
        field(3; ActualQuantity; Integer)
        {
            Caption = 'Actual Quantity';
            DataClassification = ToBeClassified;
        }
        field(4; ReturnedQuantity; Integer)
        {
            Caption = 'Returned Quantity';
            DataClassification = ToBeClassified;
        }

    }
    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }
}
