tableextension 50408 SalesInvoiceLine extends "Sales Invoice Line"
{
    fields
    {
        field(50400; "3rd Party System PK"; Code[50])
        {
            Caption = '3rd Party System';
            DataClassification = CustomerContent;
        }
    }
}
