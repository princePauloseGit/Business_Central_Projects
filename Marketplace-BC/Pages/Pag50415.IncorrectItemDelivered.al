page 50415 IncorrectItemDelivered
{
    ApplicationArea = All;
    Caption = 'Incorrect Item Delivered';
    PageType = Document;
    SourceTable = Enquiries;
    UsageCategory = Administration;
    DataCaptionExpression = 'Enquiries Process';

    layout
    {

        area(content)
        {
            group(General)
            {
                Caption = '';
                field(MisPickDoNotCollect; Rec.MisPickDoNotCollect)
                {
                    ApplicationArea = All;
                    ToolTip = 'Do not Collect Incorrect Item Delivered.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Incorrect Item Delivered")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                Caption = 'Incorrect Item Delivered';
                trigger OnAction()
                var
                    ToSalesHeaderOrder, ToSalesOrder, ToSalesReturnOrder : Record "Sales Header";
                    rec_SalesLines, rec_SalesLineRetuurned, rec_SalesLinesReturn, rec_SalesLinesOrder, rec_SalesLinesA : Record "Sales Line";
                    item, exitvalue, itemexitvalue : Decimal;
                    enum_DocumentType: Enum "Sales Document Type";
                    rec_EnquiriesLine, rec_EnquiriesLineA : Record "Enquiries Line";
                    rec_Enquiries: Record Enquiries;
                    cdu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    SalesOrderNo, ReturnOrderNo, OrderNo : Code[20];
                    total: Decimal;
                    rec_Item: Record Item;
                    note: Text;
                    enquiryNotes: Codeunit "Enquiries notes";
                    cu_commonhelper: Codeunit CommonHelper;
                    cuHOSTryReserve: Codeunit HOSTryReserve;
                    cdu_Autoreservation: Codeunit Autoreservation;

                begin

                    if Rec.MisPickDoNotCollect = false then begin
                        Clear(SalesOrderNo);

                        SalesOrderNo := cdu_EnquiriesAndReturns.createNewSalesOrder(Rec);

                        ModifySalesHeader(SalesOrderNo);
                        ModifySalesLines(SalesOrderNo);

                        cdu_EnquiriesAndReturns.SendEmail(Rec, SalesOrderNo);

                        ToSalesHeaderOrder.SetRange("No.", SalesOrderNo);

                        if ToSalesHeaderOrder.FindFirst() then begin
                            PAGE.Run(PAGE::"Sales Order", ToSalesHeaderOrder);
                        end;

                        //Document 2:SalesReturnOrder
                        Clear(ReturnOrderNo);
                        ReturnOrderNo := cdu_EnquiriesAndReturns.createSalesReturnOrder(Rec);

                        ToSalesReturnOrder.SetRange("No.", ReturnOrderNo);

                        if ToSalesReturnOrder.FindFirst() then begin

                            ToSalesReturnOrder."Document Date" := Today;
                            ToSalesReturnOrder.Validate("Document Date");
                            ToSalesReturnOrder."Posting Date" := Today;
                            ToSalesReturnOrder.Validate("Posting Date");
                            ToSalesReturnOrder."VAT Reporting Date" := Today;
                            ToSalesReturnOrder.Validate("VAT Reporting Date");
                            ToSalesReturnOrder."Order Date" := Today;
                            ToSalesReturnOrder.Validate("Order Date");
                            ToSalesReturnOrder."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                            ToSalesReturnOrder."Location Code" := '';
                            ToSalesReturnOrder."Shipping Agent Code" := '';
                            ToSalesReturnOrder."Shipping Agent Service Code" := '';
                            ToSalesReturnOrder."Ship-to Name" := '';
                            ToSalesReturnOrder."Ship-to Address" := '';
                            ToSalesReturnOrder."Ship-to Address 2" := '';
                            ToSalesReturnOrder."Ship-to City" := '';
                            ToSalesReturnOrder."Ship-to Post Code" := '';
                            ToSalesReturnOrder."Ship-to Country/Region Code" := '';
                            ToSalesReturnOrder."Ship-to Contact" := '';
                            ToSalesReturnOrder."Package Tracking No." := '';
                            ToSalesReturnOrder."Ship-to County" := '';

                            if ToSalesReturnOrder.customDeliveryNotes <> '' then begin
                                ToSalesReturnOrder.customDeliveryNotes := ToSalesReturnOrder.customDeliveryNotes + ' , ' + Rec.Comment;
                            end
                            else begin
                                ToSalesReturnOrder.customDeliveryNotes := Rec.Comment;
                            end;
                            ToSalesReturnOrder.Modify(true);
                        end;


                        rec_EnquiriesLineA.Reset();
                        rec_EnquiriesLineA.SetRange("Document No.", Rec.No);
                        rec_EnquiriesLineA.SetFilter("Return/Replace", '>%1', 0);
                        if rec_EnquiriesLineA.FindSet() then begin
                            repeat

                                rec_SalesLinesA.Reset();
                                rec_SalesLinesA.SetRange("Document No.", ReturnOrderNo);
                                rec_SalesLinesA.SetRange("Document Type", enum_DocumentType::"Return Order");
                                rec_SalesLinesA.SetRange("Line No.", rec_EnquiriesLineA."Line No.");
                                rec_SalesLinesA.SetRange("No.", rec_EnquiriesLineA."No.");
                                rec_SalesLinesA.SetRange(Quantity, rec_EnquiriesLine.Quantity);
                                rec_SalesLinesA.SetRange(isReturned, false);

                                if rec_SalesLinesA.FindSet() then begin
                                    rec_SalesLinesA.Quantity := rec_EnquiriesLineA."Return/Replace";
                                    rec_SalesLinesA.Validate(Quantity);
                                    rec_SalesLinesA."Return Qty. to Receive" := rec_EnquiriesLineA."Return/Replace";
                                    rec_SalesLinesA.Validate("Return Qty. to Receive");
                                    rec_SalesLinesA."Return Reason Code" := rec_EnquiriesLineA."Return Reason Code";
                                    rec_SalesLinesA.Validate("Return Reason Code");
                                    rec_SalesLinesA.isReturned := true;
                                    rec_SalesLinesA."Unit Price" := 0.00;
                                    rec_SalesLinesA.Validate("Unit Price");
                                    rec_SalesLinesA."Line Shipment Value" := 0.00;
                                    rec_SalesLinesA.Validate("Line Shipment Value");
                                    rec_SalesLinesA."Location Code" := 'ZRETURNS';
                                    rec_SalesLinesA.Modify(true);

                                end
                                else begin
                                    rec_SalesLinesA.Reset();
                                    rec_SalesLinesA.SetRange("Document No.", ReturnOrderNo);
                                    rec_SalesLinesA.SetRange("Document Type", enum_DocumentType::"Return Order");
                                    rec_SalesLinesA.SetRange("No.", rec_EnquiriesLineA."No.");
                                    rec_SalesLinesA.SetRange(Quantity, rec_EnquiriesLineA.Quantity);
                                    rec_SalesLinesA.SetRange(isReturned, false);

                                    if rec_SalesLinesA.FindSet() then begin

                                        rec_SalesLinesA.Quantity := rec_EnquiriesLineA."Return/Replace";
                                        rec_SalesLinesA.Validate(Quantity);
                                        rec_SalesLinesA."Return Qty. to Receive" := rec_EnquiriesLineA."Return/Replace";
                                        rec_SalesLinesA.Validate("Return Qty. to Receive");
                                        rec_SalesLinesA."Return Reason Code" := rec_EnquiriesLineA."Return Reason Code";
                                        rec_SalesLinesA.Validate("Return Reason Code");
                                        rec_SalesLinesA.isReturned := true;
                                        rec_SalesLinesA."Unit Price" := 0.00;
                                        rec_SalesLinesA.Validate("Unit Price");
                                        rec_SalesLinesA."Line Shipment Value" := 0.00;
                                        rec_SalesLinesA.Validate("Line Shipment Value");
                                        rec_SalesLinesA."Location Code" := 'ZRETURNS';
                                        rec_SalesLinesA.Modify(true);

                                    end;
                                end;
                            until rec_EnquiriesLineA.Next() = 0;

                            // Return Order QTY
                            enquiryNotes.GetReturnOrderQty(Rec.No, ReturnOrderNo);
                        end;

                        rec_SalesLineRetuurned.Reset();
                        rec_SalesLineRetuurned.SetRange("Document No.", ReturnOrderNo);
                        rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::"Return Order");
                        rec_SalesLineRetuurned.SetFilter("Location Code", '<>%1', 'ZRETURNS');
                        if rec_SalesLineRetuurned.FindSet() then begin
                            repeat
                                cdu_EnquiriesAndReturns.CancelReservation(rec_SalesLineRetuurned);
                                rec_SalesLineRetuurned.Delete();
                            until rec_SalesLineRetuurned.Next() = 0;
                        end;
                    end
                    else begin

                        Clear(OrderNo);
                        Clear(ToSalesHeaderOrder);

                        OrderNo := cdu_EnquiriesAndReturns.createNewSalesOrder(Rec);

                        ModifySalesHeader(OrderNo);
                        ModifySalesLines(OrderNo);

                        cdu_EnquiriesAndReturns.SendEmail(Rec, OrderNo);

                        ToSalesHeaderOrder.SetRange("No.", OrderNo);

                        if ToSalesHeaderOrder.FindFirst() then begin
                            PAGE.Run(PAGE::"Sales Order", ToSalesHeaderOrder);
                        end;

                    end;
                end;
            }
        }
    }

    procedure ModifySalesHeader(recordNo: Code[20])
    var
        ToSalesHeaderOrder: Record "Sales Header";
    begin
        ToSalesHeaderOrder.Reset();
        ToSalesHeaderOrder.SetRange("Document Type", "Sales Document Type"::Order);
        ToSalesHeaderOrder.SetRange("No.", recordNo);

        if ToSalesHeaderOrder.FindFirst() then begin

            ToSalesHeaderOrder."Document Date" := Today;
            ToSalesHeaderOrder.Validate("Document Date");
            ToSalesHeaderOrder."Posting Date" := Today;
            ToSalesHeaderOrder.Validate("Posting Date");
            ToSalesHeaderOrder."VAT Reporting Date" := Today;
            ToSalesHeaderOrder.Validate("VAT Reporting Date");
            ToSalesHeaderOrder."Order Date" := Today;
            ToSalesHeaderOrder.Validate("Order Date");
            ToSalesHeaderOrder."Shipping Agent Code" := '';
            ToSalesHeaderOrder."Shipping Agent Service Code" := '';
            ToSalesHeaderOrder."Package Tracking No." := '';
            ToSalesHeaderOrder.OrderBatch := 'Special';
            ToSalesHeaderOrder."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;

            if ToSalesHeaderOrder.customDeliveryNotes <> '' then begin
                ToSalesHeaderOrder.customDeliveryNotes := ToSalesHeaderOrder.customDeliveryNotes + ' , ' + Rec.Comment;
            end
            else begin
                ToSalesHeaderOrder.customDeliveryNotes := Rec.Comment;
            end;

            ToSalesHeaderOrder.ReturnOrderHistory := '';
            ToSalesHeaderOrder.HistoryNotes := '';
            ToSalesHeaderOrder.Modify(true);
        end;
    end;

    procedure ModifySalesLines(recordNo: Code[20])
    var
        rec_EnquiriesLine: Record "Enquiries Line";
        rec_SalesLines: Record "Sales Line";
        cu_commonhelper: Codeunit CommonHelper;
        cuHOSTryReserve: Codeunit HOSTryReserve;
    begin
        rec_EnquiriesLine.Reset();
        rec_EnquiriesLine.SetRange("Document No.", Rec.No);
        rec_EnquiriesLine.SetFilter("Return/Replace", '>%1', 0);

        if rec_EnquiriesLine.FindSet() then begin
            repeat
                rec_SalesLines.Reset();
                rec_SalesLines.SetRange("Document No.", recordNo);
                rec_SalesLines.SetRange("Document Type", "Sales Document Type"::Order);
                rec_SalesLines.SetRange(Quantity, rec_EnquiriesLine.Quantity);
                rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                if rec_SalesLines.FindFirst() then begin
                    rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                    rec_SalesLines.Validate(Quantity);
                    rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                    rec_SalesLines.Validate("Return Reason Code");
                    rec_SalesLines.isReturned := true;
                    rec_SalesLines.Validate(isReturned);
                    rec_SalesLines."Unit Price" := 0.00;
                    rec_SalesLines.Validate("Unit Price");
                    rec_SalesLines."Line Shipment Value" := 0.00;
                    rec_SalesLines.Validate("Line Shipment Value");
                    rec_SalesLines.Modify(true);
                end;

            until rec_EnquiriesLine.Next() = 0;
        end;

        rec_SalesLines.Reset();
        rec_SalesLines.SetRange("Document No.", recordNo);
        rec_SalesLines.SetRange("Document Type", "Sales Document Type"::Order);
        rec_SalesLines.SetRange(isReturned, true);

        if rec_SalesLines.FindSet() then begin
            repeat
                cuHOSTryReserve.TryReserve(rec_SalesLines."Document No.");
                if rec_SalesLines.IsAsmToOrderRequired() then begin
                    rec_SalesLines.AutoAsmToOrder();
                end;
            until rec_SalesLines.Next() = 0;
        end;

    end;
}
