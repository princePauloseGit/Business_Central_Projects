codeunit 50445 StockLevel
{

    procedure GetQuantity(itemno: code[20]; isEbay: Boolean): Integer
    var
        free: Integer;
    begin
        free := getAvailable(ItemNo, isEbay) + getCanAssemble(ItemNo, isEbay) - GetAssmOrd(ItemNo) - GetSo(ItemNo);
        exit(free);
    end;

    local procedure GetAssmOrd(itemno: code[20]): Integer
    var
        itm: record item;
    begin
        itm.Get(itemno);
        itm.CalcFields("Qty. on Asm. Component");
        exit(Round(itm."Qty. on Asm. Component", 1, '<'));
    end;

    local procedure getCanAssemble(ItemNo: code[20]; isEbay: Boolean): Integer
    var
        bom: record "BOM Component";
        recitem2: record item;
        ile: record "Item Ledger Entry";
        canbuild: Decimal;
        templvl: Decimal;
    begin
        recitem2.get(ItemNo);
        if not recitem2.IsAssemblyItem() then exit(0); // not assembly
        canbuild := 999999;
        bom.Reset();
        bom.SetFilter("Parent Item No.", ItemNo);

        if bom.FindSet() then
            repeat
                templvl := getAvailable(bom."No.", isEbay) - GetAssmOrd(bom."No.") - GetSO(bom."No.");
                templvl := templvl / bom."Quantity per";
                if templvl < canbuild then canbuild := templvl;
            until bom.Next() = 0;
        if (canbuild = 999999) or (canbuild < 1) then
            canbuild := 0; // reset it if no assembly found or less than zero available
        exit(Round(canbuild, 1, '<'));

    end;

    local procedure getAvailable(ItemNo: code[20]; isEbay: Boolean): Integer
    var
        ile: record "Item Ledger Entry";
        itm: record Item;
        reserveQty: Decimal;
    begin
        reserveQty := 0;
        itm.get(ItemNo);
        ile.SetRange(Open, true);
        ile.SetRange("Item No.", ItemNo);
        ile.CalcSums("Remaining Quantity");
        itm.CalcFields(QtyAtReceive);
        if isEbay = true then begin
            exit(Round(ile."Remaining Quantity" - itm.QtyAtReceive - itm.Reserve_Stock_ebay, 1, '<'));
        end else begin
            exit(Round(ile."Remaining Quantity" - itm.QtyAtReceive - itm.NON_LIST_STOCK, 1, '<'));
        end;
    end;

    local procedure GetSO(ItemNo: code[20]): Integer
    var
        sl: record "Sales Line";
    begin
        sl.SetRange("Document Type", sl."Document Type"::Order);
        sl.SetRange("No.", ItemNo);
        sl.SetRange(Type, sl.type::Item);
        sl.SetRange("Location Code", 'HARTS');
        sl.SetFilter("Outstanding Quantity", '>0');
        sl.CalcSums("Outstanding Quantity");
        exit(Round(sl."Outstanding Quantity", 1, '<'));
    end;

    procedure CalculateAvailbleStock(recItem: Record Item): Decimal
    var
        availableStock: Decimal;
    begin
        recItem.CalcFields(Inventory);
        recItem.CalcFields("Qty. on Sales Order");
        recItem.CalcFields(QtyAtReceive);
        availableStock := recItem.Inventory - recItem."Qty. on Sales Order" - recItem.QtyAtReceive - recItem."Qty. on Asm. Component";

        if availableStock < 0 then begin
            availableStock := 0;
        end;

        exit(Round(availableStock, 1, '<'));
    end;

    procedure getQtyCanBeAssembled(sku: code[20]): integer
    var
        bom: record "BOM Component";
        recitem2: record Item;
        canbuild: integer;
    begin
        canbuild := 999999;
        bom.Reset();
        bom.SetFilter("Parent Item No.", sku);
        if bom.FindSet() then
            repeat
                if recitem2.Get(bom."No.") then begin
                    recitem2.CalcFields(Inventory);
                    recitem2.CalcFields("Qty. on Sales Order");
                    if ((recitem2.Inventory - recitem2."Qty. on Sales Order") / bom."Quantity per") < canbuild then
                        canbuild := system.round((recitem2.Inventory - recitem2."Qty. on Sales Order") / bom."Quantity per", 1, '<');
                end;
            until bom.Next() = 0;
        if (canbuild = 999999) or (canbuild < 1) then
            canbuild := 0; // reset it if no assembly found or less than zero available
        exit(Round(canbuild, 1, '<'));
    end;
}
