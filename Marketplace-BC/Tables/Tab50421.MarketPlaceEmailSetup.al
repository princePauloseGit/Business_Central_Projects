table 50421 "MarketPlace Email Setup"
{
    Caption = 'MarketPlace Email Alert Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Alert Name"; Enum MarketPlaceAlerts)
        {
            Caption = 'Alert Name';
            DataClassification = ToBeClassified;
        }
        field(2; Email; Text[100])
        {
            Caption = 'Email';
            DataClassification = ToBeClassified;
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(4; "Cc Email"; Text[100])
        {
            Caption = 'Cc Email';
            DataClassification = ToBeClassified;
        }
        field(5; "Bcc Email"; Text[100])
        {
            Caption = 'Bcc Email';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
