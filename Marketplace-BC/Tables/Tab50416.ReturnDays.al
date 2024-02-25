table 50416 ReturnDays
{
    Caption = 'Days Production';
    DataClassification = ToBeClassified;
    fields
    {
        field(1; Id; Integer)
        {
            Caption = 'Id';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; Days; Integer)
        {
            Caption = 'Days';
            DataClassification = CustomerContent;
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