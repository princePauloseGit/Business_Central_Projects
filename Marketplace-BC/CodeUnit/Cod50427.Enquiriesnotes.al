codeunit 50427 "Enquiries notes"
{

    procedure GetWorkDescription(SourceRecordLink: Record "Record Link") Note: Text
    var
        MyInStream: InStream;
    begin
        Clear(Note);
        SourceRecordLink.Calcfields(Note);
        If SourceRecordLink.Note.HasValue() then begin
            SourceRecordLink.Note.CreateInStream(MyInStream);
            MyInStream.Read(Note);
        end;
    end;

    procedure GetHistoryForSalesOrder(SalesHeaderNo: code[20]; ReturnOrderNo: Code[20]): Text
    var
        rec_SalesHeader: Record "Sales Header";
        postedInvtPickHeaderNo: Code[20];
        Char1310: Char;
        OrderNoHistory: Text;
        DocType: Enum "Sales Document Type";
    begin
        rec_SalesHeader.SetRange("No.", ReturnOrderNo);
        rec_SalesHeader.SetRange("Document Type", DocType::"Return Order");

        if rec_SalesHeader.FindSet() then begin
            OrderNoHistory := 'The Sales Return Order No ' + rec_SalesHeader."No." + ' was created at ' + Format(rec_SalesHeader.SystemCreatedAt) + ' by ' + UserId;
            // InsertHistoryNote(SalesHeaderNo, OrderNoHistory);
        end;
    end;

    procedure GetReturnOrderQty(SalesHeaderNo: code[20]; ReturnOrderNo: Code[20])
    var
        rec_SalesHeader: Record "Sales Header";
        rec_SalesLines: Record "Sales Line";
        DocType: Enum "Sales Document Type";
    begin
        rec_SalesHeader.SetRange("No.", ReturnOrderNo);
        rec_SalesHeader.SetRange("Document Type", DocType::"Return Order");
        if rec_SalesHeader.FindSet() then begin
            rec_SalesLines.SetRange("Document No.", rec_SalesHeader."No.");
            if rec_SalesLines.FindSet() then
                repeat
                    GetReturnQtyToSalesOrder(SalesHeaderNo, rec_SalesLines."Return Qty. to Receive", rec_SalesLines."No.");
                until rec_SalesLines.Next() = 0;
        end;
    end;

    procedure GetReturnQtyToSalesOrder(SalesHeaderNo: Code[20]; Returnqty: Decimal; returnItem: Code[20])
    var
        rec_SalesHeader: Record "Sales Header";
        rec_SalesLines: Record "Sales Line";
        DocType: Enum "Sales Document Type";
    begin
        rec_SalesHeader.SetRange("No.", SalesHeaderNo);
        rec_SalesHeader.SetRange("Document Type", DocType::Order);
        if rec_SalesHeader.FindSet() then begin
            rec_SalesLines.SetRange("Document No.", rec_SalesHeader."No.");
            rec_SalesLines.SetRange("No.", returnItem);
            if rec_SalesLines.FindSet() then begin
                rec_SalesLines."Return Qty. to Receive" := Returnqty;
                rec_SalesLines.Modify(true);
                Commit();
            end;
        end;
    end;

    procedure InsertHistoryNote(SalesHeaderNo: code[20]; OrderNoHistory: Text)
    var
        rec_SalesHeader: Record "Sales Header";
        SourceRecordLink: Record "Record Link";
        LinkManagement: Codeunit "Record Link Management";
        textWorkDes: Text;
        rec_notes: record Notes_temp;
        RecordLink: Record "Record Link";
        DocType: Enum "Sales Document Type";
        rec_Enquiries: Record Enquiries;
    begin
        rec_Enquiries.SetRange(No, SalesHeaderNo);
        if rec_Enquiries.FindSet() then begin
            RecordLink.Init();
            RecordLink.Company := CompanyName();
            RecordLink.Type := RecordLink.Type::Note;
            RecordLink.Created := CurrentDateTime;
            RecordLink."User ID" := UserId();
            RecordLink."Record ID" := rec_SalesHeader.RecordId;
            LinkManagement.WriteNote(RecordLink, OrderNoHistory);
            RecordLink.Insert(true);
            Commit();
        end;
    end;

    procedure CopyHistoryNotesToEnquiriesNotes(EnqNo: Code[20])
    var
        RecordLink, RecordLinkNotes : Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        textWorkDes, UpdatedNotes : Text;
        trackingHistory: Text;
        rec_notes: record Notes_temp;
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        Streamout: OutStream;
        MyFieldRef: FieldRef;
        CustomerRecRef: RecordRef;
        rec_Enquiries: Record Enquiries;
        LinkID: Integer;
    begin
        RecordLink.Reset();
        clear(trackingHistory);
        Clear(RecordLinkManagement);
        rec_SalesInvoiceHeader.Reset();
        rec_notes.DeleteAll();
        Clear(rec_Enquiries);

        rec_SalesInvoiceHeader.SetRange("Order No.", EnqNo);
        rec_SalesInvoiceHeader.SetFilter("Shipping Agent Code", '%1', 'RM');

        if rec_SalesInvoiceHeader.FindSet() then begin
            trackingHistory := 'https://www.royalmail.com/track-your-item#/tracking-results/' + rec_SalesInvoiceHeader."Package Tracking No.";
        end
        else begin
            rec_SalesInvoiceHeader.SetRange("Order No.", EnqNo);
            rec_SalesInvoiceHeader.SetFilter("Shipping Agent Code", '%1', 'DPD');
            if rec_SalesInvoiceHeader.FindSet() then begin
                trackingHistory := 'https://track.dpd.co.uk/' + rec_SalesInvoiceHeader."Package Tracking No.";
            end
        end;

        Clear(RecordLinkNotes);

        rec_Enquiries.SetRange(No, EnqNo);
        if rec_Enquiries.FindSet() then begin
            if rec_Enquiries.History <> '' then begin
                if rec_Enquiries.FindSet() then begin

                    if RecordLinkNotes.FindLast() then begin
                        Clear(LinkID);
                        LinkID := RecordLinkNotes."Link ID";
                    end;

                    LinkID := LinkID + 1;

                    RecordLink.Init();
                    RecordLink.Company := CompanyName();
                    RecordLink.Type := RecordLink.Type::Note;
                    RecordLink.Created := CurrentDateTime;
                    RecordLink."User ID" := UserId();
                    RecordLink."Link ID" := LinkID;
                    RecordLink."Record ID" := rec_Enquiries.RecordId;

                    if trackingHistory <> '' then begin
                        RecordLinkManagement.WriteNote(RecordLink, rec_Enquiries.History + trackingHistory);
                    end
                    else begin
                        RecordLinkManagement.WriteNote(RecordLink, rec_Enquiries.History);
                    end;
                    RecordLink.Insert(true);
                    Commit();
                end;
            end;
        end;
    end;

}