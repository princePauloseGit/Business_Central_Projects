table 50405 "Paypal Setting"
{
    Caption = 'PayPal Setting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Settings Id';
            AutoIncrement = true;

        }
        field(2; CustomerCode; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Customer Code';

        }
        field(3; VendorCode; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Code';

        }
        field(4; BankGLCode; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bank GL Code';
        }
        field(5; URL; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'URL';
        }
        field(6; APIUser; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'API User';
        }
        field(7; APIPassword; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'API Password';
        }
        field(8; Signature; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Signature';
        }
        field(9; sftpPort; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Sftp Port';
        }
        field(10; SftpDestinationPath; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Sftp Destination Path';
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