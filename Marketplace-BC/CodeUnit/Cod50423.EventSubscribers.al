codeunit 50423 EventSubscribers
{
    Permissions = TableData "Item Ledger Entry" = rimd, TableData "Value Entry" = rimd, tabledata "Item Application Entry" = rimd;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post (Yes/No)", 'OnAfterPost', '', false, false)]
    local procedure OnAfterPost(SalesHeader: Record "Sales Header");
    var
        "Document Type": Enum "Sales Document Type";
        URL: Text;
        rec_ReturnReceiptLine: Record "Return Receipt Line";
        rec_item: Record Item;
        cu_refund: Codeunit RefundNotes;
        recBraintreeSettings: Record "Braintree Setting";
        pageDisplayURL: page DisplayUrl;
        cu_RefundProcess: Codeunit RefundProcess;
    begin
        URL := '';

        if ((SalesHeader."Document Type" = "Document Type"::"Return Order") and (SalesHeader.isRefund = true)) then begin

            if recBraintreeSettings.FindSet() then begin

                if (recBraintreeSettings.Refund = true) then begin

                    if SalesHeader.Source = "Order Source"::Amazon then begin
                        URL := 'https://sellercentral.amazon.co.uk/orders-v3/order/' + SalesHeader."External Document No." + '?ref=orddet&mons_sel_mkid=amzn1.mp.o.A1F83G8C2ARO7P&mons_sel_mcid=amzn1.merchant.o.AAGBKF49IVH4X&mons_sel_persist=true&stck=EU';
                        pageDisplayURL.CreateAmazonLink(URL);
                        pageDisplayURL.Run();
                    end;

                    if SalesHeader.Source = "Order Source"::"B&Q" then begin
                        cu_RefundProcess.ConnectBQRefundPaymentApi(SalesHeader, EnhIntegrationLogTypes::"B&Q");
                    end;

                    if SalesHeader.Source = "Order Source"::eBay then begin
                        cu_RefundProcess.ConnecteBayRefundPaymentApi(SalesHeader, EnhIntegrationLogTypes::Ebay);
                    end;

                    if SalesHeader.Source = "Order Source"::OnBuy then begin
                        cu_RefundProcess.ConnectOnBuyRefundPaymentApi(SalesHeader, EnhIntegrationLogTypes::OnBuy);
                    end;

                    if SalesHeader."Payment Method Code" = 'PAYPAL' then begin
                        cu_RefundProcess.ConnectPaymentApi(SalesHeader, EnhIntegrationLogTypes::PayPal);
                    end;

                    if SalesHeader."Payment Method Code" = 'BRAINTREE' then begin
                        cu_RefundProcess.ConnectPaymentApi(SalesHeader, EnhIntegrationLogTypes::Braintree);
                    end;

                    cu_refund.RefundNotesOnCreditMemo(SalesHeader);

                end
                else begin
                    Message('The Refund to Provider setting is turned off.');
                end;
            end;
        end;

        rec_ReturnReceiptLine.SetRange("Return Order No.", SalesHeader."No.");

        if rec_ReturnReceiptLine.FindSet() then begin
            repeat
                if not (rec_ReturnReceiptLine."No." = 'CARRIAGE') then begin
                    if not (rec_ReturnReceiptLine."No." = 'RETURNCHARGE') or (rec_ReturnReceiptLine."No." = 'RETURNCOLLECT') or (rec_ReturnReceiptLine."No." = 'CARRIAGE') then begin
                        if not (rec_ReturnReceiptLine."No." = 'RETURNCOLLECT') then begin
                            ItemJournalPost(rec_ReturnReceiptLine, rec_item);
                        end;
                    end;
                end
            until rec_ReturnReceiptLine.Next() = 0;
        end;

        rec_ReturnReceiptLine.SetRange("Return Order No.", SalesHeader."No.");
        if rec_ReturnReceiptLine.FindSet() then begin
            repeat
                if (rec_ReturnReceiptLine."No." = 'RETURNCHARGE') or (rec_ReturnReceiptLine."No." = 'RETURNCOLLECT') then begin
                    DeleteItemLedgerEntry(rec_ReturnReceiptLine."No.");
                end;
            until rec_ReturnReceiptLine.Next() = 0;
        end;
    end;

    local procedure DeleteItemLedgerEntry(itemNo: code[20])
    var
        rec_ItemLedgerEntry: Record "Item Ledger Entry";
        enumItemLedgerDocumentType: Enum "Item Ledger Document Type";
        rec_ApplicationEntry: Record "Item Application Entry";
        rec_valueEntry: Record "Value Entry";
    begin
        if (itemNo = 'RETURNCHARGE') or (itemNo = 'RETURNCOLLECT') then begin
            rec_ItemLedgerEntry.SetRange("Item No.", itemNo);
            rec_ItemLedgerEntry.SetRange("Document Type", enumItemLedgerDocumentType::"Sales Return Receipt");
            if rec_ItemLedgerEntry.FindSet() then begin
                //value entry delete
                rec_valueEntry.SetRange("Item Ledger Entry No.", rec_ItemLedgerEntry."Entry No.");
                rec_valueEntry.DeleteAll();

                //application entry delete
                rec_ApplicationEntry.SetRange("Item Ledger Entry No.", rec_ItemLedgerEntry."Entry No.");
                rec_ApplicationEntry.DeleteAll();

                //item ledger delete
                rec_ItemLedgerEntry.DeleteAll();
            end;
        end;
    end;

    procedure ItemJournalPost(recSalesLine: Record "Return Receipt Line"; rec_item: Record Item)
    var
        GLPost: Codeunit "Item Jnl.-Post Line";
        Line: Record "Item Journal Line";
    begin
        rec_item.SetRange("No.", recSalesLine."No.");
        if rec_item.FindSet() then begin
            Line.Init();
            line."Line No." := 10000;
            Line."Posting Date" := TODAY();
            Line."Entry Type" := Line."Entry Type"::"Negative Adjmt.";
            Line."Gen. Prod. Posting Group" := recSalesLine."Gen. Prod. Posting Group";
            line."Journal Template Name" := 'ITEM';
            Line."Document No." := recSalesLine."Document No.";
            Line."Item No." := recSalesLine."No.";
            Line.Validate("Item No.");
            Line.Description := recSalesLine.Description;
            Line.Validate(Description);
            Line."Reason Code" := 'ZRETURNS';
            Line."Return Reason Code" := recSalesLine."Return Reason Code";
            Line.Validate("Return Reason Code");
            Line."Location Code" := recSalesLine."Location Code";
            Line.Validate("Location Code");
            Line.Quantity := recSalesLine.Quantity;
            Line.Validate(Quantity);
            Line."Unit Amount" := rec_item."Unit Cost";
            Line.Validate("Unit Amount");
            Line."Shortcut Dimension 1 Code" := recSalesLine."Shortcut Dimension 1 Code";
            Line.Validate("Shortcut Dimension 1 Code");
            Line."Shortcut Dimension 2 Code" := recSalesLine."Shortcut Dimension 2 Code";
            Line.Validate("Shortcut Dimension 2 Code");
            GLPost.RunWithCheck(Line);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforePerformManualReleaseProcedure', '', false, false)]
    local procedure Test(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    var
        recSalesOrderArchive: Record "Sales Header Archive";
        recSalesLineArchive: Record "Sales Line Archive";
        recSalesLine: Record "Sales Line";
        returnAmount, ActualAmount : Decimal;
        cuReleaseSalesDoc: Codeunit "Release Sales Document";
    begin

        Clear(returnAmount);
        Clear(ActualAmount);

        recSalesOrderArchive.Reset();
        recSalesLineArchive.Reset();
        recSalesLine.Reset();

        if SalesHeader.isRefund = true then begin

            recSalesLine.SetRange("Document No.", SalesHeader."No.");
            recSalesLine.SetRange("Document Type", "Sales Document Type"::"Return Order");
            if recSalesLine.FindSet() then
                repeat
                    returnAmount := returnAmount + recSalesLine."Amount Including VAT";
                    SalesHeader.RefundAmount := returnAmount;

                    recSalesOrderArchive.SetRange("Document Type", "Sales Document Type"::Order);
                    recSalesOrderArchive.SetRange("No.", SalesHeader.InitialSalesOrderNumber);
                    if recSalesOrderArchive.FindSet() then
                        repeat

                            recSalesOrderArchive.CalcFields("No. of Archived Versions");

                            if recSalesOrderArchive."No. of Archived Versions" = recSalesOrderArchive."Version No." then begin

                                recSalesLineArchive.SetRange("Document No.", recSalesOrderArchive."No.");
                                recSalesLineArchive.SetRange("Line No.", recSalesLine.ArchiveLineNo);
                                recSalesLineArchive.SetRange("No.", recSalesLine."No.");
                                recSalesLineArchive.SetRange("Version No.", recSalesOrderArchive."No. of Archived Versions");

                                if recSalesLineArchive.FindSet() then
                                    repeat
                                        ActualAmount := ActualAmount + ((recSalesLineArchive."Amount Including VAT" / recSalesLineArchive.Quantity) * recSalesLine.Quantity);
                                        SalesHeader.ActualAmountToRefund := ActualAmount;
                                    until recSalesLineArchive.Next() = 0;
                            end;
                        until recSalesOrderArchive.Next() = 0;
                until recSalesLine.Next() = 0;


            if returnAmount > ActualAmount then begin
                Message('You should not be able to refund more than was initially paid');
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnBeforePerformManualReleaseProcedure', '', false, false)]
    local procedure setForceUpdate(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    var
        recSalesLine: Record "Sales Line";
        cuReleaseSalesDoc: Codeunit "Release Sales Document";
        recEbayItemList: Record EbayItemsList;
        recWarehouse: Record "Warehouse Activity Header";
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;

    begin
        recWarehouse.Reset();
        recWarehouse.SetRange("Source No.", SalesHeader."No.");

        if not recWarehouse.FindSet() then begin

            recSalesLine.Reset();
            recSalesLine.SetRange("Document No.", SalesHeader."No.");
            recSalesLine.SetRange("Document Type", "Sales Document Type"::Order);
            if recSalesLine.FindSet() then begin
                repeat
                    recEbayItemList.Reset();
                    recEbayItemList.SetRange("No.", recSalesLine."No.");
                    if recEbayItemList.FindFirst() then begin

                        if recEbayItemList.Listing_ID <> '' then begin
                            recEbayItemList.ForceUpdate := true;
                            recEbayItemList.Modify(true);
                        end;
                    end;

                    recAmazonItemsStockLevel.Reset();
                    recAmazonItemsStockLevel.SetRange(ItemNo, recSalesLine."No.");
                    if recAmazonItemsStockLevel.FindFirst() then begin
                        recAmazonItemsStockLevel.isSent := false;
                        recAmazonItemsStockLevel.Modify(true);
                    end;
                until recSalesLine.Next() = 0;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post", 'OnCodeOnBeforeItemJnlPostBatchRun', '', false, false)]
    procedure OnCodeOnBeforeItemJnlPostBatchRun(var ItemJournalLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        if ItemJournalLine.FindSet() then
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", ItemJournalLine."Item No.");

                if recEbayItemList.FindFirst() then begin

                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, ItemJournalLine."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until ItemJournalLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Assembly Document", 'OnBeforeReleaseAssemblyDoc', '', false, false)]
    local procedure setForceUpdateforAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    var
        recAssemblyLine: Record "Assembly Line";
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        recAssemblyLine.Reset();
        recAssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        recAssemblyLine.SetRange("Document Type", "Sales Document Type"::Order);
        if recAssemblyLine.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", recAssemblyLine."No.");
                if recEbayItemList.FindFirst() then begin

                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, recAssemblyLine."No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until recAssemblyLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Act.-Register (Yes/No)", 'OnBeforeRegisterRun', '', false, false)]
    local procedure setForceUpdateforWarehousePutAway(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        if WarehouseActivityLine.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", WarehouseActivityLine."Item No.");
                if recEbayItemList.FindFirst() then begin

                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, WarehouseActivityLine."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until WarehouseActivityLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnPostPutAwayOrder_OnAfterPostWarehouseActivity', '', true, true)]
    local procedure OnPostPutAwayOrder_OnAfterPostWarehouseActivity(var _OrderValues: Record "MOB Common Element"; var _WhseActivityLine: Record "Warehouse Activity Line"; var _ResultMessage: Text)
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _WhseActivityLine."Item No.");
        if recEbayItemList.FindFirst() then begin
            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        if _WhseActivityLine.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", _WhseActivityLine."Item No.");
                if recEbayItemList.FindFirst() then begin
                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, _WhseActivityLine."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until _WhseActivityLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine', '', true, true)]
    local procedure OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        ItemNo: code[50];
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;

    begin
        ItemNo := _RequestValues.GetValue('ItemNumber');
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", ItemNo);
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        if _WhseJnlLine.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", _WhseJnlLine."Item No.");
                if recEbayItemList.FindFirst() then begin

                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, _WhseJnlLine."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until _WhseJnlLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine', '', true, true)]
    local procedure OnOnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        ItemNo: code[50];
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        Clear(ItemNo);
        ItemNo := _RequestValues.GetValue('ItemNumber');
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", ItemNo);
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, ItemNo);
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateItemJnlLine', '', true, true)]
    local procedure OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        ItemNo: code[50];
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        Clear(ItemNo);
        ItemNo := _RequestValues.GetValue('ItemNumber');
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", ItemNo);
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, ItemNo);
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine', '', true, true)]
    local procedure OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        ItemNo: code[50];
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;

    begin
        Clear(ItemNo);
        ItemNo := _RequestValues.GetValue('ItemNumber');
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", ItemNo);
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, ItemNo);
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnPostPutAwayOrder_OnBeforeRunWhseActivityPost', '', true, true)]
    local procedure OnPostPutAwayOrder_OnBeforeRunWhseActivityPost(var _WhseActLinesToPost: Record "Warehouse Activity Line"; var _WhseActPost: Codeunit "Whse.-Activity-Post")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _WhseActLinesToPost."Item No.");
        if recEbayItemList.FindFirst() then begin
            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        if _WhseActLinesToPost.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", _WhseActLinesToPost."Item No.");
                if recEbayItemList.FindFirst() then begin
                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, _WhseActLinesToPost."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until _WhseActLinesToPost.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnPostPutAwayOrder_OnBeforeRunWhseActivityRegister', '', true, true)]
    local procedure OnPostPutAwayOrder_OnBeforeRunWhseActivityRegister(var _WhseActLinesToPost: Record "Warehouse Activity Line"; var _WhseActRegister: Codeunit "Whse.-Activity-Register")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _WhseActLinesToPost."Item No.");
        if recEbayItemList.FindFirst() then begin
            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        if _WhseActLinesToPost.FindSet() then begin
            repeat
                recEbayItemList.Reset();
                recEbayItemList.SetRange("No.", _WhseActLinesToPost."Item No.");
                if recEbayItemList.FindFirst() then begin
                    if recEbayItemList.Listing_ID <> '' then begin
                        recEbayItemList.ForceUpdate := true;
                        recEbayItemList.Modify(true);
                    end;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, _WhseActLinesToPost."Item No.");
                if recAmazonItemsStockLevel.FindFirst() then begin
                    recAmazonItemsStockLevel.isSent := false;
                    recAmazonItemsStockLevel.Modify(true);
                end;
            until _WhseActLinesToPost.Next() = 0;
        end;


    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnBulkMove_OnAfterCreateItemJnlLine', '', true, true)]
    local procedure OnPostAdhocRegistrationOnBulkMove_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _ItemJnlLine."Item No.");
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, _ItemJnlLine."Item No.");
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateItemJnlLine', '', true, true)]
    local procedure OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        ItemNo: code[50];
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _ItemJnlLine."Item No.");
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, _ItemJnlLine."Item No.");
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Count", 'OnPostCountOrder_OnHandleRegistrationForItemJournalLine', '', true, true)]
    procedure OnPostCountOrder_OnHandleRegistrationForItemJournalLine(var _Registration: Record "MOB WMS Registration"; var _ItemJnlLine: Record "Item Journal Line")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;

    begin
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", _ItemJnlLine."Item No.");
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, _ItemJnlLine."Item No.");
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostItemJnlLine', '', true, false)]
    procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line"; OriginalItemJnlLine: Record "Item Journal Line"; var ItemShptEntryNo: Integer; IsATO: Boolean; var TempHandlingSpecification: Record "Tracking Specification"; var TempATOTrackingSpecification: Record "Tracking Specification"; TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; ShouldPostItemJnlLine: Boolean)
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;

    begin
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", ItemJournalLine."Item No.");
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, ItemJournalLine."Item No.");
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    procedure OnAfterInsertEventonItemLedgerEntry(var Rec: Record "Item Ledger Entry")
    var
        recEbayItemList: Record EbayItemsList;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        recEbayItemList.Reset();
        recEbayItemList.SetRange("No.", Rec."Item No.");
        if recEbayItemList.FindFirst() then begin

            if recEbayItemList.Listing_ID <> '' then begin
                recEbayItemList.ForceUpdate := true;
                recEbayItemList.Modify(true);
            end;
        end;

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, Rec."Item No.");
        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.isSent := false;
            recAmazonItemsStockLevel.Modify(true);
        end;
    end;
}