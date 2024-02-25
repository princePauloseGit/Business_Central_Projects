table 50404 "Braintree Setting"
{
    Caption = 'Braintree Setting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;

        }
        field(2; CustomerCode; Code[30])
        {
            DataClassification = ToBeClassified;

        }
        field(3; VendorCode; Code[30])
        {
            DataClassification = ToBeClassified;

        }
        field(4; MerchantID; Text[50])
        {
            DataClassification = ToBeClassified;

        }
        field(5; PublicKey; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(6; PrivateKey; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(7; BankGLCode; Code[30])
        {
            DataClassification = ToBeClassified;

        }
        field(8; Refund; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
        }
        field(9; StartDate; Date)
        {
            DataClassification = CustomerContent;
        }
        field(10; EndDate; Date)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; settingsid)
        {
            Clustered = true;
        }
    }
}