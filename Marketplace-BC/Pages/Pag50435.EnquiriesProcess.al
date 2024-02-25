page 50435 EnquiriesProcess
{
    ApplicationArea = All;
    Caption = 'Returns';
    DataCaptionExpression = 'Enquiries Process';
    PageType = Document;
    SourceTable = Enquiries;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group("")
            {
                Caption = '';

                field(CollectionCharge; Rec.CollectionCharge)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {

            action(CreateExchange)
            {
                Caption = 'Create Exchange';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    recEnquiriesLine: Record "Enquiries Line";
                    recEnquiries: Record Enquiries;
                    cu_CopyDocumentMgt: Codeunit "Copy Document Mgt.";
                    ToSalesHeader, ToSalesOrder, ToSalesReturnOrder, ToSalesCreditMemo : Record "Sales Header";
                    rec_SalesLines, rec_SalesLineRetuurned, rec_SalesLinesA, rec_SalesLinesC, rec_SalesLinesD, recSalesLines : Record "Sales Line";
                    enum_DocumentType: Enum "Sales Document Type";
                    rec_EnquiriesLine: Record "Enquiries Line";
                    rec_SalesHeader: Record "Sales Header";
                    total: Decimal;
                    item, exitvalue, itemexitvalue : Decimal;
                    rec_Item: Record Item;
                    cu_commonhelper: Codeunit CommonHelper;
                    lineno: Integer;
                    cduEnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    recordNo: code[20];
                    reasonCode: Code[10];
                    flag: Boolean;
                    cuEvent: Codeunit EventSubscribers;
                    enquiryNotes: Codeunit "Enquiries notes";
                    DocType: Enum "Sales Document Type";
                    OrderNoHistory: Text;
                begin

                    if Rec.CollectionCharge = Rec.CollectionCharge::"Carrier Selected" then begin

                        recordNo := cduEnquiriesAndReturns.createSalesReturnOrder(Rec);

                        // enquiryNotes.GetHistoryForSalesOrder(Rec.No, recordNo);

                        ToSalesReturnOrder.SetRange("No.", recordNo);
                        if ToSalesReturnOrder.FindFirst() then begin
                            ToSalesReturnOrder."Document Date" := Today;
                            ToSalesReturnOrder.Validate("Document Date");
                            ToSalesReturnOrder."Posting Date" := Today;
                            ToSalesReturnOrder.Validate("Document Date");
                            ToSalesReturnOrder."VAT Reporting Date" := Today;
                            ToSalesReturnOrder.Validate("VAT Reporting Date");
                            ToSalesReturnOrder."Order Date" := Today;
                            ToSalesReturnOrder.Validate("Order Date");
                            ToSalesReturnOrder."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                            ToSalesReturnOrder."Ship-to Name" := '';
                            ToSalesReturnOrder."Ship-to Address" := '';
                            ToSalesReturnOrder."Ship-to Address 2" := '';
                            ToSalesReturnOrder."Ship-to City" := '';
                            ToSalesReturnOrder."Ship-to Post Code" := '';
                            ToSalesReturnOrder."Ship-to Country/Region Code" := '';
                            ToSalesReturnOrder."Ship-to Contact" := '';
                            ToSalesReturnOrder."Package Tracking No." := '';
                            ToSalesReturnOrder."Ship-to County" := '';
                            ToSalesReturnOrder.ReturnOrderNo := recordNo;
                            ToSalesReturnOrder.InitialSalesOrderNumber := Rec.No;
                            if ToSalesReturnOrder.customDeliveryNotes <> '' then begin
                                ToSalesReturnOrder.customDeliveryNotes := ToSalesReturnOrder.customDeliveryNotes + ' , ' + Rec.Comment;
                            end
                            else begin
                                ToSalesReturnOrder.customDeliveryNotes := Rec.Comment;
                            end;
                            ToSalesReturnOrder.isRefund := true;
                            ToSalesReturnOrder.Modify(true);
                        end;


                        rec_EnquiriesLine.Reset();
                        rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                        if rec_EnquiriesLine.FindSet() then begin
                            repeat
                                rec_SalesLines.Reset();
                                rec_SalesLines.SetRange("Document No.", recordNo);
                                rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                rec_SalesLines.SetRange("Line No.", rec_EnquiriesLine."Line No.");
                                rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                if rec_SalesLines.FindSet(true) then begin
                                    if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                        rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Validate(Quantity);
                                        rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                        rec_SalesLines.Validate("Return Qty. to Receive");
                                        rec_SalesLines."Location Code" := 'ZRETURNS';
                                        rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                        rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                        exitvalue := rec_SalesLines."Total Returned";
                                        total := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Modify(true);

                                        rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                        rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                        rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                        if rec_SalesLineRetuurned.FindFirst() then begin
                                            exitvalue := rec_SalesLineRetuurned."Total Returned";
                                            rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                            rec_SalesLineRetuurned.Modify(true);
                                        end;

                                        rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                        if rec_Item.FindFirst() then begin
                                            itemexitvalue := rec_Item.TotalReturn;
                                            rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                            rec_Item.Modify(true);
                                        end;
                                    end
                                    else begin
                                        rec_SalesLines.Delete();
                                    end;
                                end

                                else begin
                                    rec_SalesLines.Reset();
                                    rec_SalesLines.SetRange("Document No.", recordNo);
                                    rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                    rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                    if rec_SalesLines.FindSet(true) then begin
                                        if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                            rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Validate(Quantity);
                                            rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                            rec_SalesLines.Validate("Return Qty. to Receive");
                                            rec_SalesLines."Location Code" := 'ZRETURNS';
                                            rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                            rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                            exitvalue := rec_SalesLines."Total Returned";
                                            total := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Modify(true);

                                            rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                            rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                            rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                            if rec_SalesLineRetuurned.FindFirst() then begin
                                                exitvalue := rec_SalesLineRetuurned."Total Returned";
                                                rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                                rec_SalesLineRetuurned.Modify(true);
                                            end;

                                            rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                            if rec_Item.FindFirst() then begin
                                                itemexitvalue := rec_Item.TotalReturn;
                                                rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                                rec_Item.Modify(true);
                                            end;
                                        end
                                        else begin
                                            rec_SalesLines.Delete();
                                        end;
                                    end;
                                end;

                            until rec_EnquiriesLine.Next() = 0;

                            //Return Order QTY
                            enquiryNotes.GetReturnOrderQty(Rec.No, recordNo);
                        end;

                        lineno := cu_commonhelper.GetLastLineNo(recordNo);
                        recSalesLines.Reset();
                        recSalesLines.Init();
                        recSalesLines."Document No." := recordNo;
                        recSalesLines."Document Type" := enum_DocumentType::"Return Order";
                        recSalesLines.Type := "Sales Line Type"::Item;
                        recSalesLines."Line No." := lineno;
                        recSalesLines."No." := 'RETURNCHARGE';
                        recSalesLines.Quantity := -1;
                        recSalesLines.Validate(Quantity);
                        recSalesLines.Validate("No.");
                        recSalesLines."Location Code" := 'ZRETURNS';
                        recSalesLines.Insert(true);

                        // cu_commonhelper.GetZreturnQty(recordNo);
                    END;


                    if Rec.CollectionCharge = Rec.CollectionCharge::"Royal Mail" then begin

                        recordNo := cduEnquiriesAndReturns.createSalesReturnOrder(Rec);

                        // enquiryNotes.GetHistoryForSalesOrder(Rec.No, recordNo);

                        ToSalesHeader.Reset();
                        ToSalesHeader.SetRange("No.", recordNo);
                        if ToSalesHeader.FindFirst() then begin
                            ToSalesHeader."Document Date" := Today;
                            ToSalesHeader.Validate("Document Date");
                            ToSalesHeader."Posting Date" := Today;
                            ToSalesHeader.Validate("Document Date");
                            ToSalesHeader."VAT Reporting Date" := Today;
                            ToSalesHeader.Validate("VAT Reporting Date");
                            ToSalesHeader."Order Date" := Today;
                            ToSalesHeader.Validate("Order Date");
                            ToSalesHeader."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                            ToSalesHeader."Ship-to Name" := '';
                            ToSalesHeader."Ship-to Address" := '';
                            ToSalesHeader."Ship-to Address 2" := '';
                            ToSalesHeader."Ship-to City" := '';
                            ToSalesHeader."Ship-to Post Code" := '';
                            ToSalesHeader."Ship-to Country/Region Code" := '';
                            ToSalesHeader."Ship-to Contact" := '';
                            ToSalesHeader."Package Tracking No." := '';
                            ToSalesHeader."Ship-to County" := '';
                            ToSalesHeader.InitialSalesOrderNumber := Rec.No;

                            if ToSalesHeader.customDeliveryNotes <> '' then begin
                                ToSalesHeader.customDeliveryNotes := ToSalesHeader.customDeliveryNotes + ' , ' + Rec.Comment;
                            end
                            else begin
                                ToSalesHeader.customDeliveryNotes := Rec.Comment;
                            end;
                            ToSalesHeader.isRefund := true;
                            ToSalesHeader.Modify(true);
                        end;

                        rec_EnquiriesLine.Reset();
                        rec_EnquiriesLine.SetRange("Document No.", Rec.No);

                        if rec_EnquiriesLine.FindSet() then begin
                            repeat
                                rec_SalesLines.Reset();
                                rec_SalesLines.SetRange("Document No.", recordNo);
                                rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                rec_SalesLines.SetRange("Line No.", rec_EnquiriesLine."Line No.");
                                rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                if rec_SalesLines.FindSet() then begin
                                    if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                        rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Validate(Quantity);
                                        rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                        rec_SalesLines.Validate("Return Qty. to Receive");
                                        rec_SalesLines."Location Code" := 'ZRETURNS';
                                        rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                        rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                        exitvalue := rec_SalesLines."Total Returned";
                                        total := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Modify(true);

                                        rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                        rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                        rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                        if rec_SalesLineRetuurned.FindFirst() then begin
                                            exitvalue := rec_SalesLineRetuurned."Total Returned";
                                            rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                            rec_SalesLineRetuurned.Modify(true);
                                        end;

                                        rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                        if rec_Item.FindFirst() then begin
                                            itemexitvalue := rec_Item.TotalReturn;
                                            rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                            rec_Item.Modify(true);
                                        end;
                                    end
                                    else begin
                                        rec_SalesLines.Delete();
                                    end;
                                end

                                else begin
                                    rec_SalesLines.Reset();
                                    rec_SalesLines.SetRange("Document No.", recordNo);
                                    rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                    rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                    if rec_SalesLines.FindSet() then begin
                                        if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                            rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Validate(Quantity);
                                            rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                            rec_SalesLines.Validate("Return Qty. to Receive");
                                            rec_SalesLines."Location Code" := 'ZRETURNS';
                                            rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                            rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                            exitvalue := rec_SalesLines."Total Returned";
                                            total := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Modify(true);

                                            rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                            rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                            rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                            if rec_SalesLineRetuurned.FindFirst() then begin
                                                exitvalue := rec_SalesLineRetuurned."Total Returned";
                                                rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                                rec_SalesLineRetuurned.Modify(true);
                                            end;

                                            rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                            if rec_Item.FindFirst() then begin
                                                itemexitvalue := rec_Item.TotalReturn;
                                                rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                                rec_Item.Modify(true);
                                            end;
                                        end
                                        else begin
                                            rec_SalesLines.Delete();

                                        end;
                                    end;
                                end;

                            until rec_EnquiriesLine.Next() = 0;

                            //Return Order QTY
                            enquiryNotes.GetReturnOrderQty(Rec.No, recordNo);
                        end;

                        lineno := cu_commonhelper.GetLastLineNo(recordNo);
                        recSalesLines.Reset();
                        recSalesLines.Init();
                        recSalesLines."Document No." := recordNo;
                        recSalesLines."Document Type" := enum_DocumentType::"Return Order";
                        recSalesLines.Type := "Sales Line Type"::Item;
                        recSalesLines."Line No." := lineno;
                        recSalesLines."No." := 'RETURNCOLLECT';
                        recSalesLines.Quantity := -1;
                        recSalesLines.Validate(Quantity);
                        recSalesLines.Validate("No.");
                        recSalesLines."Location Code" := 'ZRETURNS';
                        recSalesLines.Insert(true);
                    end;


                    if Rec.CollectionCharge = Rec.CollectionCharge::Waiver then begin
                        recordNo := cduEnquiriesAndReturns.createSalesReturnOrder(Rec);

                        // enquiryNotes.GetHistoryForSalesOrder(Rec.No, recordNo);


                        ToSalesReturnOrder.SetRange("No.", recordNo);
                        if ToSalesReturnOrder.FindSet() then begin
                            ToSalesReturnOrder."Document Date" := Today;
                            ToSalesReturnOrder.Validate("Document Date");
                            ToSalesReturnOrder."VAT Reporting Date" := Today;
                            ToSalesReturnOrder.Validate("VAT Reporting Date");
                            ToSalesReturnOrder."Order Date" := Today;
                            ToSalesReturnOrder.Validate("Order Date");
                            ToSalesReturnOrder."Posting Date" := Today;
                            ToSalesReturnOrder.Validate("Posting Date");
                            ToSalesReturnOrder."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                            ToSalesReturnOrder."Ship-to Name" := '';
                            ToSalesReturnOrder."Ship-to Address" := '';
                            ToSalesReturnOrder."Ship-to Address 2" := '';
                            ToSalesReturnOrder."Ship-to City" := '';
                            ToSalesReturnOrder."Ship-to Post Code" := '';
                            ToSalesReturnOrder."Ship-to Country/Region Code" := '';
                            ToSalesReturnOrder."Ship-to Contact" := '';
                            ToSalesReturnOrder."Package Tracking No." := '';
                            ToSalesReturnOrder."Ship-to County" := '';
                            ToSalesReturnOrder.InitialSalesOrderNumber := Rec.No;

                            if ToSalesReturnOrder.customDeliveryNotes <> '' then begin
                                ToSalesReturnOrder.customDeliveryNotes := ToSalesReturnOrder.customDeliveryNotes + ' , ' + Rec.Comment;
                            end
                            else begin
                                ToSalesReturnOrder.customDeliveryNotes := Rec.Comment;
                            end;
                            ToSalesReturnOrder.isRefund := true;
                            ToSalesReturnOrder.Modify(true);
                        end;

                        rec_EnquiriesLine.Reset();
                        rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                        if rec_EnquiriesLine.FindSet() then begin
                            repeat
                                rec_SalesLines.Reset();
                                rec_SalesLines.SetRange("Document No.", recordNo);
                                rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                rec_SalesLines.SetRange("Line No.", rec_EnquiriesLine."Line No.");
                                rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                if rec_SalesLines.FindSet(true) then begin
                                    if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                        rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Validate(Quantity);
                                        rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                        rec_SalesLines.Validate("Return Qty. to Receive");
                                        rec_SalesLines."Location Code" := 'ZRETURNS';
                                        rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                        rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                        exitvalue := rec_SalesLines."Total Returned";
                                        total := rec_EnquiriesLine."Return/Replace";
                                        rec_SalesLines.Modify(true);

                                        rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                        rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                        rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                        if rec_SalesLineRetuurned.FindFirst() then begin
                                            exitvalue := rec_SalesLineRetuurned."Total Returned";
                                            rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                            rec_SalesLineRetuurned.Modify(true);
                                        end;

                                        rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                        if rec_Item.FindFirst() then begin
                                            itemexitvalue := rec_Item.TotalReturn;
                                            rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                            rec_Item.Modify(true);
                                        end;
                                    end
                                    else begin
                                        rec_SalesLines.Delete();
                                    end;
                                end

                                else begin
                                    rec_SalesLines.Reset();
                                    rec_SalesLines.SetRange("Document No.", recordNo);
                                    rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                    rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                    if rec_SalesLines.FindSet(true) then begin
                                        if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                            rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Validate(Quantity);
                                            rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                            rec_SalesLines.Validate("Return Qty. to Receive");
                                            rec_SalesLines."Location Code" := 'ZRETURNS';
                                            rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                            rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                            exitvalue := rec_SalesLines."Total Returned";
                                            total := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Modify(true);

                                            rec_SalesLineRetuurned.SetRange("Document No.", recordNo);
                                            rec_SalesLineRetuurned.SetRange("Document Type", enum_DocumentType::Order);
                                            rec_SalesLineRetuurned.SetRange("Line No.", rec_EnquiriesLine."Line No.");

                                            if rec_SalesLineRetuurned.FindFirst() then begin
                                                exitvalue := rec_SalesLineRetuurned."Total Returned";
                                                rec_SalesLineRetuurned."Total Returned" := exitvalue + total;
                                                rec_SalesLineRetuurned.Modify(true);
                                            end;

                                            rec_Item.SetRange("No.", rec_SalesLineRetuurned."No.");
                                            if rec_Item.FindFirst() then begin
                                                itemexitvalue := rec_Item.TotalReturn;
                                                rec_Item.TotalReturn := itemexitvalue + exitvalue + total;
                                                rec_Item.Modify(true);
                                            end;
                                        end
                                        else begin
                                            rec_SalesLines.Delete();
                                        end;
                                    end;
                                end;

                            until rec_EnquiriesLine.Next() = 0;
                            //Return Order QTY
                            enquiryNotes.GetReturnOrderQty(Rec.No, recordNo);
                        END;
                    end;
                end;
            }
        }
    }
    trigger OnOpenPage()
    var
        recEnquiries: Record Enquiries;
    begin
        recEnquiries.SetRange(No, Rec.No);
        if recEnquiries.FindSet() then
            CurrPage.SetTableView(recEnquiries);
    end;
}