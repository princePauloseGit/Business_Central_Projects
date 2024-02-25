tableextension 50405 "Sales Line Archive Ext" extends "Sales Line Archive"
{
    fields
    {
        field(50400; "3rd Party System PK"; Code[50])
        {
            Caption = '3rd Party System';
            DataClassification = CustomerContent;
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
    }
}
