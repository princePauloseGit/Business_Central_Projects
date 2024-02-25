codeunit 50413 Autoreservation
{
    procedure ReserveSalesLine(var rec_DisplayFilterData: Record "Sales Line")
    var
        rec_TempReservEntry: Record "Reservation Entry" temporary;
        rec_SalesLine: Record "Sales Line";
        rec_ItemLedgerEntry: Record "Item Ledger Entry";
        cdu_CreateReservEntry: Codeunit "Create Reserv. Entry";
        enum_ReservStatus: Enum "Reservation Status";
        rec_FromTrackingSpecification: Record "Tracking Specification" temporary;
        requiredQuantity, remainingQty : Integer;
        enum_EntryType: Enum "Item Ledger Entry Type";
        enum_DocumentType: Enum "Item Ledger Document Type";
        isFullyReserved: Boolean;
    begin
        requiredQuantity := rec_DisplayFilterData.Quantity;

        rec_ItemLedgerEntry.SetRange("Item No.", rec_DisplayFilterData."No.");
        rec_ItemLedgerEntry.SetRange("Location Code", rec_DisplayFilterData."Location Code");
        rec_ItemLedgerEntry.SetRange(Positive, true);
        rec_ItemLedgerEntry.SetFilter("Remaining Quantity", '<>%1', rec_ItemLedgerEntry."Reserved Quantity");

        if rec_ItemLedgerEntry.FindSet() then
            repeat
                if (rec_ItemLedgerEntry."Entry Type" = enum_EntryType::"Positive Adjmt.") or
                (rec_ItemLedgerEntry."Entry Type" = enum_EntryType::Purchase) or
                ((rec_ItemLedgerEntry."Entry Type" = enum_EntryType::Sale) and (rec_ItemLedgerEntry."Document Type" = enum_DocumentType::"Sales Credit Memo"))
                then begin
                    rec_ItemLedgerEntry.CalcFields("Reserved Quantity");
                    remainingQty := rec_ItemLedgerEntry."Remaining Quantity" - rec_ItemLedgerEntry."Reserved Quantity";

                    if (remainingQty > 0) and (requiredQuantity > 0) then begin

                        rec_TempReservEntry.DeleteAll();
                        rec_TempReservEntry.Init();

                        if requiredQuantity <= remainingQty then begin
                            rec_TempReservEntry.Quantity := requiredQuantity;
                            requiredQuantity := 0;
                        end else begin
                            rec_TempReservEntry.Quantity := remainingQty;
                            requiredQuantity := requiredQuantity - remainingQty;
                        end;

                        if requiredQuantity = 0 then begin
                            isFullyReserved := true;
                        end;

                        rec_TempReservEntry."Item No." := rec_ItemLedgerEntry."Item No.";
                        rec_TempReservEntry."Lot No." := rec_ItemLedgerEntry."Lot No.";
                        rec_TempReservEntry."Location Code" := rec_ItemLedgerEntry."Location Code";
                        rec_TempReservEntry."Item Ledger Entry No." := rec_ItemLedgerEntry."Entry No.";
                        rec_TempReservEntry.Insert();

                        if rec_TempReservEntry.FindSet() then begin
                            rec_SalesLine.SetRange("No.", rec_TempReservEntry."Item No.");
                            rec_SalesLine.SetRange("Document No.", rec_DisplayFilterData."Document No.");
                            rec_SalesLine.SetRange("Line No.", rec_DisplayFilterData."Line No.");
                            rec_SalesLine.SetRange("Sell-to Customer No.", rec_DisplayFilterData."Sell-to Customer No.");
                            rec_SalesLine.SetRange("Location Code", rec_TempReservEntry."Location Code");

                            if rec_SalesLine.FindSet() then begin
                                rec_FromTrackingSpecification.DeleteAll();
                                rec_FromTrackingSpecification.Init();
                                rec_FromTrackingSpecification."Item No." := rec_SalesLine."No.";
                                rec_FromTrackingSpecification."Source Type" := rec_ItemLedgerEntry.RecordId.TableNo;
                                rec_FromTrackingSpecification."Source Subtype" := rec_SalesLine.Subtype;
                                rec_FromTrackingSpecification."Location Code" := rec_SalesLine."Location Code";
                                rec_FromTrackingSpecification."Source Ref. No." := rec_TempReservEntry."Item Ledger Entry No.";
                                rec_FromTrackingSpecification."Quantity (Base)" := rec_TempReservEntry.Quantity;
                                rec_FromTrackingSpecification.Insert();

                                cdu_CreateReservEntry.SetDates(0D, rec_TempReservEntry."Expiration Date");
                                cdu_CreateReservEntry.CreateReservEntryFor(Database::"Sales Line", 1, rec_SalesLine."Document No.", '', 0, rec_SalesLine."Line No.", rec_SalesLine."Qty. per Unit of Measure", rec_TempReservEntry.Quantity, rec_TempReservEntry.Quantity * rec_SalesLine."Qty. per Unit of Measure", rec_TempReservEntry);
                                cdu_CreateReservEntry.CreateReservEntryFrom(rec_FromTrackingSpecification);
                                cdu_CreateReservEntry.CreateEntry(rec_SalesLine."No.", rec_SalesLine."Variant Code", rec_SalesLine."Location Code", rec_SalesLine.Description, rec_SalesLine."Shipment Date", 0D, 0, enum_ReservStatus::Reservation);
                            end;
                        end;
                    end
                end
            until (rec_ItemLedgerEntry.Next() = 0) or (isFullyReserved = true);
    end;
}
