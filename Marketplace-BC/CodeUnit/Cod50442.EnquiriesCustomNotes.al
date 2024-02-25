codeunit 50442 "Enquiries Custom notes"
{
    procedure CopyLinksFromEnquiriesToSalesHeader(HeaderNo: Code[20])
    var
        SourceRecordLink, HeaderRecordLink : Record "Record Link";
        rec_Enquiries: Record EnquiriesCustomNotes;
        textWorkDes: Text;
        rec_notes: record Notes_temp;
        RecordLink, RecordLinkNotes : Record "Record Link";
        LinkManagement: Codeunit "Record Link Management";
        rec_SalesHeader: Record "Sales Header";
        LinkID: Integer;
        cdu_Base64: Codeunit "Base64 Convert";
        myout: OutStream;
    begin
        rec_notes.DeleteAll();
        SourceRecordLink.Reset();
        Clear(textWorkDes);
        RecordLink.Reset();
        HeaderRecordLink.Reset();


        rec_SalesHeader.SetRange("No.", HeaderNo);
        if rec_SalesHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_SalesHeader.RecordId);
            if SourceRecordLink.FindSet() then
                repeat
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');

                    if textWorkDes <> '' then begin
                        rec_notes.Init();
                        rec_notes.No := CreateGuid();
                        rec_notes.Notes := textWorkDes;
                        rec_notes."Record Id" := SourceRecordLink."Link ID";
                        rec_notes.Insert();
                        Commit();
                    end;
                until SourceRecordLink.Next() = 0;
        end;


        SourceRecordLink.Reset();
        rec_Enquiries.Reset();
        RecordLinkNotes.Reset();

        rec_SalesHeader.SetRange("No.", HeaderNo);
        if rec_SalesHeader.FindSet() then begin
            HeaderRecordLink.SetRange("Record ID", rec_SalesHeader."Enq-Sales RecordId");
            if HeaderRecordLink.FindSet() then
                repeat
                    RecordLinkNotes.Reset();
                    RecordLinkNotes.SetCurrentKey("Link ID");
                    RecordLinkNotes.SetAscending("Link ID", false);
                    if RecordLinkNotes.FindFirst() then begin
                        Clear(LinkID);
                        LinkID := RecordLinkNotes."Link ID";
                    end;
                    textWorkDes := GetWorkDescription(HeaderRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');
                    if textWorkDes <> '' then begin
                        rec_notes.SetRange(Notes, textWorkDes);
                        if not rec_notes.FindSet() then begin
                            LinkID := LinkID + 1;

                            RecordLink.Init();
                            RecordLink.Company := CompanyName();
                            RecordLink.Type := RecordLink.Type::Note;
                            RecordLink.Created := CurrentDateTime;
                            RecordLink."User ID" := HeaderRecordLink."User ID";
                            RecordLink."Link ID" := LinkID;
                            RecordLink."Record ID" := rec_SalesHeader.RecordId;
                            LinkManagement.WriteNote(RecordLink, textWorkDes);
                            RecordLink.Insert(true);
                            Commit();
                        end;
                    end;
                until HeaderRecordLink.Next() = 0;
        end;
    end;

    procedure CopyLinksFromSalesHeaderToEnq(EnqNo: Code[20])
    var
        SourceRecordLink: Record "Record Link";
        textWorkDes: Text;
        rec_notes: record Notes_temp;
        RecordLink, RecordLinkNotes : Record "Record Link";
        LinkManagement: Codeunit "Record Link Management";
        LinkID: Integer;
        rec_SalesHeader: Record "Sales Header";
        rec_EnquiriesHeader: Record Enquiries;
        cdu_Base64: Codeunit "Base64 Convert";
    begin
        RecordLink.Reset();
        rec_notes.DeleteAll();
        SourceRecordLink.Reset();
        Clear(textWorkDes);
        Clear(rec_EnquiriesHeader);

        rec_EnquiriesHeader.SetRange(No, EnqNo);
        if rec_EnquiriesHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_EnquiriesHeader.RecordId);
            if SourceRecordLink.FindSet() then
                repeat
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');

                    if textWorkDes <> '' then begin
                        rec_notes.Init();
                        rec_notes.No := CreateGuid();
                        rec_notes.Notes := textWorkDes;
                        rec_notes."Record Id" := SourceRecordLink."Link ID";
                        rec_notes.Insert();
                        Commit();
                    end;
                until SourceRecordLink.Next() = 0;
        end;


        SourceRecordLink.Reset();
        rec_SalesHeader.Reset();
        RecordLinkNotes.Reset();

        rec_SalesHeader.SetRange("No.", EnqNo);
        if rec_SalesHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_SalesHeader.RecordId);
            if SourceRecordLink.FindSet() then
                repeat
                    if RecordLinkNotes.FindLast() then begin
                        Clear(LinkID);
                        LinkID := RecordLinkNotes."Link ID";
                    end;
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');

                    if textWorkDes <> '' then begin
                        rec_notes.SetRange(Notes, textWorkDes);
                        if not rec_notes.FindSet() then begin
                            LinkID := LinkID + 1;

                            RecordLink.Init();
                            RecordLink.Company := CompanyName();
                            RecordLink.Type := RecordLink.Type::Note;
                            RecordLink.Created := CurrentDateTime;
                            RecordLink."User ID" := SourceRecordLink."User ID";
                            RecordLink."Link ID" := LinkID;
                            RecordLink."Record ID" := rec_EnquiriesHeader.RecordId;
                            LinkManagement.WriteNote(RecordLink, textWorkDes);
                            RecordLink.Insert(true);
                            Commit();
                        end;
                    end;
                until SourceRecordLink.Next() = 0;
        end;
    end;

    procedure CopyLinksFromInvoicePostedToEnq(EnqNo: Code[20])
    var
        SourceRecordLink: Record "Record Link";
        //rec_Enquiries: Record EnquiriesCustomNotes;
        rec_EnquiriesHeader: Record Enquiries;
        textWorkDes: Text;
        rec_notes: record Notes_temp;
        RecordLink, RecordLinkNotes : Record "Record Link";
        LinkManagement: Codeunit "Record Link Management";
        LinkID: Integer;
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        rec_notes.DeleteAll();
        SourceRecordLink.Reset();
        Clear(LinkManagement);
        Clear(textWorkDes);
        RecordLink.Reset();

        rec_EnquiriesHeader.SetRange(No, EnqNo);
        if rec_EnquiriesHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_EnquiriesHeader.RecordId);
            if SourceRecordLink.FindSet() then begin
                repeat
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');


                    if textWorkDes <> '' then begin
                        rec_notes.Init();
                        rec_notes.No := CreateGuid();
                        rec_notes.Notes := textWorkDes;
                        rec_notes."Record Id" := SourceRecordLink."Link ID";
                        rec_notes.Insert();
                        Commit();
                    end;
                until SourceRecordLink.Next() = 0;
            end;
        end;


        rec_SalesInvoiceHeader.Reset();
        RecordLinkNotes.Reset();

        rec_SalesInvoiceHeader.SetRange("Order No.", EnqNo);
        if rec_SalesInvoiceHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_SalesInvoiceHeader.RecordId);
            if SourceRecordLink.FindSet() then
                repeat
                    if RecordLinkNotes.FindLast() then begin
                        Clear(LinkID);
                        LinkID := RecordLinkNotes."Link ID";
                    end;
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');

                    if textWorkDes <> '' then begin
                        rec_notes.SetRange(Notes, textWorkDes);
                        if not rec_notes.FindSet() then begin
                            LinkID := LinkID + 1;

                            RecordLink.Init();
                            RecordLink.Company := CompanyName();
                            RecordLink.Type := RecordLink.Type::Note;
                            RecordLink.Created := CurrentDateTime;
                            RecordLink."User ID" := SourceRecordLink."User ID";
                            RecordLink."Link ID" := LinkID;
                            RecordLink."Record ID" := rec_EnquiriesHeader.RecordId;
                            LinkManagement.WriteNote(RecordLink, textWorkDes);
                            RecordLink.Insert(true);

                            Commit();
                        end;
                    end;
                until SourceRecordLink.Next() = 0;
        end;
    end;

    procedure CopyLinksFromPostedCreditMemoToEnq(EnqNo: Code[20])
    var
        SourceRecordLink: Record "Record Link";
        textWorkDes: Text;
        rec_notes: record Notes_temp;
        RecordLink, RecordLinkNotes : Record "Record Link";
        LinkManagement: Codeunit "Record Link Management";
        LinkID: Integer;
        SalesCreditMemo: Record "Sales Cr.Memo Header";
        rec_EnquiriesHeader: Record Enquiries;
    begin
        rec_notes.DeleteAll();
        SourceRecordLink.Reset();

        rec_EnquiriesHeader.SetRange(No, EnqNo);
        if rec_EnquiriesHeader.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", rec_EnquiriesHeader.RecordId);
            if SourceRecordLink.FindSet() then begin
                repeat
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');

                    if textWorkDes <> '' then begin
                        rec_notes.Init();
                        rec_notes.No := CreateGuid();
                        rec_notes.Notes := textWorkDes;
                        rec_notes."Record Id" := SourceRecordLink."Link ID";
                        rec_notes.Insert();
                    end;
                until SourceRecordLink.Next() = 0;
            end;
        end;

        SalesCreditMemo.Reset();
        RecordLinkNotes.Reset();

        SalesCreditMemo.SetRange("Return Order No.", EnqNo);
        if SalesCreditMemo.FindSet() then begin
            SourceRecordLink.SetRange("Record ID", SalesCreditMemo.RecordId);
            if SourceRecordLink.FindSet() then
                repeat
                    if RecordLinkNotes.FindLast() then begin
                        Clear(LinkID);
                        LinkID := RecordLinkNotes."Link ID";
                    end;
                    textWorkDes := GetWorkDescription(SourceRecordLink);
                    textWorkDes := ReplaceUnicodeCharacters(textWorkDes);
                    textWorkDes := textWorkDes.Replace('', '');
                    textWorkDes := textWorkDes.Replace('Â', '');
                    textWorkDes := textWorkDes.Replace('â‚¬', '€');
                    if textWorkDes <> '' then begin

                        rec_notes.SetRange(Notes, textWorkDes);
                        if not rec_notes.FindSet() then begin
                            LinkID := LinkID + 1;
                            RecordLink.Init();
                            RecordLink.Company := CompanyName();
                            RecordLink.Type := RecordLink.Type::Note;
                            RecordLink.Created := CurrentDateTime;
                            RecordLink."User ID" := SourceRecordLink."User ID";
                            RecordLink."Link ID" := LinkID;
                            RecordLink."Record ID" := rec_EnquiriesHeader.RecordId;

                            LinkManagement.WriteNote(RecordLink, textWorkDes);

                            RecordLink.Insert(true);
                            Commit();
                        end;
                    end;
                until SourceRecordLink.Next() = 0;
        end;
    end;

    procedure GetWorkDescription(SourceRecordLink: Record "Record Link") Note: Text
    var
        MyInStream: InStream;
        TypeHelper: Codeunit "Type Helper";
        myout: OutStream;
    begin
        SourceRecordLink.Calcfields(Note);
        If SourceRecordLink.Note.HasValue() then begin
            SourceRecordLink.Note.CreateInStream(MyInStream, TextEncoding::WINDOWS);
            MyInStream.Read(Note);
        end;
    end;

    procedure ReplaceUnicodeCharacters(Note: Text): Text
    var
        UnicodeReplacementChar: Text;
        NoteAfterReplace: Text;
        Index: Integer;
        CharCode: Integer;
        NotesChar: Char;
    begin
        UnicodeReplacementChar := '';
        for Index := 1 to StrLen(Note) do begin
            NotesChar := Note[Index];
            CharCode := NotesChar;

            // Replace Unicode characters with the replacement character
            if (CharCode <= 31) or (CharCode >= 57344) and (CharCode <= 63743) or (CharCode >= 8960) and (CharCode <= 11135) then
                NoteAfterReplace := NoteAfterReplace + UnicodeReplacementChar
            else begin
                if Index <> 1 then begin
                    NoteAfterReplace := NoteAfterReplace + NotesChar;
                end;
            end;
        end;

        exit(NoteAfterReplace);
    end;
}