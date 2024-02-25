codeunit 50429 RefundNotes
{

    procedure RefundNotesOnCreditMemo(SalesHeader: Record "Sales Header")
    var
        rec_CreditMemoHeader: Record "Sales Cr.Memo Header";
        RefundNote: Text;
        cdu_EnquiriesReturns: Codeunit EnquiriesAndReturns;
        refundAmount: Decimal;
        cu_RefundProcess: Codeunit RefundProcess;
    begin
        rec_CreditMemoHeader.SetRange("Return Order No.", SalesHeader."No.");
        if rec_CreditMemoHeader.FindSet() then begin

            rec_CreditMemoHeader.CalcFields("Amount Including VAT");

            if (SalesHeader."Payment Method Code" = 'BRAINTREE') or (SalesHeader."Payment Method Code" = 'PAYPAL') then begin
                refundAmount := cu_RefundProcess.CheckMagentoGrossValue(SalesHeader, rec_CreditMemoHeader."Amount Including VAT");
            end
            else begin
                refundAmount := rec_CreditMemoHeader."Amount Including VAT";
            end;

            RefundNote := 'A Refund has been processed for the Sales Return Order No. ' + rec_CreditMemoHeader."Return Order No." + ' by ' + cdu_EnquiriesReturns.getUserName(rec_CreditMemoHeader.SystemCreatedBy) + ' at ' + format(rec_CreditMemoHeader.SystemCreatedAt) + ' and the amount of refund is ' + Format(refundAmount, 0, '<Precision, 2:2><Standard Format, 0>');

            WriteNoteOnCreditMemo(rec_CreditMemoHeader."Return Order No.", RefundNote);
            WriteRefundNoteInitalSo(rec_CreditMemoHeader."Return Order No.", RefundNote)
        end;
    end;

    procedure WriteNoteOnCreditMemo(ReturnOrderNo: Code[20]; RefundNote: Text)
    var
        RecordLink: Record "Record Link";
        rec_CreditMemoHeader: Record "Sales Cr.Memo Header";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.Reset();
        Clear(RecordLinkManagement);
        rec_CreditMemoHeader.Reset();

        rec_CreditMemoHeader.SetRange("Return Order No.", ReturnOrderNo);
        if rec_CreditMemoHeader.FindSet() then begin
            RecordLink.Reset();
            RecordLink.Init();
            RecordLink.Company := CompanyName();
            RecordLink.Type := RecordLink.Type::Note;
            RecordLink.Created := CurrentDateTime;
            RecordLink."User ID" := UserId();
            RecordLink."Record ID" := rec_CreditMemoHeader.RecordId;
            RecordLinkManagement.WriteNote(RecordLink, RefundNote);
            RecordLink.Insert(true);
            Commit();
        end;
    end;

    procedure WriteRefundNoteInitalSo(SalesHeaderNo: code[20]; RefundNoteOnSO: Text)
    var
        rec_SalesHeader: Record "Sales Header";
        rec_SalesMemoHeader: Record "Sales Cr.Memo Header";
        RecordLinkManagement: Codeunit "Record Link Management";
        RecordLink: Record "Record Link";
        DocType: Enum "Sales Document Type";
        InitalSoNO: Code[20];
    begin
        RecordLink.Reset();
        Clear(RecordLinkManagement);
        rec_SalesMemoHeader.Reset();

        rec_SalesMemoHeader.SetRange("Return Order No.", SalesHeaderNo);
        if rec_SalesMemoHeader.FindSet() then begin

            // InitalSoNO := rec_SalesMemoHeader.InitialSoNumber;

            rec_SalesHeader.SetRange("No.", rec_SalesMemoHeader.InitialSalesOrderNumber);
            rec_SalesHeader.SetRange("Document Type", DocType::Order);
            if rec_SalesHeader.FindSet() then begin
                RecordLink.Init();
                RecordLink.Company := CompanyName();
                RecordLink.Type := RecordLink.Type::Note;
                RecordLink.Created := CurrentDateTime;
                RecordLink."User ID" := UserId();
                RecordLink."Record ID" := rec_SalesHeader.RecordId;
                RecordLinkManagement.WriteNote(RecordLink, RefundNoteOnSO);
                RecordLink.Insert(true);
                Commit();
            end;
        end;
    end;
}
