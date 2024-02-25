tableextension 50409 "Sales Invoice Header Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(50402; OrderBatch; Code[20])
        {
            Caption = 'Order Batch';
            DataClassification = ToBeClassified;
        }
        field(50409; InitialSalesOrderNumber; Code[20])
        {
            Caption = 'Initial Sales Order Number';
        }
    }
}
