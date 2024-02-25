table 50412 Enquiries
{
    Caption = 'Enquiries';
    DataClassification = ToBeClassified;
    fields
    {
        field(1; "No"; Code[20])
        {
            Caption = 'Order No.';
        }
        field(16; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = ToBeClassified;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = ToBeClassified;

        }
        field(3; Contact; Text[100])
        {
            Caption = 'Contact';
            DataClassification = ToBeClassified;
        }
        field(4; Address; Text[100])
        {
            Caption = 'Address';
            DataClassification = ToBeClassified;
        }
        field(37; "Address 2"; Text[100])
        {
            Caption = 'Address 2';
            DataClassification = ToBeClassified;
        }
        field(5; Town; Text[100])
        {
            Caption = 'Town';
            DataClassification = ToBeClassified;
        }
        field(6; County; Text[30])
        {
            Caption = 'County';
            DataClassification = ToBeClassified;
        }
        field(7; Postcode; Text[50])
        {
            Caption = 'Postcode';
            DataClassification = ToBeClassified;
        }
        field(8; Country; Text[100])
        {
            Caption = 'Country';
            DataClassification = ToBeClassified;
        }
        field(9; Email; Text[100])
        {
            Caption = 'Email';
            DataClassification = ToBeClassified;
        }
        field(10; Phone; Text[100])
        {
            Caption = 'Phone';
            DataClassification = ToBeClassified;
        }
        field(11; "Sell-to Customer No."; Code[50])
        {
            Caption = 'Sell-to Customer No.';
        }
        field(12; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Ship-to Customer Name';
        }
        field(13; "Description"; Text[500])
        {
            Caption = 'External Document No';
        }
        field(14; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(15; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
            Editable = false;
        }

        field(17; "Ship-to-Contact"; Text[100])
        {

        }
        field(18; "Ship-to City"; Text[30])
        {

        }
        field(19; "Ship-to County"; Text[50])
        {

        }
        field(20; "Ship-to Post Code"; Text[50])
        {
        }


        field(21; "Ship-to Country"; Text[50])
        {

        }
        field(22; "Amount"; Decimal)
        {

        }
        field(23; "isArchive"; Boolean)
        {

        }
        field(24; "ArchieveVersionNo"; Integer)
        {

        }
        field(29; "Total Value"; Decimal)
        {
            Editable = false;
        }
        field(26; "History"; Text[2048])
        {

        }
        field(27; "Reference"; Text[2048])
        {

        }
        field(28; "Internal Notes"; Text[2048])
        {

        }
        field(25; "ArchieveOccurrence"; Integer)
        {

        }
        field(30; "Ship-to Address"; Text[100])
        {

        }
        field(31; "Sell-to City"; Text[50])
        {

        }
        field(32; DateCreated; Date)
        {

        }
        field(33; CollectionCharge; Option)
        {
            Caption = 'Collection Charge';
            DataClassification = ToBeClassified;
            OptionMembers = "Carrier Selected","Royal Mail",Waiver;
        }
        field(34; DamageDoNotCollect; Boolean)
        {
            Caption = 'Damage Do Not Collect';
        }
        field(35; MisPickDoNotCollect; Boolean)
        {
            Caption = 'Mispick Do Not Collect';
        }
        field(36; ShortcutDimension1; Code[20])
        {
            Caption = 'Shortcut Dimension 1';
        }
        field(38; Comment; Text[2048])
        {
            Caption = 'Return Comment';
        }
        field(39; "EnqRecordId"; RecordId)
        {
            Caption = 'EnqRecordId';
        }
        field(40; SessionId; Integer)
        {
            Caption = 'SessionId';
        }

    }

    keys
    {
        key(PK; No)
        {
            Clustered = true;
        }
    }
}
