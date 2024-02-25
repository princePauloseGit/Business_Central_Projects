codeunit 50424 "Ebay Order Download"
{
    trigger OnRun()
    begin
        ConnectEbayAPIForSalesOrders()
    end;

    var
        eBayURI: Text;
        rec_EbaySettings: Record "ebay Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure ConnectEbayAPIForSalesOrders()
    var
        result: text;
        past10Days: Date;
    begin
        Clear(RESTAPIHelper);
        Clear(eBayURI);
        eBayURI := RESTAPIHelper.GetBaseURl() + 'Ebay/GetOrders';
        past10Days := cu_CommonHelper.CalculateDate(10);

        rec_EbaySettings.Reset();
        if rec_EbaySettings.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                Clear(RESTAPIHelper);
                //Headers
                RESTAPIHelper.Initialize('POST', eBayURI);

                RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());

                RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                //Body
                RESTAPIHelper.AddBody('{"days": 10}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result, rec_EbaySettings);
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    procedure ConnectEbayAPIForManualSalesOrders()
    var
        result, nextPage, body : text;
        past10Days: Date;
        JObject: JsonObject;
        varjsonToken: JsonToken;
    begin

        Clear(RESTAPIHelper);
        Clear(eBayURI);
        eBayURI := RESTAPIHelper.GetBaseURl() + 'Ebay/GetOrders';
        past10Days := cu_CommonHelper.CalculateDate(10);

        rec_EbaySettings.Reset();

        if rec_EbaySettings.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                if rec_EbaySettings.ManualTest = true then begin
                    Clear(RESTAPIHelper);
                    //Headers
                    RESTAPIHelper.Initialize('POST', eBayURI);

                    RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                    RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());

                    RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                    //Body
                    if rec_EbaySettings.nextpage = '' then begin
                        nextPage := '';
                    end else begin
                        nextPage := format(rec_EbaySettings.nextpage);
                    end;

                    body := '{"days": 10,"limit": ' + format(rec_EbaySettings.limit) + ',"nextPage": "' + nextPage + '","manualTest": true }';

                    RESTAPIHelper.AddBody(body);

                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();

                        ReadApiResponse(result, rec_EbaySettings);

                        if not JObject.ReadFrom(result) then begin
                            Error('Invalid response, expected a JSON object');
                        end;

                        JObject.Get('nextToken', varjsonToken);

                        if (format(varjsonToken) = '""') and (rec_EbaySettings.ManualTest = true) then begin
                            rec_EbaySettings.ManualTest := false;
                            rec_EbaySettings.limit := 0;

                            rec_EbaySettings.Modify(true);
                        end;

                        if rec_EbaySettings.ManualTest = true then begin
                            rec_EbaySettings.nextpage := format(varjsonToken);

                            rec_EbaySettings.Modify(true);
                        end;
                    end;

                end else begin
                    Message('Manual test is off for customer %1', rec_EbaySettings.CustomerCode);
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    local procedure ReadApiResponse(var apiResponse: Text; var recEbaySetting: Record "ebay Setting")
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        i: Integer;
        eBayOrderId: Code[40];
        description: Text;
        JObject: JsonObject;
        recSalesHeader: Record "Sales Header";
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        integrationRecordId: Text;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('orders', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(eBayOrderId);
                eBayOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');

                if not InsertSalesHeader(varjsonToken, eBayOrderId, rec_EbaySettings) then begin
                    description := 'Entry for OrderId ' + eBayOrderId + ' is failed to download';
                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, eBayOrderId, EnhIntegrationLogTypes::Ebay, false, 'Order Id');
                end;
                Commit();
            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Ebay);
        end;
        Commit();
    end;

    [TryFunction]
    procedure InsertSalesHeader(varjsonToken: JsonToken; eBayOrderId: Code[20]; recEbaySetting: Record "ebay Setting")
    var
        recSalesHeader: Record "Sales Header";
        recSalesInvoiceHeader: Record "Sales Invoice Header";
        recLegacyOrders: Record LegacyOrders;
        i, j, lineNo : Integer;
        varJsonArray, responseArray : JsonArray;
        JObject: JsonObject;
        fulfilmentInstructionToken, shippingStepToken, shipToToken, billToToken, sellToToken, shipContactAddressToken, primaryPhoneToken, orderLinesToken, billContactAddressToken, sellContactAddressToken : JsonToken;
        salesno: Code[20];
        description, shippingServiceCode : Text;
        orderLineId, ItemNo : Code[40];
        postalCode, sellAddress, county, shipAddress, billAddress : Text;
        recItem: Record Item;
        itemNotExist, LineNotInserted : Boolean;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesHeaderNo: Code[20];
    begin
        recSalesHeader.Reset();
        recLegacyOrders.Reset();
        recLegacyOrders.SetRange(MarketplaceName, 'Ebay');
        recLegacyOrders.SetRange(OrderId, eBayOrderId);

        if not recLegacyOrders.FindFirst() then begin
            recSalesHeader.SetRange("External Document No.", eBayOrderId);
            if not recSalesHeader.FindFirst() then begin
                recSalesInvoiceHeader.SetRange("External Document No.", eBayOrderId);
                if not recSalesInvoiceHeader.FindFirst() then begin

                    varjsonToken.SelectToken('orderLines', orderLinesToken);
                    if orderLinesToken.IsArray then begin
                        responseArray := orderLinesToken.AsArray();
                        for j := 0 to responseArray.Count - 1 do begin
                            responseArray.Get(j, orderLinesToken);

                            ItemNo := NYTJSONMgt.GetValueAsText(orderLinesToken, 'sku');

                            recItem.SetRange("No.", ItemNo);

                            if recItem.FindFirst() then begin
                                if recItem.Blocked then begin
                                    description := 'This item ' + ItemNo + ' is blocked';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, eBayOrderId, EnhIntegrationLogTypes::Ebay, true, 'Order Id');
                                end;
                            end
                            else begin
                                itemNotExist := true;
                                description := 'This Item not found ' + ItemNo + ' so failed to download the order';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, eBayOrderId, EnhIntegrationLogTypes::Ebay, true, 'Order Id');
                            end;
                        end;
                    end;
                    if itemNotExist = false then begin
                        recSalesHeader.Init();
                        recSalesHeader.InitRecord;
                        recSalesHeader."No." := '';
                        salesno := recSalesHeader."No.";
                        recSalesHeader."Document Type" := "Sales Document Type"::Order;
                        recSalesHeader."Sell-to Customer No." := recEbaySetting.CustomerCode;
                        recSalesHeader.Validate("Sell-to Customer No.");
                        recSalesHeader."External Document No." := eBayOrderId;
                        recSalesHeader."Shortcut Dimension 1 Code" := 'Ebay';
                        recSalesHeader.Source := "Order Source"::eBay;

                        recSalesHeader."Payment Method Code" := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderPaymentMethod');
                        recSalesHeader.OrderBatch := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderBatchValue');

                        shippingServiceCode := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderBatchValue');

                        if (shippingServiceCode = 'MANUAL') then begin
                            recSalesHeader."Shipping Agent Code" := 'MANUAL';
                            recSalesHeader."Shipping Agent Service Code" := 'MANUAL';
                        end;

                        if (shippingServiceCode = 'POST') then begin
                            recSalesHeader."Shipping Agent Code" := 'RM';
                            recSalesHeader."Shipping Agent Service Code" := 'RM';
                        end;

                        if (shippingServiceCode = 'CARRIER') then begin
                            recSalesHeader."Shipping Agent Code" := 'DPD';
                            recSalesHeader."Shipping Agent Service Code" := '12';
                        end;

                        varjsonToken.SelectToken('fulfillmentStartInstructions', fulfilmentInstructionToken);
                        if fulfilmentInstructionToken.IsArray then begin
                            responseArray := fulfilmentInstructionToken.AsArray();
                            responseArray.Get(0, fulfilmentInstructionToken);

                            fulfilmentInstructionToken.SelectToken('shippingStep', shippingStepToken);

                            if fulfilmentInstructionToken.IsObject then begin
                                shippingStepToken.SelectToken('shipTo', shipToToken);
                                shippingStepToken.SelectToken('billTo', billToToken);
                                shippingStepToken.SelectToken('sellTo', sellToToken);

                                recSalesHeader."Ship-to Name" := NYTJSONMgt.GetValueAsText(shipToToken, 'fullName');
                                recSalesHeader."Ship-to Contact" := NYTJSONMgt.GetValueAsText(shipToToken, 'fullName');

                                recSalesHeader."bill-to Name" := NYTJSONMgt.GetValueAsText(billToToken, 'fullName');
                                recSalesHeader."Bill-to Contact" := NYTJSONMgt.GetValueAsText(billToToken, 'fullName');

                                recSalesHeader."sell-to Contact" := NYTJSONMgt.GetValueAsText(sellToToken, 'fullName');
                                recSalesHeader."Sell-to E-Mail" := NYTJSONMgt.GetValueAsText(sellToToken, 'email');

                                if shippingStepToken.IsObject then begin
                                    sellToToken.SelectToken('contactAddress', sellContactAddressToken);
                                    //sell to
                                    recSalesHeader."sell-to Address" := NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'addressLine1');
                                    sellAddress := NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'addressLine2');
                                    recSalesHeader."Sell-to Address 2" := CopyStr(sellAddress, 1, 50);
                                    recSalesHeader."sell-to City" := CopyStr(NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'city'), 1, 30);
                                    recSalesHeader."sell-to Country/Region Code" := NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'countryCode');
                                    recSalesHeader."Sell-to Post Code" := NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'postalCode');
                                    county := NYTJSONMgt.GetValueAsText(sellContactAddressToken, 'stateOrProvince');
                                    recSalesHeader."Sell-to County" := CopyStr(county, 1, 30);

                                    sellToToken.SelectToken('primaryPhone', primaryPhoneToken);
                                    recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(primaryPhoneToken, 'phoneNumber');

                                    //Bill to
                                    billToToken.SelectToken('contactAddress', billContactAddressToken);

                                    recSalesHeader."Bill-to Address" := NYTJSONMgt.GetValueAsText(billContactAddressToken, 'addressLine1');
                                    billAddress := NYTJSONMgt.GetValueAsText(billContactAddressToken, 'addressLine2');
                                    recSalesHeader."Bill-to Address 2" := CopyStr(billAddress, 1, 50);
                                    recSalesHeader."bill-to City" := CopyStr(NYTJSONMgt.GetValueAsText(billContactAddressToken, 'city'), 1, 30);
                                    recSalesHeader."bill-to Country/Region Code" := NYTJSONMgt.GetValueAsText(billContactAddressToken, 'countryCode');
                                    recSalesHeader."Bill-to Post Code" := NYTJSONMgt.GetValueAsText(billContactAddressToken, 'postalCode');
                                    recSalesHeader."bill-to County" := CopyStr(county, 1, 30);

                                    //ship to
                                    shipToToken.SelectToken('contactAddress', shipContactAddressToken);
                                    recSalesHeader."Ship-to Address" := NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'addressLine1');
                                    shipAddress := NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'addressLine2');
                                    recSalesHeader."Ship-to Address 2" := CopyStr(shipAddress, 1, 50);
                                    recSalesHeader."Ship-to City" := CopyStr(NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'city'), 1, 30);
                                    recSalesHeader."Ship-to Country/Region Code" := NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'countryCode');
                                    recSalesHeader."Ship-to Post Code" := NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'postalCode');
                                    recSalesHeader."Ship-to County" := CopyStr(county, 1, 30);

                                    postalCode := NYTJSONMgt.GetValueAsText(shipContactAddressToken, 'postalCode');
                                end;
                            end;
                        end;

                        recSalesHeader.Insert(true);
                        Commit();

                        SalesHeaderNo := recSalesHeader."No.";

                        varjsonToken.SelectToken('orderLines', orderLinesToken);

                        if orderLinesToken.IsArray then begin
                            responseArray := orderLinesToken.AsArray();

                            for j := 0 to responseArray.Count - 1 do begin
                                lineNo := 10000 + (j * 10000);
                                responseArray.Get(j, orderLinesToken);

                                if not InsertSalesLine(varjsonToken, orderLinesToken, recSalesHeader."No.", lineNo, false, postalCode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'In Order ' + eBayOrderId + ' entry for Orderline ' + orderLineId + 'is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, eBayOrderId, EnhIntegrationLogTypes::Ebay, false, 'Order Id');
                                    LineNotInserted := true;
                                end;
                            end;

                            if LineNotInserted = false then begin

                                lineNo := lineNo + 10000;

                                if not InsertSalesLine(varjsonToken, orderLinesToken, recSalesHeader."No.", lineNo, true, postalCode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'Entry for item Carriage charge is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, eBayOrderId, EnhIntegrationLogTypes::"Ebay", false, 'Order Id');
                                end;

                                recSalesHeader."Shortcut Dimension 1 Code" := 'Ebay';
                                ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                recSalesHeader.Modify(true);

                                // recSalesHeader.Reset();
                                // recSalesHeader.SetRange("No.", SalesHeaderNo);

                                // if recSalesHeader.FindFirst() then begin
                                //     recSalesHeader."Shortcut Dimension 1 Code" := 'EBAY';
                                //     recSalesHeader.Modify(true);

                                //     ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                //     Commit();
                                // end;

                                recLegacyOrders.Init();
                                recLegacyOrders.MarketplaceName := 'Ebay';
                                recLegacyOrders.OrderId := recSalesHeader."External Document No.";
                                recLegacyOrders.Insert(true);
                                Commit();
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;

    [TryFunction]
    //Insert records into Sales Line table
    local procedure InsertSalesLine(var varjsonToken: JsonToken; orderLinesToken: JsonToken; var documnetNo: Code[20]; var lineNo: Integer; carriageflag: Boolean; postalCode: Text)
    var
        recSalesLine: Record "Sales Line";
        recItem: Record Item;
        ItemNo: Code[30];
        unitPriceToken: JsonToken;
        UnitPriceIncludingVat, UnitPriceExcludingVat, VatPercentage, UnitPriceFromApi : Decimal;
        quantity: Integer;
        cuHOSTryReserve: Codeunit HOSTryReserve;
        recEbayItemList: Record EbayItemsList;
    begin

        recSalesLine.Init();
        recSalesLine."Line No." := lineNo;
        recSalesLine."Document No." := documnetNo;
        recSalesLine."Document Type" := "Sales Document Type"::Order;
        recSalesLine.Type := "Sales Line Type"::Item;

        if not carriageflag then begin
            ItemNo := NYTJSONMgt.GetValueAsText(orderLinesToken, 'sku');
            recSalesLine."No." := ItemNo;
            recSalesLine.Validate("No.");

            recSalesLine."3rd Party System PK" := NYTJSONMgt.GetValueAsText(orderLinesToken, 'lineItemId');

            quantity := NYTJSONMgt.GetValueAsDecimal(orderLinesToken, 'quantity');
            recSalesLine.Quantity := quantity;
            recSalesLine.Validate(Quantity);

            orderLinesToken.SelectToken('lineItemCost', unitPriceToken);
            // UnitPriceFromApi := (NYTJSONMgt.GetValueAsDecimal(unitPriceToken, 'value'));
            recSalesLine.ActualApiPrice := (NYTJSONMgt.GetValueAsDecimal(unitPriceToken, 'value')) / quantity;
            recSalesLine.TotalApiPrice := (NYTJSONMgt.GetValueAsDecimal(unitPriceToken, 'value'));

            UnitPriceIncludingVat := (NYTJSONMgt.GetValueAsDecimal(unitPriceToken, 'value')) / quantity;
            recSalesLine."Unit Price" := UnitPriceIncludingVat;
            recSalesLine.Validate("Unit Price");

            if (postalCode.StartsWith('JE')) or (postalCode.StartsWith('GY')) then begin
                recSalesLine."VAT Prod. Posting Group" := 'ZERO_0%';
                recSalesLine.Validate("VAT Prod. Posting Group");
            end
            else begin
                VatPercentage := 1 + (recSalesLine."VAT %" / 100);
                UnitPriceExcludingVat := UnitPriceIncludingVat / VatPercentage;

                recSalesLine."Unit Price" := UnitPriceExcludingVat;
                recSalesLine.Validate("Unit Price");
            end;

            recEbayItemList.Reset();
            recEbayItemList.SetRange("No.", ItemNo);

            if recEbayItemList.FindFirst() then begin

                if recEbayItemList.Listing_ID <> '' then begin
                    recEbayItemList.ForceUpdate := true;
                    recEbayItemList.Modify(true);
                end;
            end;

        end
        else begin
            recItem.SetRange("No.", 'CARRIAGE');
            if recItem.FindSet() then begin
                recSalesLine."No." := recItem."No.";
                recSalesLine.Validate("No.");
                recSalesLine.Quantity := 1;
                recSalesLine.Validate(Quantity);
                UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(varjsonToken, 'shippingPrice');

                recSalesLine."Unit Price" := UnitPriceIncludingVat;
                recSalesLine.Validate("Unit Price");

                if (postalCode.StartsWith('JE')) or (postalCode.StartsWith('GY')) then begin
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
        end;

        recSalesLine."Shortcut Dimension 1 Code" := 'EBAY';
        recSalesLine.Insert(true);

        if recSalesLine."No." <> 'CARRIAGE' then begin
            cuHOSTryReserve.TryReserve(recSalesLine."Document No.");
            //cu_CommonHelper.InsertMagentoGrossValue(documnetNo, UnitPriceFromApi);
        end;

        if recSalesLine.IsAsmToOrderRequired() then begin
            recSalesLine.AutoAsmToOrder();
        end;
        Commit();
    end;
}