table 50402 "Onbuy Setting"
{
    Caption = 'Onbuy Setting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;

        }
        field(2; OnbuyCustomerCode; Code[30])
        {
            DataClassification = ToBeClassified;

        }
        field(3; OnbuyVendorCode; Code[30])
        {
            DataClassification = ToBeClassified;

        }
        field(4; ClientKey; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(5; SID; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(6; SecretKey; Text[100])
        {
            DataClassification = ToBeClassified;

        }
        field(7; URL; Text[100])
        {
            DataClassification = ToBeClassified;

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