tableextension 50400 "Sales Header" extends "Sales Header"
{
    fields
    {
        field(50400; Source; Enum "Order Source")
        {
            Caption = 'Source';
        }
        field(50401; IsPrime; Boolean)
        {
            Caption = 'Is Prime';
        }
        field(50402; OrderBatch; Code[20])
        {
            Caption = 'Order Batch';
        }
        field(50403; ShipServiceLevel; Code[50])
        {
            Caption = 'Ship Service Level';
        }
        field(50404; ReturnOrderNo; Code[20])
        {
            Caption = 'Return Order No.';
        }
        field(50405; ReturnOrderHistory; Text[2048])
        {
            Caption = 'Return Order History';
        }
        field(50406; HistoryNotes; Text[2048])
        {
            Caption = 'History Notes';
        }
        field(50407; "Enq-Sales RecordId"; RecordId)
        {
            Caption = 'Enq-Sales RecordId';
        }
        field(50408; isRefund; Boolean)
        {
            Caption = 'isRefund';
        }
        field(50409; InitialSalesOrderNumber; Code[20])
        {
            Caption = 'Initial Sales Order Number';
        }
        field(50410; IsAcceptedOrder; Boolean)
        {
            Caption = 'Is Accepted Order';
        }
        field(50412; ActualAmountToRefund; Decimal)
        {
            Caption = 'Actual Amount To Refund';
        }
        field(50413; RefundAmount; Decimal)
        {
            Caption = 'Refund Amount';
        }
    }

}
