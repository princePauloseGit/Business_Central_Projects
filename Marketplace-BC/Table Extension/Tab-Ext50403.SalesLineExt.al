tableextension 50403 "Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(50400; "3rd Party System PK"; Code[50])
        {
            Caption = '3rd Party System';
            DataClassification = ToBeClassified;
        }
        field(50401; "Total Returned"; Integer)
        {
            Caption = 'Total Returned';
            DataClassification = ToBeClassified;
        }
        field(50402; "isReturned"; Boolean)
        {
            Caption = 'isReturned';
            DataClassification = ToBeClassified;
        }
        field(50403; "ActualApiPrice"; Decimal)
        {
            Caption = 'Actual Api Price';
            DataClassification = ToBeClassified;
        }
        field(50404; "TotalApiPrice"; Decimal)
        {
            Caption = 'Total Api Price';
            DataClassification = ToBeClassified;
        }
        field(50405; "ArchiveLineNo"; Integer)
        {
            Caption = 'Archive Line No';
            DataClassification = ToBeClassified;
        }
    }
}
