pageextension 50408 "Sales Return order" extends "Sales Return Order"
{
    layout
    {
        addlast(General)
        {
            field(customDeliveryNotes; Rec.customDeliveryNotes)
            {
                Editable = true;
                ApplicationArea = All;
                Caption = 'Delivery Instructions';
            }
        }
    }
    actions
    {
        modify(Release)
        {
            trigger OnAfterAction()
            var
                recSalesOrderArchive: Record "Sales Header Archive";
                cuReleaseSalesDoc: Codeunit "Release Sales Document";
            begin

                if (Rec.RefundAmount > Rec.ActualAmountToRefund) and (Rec.isRefund = true) then
                    cuReleaseSalesDoc.PerformManualReopen(Rec)
            end;
        }
    }
    trigger OnModifyRecord(): Boolean
    var
        SalesDocumentStatus: Enum "Sales Document Status";
    begin
        if Rec.Status = SalesDocumentStatus::Released then begin
            CurrPage.Close();
        end;
    end;
}