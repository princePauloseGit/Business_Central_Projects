page 50429 EnquiriesCard
{
    Caption = 'Enquiry Card';
    PageType = Card;
    SourceTable = Enquiries;
    DataCaptionExpression = Rec.No + ' ' + Rec."Sell-to Customer Name";

    layout
    {
        area(content)
        {
            group(Customer)
            {

                field("Name"; Rec."Sell-to Customer Name")
                {

                    ApplicationArea = All;
                    Caption = 'Name';
                }
                field("contact"; rec.Contact)
                {
                    ApplicationArea = All;
                    Caption = 'Contact';
                }
                field("Address"; rec.Address)
                {
                    ApplicationArea = All;
                    Caption = 'Address';
                }
                field("Address 2"; rec."Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Address 2';
                }
                field("City"; rec."Sell-to City")
                {
                    ApplicationArea = All;
                    Caption = 'City';
                }
                field("County"; rec.County)
                {
                    ApplicationArea = All;
                    Caption = 'County';
                }
                field("Postcode"; rec.Postcode)
                {
                    ApplicationArea = All;
                    Caption = 'Postcode';
                }
                field("Country"; rec.Country)
                {
                    ApplicationArea = All;
                    Caption = 'Country';
                }
                field("EMail"; rec.Email)
                {
                    ApplicationArea = All;
                    Caption = 'Email';
                }
                field("Phone No."; rec.Phone)
                {
                    ApplicationArea = All;
                    Caption = 'Phone No.';
                }

            }
            group(Delivery)
            {
                field("Ship-to-Contact"; Rec."Ship-to-Contact")
                {

                    ApplicationArea = All;
                    Caption = 'Ship-to Contact';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {

                    ApplicationArea = All;
                    Caption = 'Ship-to Address';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {

                    ApplicationArea = All;
                    Caption = 'Ship-to City';
                }
                field("Ship-to County"; Rec."Ship-to County")
                {

                    ApplicationArea = All;
                    Caption = 'Ship-to County';
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {

                    ApplicationArea = All;
                    Caption = 'Ship-to Postcode';
                }
                field("Ship-to Country"; Rec."Ship-to Country")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Country';
                }

            }
            group("Sales Order")
            {
                field("Total Value"; Rec."Total Value")
                {
                    ApplicationArea = All;
                    Caption = 'Total Value';
                }
                field(History; Rec.History)
                {
                    ApplicationArea = All;
                    Caption = 'History';
                    MultiLine = true;
                    Editable = false;
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = All;
                    Caption = 'Reference';
                }
                field(Description; rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field("Internal Notes"; Rec."Internal Notes")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Caption = 'Internal Notes';
                }
            }
            part(SalesLines; "Enquiries Order Subform")
            {
                Caption = 'Sales Order line';
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field(No);
                UpdatePropagation = Both;
                SubPageView = sorting("Line No.") order(descending);
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(3),
                              "No." = FIELD(No);
            }
            systempart(PyamentTermsLinks; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(PyamentTermsNotes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Returns)
            {
                Caption = 'Returns';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    recEnquiriesLine: Record "Enquiries Line";
                    SourceRecordLink: Record "Record Link";
                    flag: Boolean;
                begin
                    recEnquiriesLine.SetRange("Document No.", Rec.No);
                    recEnquiriesLine.SetFilter("Return/Replace", '>%1', 0);
                    if recEnquiriesLine.FindSet() then begin
                        repeat
                            flag := true;
                        until recEnquiriesLine.Next() = 0;
                    end;
                    if flag = true then begin

                        page.Run(Page::EnquiriesProcess, Rec);
                    end
                    else begin
                        Error('Must provide Return/Replace quantity');
                    end;
                end;
            }
            action(DamageFaulty)
            {
                Caption = 'Damage/Faulty';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    recEnquiriesLine: Record "Enquiries Line";
                    SourceRecordLink: Record "Record Link";
                    flag: Boolean;
                begin
                    recEnquiriesLine.SetRange("Document No.", Rec.No);
                    recEnquiriesLine.SetFilter("Return/Replace", '>%1', 0);
                    if recEnquiriesLine.FindSet() then begin
                        repeat
                            flag := true;
                        until recEnquiriesLine.Next() = 0;
                    end;
                    if flag = true then begin

                        page.Run(Page::"Damage/Faulty Delivery", Rec);
                    end
                    else begin
                        Error('Must provide Return/Replace quantity');
                    end;
                end;
            }
            action(PartialRefund)
            {
                Caption = 'Partial Refund';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    recEnquiriesLine: Record "Enquiries Line";
                    cdu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    cu_CopyDocumentMgt: Codeunit "Copy Document Mgt.";
                    ToSalesHeader, ToSalesOrder, ToSalesReturnOrder, ToCreditMemoHeader : Record "Sales Header";
                    rec_SalesLines, rec_SalesLineRetuurned, rec_SalesLinesCredit : Record "Sales Line";
                    enum_DocumentType: Enum "Sales Document Type";
                    rec_EnquiriesLine: Record "Enquiries Line";
                    total: Decimal;
                    item, exitvalue, itemexitvalue : Decimal;
                    rec_Item: Record Item;
                    cu_commonhelper: Codeunit CommonHelper;
                    lineno: Integer;
                    recordNo: code[20];
                    flag: Boolean;
                    enquiryNotes: Codeunit "Enquiries notes";
                begin
                    recEnquiriesLine.SetRange("Document No.", Rec.No);
                    recEnquiriesLine.SetFilter("Return/Replace", '>%1', 0);
                    if recEnquiriesLine.FindSet() then begin
                        repeat
                            flag := true;
                        until recEnquiriesLine.Next() = 0;
                    end;
                    if flag = true then begin

                        recordNo := cdu_EnquiriesAndReturns.createSalesReturnOrder(Rec);

                        // enquiryNotes.GetHistoryForSalesOrder(Rec.No, recordNo);

                        ToCreditMemoHeader.SetRange("No.", recordNo);
                        if ToCreditMemoHeader.FindSet() then begin
                            ToCreditMemoHeader."Document Date" := Today;
                            ToCreditMemoHeader.Validate("Document Date");
                            ToCreditMemoHeader."VAT Reporting Date" := Today;
                            ToCreditMemoHeader.Validate("VAT Reporting Date");
                            ToCreditMemoHeader."Order Date" := Today;
                            ToCreditMemoHeader.Validate("Order Date");
                            ToCreditMemoHeader."Posting Date" := Today;
                            ToCreditMemoHeader.Validate("Posting Date");
                            ToCreditMemoHeader."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                            ToCreditMemoHeader."Ship-to Name" := '';
                            ToCreditMemoHeader."Ship-to Address" := '';
                            ToCreditMemoHeader."Ship-to Address 2" := '';
                            ToCreditMemoHeader."Ship-to City" := '';
                            ToCreditMemoHeader."Ship-to Post Code" := '';
                            ToCreditMemoHeader."Ship-to Country/Region Code" := '';
                            ToCreditMemoHeader."Ship-to Contact" := '';
                            ToCreditMemoHeader."Package Tracking No." := '';
                            ToCreditMemoHeader."Ship-to County" := '';
                            ToCreditMemoHeader.InitialSalesOrderNumber := Rec.No;

                            if ToCreditMemoHeader.customDeliveryNotes <> '' then begin
                                ToCreditMemoHeader.customDeliveryNotes := ToCreditMemoHeader.customDeliveryNotes + ' , ' + Rec.Comment;
                            end
                            else begin
                                ToCreditMemoHeader.customDeliveryNotes := Rec.Comment;
                            end;
                            ToCreditMemoHeader.isRefund := true;
                            ToCreditMemoHeader.Modify(true);
                        end;

                        rec_EnquiriesLine.SetRange("Document No.", Rec.No);
                        if rec_EnquiriesLine.FindSet() then
                            repeat
                                rec_SalesLines.Reset();
                                rec_SalesLines.SetRange("Document No.", recordNo);
                                rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                                rec_SalesLines.SetRange("Line No.", rec_EnquiriesLine."Line No.");
                                rec_SalesLines.SetRange("No.", rec_EnquiriesLine."No.");

                                if rec_SalesLines.FindSet() then begin
                                    if rec_EnquiriesLine."Return/Replace" > 0 then begin
                                        rec_Item.SetRange("No.", rec_SalesLines."No.");
                                        if rec_Item.FindSet() then begin
                                            rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Validate(Quantity);
                                            rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Validate("Return Qty. to Receive");
                                            rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                            rec_SalesLines."Unit Cost" := rec_Item."Unit Cost";
                                            rec_SalesLines.Validate("Unit Cost");
                                            rec_SalesLines."Location Code" := 'ZRETURNS';
                                            rec_SalesLines."Shortcut Dimension 1 Code" := rec.ShortcutDimension1;
                                            rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                            exitvalue := rec_SalesLines."Total Returned";
                                            total := rec_EnquiriesLine."Return/Replace";
                                            rec_SalesLines.Modify(true);

                                        end;

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
                                        end
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
                                            rec_Item.SetRange("No.", rec_SalesLines."No.");
                                            if rec_Item.FindSet() then begin
                                                rec_SalesLines.Quantity := rec_EnquiriesLine."Return/Replace";
                                                rec_SalesLines.Validate(Quantity);
                                                rec_SalesLines."Return Qty. to Receive" := rec_EnquiriesLine."Return/Replace";
                                                rec_SalesLines.Validate("Return Qty. to Receive");
                                                rec_SalesLines."Return Reason Code" := rec_EnquiriesLine."Return Reason Code";
                                                rec_SalesLines.ArchiveLineNo := rec_EnquiriesLine.ArchiveLineNo;
                                                rec_SalesLines."Unit Cost" := rec_Item."Unit Cost";
                                                rec_SalesLines.Validate("Unit Cost");
                                                rec_SalesLines."Location Code" := 'ZRETURNS';
                                                exitvalue := rec_SalesLines."Total Returned";
                                                total := rec_EnquiriesLine."Return/Replace";
                                                rec_SalesLines.Modify(true);
                                            end;
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

                        // rec_SalesLines.Reset();
                        // rec_SalesLines.SetRange("Document No.", recordNo);
                        // rec_SalesLines.SetRange("Document Type", enum_DocumentType::"Return Order");
                        // rec_SalesLines.SetRange("No.", 'CARRIAGE');
                        // if rec_SalesLines.FindFirst() then begin
                        //     repeat
                        //         rec_SalesLines.Delete();
                        //     until rec_SalesLines.Next() = 0;
                        // end;
                    end
                    else begin
                        Error('Must provide Return/Replace quantity');
                    end;
                end;
            }


            action(Mispick)
            {
                Caption = 'Mispick';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    cu_EnquiriesAndReturns: Codeunit EnquiriesAndReturns;
                    recEnquiriesLine: Record "Enquiries Line";
                    SourceRecordLink: Record "Record Link";
                    flag: Boolean;
                begin
                    recEnquiriesLine.SetRange("Document No.", Rec.No);
                    recEnquiriesLine.SetFilter("Return/Replace", '>%1', 0);
                    if recEnquiriesLine.FindSet() then begin
                        repeat
                            flag := true;
                        until recEnquiriesLine.Next() = 0;
                    end;
                    if flag = true then begin
                        page.Run(Page::IncorrectItemDelivered, Rec);
                    end
                    else begin
                        Error('Must provide Return/Replace quantity');
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        recSalesHeader: Record "Sales Header";
        recSalesArchiveHeader: Record "Sales Header Archive";
        recEnquiriesNotes: Record EnquiriesCustomNotes;
    begin
        recSalesHeader.SetRange("No.", Rec.No);
        if recSalesHeader.FindSet() then begin
            recSalesHeader."Enq-Sales RecordId" := Rec.RecordId;
            recSalesHeader.Modify();
            Commit();
        end;

        recSalesArchiveHeader.SetRange("No.", Rec.No);
        if recSalesArchiveHeader.FindSet() then begin
            repeat
                recSalesArchiveHeader."Enq-Sales RecordId" := Rec.RecordId;
                recSalesArchiveHeader.Modify();
                Commit();
            until recSalesArchiveHeader.Next() = 0;
        end;
    end;
    // cdu.CopyLinksFromEnquiriesToSales(Rec);       


    trigger OnClosePage()
    var
        recEnquiriesNotes: Record EnquiriesCustomNotes;
        recEnquiries: Record Enquiries;

    begin
        recEnquiriesNotes.SetRange(OrderNo, Rec.No);
        if recEnquiriesNotes.FindSet() then begin
            recEnquiriesNotes.DeleteLinks();
            recEnquiriesNotes.CopyLinks(Rec);
            recEnquiriesNotes.HasLink := true;
            recEnquiriesNotes.Modify();
        end;
    end;

}
