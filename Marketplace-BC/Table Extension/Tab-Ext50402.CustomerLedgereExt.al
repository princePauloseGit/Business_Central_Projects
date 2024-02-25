tableextension 50402 "Customer Ledger Ext" extends "Cust. Ledger Entry"
{
    fields
    {
        field(50100; Source; Enum "Order Source")
        {
            Caption = 'Source';
            DataClassification = ToBeClassified;
        }
    }
}
