table 50408 AmazonBoxSizes
{
    Caption = 'AmazonBoxSizes';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Name; Text[20])
        {
            Caption = 'Name';
            DataClassification = ToBeClassified;
        }
        field(2; UsedFor; Text[30])
        {
            Caption = 'Used For';
            DataClassification = ToBeClassified;
        }
        field(3; Length; Decimal)
        {
            Caption = 'Length';
            DataClassification = ToBeClassified;
        }
        field(4; Width; Decimal)
        {
            Caption = 'Width';
            DataClassification = ToBeClassified;
        }
        field(5; Height; Decimal)
        {
            Caption = 'Height';
            DataClassification = ToBeClassified;
        }
        field(6; "Packaging Weight"; Decimal)
        {
            Caption = 'Packaging Weight';
            DecimalPlaces = 2;
            DataClassification = ToBeClassified;
        }
        field(7; Volume; Decimal)
        {
            Caption = 'Volume';
            DataClassification = ToBeClassified;
        }
        field(8; isFBA; Boolean)
        {
            Caption = 'Is FBA';
            DataClassification = ToBeClassified;
        }
        field(9; Fee; Decimal)
        {
            Caption = 'Fee';
            DataClassification = ToBeClassified;
        }
        field(10; "Max box weight"; Decimal)
        {
            Caption = 'Max box weight';
            DataClassification = ToBeClassified;
            DecimalPlaces = 2;
        }

    }
    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }
}
