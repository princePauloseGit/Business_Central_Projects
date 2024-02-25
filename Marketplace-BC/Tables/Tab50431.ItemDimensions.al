table 50431 ItemDimensions
{
    Caption = 'Item Dimensions';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
        }
        field(2; API_Height; Decimal)
        {
            Caption = 'API_Height';
        }
        field(3; API_Weight; Decimal)
        {
            Caption = 'API_Weight';
        }
        field(4; API_Width; Decimal)
        {
            Caption = 'API_Width';
        }
        field(5; API_Length; Decimal)
        {
            Caption = 'API_Length';
        }
        field(6; FBA_SKU; code[100])
        {
            Caption = 'FBA_SKU';
        }
        field(7; ASIN; Text[100])
        {
            Caption = 'ASIN';
        }
        field(8; No; Code[20])
        {
            Caption = 'No.';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(FBA_SKU; FBA_SKU)
        {
            Clustered = false;
        }
    }
}
