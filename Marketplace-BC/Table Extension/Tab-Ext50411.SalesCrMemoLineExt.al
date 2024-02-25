tableextension 50411 "Sales Cr.Memo Line Ext" extends "Sales Cr.Memo Line"
{
    fields
    {
        field(50400; "3rd Party System PK"; Code[50])
        {
            Caption = '3rd Party System PK';
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
    }
}
