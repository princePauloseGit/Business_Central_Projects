table 50411 "B&Q Settings"
{
    Caption = 'B&&Q Settings';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            AutoIncrement = true;
            DataClassification = CustomerContent;
        }
        field(2; CustomerCode; Code[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Customer Code';
        }
        field(3; APIKey; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'API Key';
        }
        field(4; VendorCode; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Vendor Code';
        }
        field(5; Limit; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Limit';
            trigger OnValidate()
            begin

                if Limit > 100 then
                    Error('Please enter the limit below 100');
            end;
        }
        field(6; ManualTest; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Manual Test';

        }
        field(8; offset; Text[5])
        {
            DataClassification = CustomerContent;
            Caption = 'offset';
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
