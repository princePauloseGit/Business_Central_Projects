table 50400 "Amazon Setting"
{
    Caption = 'Amazon Setting';
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
        }
        field(3; VendorCode; Code[30])
        {
            DataClassification = CustomerContent;

        }
        field(4; APIKey; Text[100])
        {
            DataClassification = CustomerContent;

        }
        field(5; APISecret; Text[100])
        {
            DataClassification = CustomerContent;

        }
        field(6; ConditionNote; Text[2048])
        {
            DataClassification = CustomerContent;

        }
        field(7; PostingGroupFBA; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(8; PostingGroupMFA; Code[20])
        {
            DataClassification = CustomerContent;

        }
        field(9; MarketplaceID; Text[50])
        {
            DataClassification = CustomerContent;

        }
        field(10; MerchantID; Text[50])
        {
            DataClassification = CustomerContent;

        }
        field(11; ServiceURL; Text[100])
        {
            DataClassification = CustomerContent;

        }
        field(12; BankGLCode; Code[30])
        {
            DataClassification = CustomerContent;
        }
        field(13; RoleArn; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(14; ClientId; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(15; ClientSecret; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(16; RefreshToken; Text[500])
        {
            DataClassification = CustomerContent;
        }
        field(17; "FBA Invoices and Credits"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(18; Payments; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(19; Orders; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(20; "Product / Stock File"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(21; ManualTest; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(22; limit; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(23; nextToken; Text[2048])
        {
            DataClassification = CustomerContent;
        }
        field(24; fbaDate; Date)
        {
            DataClassification = CustomerContent;
        }
        field(25; Environment; Enum "Environment Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Environment';
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