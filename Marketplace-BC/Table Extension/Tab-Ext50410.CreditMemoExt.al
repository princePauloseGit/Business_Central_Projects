tableextension 50410 CreditMemoExt extends "Sales Cr.Memo Header"
{
    fields
    {
        field(50409; InitialSalesOrderNumber; Code[20])
        {
            Caption = 'Initial Sales Order Number';
        }
        field(90133; MagentoGrossValue; Decimal)
        {
            Caption = 'Magento Gross Value';
        }
    }
}
