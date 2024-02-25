table 50413 "Enquiries Line"
{
    Caption = 'Enquiries Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = ToBeClassified;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = ToBeClassified;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = ToBeClassified;
        }
        field(5; "Type"; Enum "Sales Line Type")
        {
            Caption = 'Type';
            DataClassification = ToBeClassified;
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
        }
        field(9; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            DataClassification = ToBeClassified;
        }
        field(10; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DataClassification = ToBeClassified;
        }
        field(11; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            DataClassification = ToBeClassified;
        }
        field(12; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = ToBeClassified;
        }
        field(13; "Return/Replace"; Decimal)
        {
            Caption = 'Return/Replace';
            DataClassification = ToBeClassified;
        }
        field(14; VAT; Decimal)
        {
            Caption = 'VAT';
            DataClassification = ToBeClassified;
        }
        field(15; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            DataClassification = ToBeClassified;
            TableRelation = "Return Reason";
        }
        field(16; SessionId; Integer)
        {
            Caption = 'Session Id';
            DataClassification = ToBeClassified;
        }
        field(17; "ArchiveLineNo"; Integer)
        {
            Caption = 'Archive Line No';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {

    }
}
