codeunit 50422 "EmailItemExceededReturnRate"
{
    var
        CSVText: Text;
        Char1310: Char;
        OutS: OutStream;
        InS: InStream;
        CU_EmailMessage: Codeunit "Email Message";
        CU_Email: Codeunit Email;
        MsgBody: Text[2048];
        EmailList: List of [Text];
        Rec_TempBlob: Codeunit "Temp Blob";

    procedure SendEmailItemsReturnRate()
    var
        shipDate, totalQtySold, totalReturnQty : Integer;
        rec_SalesLine: Record "Sales Line";
        rec_SalesCrMemoLine: Record "Sales Cr.Memo Line";
        enumSalesDocType: Enum "Sales Document Type";
        totalSales: Decimal;
        rec_SalesShipmentLine: Record "Sales Shipment Line";
        rec_Item: Record Item;
        rec_ReturnDays: Record ReturnDays;
        PastXdays: date;
        PastDay: Text[2048];
        filename: Text;

    begin
        InitializeCSVHeader();
        totalQtySold := 0;
        if rec_ReturnDays.FindFirst() then begin
            shipDate := rec_ReturnDays.Days;
        end;

        PastXdays := CalcDate('-' + format(shipDate) + 'D', Today);

        rec_Item.Reset();
        if rec_Item.FindSet() then begin

            repeat
                totalQtySold := 0;
                totalReturnQty := 0;
                rec_SalesShipmentLine.Reset();
                rec_SalesShipmentLine.SetRange("No.", rec_Item."No.");
                rec_SalesShipmentLine.SetRange("Shipment Date", PastXdays, Today);
                if rec_SalesShipmentLine.FindSet() then begin
                    repeat
                        totalQtySold := totalQtySold + rec_SalesShipmentLine.Quantity;
                    until rec_SalesShipmentLine.Next() = 0;
                end;

                rec_SalesCrMemoLine.SetRange("No.", rec_Item."No.");
                rec_SalesCrMemoLine.SetRange("Shipment Date", PastXdays, Today);

                if rec_SalesCrMemoLine.FindSet() then begin
                    repeat
                        totalReturnQty := totalReturnQty + rec_SalesCrMemoLine.Quantity;
                    until rec_SalesCrMemoLine.Next() = 0;
                end;

                if (totalReturnQty > (totalQtySold / 10))
                 then
                    CreateCSV(rec_Item."No.", totalQtySold, totalReturnQty);

            until rec_Item.Next() = 0;
        end;


        filename := 'Return Rate.csv';
        Rec_TempBlob.CREATEOUTSTREAM(OutS);
        OutS.WRITETEXT(CSVText);
        Rec_TempBlob.CREATEINSTREAM(InS);
        DownloadFromStream(InS, '', '', '', filename);
        EmailtheCSV();
    end;

    local procedure InitializeCSVHeader()
    var
    begin
        CLEAR(Char1310);
        Char1310 := 10;

        CSVText := CSVText + '"Item No"' + ',' + '"Total Order"' + ',' + '"Total Return"' + FORMAT(Char1310);
    end;

    local procedure CreateCSV(ItemNo: Text; Total_Order: Decimal; Total_Return: decimal)
    begin
        CSVText := CSVText + '"' + ItemNo + '","' + Format(Round(Total_Order, 0.01), 0, 1) + '","' + Format(Round(Total_Return, 0.01), 0, 1) + '"' + FORMAT(Char1310);
    end;

    procedure EmailtheCSV()
    var
        recEmailInternalPO: Record EmailAlert;
    begin
        Rec_TempBlob.CREATEOUTSTREAM(OutS);
        OutS.WRITETEXT(CSVText);
        Rec_TempBlob.CREATEINSTREAM(InS);

        recEmailInternalPO.Reset();
        if recEmailInternalPO.FindSet() then begin
            repeat

                MsgBody := 'Hello, <br/><br/> Please find the attached Item file which has exceeded Return Rate.<br/><br/> Kind Regards';

                CU_EmailMessage.Create(recEmailInternalPO."Email Address", 'Item exceeded Return Rate', MsgBody, true);
                CU_EmailMessage.AddAttachment('ReturnItems.csv', 'CSV', InS);
                CU_Email.Send(CU_EmailMessage);

            until recEmailInternalPO.Next() = 0;
        end;
    end;

    procedure SendRefundEmail(SalesHeader: Record "Sales Header"; refundAmount: Decimal)
    var
        cdu_EmailMessage: Codeunit "Email Message";
        cdu_Email: Codeunit Email;
        Subject: Text;
        Body: Text;
    begin
        Subject := 'Harts of Stur - refund on order ' + SalesHeader."External Document No.";
        Body += 'Hi, <br><br> Further to your recent order, a refund of £' + Format(refundAmount, 0, '<Precision, 2:2><Standard Format, 0>') + ' has now been issued back to your original payment method. This should clear within three to five working days.<br><br>Please do contact us should you have any other queries,';
        Body += '<br><br>Kind Regards,<br><br>Harts of Stur ';

        cdu_EmailMessage.Create(SalesHeader."Sell-to E-Mail", Subject, Body, true);
        cdu_Email.Send(cdu_EmailMessage);
    end;
}
