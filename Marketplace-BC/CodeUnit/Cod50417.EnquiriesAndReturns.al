codeunit 50417 EnquiriesAndReturns
{
    var
        cdu_CommonHelper: Codeunit CommonHelper;
        recEnquiriesNotes: Record EnquiriesCustomNotes;

    procedure InsertEnquiriesHeader(rec_EnquiryFilter: Record EnquiryFilter; soSessionId: Integer): Dictionary of [Integer, Text]
    var
        recEnquiries: Record Enquiries;
        rec_SalesHeader: Record "Sales Header";
        rec_SalesHeaderArchive: Record "Sales Header Archive";
        enumSalesDocType: Enum "Sales Document Type";
        recEnquiriesLine: Record "Enquiries Line";
        versionNo, element, oldSessionId : Integer;
        SourceRecordLink: Record "Record Link";
        id: RecordId;
        EndTime: DateTime;
        curr_Time, Now : DateTime;
        rec_SalesLines: Record "Sales Line";
        returnHistory: Text;
        cdu_Enquiriesnotes: Codeunit "Enquiries notes";
        recSalesHeader: Record "Sales Header";
        user: Text;
        errorMessageBody: Dictionary of [Integer, Text];
    begin
        user := UserId;
        oldSessionId := 0;
        rec_SalesHeader.Reset();
        recEnquiries.Reset();

        if (rec_EnquiryFilter.userid = user) and (rec_EnquiryFilter.sessionId = soSessionId) then begin
            // repeat

            if rec_EnquiryFilter.SalesOrderArchive = '' then begin
                if rec_EnquiryFilter.ExternalDocNo <> '' then begin
                    rec_SalesHeader.SetRange("External Document No.", rec_EnquiryFilter.ExternalDocNo);
                end;

                if rec_EnquiryFilter.SalesOrderNo <> '' then begin
                    rec_SalesHeader.SetRange("No.", rec_EnquiryFilter.SalesOrderNo);
                end;

                if rec_EnquiryFilter.ShiptoCode <> '' then begin
                    rec_SalesHeader.SetRange("Ship-to Post Code", rec_EnquiryFilter.ShiptoCode);
                end;

                if rec_EnquiryFilter.BillPostCode <> '' then begin
                    rec_SalesHeader.SetRange("Bill-to Post Code", rec_EnquiryFilter.BillPostCode);
                end;

                rec_SalesHeader.SetFilter("Document Type", '%1 | %2', enumSalesDocType::Order, enumSalesDocType::"Return Order");

                if rec_SalesHeader.FindSet() then begin
                    repeat

                        recEnquiries.SetRange(No, rec_SalesHeader."No.");
                        if not recEnquiries.FindSet() then begin

                            recEnquiries.Init();
                            recEnquiries.Id := CreateGuid();
                            recEnquiries.No := rec_SalesHeader."No.";
                            recEnquiries.SessionId := soSessionId;
                            recEnquiries."Sell-to Customer No." := rec_SalesHeader."Bill-to Customer No.";
                            recEnquiries."Sell-to Customer Name" := rec_SalesHeader."Bill-to Name";
                            recEnquiries.Contact := rec_SalesHeader."Bill-to Contact";
                            recEnquiries.Address := rec_SalesHeader."Bill-to Address";
                            recEnquiries."Address 2" := rec_SalesHeader."Bill-to Address 2";
                            recEnquiries.County := rec_SalesHeader."Bill-to County";
                            recEnquiries.Postcode := rec_SalesHeader."Bill-to Post Code";
                            recEnquiries.Country := rec_SalesHeader."Bill-to Country/Region Code";
                            recEnquiries.Email := rec_SalesHeader."Sell-to E-Mail";
                            recEnquiries.Phone := rec_SalesHeader."Sell-to Phone No.";
                            recEnquiries."Sell-to City" := rec_SalesHeader."Bill-to City";

                            recEnquiries."Ship-to-Contact" := rec_SalesHeader."Ship-to Contact";
                            recEnquiries."Ship-to City" := rec_SalesHeader."Ship-to City";
                            recEnquiries."Ship-to County" := rec_SalesHeader."Ship-to County";
                            recEnquiries."Ship-to Post Code" := rec_SalesHeader."Ship-to Post Code";
                            recEnquiries."Ship-to Country" := rec_SalesHeader."Ship-to Country/Region Code";
                            recEnquiries."Ship-to Address" := rec_SalesHeader."Ship-to Address";

                            rec_SalesHeader.CalcFields("Amount Including VAT");

                            recEnquiries."Total Value" := rec_SalesHeader."Amount Including VAT";
                            if rec_SalesHeader."Document Type" = rec_SalesHeader."Document Type"::"Return Order" then begin
                                recEnquiries.History := CopyStr(GetSalesReturnHistory(rec_SalesHeader."No."), 1, 2048);
                            end
                            else begin
                                recEnquiries.History := CopyStr(GetSalesHistory(rec_SalesHeader."No."), 1, 2048);
                            end;

                            recEnquiries.Reference := rec_SalesHeader."Your Reference";
                            recEnquiries.Description := rec_SalesHeader."External Document No.";
                            recEnquiries."Internal Notes" := rec_SalesHeader.customDeliveryNotes;
                            recEnquiries.isArchive := false;
                            recEnquiries.DateCreated := DT2DATE(rec_SalesHeader.SystemCreatedAt);

                            recEnquiries."Sell-to Customer No." := rec_SalesHeader."Sell-to Customer No.";
                            recEnquiries."Location Code" := rec_SalesHeader."Location Code";
                            recEnquiries.Status := rec_SalesHeader.Status;
                            recEnquiries.ShortcutDimension1 := rec_SalesHeader."Shortcut Dimension 1 Code";

                            recEnquiries.Insert(true);
                            Commit();

                            //Custom Notes table to insert order ID

                            recSalesHeader.SetRange("No.", recEnquiries.No);
                            if recSalesHeader.FindSet() then begin
                                recSalesHeader."Enq-Sales RecordId" := recEnquiries.RecordId;
                                recSalesHeader.Modify();
                                Commit();
                            end;

                            recEnquiriesNotes.SetRange(OrderNo, rec_SalesHeader."No.");
                            if not recEnquiriesNotes.FindSet() then begin
                                recEnquiriesNotes.Init();
                                recEnquiriesNotes.OrderNo := rec_SalesHeader."No.";
                                recEnquiriesNotes.Insert(true);
                                Commit();
                            end;

                            InsertSalesLine(rec_SalesHeader, soSessionId, user);
                            Commit();
                            GetCustomeNotes(rec_SalesHeader."No.");
                            Commit();
                        end
                        else begin
                            if recEnquiries.FindFirst() then begin
                                if not errorMessageBody.ContainsKey(oldSessionId) then begin
                                    oldSessionId := recEnquiries.SessionId;
                                    errorMessageBody.Add(oldSessionId, rec_SalesHeader."No.");
                                end;
                            end;
                        end;
                    until rec_SalesHeader.Next() = 0;
                end;
            end;
        end;

        exit(errorMessageBody);
    end;

    procedure InsertSalesLine(recEnquiries: Record "Sales Header"; lineSessionId: Integer; User: Text)
    var
        rec_SalesLine: Record "Sales Line";
        recEnquiriesLine: Record "Enquiries Line";
        enumSalesDocType: Enum "Sales Document Type";
        enquiriesLineSessionId: Integer;
        enquiriesLineUserId: Text;
    begin

        enquiriesLineSessionId := sessionId();
        enquiriesLineUserId := UserId;

        rec_SalesLine.SetRange("Document No.", recEnquiries."No.");
        rec_SalesLine.SetFilter("Document Type", '%1 | %2', enumSalesDocType::Order, enumSalesDocType::"Return Order");
        if rec_SalesLine.FindSet() then begin
            repeat
                recEnquiriesLine.Init();
                recEnquiriesLine.Id := CreateGuid();
                recEnquiriesLine."Line No." := rec_SalesLine."Line No.";
                recEnquiriesLine."No." := rec_SalesLine."No.";
                recEnquiriesLine.SessionId := lineSessionId;
                recEnquiriesLine.Description := rec_SalesLine.Description;
                recEnquiriesLine."Document Type" := rec_SalesLine."Document Type";
                recEnquiriesLine."Document No." := rec_SalesLine."Document No.";
                recEnquiriesLine."Location Code" := rec_SalesLine."Location Code";
                recEnquiriesLine.Quantity := rec_SalesLine.Quantity;
                recEnquiriesLine."Quantity Shipped" := rec_SalesLine."Quantity Shipped";
                recEnquiriesLine."Quantity Invoiced" := rec_SalesLine."Quantity Invoiced";
                recEnquiriesLine.Type := rec_SalesLine.Type;
                recEnquiriesLine."Unit Price" := rec_SalesLine."Unit Price";
                recEnquiriesLine.VAT := rec_SalesLine."Amount Including VAT" - rec_SalesLine."Line Amount";
                recEnquiriesLine.Insert(true);
                Commit();
            until rec_SalesLine.Next() = 0;
        end;

    end;

    procedure InsertSalesLineArchive(recEnquiries: Record Enquiries; versionNo: Integer; archiveSessionId: Integer)
    var
        rec_SalesLineArchive: Record "Sales Line Archive";
        recEnquiriesLine: Record "Enquiries Line";
        recEnquiriesLineB: Record "Enquiries Line";
        enumSalesDocType: Enum "Sales Document Type";
        total: Decimal;
    begin
        total := 0;
        rec_SalesLineArchive.SetRange("Document No.", recEnquiries.No);
        rec_SalesLineArchive.SetFilter("Document Type", '%1 | %2', enumSalesDocType::Order, enumSalesDocType::"Return Order");
        rec_SalesLineArchive.SetRange("Version No.", versionNo);
        if rec_SalesLineArchive.FindSet() then begin
            repeat
                recEnquiriesLine.Init();
                recEnquiriesLine.Id := CreateGuid();
                recEnquiriesLine."Line No." := rec_SalesLineArchive."Line No.";
                recEnquiriesLine."No." := rec_SalesLineArchive."No.";
                recEnquiriesLine.SessionId := archiveSessionId;
                recEnquiriesLine.Description := rec_SalesLineArchive.Description;
                recEnquiriesLine."Document Type" := rec_SalesLineArchive."Document Type";
                recEnquiriesLine."Document No." := rec_SalesLineArchive."Document No.";
                recEnquiriesLine."Location Code" := rec_SalesLineArchive."Location Code";
                recEnquiriesLine.Quantity := rec_SalesLineArchive.Quantity;

                if rec_SalesLineArchive."Quantity Shipped" = 0
                then begin
                    recEnquiriesLine."Quantity Shipped" := rec_SalesLineArchive."Qty. to Ship";
                    recEnquiriesLine."Quantity Invoiced" := rec_SalesLineArchive."Qty. to Invoice";
                end
                else begin
                    recEnquiriesLine."Quantity Shipped" := rec_SalesLineArchive."Quantity Shipped";
                    recEnquiriesLine."Quantity Invoiced" := rec_SalesLineArchive."Quantity Invoiced";
                end;
                recEnquiriesLine.Type := rec_SalesLineArchive.Type;
                recEnquiriesLine."Unit Price" := rec_SalesLineArchive."Unit Price";
                recEnquiriesLine.VAT := rec_SalesLineArchive."Amount Including VAT" - rec_SalesLineArchive."Line Amount";
                recEnquiriesLine.ArchiveLineNo := rec_SalesLineArchive."Line No.";
                recEnquiriesLine.Insert(true);
                Commit();
            //end;
            until rec_SalesLineArchive.Next() = 0;
        end;
    end;


    procedure GetSalesHistory(SalesHeaderNo: code[30]): Text
    var
        rec_SalesShipmentHeader: Record "Sales Shipment Header";
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        rec_PostedInvtPickLine: Record "Posted Invt. Pick Line";
        rec_WarehouseActivityHeader: Record "Warehouse Activity Header";
        rec_SalesArchiveHeader: Record "Sales Header Archive";
        rec_SalesReturnOrder: Record "Sales Header";
        postedInvtPickHeaderNo: Code[20];
        Char1310: Char;
        rec_User: Record User;
        rec_SalesHeader: Record "Sales Header";
        enumSalesDocType: Enum "Sales Document Type";
        reportIdList: list of [Text];
        allHistory, InventoryHistory, OrderNoHistory, ShipmentNoHistory, MethodofDispatch, InvoiceHistoryNotes, ReturnOrderNoHistory, ArchiveReturnOrderHistory, username : Text;
    begin
        Clear(OrderNoHistory);
        Char1310 := 10;
        rec_SalesHeader.SetRange("No.", SalesHeaderNo);
        rec_SalesHeader.SetRange("Document Type", enumSalesDocType::Order);
        if rec_SalesHeader.FindSet() then begin
            username := '';
            username := getUserName(rec_SalesHeader.SystemCreatedBy);
            OrderNoHistory := 'The Sales Order No ' + rec_SalesHeader."No." + ' was created at ' + Format(rec_SalesHeader.SystemCreatedAt) + ' by ' + username + Format(Char1310);
        end
        else begin
            rec_SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
            if rec_SalesInvoiceHeader.FindSet() then begin
                username := '';
                username := getUserName(rec_SalesInvoiceHeader.SystemCreatedBy);
                OrderNoHistory := 'The Sales Order No ' + rec_SalesInvoiceHeader."Order No." + ' was created on ' + Format(rec_SalesInvoiceHeader."Order Date") + ' by ' + username + Format(Char1310);
            end
            else begin
                rec_SalesArchiveHeader.SetRange("No.", SalesHeaderNo);
                if rec_SalesArchiveHeader.FindSet() then begin
                    username := '';
                    username := getUserName(rec_SalesArchiveHeader.SystemCreatedBy);
                    OrderNoHistory := 'The Sales Order No ' + rec_SalesArchiveHeader."No." + ' was created on ' + Format(rec_SalesArchiveHeader.SystemCreatedAt) + ' by ' + username + Format(Char1310);
                end
            end;
        end;

        rec_WarehouseActivityHeader.SetRange("Source No.", SalesHeaderNo);
        if rec_WarehouseActivityHeader.FindSet() then begin
            username := '';
            username := getUserName(rec_WarehouseActivityHeader.SystemCreatedBy);
            InventoryHistory := 'Inventory Picking was ' + rec_WarehouseActivityHeader."No." + ' created at ' + Format(rec_WarehouseActivityHeader.SystemCreatedAt) + ' by ' + username + Format(Char1310);
        end;

        rec_SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
        if rec_SalesInvoiceHeader.FindSet() then begin
            repeat
                username := '';
                username := getUserName(rec_SalesInvoiceHeader.SystemCreatedBy);
                InvoiceHistoryNotes := 'Invoice No: ' + rec_SalesInvoiceHeader."No." + ' was created at ' + Format(rec_SalesInvoiceHeader.SystemCreatedAt) + ' by ' + username + Format(Char1310);
            until rec_SalesInvoiceHeader.Next() = 0;
        end;

        rec_SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
        if rec_SalesInvoiceHeader.FindSet() then begin
            MethodofDispatch := 'Method of Dispatch: ' + rec_SalesInvoiceHeader."Shipping Agent Code" + Format(Char1310);
        end;

        rec_SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
        if rec_SalesInvoiceHeader.FindSet() then begin
            ShipmentNoHistory := 'The Shipping Reference: ' + rec_SalesInvoiceHeader."Package Tracking No." + Format(Char1310);
        end;

        rec_SalesReturnOrder.SetRange("No.", SalesHeaderNo);
        if rec_SalesReturnOrder.FindSet() then begin
            ReturnOrderNoHistory := rec_SalesReturnOrder.ReturnOrderHistory + Format(Char1310);
        end;

        rec_SalesArchiveHeader.SetRange("No.", SalesHeaderNo);
        if rec_SalesArchiveHeader.FindSet() then begin
            ArchiveReturnOrderHistory := rec_SalesArchiveHeader.ReturnOrderHistory + Format(Char1310);
        end;

        allHistory := OrderNoHistory + InvoiceHistoryNotes + InventoryHistory + ShipmentNoHistory + MethodofDispatch + ReturnOrderNoHistory + ArchiveReturnOrderHistory;
        rec_SalesHeader.SetRange("No.", SalesHeaderNo);
        rec_SalesHeader.SetRange("Document Type", enumSalesDocType::Order);
        if rec_SalesHeader.FindSet(true) then begin
            rec_SalesHeader.HistoryNotes := CopyStr(allHistory, 1, 2048);
            rec_SalesHeader.Modify(true);
            Commit();
            exit(rec_SalesHeader.HistoryNotes);
        end;

        rec_SalesArchiveHeader.Reset();
        rec_SalesArchiveHeader.SetRange("No.", SalesHeaderNo);
        rec_SalesArchiveHeader.SetRange("Document Type", enumSalesDocType::Order);
        if rec_SalesArchiveHeader.FindSet(true) then begin
            rec_SalesArchiveHeader.HistoryNotes := CopyStr(allHistory, 1, 2048);
            rec_SalesArchiveHeader.Modify(true);
            Commit();
            exit(rec_SalesArchiveHeader.HistoryNotes);
        end;
    end;


    procedure createSalesReturnOrder(rec: Record Enquiries): Code[20]
    var
        cu_CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ToSalesHeader, ToSalesOrder, ToSalesReturnOrder : Record "Sales Header";
        rec_SalesLines, rec_SalesLineRetuurned : Record "Sales Line";
        enum_DocumentType: Enum "Sales Document Type";
        rec_EnquiriesLine: Record "Enquiries Line";
        rec_Enquiries: Record Enquiries;
        SourceRecordLink: Record "Record Link";
        id: RecordId;
        "Enquiries notes": Codeunit "Enquiries notes";
        OrderNo: Code[20];
        textWorkDes: Text;
    begin
        ToSalesReturnOrder.Init();
        ToSalesReturnOrder.InitRecord;
        ToSalesReturnOrder."Document Type" := enum_DocumentType::"Return Order";
        ToSalesReturnOrder.Insert(true);
        Commit();

        ToSalesReturnOrder.SetRange("Document Type", enum_DocumentType::"Return Order");
        ToSalesReturnOrder.SetRange("No.", ToSalesReturnOrder."No.");
        if ToSalesHeader.FindFirst() then begin
            if not rec.isArchive then begin
                cu_CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
                cu_CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, rec.No, ToSalesReturnOrder);
                rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                if rec_EnquiriesLine.FindSet() then begin
                    SourceRecordLink.SetRange("Record ID", Rec.RecordId);
                    if SourceRecordLink.FindSet() then begin
                        if Rec.HasLinks = true then begin
                            ToSalesReturnOrder.CopyLinks(Rec);
                            OrderNo := rec.No;
                            AddReturnOrderHistoryToEnquiry(OrderNo, ToSalesReturnOrder."No.", ToSalesReturnOrder.SystemCreatedAt);
                            // end;
                        end;
                    end;
                    PAGE.Run(PAGE::"Sales Return Order", ToSalesReturnOrder);
                end
            end
            else begin
                cu_CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
                cu_CopyDocumentMgt.SetArchDocVal(rec.ArchieveOccurrence, rec.ArchieveVersionNo);
                cu_CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Arch. Order", rec.No, ToSalesReturnOrder);
                rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                if rec_EnquiriesLine.FindSet() then begin
                    SourceRecordLink.SetRange("Record ID", Rec.RecordId);
                    if SourceRecordLink.FindSet() then begin
                        if Rec.HasLinks = true then begin
                            ToSalesReturnOrder.CopyLinks(Rec);
                            OrderNo := rec.No;
                            ArchieveReturnOrderHistoryToEnquiry(OrderNo, ToSalesReturnOrder."No.", ToSalesReturnOrder.SystemCreatedAt);
                        end;
                    end;
                    PAGE.Run(PAGE::"Sales Return Order", ToSalesReturnOrder);
                end;
            end;
        end;
        exit(ToSalesReturnOrder."No.");
    end;

    procedure createNewSalesOrder(rec: Record Enquiries): Code[20]
    var
        cu_CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ToSalesHeader, ToSalesOrder, ToSalesReturnOrder : Record "Sales Header";
        rec_SalesLines, rec_SalesLineRetuurned : Record "Sales Line";
        enum_DocumentType: Enum "Sales Document Type";
        rec_EnquiriesLine: Record "Enquiries Line";
        rec_Enquiries: Record Enquiries;
        SourceRecordLink: Record "Record Link";
        id: RecordId;
    begin
        ToSalesHeader.Init();
        ToSalesHeader.InitRecord;
        ToSalesHeader."Document Type" := enum_DocumentType::Order;
        ToSalesOrder.InitialSalesOrderNumber := Rec.No;
        ToSalesHeader.Insert(true);

        ToSalesHeader.SetRange("Document Type", enum_DocumentType::Order);
        ToSalesHeader.SetRange("No.", ToSalesHeader."No.");

        if ToSalesHeader.FindFirst() then begin
            if not rec.isArchive then begin
                cu_CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
                cu_CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Order, rec.No, ToSalesHeader);
                rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                if rec_EnquiriesLine.FindSet() then begin
                    SourceRecordLink.SetRange("Record ID", Rec.RecordId);
                    if SourceRecordLink.FindSet() then begin
                        if Rec.HasLinks = true then
                            ToSalesHeader.CopyLinks(Rec);
                    end;
                    //PAGE.Run(PAGE::"Sales Order", ToSalesHeader);
                end
            end
            else begin
                cu_CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
                cu_CopyDocumentMgt.SetArchDocVal(rec.ArchieveOccurrence, rec.ArchieveVersionNo);
                cu_CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Arch. Order", rec.No, ToSalesHeader);
                rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                if rec_EnquiriesLine.FindSet() then begin
                    SourceRecordLink.SetRange("Record ID", Rec.RecordId);
                    if SourceRecordLink.FindSet() then begin
                        if Rec.HasLinks = true then
                            ToSalesHeader.CopyLinks(Rec);
                    end;
                    //PAGE.Run(PAGE::"Sales Order", ToSalesHeader);
                end;
            end;
        end;
        exit(ToSalesHeader."No.");
    end;

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

    procedure SendEmail(Rec_Enquries: Record Enquiries; SalesOrderNo: Code[20])
    var
        cdu_EmailMessage: Codeunit "Email Message";
        cdu_Email: Codeunit Email;
        ToRecipients: Text;
        Subject: Text;
        Body, AddBody : Text;
        enum_RecipientType: Enum "Email Recipient Type";
        rec_salesheader: Record "Sales Header";
        enum_DocumentType: Enum "Sales Document Type";
        recEmailInternalPO: Record "MarketPlace Email Setup";
        enumalerts: Enum MarketPlaceAlerts;
        recSalesHeader: Record "Sales Header";
    begin
        Clear(recSalesHeader);

        Subject := 'Mispick Alert';
        Body += '<style>table, th, td {border:1px solid #999999;border-collapse: collapse;text-align:left;}th{padding:5px;background:#ccc;}td{padding:5px;}</style>';
        Body += '<tr>';
        Body += '<table border="1">';
        Body += '<th>Order Number</th>';
        Body += '<th>Order Origin</th>';
        Body += '<th>Mispick Note</th>';
        Body += '</tr>';
        Body += '</tr>';

        recSalesHeader.SetRange("No.", SalesOrderNo);
        rec_SalesHeader.SetRange("Document Type", enum_DocumentType::Order);
        if recSalesHeader.FindSet() then begin
            Body += '<tr>';
            Body += STRSUBSTNO('<td>%1</td>', SalesOrderNo);
            Body += STRSUBSTNO('<td>%1</td>', recSalesHeader.Source);
            Body += STRSUBSTNO('<td>%1</td>', Rec_Enquries.Comment + ' Mispick Created From Order ' + Rec_Enquries.No);
            Body += '</tr>';
        end;

        Body += '</table>';
        Body += '<br><br>Kind Regards,<br><br>Business Central';
        cdu_EmailMessage.Create(cdu_CommonHelper.MarketplaceEmailSetup(enumalerts::"EnquiriesAndReturns"), Subject, Body, true);
        if recSalesHeader.Count > 0 then begin
            cdu_Email.Send(cdu_EmailMessage);
        end;
    end;

    procedure InsertArchiveOrder(rec_EnquiryFilter: Record EnquiryFilter; archiveSessionID: Integer): Dictionary of [Integer, Text]
    var
        recEnquiries: Record Enquiries;
        // rec_SalesHeader: Record "Sales Header";
        rec_SalesHeaderArchive: Record "Sales Header Archive";
        enumSalesDocType: Enum "Sales Document Type";
        recEnquiriesLine: Record "Enquiries Line";
        versionNo, element, oldSessionId : Integer;
        SourceRecordLink: Record "Record Link";
        id: RecordId;
        EndTime: DateTime;
        curr_Time, Now : DateTime;
        rec_SalesLines: Record "Sales Line";
        returnHistory: Text;
        cdu_Enquiriesnotes: Codeunit "Enquiries notes";
        user: text;
        errorMessageBody: Dictionary of [Integer, Text];
    begin
        user := UserId;
        rec_SalesHeaderArchive.Reset();
        recEnquiries.Reset();

        if (rec_EnquiryFilter.userid = user) and (rec_EnquiryFilter.sessionId = archiveSessionID) then begin
            //  repeat
            if rec_EnquiryFilter.SalesOrderNo = '' then begin
                if rec_EnquiryFilter.ExternalDocNo <> '' then begin
                    rec_SalesHeaderArchive.SetRange("External Document No.", rec_EnquiryFilter.ExternalDocNo);
                end;

                if rec_EnquiryFilter.SalesOrderArchive <> '' then begin
                    rec_SalesHeaderArchive.SetRange("No.", rec_EnquiryFilter.SalesOrderArchive);
                end;

                if rec_EnquiryFilter.ShiptoCode <> '' then begin
                    rec_SalesHeaderArchive.SetRange("Ship-to Post Code", rec_EnquiryFilter.ShiptoCode);
                end;

                if rec_EnquiryFilter.BillPostCode <> '' then begin
                    rec_SalesHeaderArchive.SetRange("Bill-to Post Code", rec_EnquiryFilter.BillPostCode);
                end;

                rec_SalesHeaderArchive.SetFilter("Document Type", '%1 | %2', enumSalesDocType::Order, enumSalesDocType::"Return Order");
                if rec_SalesHeaderArchive.FindSet() then begin
                    repeat
                        rec_SalesHeaderArchive.CalcFields("No. of Archived Versions");
                        rec_SalesHeaderArchive.CalcFields("Source Doc. Exists");
                        versionNo := rec_SalesHeaderArchive."No. of Archived Versions";
                        if (rec_SalesHeaderArchive."No. of Archived Versions" = rec_SalesHeaderArchive."Version No.") and (rec_SalesHeaderArchive."Source Doc. Exists" = false) then begin

                            recEnquiries.SetRange(No, rec_SalesHeaderArchive."No.");
                            if not recEnquiries.FindSet() then begin
                                recEnquiries.Reset();
                                recEnquiries.Init();
                                recEnquiries.Id := CreateGuid();
                                recEnquiries.No := rec_SalesHeaderArchive."No.";
                                recEnquiries.SessionId := archiveSessionID;
                                recEnquiries."Sell-to Customer No." := rec_SalesHeaderArchive."Bill-to Customer No.";
                                recEnquiries."Sell-to Customer Name" := rec_SalesHeaderArchive."Bill-to Name";
                                recEnquiries.Contact := rec_SalesHeaderArchive."Bill-to Contact";
                                recEnquiries.Address := rec_SalesHeaderArchive."Bill-to Address";
                                recEnquiries."Address 2" := rec_SalesHeaderArchive."Bill-to Address 2";
                                recEnquiries.County := rec_SalesHeaderArchive."Bill-to County";
                                recEnquiries.Postcode := rec_SalesHeaderArchive."Bill-to Post Code";
                                recEnquiries.Country := rec_SalesHeaderArchive."Bill-to Country/Region Code";
                                recEnquiries.Email := rec_SalesHeaderArchive."Sell-to E-Mail";
                                recEnquiries.Phone := rec_SalesHeaderArchive."Sell-to Phone No.";
                                recEnquiries."Sell-to City" := rec_SalesHeaderArchive."Bill-to City";

                                recEnquiries."Ship-to-Contact" := rec_SalesHeaderArchive."Ship-to Contact";
                                recEnquiries."Ship-to City" := rec_SalesHeaderArchive."Ship-to City";
                                recEnquiries."Ship-to County" := rec_SalesHeaderArchive."Ship-to County";
                                recEnquiries."Ship-to Country" := rec_SalesHeaderArchive."Ship-to Country/Region Code";
                                recEnquiries."Ship-to Post Code" := rec_SalesHeaderArchive."Ship-to Post Code";
                                recEnquiries."Ship-to Address" := rec_SalesHeaderArchive."Ship-to Address";
                                recEnquiries."Internal Notes" := rec_SalesHeaderArchive.customDeliveryNotes;

                                rec_SalesHeaderArchive.CalcFields("Amount Including VAT");
                                recEnquiries."Total Value" := rec_SalesHeaderArchive."Amount Including VAT";

                                if rec_SalesHeaderArchive."Document Type" = rec_SalesHeaderArchive."Document Type"::"Return Order" then begin
                                    recEnquiries.History := CopyStr(GetSalesReturnHistory(rec_SalesHeaderArchive."No."), 1, 2048);
                                end
                                else begin
                                    recEnquiries.History := CopyStr(GetSalesHistory(rec_SalesHeaderArchive."No."), 1, 2048);
                                end;

                                recEnquiries.Reference := rec_SalesHeaderArchive."Your Reference";
                                recEnquiries.Description := rec_SalesHeaderArchive."External Document No.";
                                recEnquiries.isArchive := true;
                                recEnquiries."Location Code" := rec_SalesHeaderArchive."Location Code";
                                recEnquiries.Status := rec_SalesHeaderArchive.Status;
                                recEnquiries.ArchieveVersionNo := rec_SalesHeaderArchive."Version No.";
                                recEnquiries.ArchieveOccurrence := rec_SalesHeaderArchive."Doc. No. Occurrence";
                                recEnquiries.DateCreated := DT2DATE(rec_SalesHeaderArchive.SystemCreatedAt);
                                recEnquiries.ShortcutDimension1 := rec_SalesHeaderArchive."Shortcut Dimension 1 Code";
                                recEnquiries.Insert(true);
                                Commit();

                                //Custom Notes table to insert order no
                                recEnquiriesNotes.SetRange(OrderNo, rec_SalesHeaderArchive."No.");
                                if not recEnquiriesNotes.FindSet() then begin
                                    recEnquiriesNotes.Init();
                                    recEnquiriesNotes.OrderNo := rec_SalesHeaderArchive."No.";
                                    recEnquiriesNotes.Insert(true);
                                    Commit();
                                end;

                                InsertSalesLineArchive(recEnquiries, versionNo, archiveSessionID);
                                Commit();
                                GetCustomeNotesFromArchive(recEnquiries.No, versionNo);
                                Commit();
                            end
                            else begin
                                if recEnquiries.FindFirst() then begin
                                    if not errorMessageBody.ContainsKey(oldSessionId) then begin
                                        oldSessionId := recEnquiries.SessionId;
                                        errorMessageBody.Add(oldSessionId, rec_SalesHeaderArchive."No.");
                                    end;
                                end;
                            end;
                        end;
                    until rec_SalesHeaderArchive.next() = 0;
                end;
            end;
        end;
        exit(errorMessageBody);
    end;

    procedure AddReturnOrderHistoryToEnquiry(OrderNo: Code[20]; ReturnOrderNo: Code[20]; CreatedAt: DateTime)
    var
        recEnquiry: Record Enquiries;
        recSalesHeader: Record "Sales Header";
        Char1310: Char;
        username: Text;
    begin
        Char1310 := 10;
        recEnquiry.SetRange(No, OrderNo);
        if recEnquiry.FindSet(true) then begin
            recSalesHeader.SetRange("No.", OrderNo);
            if recSalesHeader.FindSet(true) then begin
                username := '';
                username := getUserName(recSalesHeader.SystemCreatedBy);
                recSalesHeader.ReturnOrderHistory := CopyStr(recSalesHeader.ReturnOrderHistory + 'The Return Order No. ' + ReturnOrderNo + ' was created by ' + username + Format(Char1310), 1, 2048);
                recSalesHeader.Modify(true);
                Commit();
            end;
        end;
    end;

    procedure ArchieveReturnOrderHistoryToEnquiry(OrderNo: Code[20]; ReturnOrderNo: Code[20]; CreatedAt: DateTime)
    var
        recEnquiry: Record Enquiries;
        recSalesHeaderArchive: Record "Sales Header Archive";
        Char1310: Char;
        username: Text;
    begin
        Char1310 := 10;
        recEnquiry.SetRange(No, OrderNo);
        if recEnquiry.FindSet(true) then begin
            recSalesHeaderArchive.SetRange("No.", OrderNo);
            if recSalesHeaderArchive.FindSet(true) then begin
                username := '';
                username := getUserName(recSalesHeaderArchive.SystemCreatedBy);
                recSalesHeaderArchive.ReturnOrderHistory := CopyStr(recSalesHeaderArchive.ReturnOrderHistory + 'The Return Order No. ' + ReturnOrderNo + ' was created by ' + username + Format(Char1310), 1, 2048);
                recSalesHeaderArchive.Modify(true);
                Commit();
            end;
        end;
    end;

    procedure GetCustomeNotes(OrderNo: Code[20])
    var
        recSalesHeader: Record "Sales Header";
        RecordLink: Record "Record Link";
        cdu_Notes: Codeunit "Enquiries notes";
        rec_EnquiryNotes: Record EnquiriesCustomNotes;
        rec_notes: Record Notes_temp;
        recEnquiries: Record Enquiries;
        cdu_CutomeNotes: Codeunit "Enquiries Custom notes";
        en_doctype: Enum "Sales Document Type";
    begin
        RecordLink.Reset();
        recEnquiries.Reset();
        rec_EnquiryNotes.Reset();
        Clear(cdu_Notes);

        recEnquiries.SetRange(No, OrderNo);
        if recEnquiries.FindSet() then begin
            if recEnquiries.HasLinks = true then begin
                cdu_CutomeNotes.CopyLinksFromSalesHeaderToEnq(recEnquiries.No);
                Commit();
            end
            else begin
                recSalesHeader.SetRange("No.", recEnquiries.No);
                if recSalesHeader.FindSet() then begin
                    cdu_Notes.CopyHistoryNotesToEnquiriesNotes(recEnquiries.No);
                    recEnquiries.CopyLinks(recSalesHeader);
                    Commit();
                end;
            end
        end;
    end;

    procedure GetCustomeNotesFromArchive(SalesOrderNo: Code[20]; VersionNo: Integer);
    var
        recSalesHeaderArchive: Record "Sales Header Archive";
        recRecordLine: Record "Record Link";
        SourceRecordLink, RecordLink : Record "Record Link";
        cdu_Notes: Codeunit "Enquiries notes";
        rec_notes: Record Notes_temp;
        recEnquiries: Record Enquiries;
        //  rec_EnquiryNotes: Record EnquiriesCustomNotes;
        cdu_CutomeNotes: Codeunit "Enquiries Custom notes";
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesCreditHeader: Record "Sales Cr.Memo Header";
        en_doctype: Enum "Sales Document Type";
    begin
        recRecordLine.Reset();
        Clear(cdu_Notes);
        recEnquiries.Reset();

        recEnquiries.SetRange(No, SalesOrderNo);
        if recEnquiries.FindSet() then begin

            if recEnquiries.HasLinks = true then begin
                cdu_CutomeNotes.CopyLinksFromInvoicePostedToEnq(recEnquiries.No);
                cdu_CutomeNotes.CopyLinksFromPostedCreditMemoToEnq(recEnquiries.No);
                Commit();
            end
            else begin
                recSalesHeaderArchive.Reset();
                rec_SalesInvoiceHeader.Reset();
                recSalesHeaderArchive.SetRange("No.", recEnquiries.No);
                recSalesHeaderArchive.SetRange("Version No.", VersionNo);
                if recSalesHeaderArchive.FindSet() then begin
                    cdu_Notes.CopyHistoryNotesToEnquiriesNotes(recEnquiries.No);

                    rec_SalesInvoiceHeader.SetRange("Order No.", recEnquiries.No);
                    if rec_SalesInvoiceHeader.FindSet() then begin
                        recEnquiries.CopyLinks(rec_SalesInvoiceHeader);
                    end;

                    if recSalesHeaderArchive."Document Type" = en_doctype::"Return Order" then begin
                        rec_SalesCreditHeader.SetRange("Return Order No.", recSalesHeaderArchive."No.");
                        if rec_SalesCreditHeader.FindSet() then begin
                            recEnquiries.CopyLinks(rec_SalesCreditHeader);
                        end;
                    end;
                    Commit();
                end;
            end;
        end;
    end;

    procedure GetSalesReturnHistory(SalesReturnNo: code[20]): Text
    var
        rec_SalesCrMemo: Record "Sales Cr.Memo Header";
        Char1310: Char;
        rec_SalesHeader: Record "Sales Header";
        enumSalesDocType: Enum "Sales Document Type";
        ReturnOrderHistory, retunrOrderNoHistory, ShipmentNoHistory, MethodofDispatch, ReturnInvoiceHistoryNotes, username : Text;
    begin
        Char1310 := 10;
        rec_SalesHeader.SetRange("No.", SalesReturnNo);
        rec_SalesHeader.SetRange("Document Type", enumSalesDocType::"Return Order");
        if rec_SalesHeader.FindSet() then begin
            username := '';
            username := getUserName(rec_SalesHeader.SystemCreatedBy);
            retunrOrderNoHistory := 'The Return Order No ' + rec_SalesHeader."No." + ' was created at ' + Format(rec_SalesHeader.SystemCreatedAt) + ' by ' + username + Format(Char1310);
        end
        else begin
            rec_SalesCrMemo.SetRange("Return Order No.", SalesReturnNo);
            if rec_SalesCrMemo.FindSet() then begin
                username := '';
                username := getUserName(rec_SalesCrMemo.SystemCreatedBy);
                retunrOrderNoHistory := 'The Return Order No ' + rec_SalesCrMemo."Return Order No." + ' was created at ' + Format(rec_SalesCrMemo.SystemCreatedAt) + ' by ' + username + Format(Char1310);
            end;
        end;

        rec_SalesCrMemo.SetRange("Return Order No.", SalesReturnNo);
        if rec_SalesCrMemo.FindSet() then begin
            repeat
                username := '';
                username := getUserName(rec_SalesCrMemo.SystemCreatedBy);
                ReturnInvoiceHistoryNotes := 'Invoice No: ' + rec_SalesCrMemo."No." + ' at ' + Format(rec_SalesCrMemo.SystemCreatedAt) + ' by ' + username + Format(Char1310);
            until rec_SalesCrMemo.Next() = 0;
        end;

        rec_SalesCrMemo.SetRange("Return Order No.", SalesReturnNo);
        if rec_SalesCrMemo.FindSet() then begin
            repeat
                MethodofDispatch := 'Method of Dispatch: ' + rec_SalesCrMemo."Shipping Agent Code" + Format(Char1310);
            until rec_SalesCrMemo.Next() = 0;
        end;

        rec_SalesCrMemo.SetRange("Return Order No.", SalesReturnNo);
        if rec_SalesCrMemo.FindSet() then begin
            repeat
                ShipmentNoHistory := 'The Shipping Reference: ' + rec_SalesCrMemo."Package Tracking No." + Format(Char1310);
            until rec_SalesCrMemo.Next() = 0;
        end;
        ReturnOrderHistory := retunrOrderNoHistory + ReturnInvoiceHistoryNotes + MethodofDispatch + ShipmentNoHistory;
        exit(ReturnOrderHistory);
    end;

    procedure getUserName(userGuid: Guid): Text
    var
        userName: text;
        recUser: Record User;
    begin
        userName := '';
        recUser.SetRange("User Security ID", userGuid);
        if recUser.Findset() then begin
            userName := recUser."Full Name";
            exit(userName);
        end;
    end;

    procedure CancelReservation(rec_DisplayFilterData: Record "Sales Line")
    var
        rec_ReservEntry: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        rec_ReservEntry.SetRange("Source ID", rec_DisplayFilterData."Document No.");
        rec_ReservEntry.SetRange("Location Code", rec_DisplayFilterData."Location Code");
        rec_ReservEntry.SetRange("Item No.", rec_DisplayFilterData."No.");
        if rec_ReservEntry.FindSet() then
            repeat
                ReservEngineMgt.CancelReservation(rec_ReservEntry);
                Commit();
            until rec_ReservEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopySalesLine', '', false, false)]
    local procedure OnBeforeCopySalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; MoveNegLines: Boolean; var Result: Boolean; var IsHandled: Boolean; DocLineNo: Integer)
    var
        RecEnquiriesLine: Record "Enquiries Line";
    begin
        RecEnquiriesLine.Reset();

        RecEnquiriesLine.SetRange("Document No.", FromSalesLine."Document No.");
        RecEnquiriesLine.SetRange("Line No.", FromSalesLine."Line No.");
        RecEnquiriesLine.SetFilter("Return/Replace", '=%1', 0);
        if RecEnquiriesLine.FindFirst() then begin
            FromSalesLine.Quantity := RecEnquiriesLine.Quantity;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopyArchSalesLine', '', false, false)]
    local procedure OnBeforeCopyArcSalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    var
        RecEnquiriesLine: Record "Enquiries Line";
    begin
        RecEnquiriesLine.Reset();

        RecEnquiriesLine.SetRange("Document No.", FromSalesLineArchive."Document No.");
        RecEnquiriesLine.SetRange("Line No.", FromSalesLineArchive."Line No.");
        RecEnquiriesLine.SetFilter("Return/Replace", '=%1', 0);
        if RecEnquiriesLine.FindFirst() then begin
            CopyThisLine := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopyFieldsFromOldSalesHeader', '', false, false)]
    local procedure OnBeforeCopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.InitialSalesOrderNumber := OldSalesHeader."No.";
    end;

}