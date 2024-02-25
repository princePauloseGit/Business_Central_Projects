table 50429 RefundPayments
{
    Caption = 'RefundPayments';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; id; Guid)
        {
            Caption = 'id';
            DataClassification = ToBeClassified;
        }
        field(2; MarketPlace; Text[50])
        {
            Caption = 'MarketPlace';
            DataClassification = ToBeClassified;
        }
        field(3; TranscationId; Text[2048])
        {
            Caption = 'TranscationId';
            DataClassification = ToBeClassified;
        }
        field(4; RefundAmount; Text[2048])
        {
            Caption = 'RefundAmount';
            DataClassification = ToBeClassified;
        }
        field(5; isRefunded; Text[2048])
        {
            Caption = 'isRefunded';
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
