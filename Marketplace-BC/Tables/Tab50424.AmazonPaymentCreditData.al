table 50424 AmazonPaymentCreditData
{
    Caption = 'AmazonPaymentCreditData';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "External Document No"; Code[35])
        {
            Caption = 'External Document No';
            DataClassification = ToBeClassified;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "External Document No")
        {
            Clustered = true;
        }
    }
}
