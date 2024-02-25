codeunit 50419 BQOrdersDownload
{
    trigger OnRun()
    begin
        ConnectBQAPIForSalesOrders();
    end;

    var
        BQURI: Text;
        rec_BQSetting: Record "B&Q Settings";
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure ConnectBQAPIForSalesOrders()
    var
        result: text;
        pastDate: Date;
    begin
        Clear(RESTAPIHelper);
        Clear(BQURI);
        BQURI := RESTAPIHelper.GetBaseURl() + 'BQ/GetBQOrders';

        if Date2DWY(Today, 1) = 1 then
            pastDate := cu_CommonHelper.CalculateDate(7)
        else
            pastDate := cu_CommonHelper.CalculateDate(3);

        rec_BQSetting.Reset();
        if rec_BQSetting.FindSet() then begin
            repeat
                //Headers
                RESTAPIHelper.Initialize('POST', BQURI);
                RESTAPIHelper.AddRequestHeader('Authorization', rec_BQSetting.APIKey.Trim());

                //Body
                RESTAPIHelper.AddBody('{"start_date": "' + Format(pastDate, 0, 9) + '"}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::"B&Q") then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result, rec_BQSetting);
                end;
            until rec_BQSetting.Next() = 0;
        end;
    end;

    procedure ConnectBQAPIForManualSalesOrders()
    var
        offset, result, Body : text;
        pastDate: Date;
        varjsonToken, nextToken : JsonToken;
        JObject: JsonObject;

    begin
        Clear(RESTAPIHelper);
        Clear(BQURI);
        BQURI := RESTAPIHelper.GetBaseURl() + 'BQ/GetBQOrders';

        if Date2DWY(Today, 1) = 1 then
            pastDate := cu_CommonHelper.CalculateDate(7)
        else
            pastDate := cu_CommonHelper.CalculateDate(3);

        rec_BQSetting.Reset();
        if rec_BQSetting.FindSet() then begin
            repeat
                if rec_BQSetting.manualTest = true then begin

                    //Headers
                    RESTAPIHelper.Initialize('POST', BQURI);
                    RESTAPIHelper.AddRequestHeader('Authorization', rec_BQSetting.APIKey.Trim());

                    if (rec_BQSetting.offset = 'null') or (rec_BQSetting.offset = '') then begin
                        offset := '0';
                    end else begin
                        offset := format(rec_BQSetting.offset);
                    end;

                    //Body
                    Body := '{"start_date": "' + Format(pastDate, 0, 9) + '", "paginate":true,"max":' + Format(rec_BQSetting.Limit) + ',"offset":' + Format(offset) + '}';


                    RESTAPIHelper.AddBody('{"start_date": "' + Format(pastDate, 0, 9) + '", "paginate":true,"max":' + Format(rec_BQSetting.Limit) + ',"offset":' + Format(offset) + '}');

                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::"B&Q") then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadApiResponse(result, rec_BQSetting);

                        if not JObject.ReadFrom(result) then begin
                            Error('Invalid response, expected a JSON object');
                        end;

                        JObject.Get('nextPage', varjsonToken);

                        if (format(varjsonToken) = '0') and (rec_BQSetting.manualTest = true) then begin
                            rec_BQSetting.manualTest := false;
                            rec_BQSetting.Limit := 0;

                            rec_BQSetting.Modify(true);
                        end;

                        if rec_BQSetting.manualTest = true then begin
                            rec_BQSetting.offset := format(varjsonToken);

                            rec_BQSetting.Modify(true);
                        end;
                    end;

                end else begin
                    Message('Manual Test is off for customer %1', rec_BQSetting.CustomerCode);
                end;
            until rec_BQSetting.Next() = 0;
        end;
    end;

    local procedure ReadApiResponse(var apiResponse: Text; var recBQSetting: Record "B&Q Settings")
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        index: Integer;
        BQOrderId: Code[40];
        description, integrationRecordId : Text;
        JObject: JsonObject;
        recSalesHeader: Record "Sales Header";
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('orders', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for index := 0 to varJsonArray.Count - 1 do begin
                Sleep(500);
                varJsonArray.Get(index, varjsonToken);

                Clear(BQOrderId);
                BQOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');

                if not InsertSalesHeader(varjsonToken, BQOrderId, recBQSetting, index) then begin
                    description := 'Entry for OrderId ' + BQOrderId + ' is failed to download';
                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, BQOrderId, EnhIntegrationLogTypes::"B&Q", false, 'Order Id');
                end;
            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for index := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(index, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::"B&Q");
        end;
    end;

    //Insert records into Sales Header table
    [TryFunction]
    procedure InsertSalesHeader(varjsonToken: JsonToken; BQOrderId: Code[20]; recBQSetting: Record "B&Q Settings"; r: Integer)
    var
        recSalesHeader: Record "Sales Header";
        recSalesInvoiceHeader: Record "Sales Invoice Header";
        recLegacyOrders: Record LegacyOrders;
        i, j, lineNo : Integer;
        varJsonArray, responseArray : JsonArray;
        customerToken, billingAddressToken, shippingAddressToken, orderLinesToken, customerAddressToken : JsonToken;
        enumSalesHeaderStatus: enum "Sales Document Status";
        orderLineId, ItemNo : Code[40];
        shipToPostcode, shipToCounty, billToCounty, description : Text;
        itemNotExist, LineNotInserted : Boolean;
        SalesHeaderNo: Code[20];
        recItem: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        customerAddressToken := varjsonToken;
        Clear(shipToPostcode);
        Clear(orderLinesToken);
        Clear(NYTJSONMgt);
        Clear(customerToken);
        Clear(shippingAddressToken);
        Clear(billingAddressToken);

        recSalesHeader.Reset();
        recLegacyOrders.Reset();
        recLegacyOrders.SetRange(MarketplaceName, 'B&Q');
        recLegacyOrders.SetRange(OrderId, BQOrderId);

        if not recLegacyOrders.FindFirst() then begin

            recSalesHeader.SetRange("External Document No.", BQOrderId);

            if not recSalesHeader.FindFirst() then begin

                recSalesInvoiceHeader.SetRange("External Document No.", BQOrderId);

                if not recSalesInvoiceHeader.FindFirst() then begin

                    varjsonToken.SelectToken('orderLines', orderLinesToken);

                    if orderLinesToken.IsArray then begin
                        responseArray := orderLinesToken.AsArray();

                        for j := 0 to responseArray.Count - 1 do begin
                            responseArray.Get(j, orderLinesToken);

                            ItemNo := NYTJSONMgt.GetValueAsText(orderLinesToken, 'offerSKU');

                            recItem.SetRange("No.", ItemNo);

                            if recItem.FindFirst() then begin
                                if recItem.Blocked then begin
                                    description := 'This item ' + ItemNo + ' is blocked';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, BQOrderId, EnhIntegrationLogTypes::"B&Q", true, 'Order Id');
                                end;
                            end
                            else begin
                                itemNotExist := true;
                                description := 'This Item not found ' + ItemNo + ' so failed to download the order';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, BQOrderId, EnhIntegrationLogTypes::"B&Q", true, 'Order Id');
                            end;
                        end;
                    end;

                    if itemNotExist = false then begin
                        recSalesHeader.Init();
                        recSalesHeader.InitRecord;
                        recSalesHeader."No." := '';
                        recSalesHeader."Document Type" := "Sales Document Type"::Order;

                        recSalesHeader."Sell-to Customer No." := recBQSetting.CustomerCode;
                        recSalesHeader.Validate("Sell-to Customer No.");
                        recSalesHeader."External Document No." := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');
                        recSalesHeader."Customer Posting Group" := 'DOMESTIC';

                        customerAddressToken.SelectToken('customer', customerToken);

                        if customerToken.IsObject then begin

                            customerToken.SelectToken('shippingAddress', shippingAddressToken);

                            if shippingAddressToken.IsObject then begin

                                recSalesHeader."Ship-to Name" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'firstName') + ' ' + NYTJSONMgt.GetValueAsText(shippingAddressToken, 'lastName');
                                recSalesHeader."Ship-to Address" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'street1');
                                recSalesHeader."Ship-to City" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'city'), 1, 30);
                                recSalesHeader."Ship-to Post Code" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'zipCode');
                                shipToPostcode := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'zipCode');
                                shipToCounty := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'state');
                                recSalesHeader."Ship-to County" := CopyStr(shipToCounty, 1, 30);
                                recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'phone');
                                recSalesHeader."Ship-to Contact" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'firstName') + ' ' + NYTJSONMgt.GetValueAsText(shippingAddressToken, 'lastName');
                            end;

                            customerToken.SelectToken('billingAddress', billingAddressToken);

                            if billingAddressToken.IsObject then begin
                                recSalesHeader."Bill-to Address" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'street1');
                                recSalesHeader."Bill-to City" := CopyStr(NYTJSONMgt.GetValueAsText(billingAddressToken, 'city'), 1, 30);
                                recSalesHeader."Bill-to Post Code" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'zipCode');
                                billToCounty := NYTJSONMgt.GetValueAsText(billingAddressToken, 'state');
                                recSalesHeader."Bill-to County" := CopyStr(billToCounty, 1, 30);
                                recSalesHeader."Bill-to Name" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'firstName') + ' ' + NYTJSONMgt.GetValueAsText(billingAddressToken, 'lastName');
                                recSalesHeader."Bill-to Contact" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'firstName') + ' ' + NYTJSONMgt.GetValueAsText(billingAddressToken, 'lastName');
                            end;
                        end;

                        recSalesHeader."Sell-to E-Mail" := NYTJSONMgt.GetValueAsText(varjsonToken, 'customerNotificationEmail');
                        recSalesHeader.Validate("Sell-to E-Mail");
                        recSalesHeader."Payment Method Code" := 'B&Q';
                        recSalesHeader.OrderBatch := 'B&Q';
                        recSalesHeader."Shipping Agent Code" := 'DPD';
                        recSalesHeader."Shipping Agent Service Code" := '12';
                        recSalesHeader.Source := "Order Source"::"B&Q";

                        recSalesHeader.Insert(true);
                        Commit();

                        SalesHeaderNo := recSalesHeader."No.";

                        varjsonToken.SelectToken('orderLines', orderLinesToken);

                        if orderLinesToken.IsArray then begin
                            responseArray := orderLinesToken.AsArray();

                            for j := 0 to responseArray.Count - 1 do begin
                                lineNo := 10000 + (j * 10000);
                                responseArray.Get(j, orderLinesToken);

                                if not InsertSalesLine(varjsonToken, orderLinesToken, recSalesHeader."No.", lineNo, false, shipToPostcode) then begin

                                    recSalesHeader.Delete(true);
                                    ItemNo := NYTJSONMgt.GetValueAsText(orderLinesToken, 'offerSKU');
                                    description := 'In Order ' + BQOrderId + ' entry for Orderline ' + ItemNo + ' is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, BQOrderId, EnhIntegrationLogTypes::"B&Q", false, 'Order Id');
                                    LineNotInserted := true;
                                end;
                            end;

                            if LineNotInserted = false then begin

                                lineNo := lineNo + 10000;

                                if not InsertSalesLine(varjsonToken, orderLinesToken, recSalesHeader."No.", lineNo, true, shipToPostcode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'Entry for item Carriage charge is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, BQOrderId, EnhIntegrationLogTypes::"B&Q", false, 'Order Id');
                                end;

                                recSalesHeader."Shortcut Dimension 1 Code" := 'B&Q';
                                ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                recSalesHeader.Modify(true);

                                // recSalesHeader.Reset();
                                // recSalesHeader.SetRange("No.", SalesHeaderNo);

                                // if recSalesHeader.FindFirst() then begin
                                //     recSalesHeader."Shortcut Dimension 1 Code" := 'B&Q';
                                //     recSalesHeader.Modify(true);

                                //     ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                //     Commit();
                                // end;

                                recLegacyOrders.Init();
                                recLegacyOrders.MarketplaceName := 'B&Q';
                                recLegacyOrders.OrderId := recSalesHeader."External Document No.";
                                recLegacyOrders.Insert(true);
                            end;
                        end;
                    end;
                end;
            end;
        end;
        Commit();
    end;

    [TryFunction]
    //Insert records into Sales Line table
    local procedure InsertSalesLine(var varjsonToken: JsonToken; orderLinesToken: JsonToken; var documnetNo: Code[20]; var lineNo: Integer; carriageflag: Boolean; shipToPostcode: Text)
    var
        recSalesLine: Record "Sales Line";
        recItem: Record Item;
        ItemNo: Code[30];
        quantity: Integer;
        UnitPriceIncludingVat, UnitPriceExcludingVat, VatPercentage, UnitPriceFromApi : Decimal;
        cuHOSTryReserve: Codeunit HOSTryReserve;

    begin
        recSalesLine.Init();
        recSalesLine."Line No." := lineNo;
        recSalesLine."Document No." := documnetNo;
        recSalesLine."Document Type" := "Sales Document Type"::Order;
        recSalesLine.Type := "Sales Line Type"::Item;

        if not carriageflag then begin
            recSalesLine."No." := NYTJSONMgt.GetValueAsText(orderLinesToken, 'offerSKU');
            recSalesLine.Validate("No.");
            ItemNo := NYTJSONMgt.GetValueAsText(orderLinesToken, 'offerSKU');
            quantity := NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'quantity');
            recSalesLine.Quantity := quantity;
            recSalesLine.Validate(Quantity);

            recSalesLine.ActualApiPrice := NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'priceUnit');
            recSalesLine.TotalApiPrice := (NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'priceUnit')) * quantity;

            //            UnitPriceFromApi := NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'priceUnit') * quantity;

            UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'priceUnit');
            recSalesLine."Unit Price" := UnitPriceIncludingVat;
            recSalesLine.Validate("Unit Price");

            if (shipToPostcode.StartsWith('JE')) or (shipToPostcode.StartsWith('GY')) then begin
                recSalesLine."VAT Prod. Posting Group" := 'ZERO_0%';
                recSalesLine.Validate("VAT Prod. Posting Group");
            end
            else begin
                VatPercentage := 1 + (recSalesLine."VAT %" / 100);
                UnitPriceExcludingVat := UnitPriceIncludingVat / VatPercentage;

                recSalesLine."Unit Price" := UnitPriceExcludingVat;
                recSalesLine.Validate("Unit Price");
            end;
            recSalesLine."3rd Party System PK" := NYTJSONMgt.GetValueAsText(orderLinesToken, 'orderLineId');
        end
        else begin
            recSalesLine."No." := 'CARRIAGE';
            recSalesLine.Validate("No.");
            recSalesLine.Description := NYTJSONMgt.GetValueAsText(varjsonToken, 'shippingTypeLabel');
            UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(varjsonToken, 'shippingPrice');

            recSalesLine.Quantity := 1;
            recSalesLine.Validate(Quantity);

            recSalesLine."Unit Price" := UnitPriceIncludingVat;
            recSalesLine.Validate("Unit Price");

            if (shipToPostcode.StartsWith('JE')) or (shipToPostcode.StartsWith('GY')) then begin
                recSalesLine."VAT Prod. Posting Group" := 'ZERO_0%';
                recSalesLine.Validate("VAT Prod. Posting Group");
            end
            else begin
                VatPercentage := 1 + (recSalesLine."VAT %" / 100);
                UnitPriceExcludingVat := UnitPriceIncludingVat / VatPercentage;

                recSalesLine."Unit Price" := UnitPriceExcludingVat;
                recSalesLine.Validate("Unit Price");
            end;
        end;

        recSalesLine."Shortcut Dimension 1 Code" := 'B&Q';
        recSalesLine.Insert(true);
        Commit();

        if recSalesLine."No." <> 'CARRIAGE' then begin
            cuHOSTryReserve.TryReserve(recSalesLine."Document No.");
            //cu_CommonHelper.InsertMagentoGrossValue(documnetNo, UnitPriceFromApi);
        end;

        if recSalesLine.IsAsmToOrderRequired() then begin
            recSalesLine.AutoAsmToOrder();
        end;
    end;
}