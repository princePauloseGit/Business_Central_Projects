table 50410 SettelmentPaymentIds
{
    Caption = 'Settelment Payment Ids';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "ID"; Integer)
        {
            Caption = 'ID';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Report ID"; Text[100])
        {
            Caption = 'Report ID';
            DataClassification = CustomerContent;
        }
        field(3; "canArchived"; Boolean)
        {
            Caption = 'Can Archived';
            DataClassification = CustomerContent;
        }
        field(4; "Paypal Settelment Date"; Date)
        {
            Caption = 'PayPal Settelment Date';
            DataClassification = CustomerContent;
        }
        field(5; "MarketPlace"; Text[50])
        {
            Caption = 'Marketplace';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
    }
}
