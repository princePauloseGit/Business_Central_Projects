codeunit 50407 "AmazonOrdersDownload"
{
    trigger OnRun()
    begin
        ConnectAmazonAPIForSalesOrders();
    end;

    var
        amazonURI: Text;
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    // Connect Amazon Api for Get Orders
    procedure ConnectAmazonAPIForSalesOrders()
    var
        result, errorMessage : text;
        Past10DaysDate: Date;
        i: Integer;
        rec_AmazonSetting: Record "Amazon Setting";
    begin
        //get past 10 day date 
        Past10DaysDate := cu_CommonHelper.CalculateDate(10);

        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                if rec_AmazonSetting.Orders then begin
                    Clear(RESTAPIHelper);
                    amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetOrders';
                    RESTAPIHelper.Initialize('POST', amazonURI);
                    RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                    RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                    RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
                    //Body
                    RESTAPIHelper.AddBody('{"testCase": "","createdAfter": "' + Format(Past10DaysDate, 0, 9) + '","orderStatuses": [2,3],"marketplaceIds": ["' + rec_AmazonSetting.MarketplaceID.Trim() + '"],"maxResultsPerPage": 50,"maxNumberOfPages": 1,"isNeedRestrictedDataToken": true,"fulfillmentChannels": [1]}');

                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadApiResponse(result, rec_AmazonSetting);
                    end;
                end
                else begin
                    errorMessage := 'The Download Order is disabled for the customer; please grant access to proceed.';
                    cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    procedure ConnectManualAmazonAPIForSalesOrders()
    var
        result, errorMessage, body : text;
        Past10DaysDate: Date;
        i: Integer;
        rec_AmazonSetting: Record "Amazon Setting";
        varjsonToken, nextToken : JsonToken;
        JObject: JsonObject;
    begin
        //get past 10 day date 
        Past10DaysDate := cu_CommonHelper.CalculateDate(10);

        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                if (rec_AmazonSetting.manualTest = true) and (rec_AmazonSetting.nextToken = '') then begin
                    if rec_AmazonSetting.Orders then begin
                        Clear(RESTAPIHelper);
                        amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetOrders';
                        RESTAPIHelper.Initialize('POST', amazonURI);
                        RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                        RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                        RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                        RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                        RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                        RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                        RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());

                        RESTAPIHelper.AddBody('{"testCase": "","createdAfter": "' + Format(Past10DaysDate, 0, 9) + '","orderStatuses": [2,3],"marketplaceIds": ["' + rec_AmazonSetting.MarketplaceID.Trim() + '"],"maxResultsPerPage": ' + format(rec_AmazonSetting.limit) + ',"maxNumberOfPages": 1,"isNeedRestrictedDataToken": true,"fulfillmentChannels": [1]}');

                        //ContentType
                        RESTAPIHelper.SetContentType('application/json');

                        if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                            result := RESTAPIHelper.GetResponseContentAsText();

                            ReadApiResponse(result, rec_AmazonSetting);

                            if not JObject.ReadFrom(result) then begin
                                Error('Invalid response, expected a JSON object');
                            end;

                            JObject.Get('nextToken', varjsonToken);

                            if (format(varjsonToken) = '""') and (format(varjsonToken) = '') and (format(varjsonToken) = 'null') and (rec_AmazonSetting.ManualTest = true) then begin
                                rec_AmazonSetting.ManualTest := false;
                                rec_AmazonSetting.limit := 0;
                                rec_AmazonSetting.nextToken := '';

                                rec_AmazonSetting.Modify(true);
                            end;

                            if rec_AmazonSetting.ManualTest = true then begin
                                rec_AmazonSetting.nextToken := format(varjsonToken);

                                rec_AmazonSetting.Modify(true);
                            end;

                            exit;
                        end
                        else
                            Message('Please check API Details');
                    end
                    else begin
                        errorMessage := 'The Download Order is disabled for the customer; please grant access to proceed.';
                        cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                    end;
                end;

                if (rec_AmazonSetting.manualTest = true) and (rec_AmazonSetting.nextToken <> '')
                then begin
                    ConnectAmazonAPIGetOrdersByNextToken(rec_AmazonSetting, rec_AmazonSetting.nextToken);
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    // Connect Amazon GetOrders Api after getting next token
    procedure ConnectAmazonAPIGetOrdersByNextToken(rec_AmazonSetting: Record "Amazon Setting"; nextToken: Text)
    var
        result: Text;
        i: Integer;
        varjsonToken: JsonToken;
        JObject: JsonObject;
    begin
        SLEEP(2500);
        Clear(RESTAPIHelper);
        amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetOrdersByNextToken';
        RESTAPIHelper.Initialize('POST', amazonURI);
        RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
        RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
        RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
        RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
        RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
        RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
        RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
        RESTAPIHelper.AddRequestHeader('NextToken', nextToken);

        RESTAPIHelper.AddBody('{"isNeedRestrictedDataToken": true}');
        RESTAPIHelper.SetContentType('application/json');

        if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
            result := RESTAPIHelper.GetResponseContentAsText();
            ReadApiResponse(result, rec_AmazonSetting);

            if not JObject.ReadFrom(result) then begin
                Error('Invalid response, expected a JSON object');
            end;

            JObject.Get('nextToken', varjsonToken);

            if (format(varjsonToken) = '""') and (format(varjsonToken) = '') and (format(varjsonToken) = 'null') and (rec_AmazonSetting.ManualTest = true) then begin
                rec_AmazonSetting.ManualTest := false;
                rec_AmazonSetting.limit := 0;
                rec_AmazonSetting.nextToken := '';

                rec_AmazonSetting.Modify(true);
            end;

            if rec_AmazonSetting.ManualTest = true then begin
                rec_AmazonSetting.nextToken := format(varjsonToken);

                rec_AmazonSetting.Modify(true);
            end;

            exit;
        end;
    end;

    local procedure ReadApiResponse(var apiResponse: Text; var recAmazonSetting: Record "Amazon Setting")
    var
        i: Integer;
        varJsonArray, Jarray : JsonArray;
        varjsonToken, JToken, nextJToken : JsonToken;
        amazonOrderId: Code[40];
        description, nextToken, integrationRecordId : Text;
        JObject: JsonObject;
        recSalesHeader: Record "Sales Header";
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('orders', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(amazonOrderId);
                amazonOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');

                if not InsertSalesHeader(varjsonToken, amazonOrderId, recAmazonSetting) then begin
                    description := 'Entry for OrderId ' + amazonOrderId + ' is failed to download';
                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
                end;
                Commit();
            end;
        end;

        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');
        JObject.Get('errorLogs', Jtoken);

        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(Jtoken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);
                cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Amazon);
            end;
        end;

        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('nextToken', nextJToken);

        if (format(nextJToken) <> '') and (format(nextJToken) <> 'null') and (format(nextJToken) <> '""') then begin
            nextToken := nextJToken.AsValue().AsText();
            if (recAmazonSetting.ManualTest = false) then begin
                ConnectAmazonAPIGetOrdersByNextToken(recAmazonSetting, nextToken);
            end;
        end;
    end;

    //Insert Sales Header 
    [TryFunction]
    local procedure InsertSalesHeader(var varjsonToken: JsonToken; amazonOrderId: Code[20]; var recAmazonSetting: Record "Amazon Setting")
    var
        recSalesHeader: Record "Sales Header";
        recSalesInvoiceHeader: Record "Sales Invoice Header";
        recLegacyOrders: Record LegacyOrders;
        i, j, lineNo : Integer;
        responseArray: JsonArray;
        shippingAddressToken, orderItemListToken, orderTotaltoken, buyerInfoToken : JsonToken;
        salesno, SalesHeaderNo : Code[20];
        orderItemId, ItemNo : Code[40];
        orderTotalAmount: Decimal;
        description, postalCode, address, county : Text;
        itemExist, itemNotExist, LineNotInserted : Boolean;
        recItem: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        Clear(amazonOrderId);
        amazonOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');
        Clear(postalCode);
        recLegacyOrders.Reset();
        recSalesHeader.Reset();
        recSalesInvoiceHeader.Reset();
        recLegacyOrders.SetRange(MarketplaceName, 'Amazon');
        recLegacyOrders.SetRange(OrderId, amazonOrderId);

        if not recLegacyOrders.FindFirst() then begin
            recSalesHeader.SetRange("External Document No.", amazonOrderId);

            if not recSalesHeader.FindFirst() then begin
                recSalesInvoiceHeader.SetRange("External Document No.", amazonOrderId);

                if not recSalesInvoiceHeader.FindFirst() then begin
                    varjsonToken.SelectToken('orderItemList', orderItemListToken);

                    if orderItemListToken.IsArray then begin
                        responseArray := orderItemListToken.AsArray();

                        for j := 0 to responseArray.Count - 1 do begin
                            lineNo := 10000 + (j * 10000);
                            responseArray.Get(j, orderItemListToken);
                            ItemNo := NYTJSONMgt.GetValueAsText(orderItemListToken, 'sellerSKU');

                            recItem.SetRange("No.", ItemNo);

                            if recItem.FindFirst() then begin
                                if recItem.Blocked then begin
                                    description := 'This item ' + ItemNo + ' is blocked';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, true, 'Order Id');
                                end;
                            end
                            else begin
                                itemNotExist := true;
                                description := '' + ItemNo + ' Item not found so failed to download the order';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, true, 'Order Id');
                            end;
                        end;
                    end;

                    if itemNotExist = false then begin
                        recSalesHeader.Init();
                        recSalesHeader.InitRecord;
                        recSalesHeader."No." := '';
                        salesno := recSalesHeader."No.";
                        recSalesHeader."Document Type" := "Sales Document Type"::Order;
                        recSalesHeader."Sell-to Customer No." := recAmazonSetting.CustomerCode;
                        recSalesHeader.Validate("Sell-to Customer No.");
                        recSalesHeader."External Document No." := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');
                        recSalesHeader."Customer Posting Group" := recAmazonSetting.PostingGroupMFA;

                        varjsonToken.SelectToken('orderTotal', orderTotaltoken);
                        if varjsonToken.IsObject then begin
                            orderTotalAmount := NYTJSONMgt.GetValueAsDecimal(orderTotaltoken, 'amount');
                        end;

                        varjsonToken.SelectToken('shippingAddress', shippingAddressToken);

                        if varjsonToken.IsObject then begin
                            recSalesHeader."Ship-to Name" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'name');
                            recSalesHeader."Ship-to Address" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'addressLine1');
                            address := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'addressLine2');
                            recSalesHeader."Ship-to Address 2" := CopyStr(address, 1, 50);
                            recSalesHeader."Ship-to City" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'city'), 1, 30);
                            recSalesHeader."Ship-to Post Code" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'postalCode');
                            recSalesHeader."Ship-to Contact" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'name');
                            recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'phone');
                            county := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'county');
                            recSalesHeader."Ship-to County" := CopyStr(county, 1, 30);
                            postalCode := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'postalCode');

                            recSalesHeader."Bill-to Name" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'name');
                            recSalesHeader."Bill-to Address" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'addressLine1');
                            recSalesHeader."Bill-to Address 2" := CopyStr(address, 1, 50);
                            recSalesHeader."Bill-to City" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'city'), 1, 30);
                            recSalesHeader."Bill-to Post Code" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'postalCode');
                            recSalesHeader."Bill-to Contact" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'name');
                            recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'phone');
                            recSalesHeader."Bill-to County" := CopyStr(county, 1, 30);
                        end;

                        varjsonToken.SelectToken('buyerInfo', buyerInfoToken);

                        if varjsonToken.IsObject then begin
                            recSalesHeader."Sell-to E-Mail" := NYTJSONMgt.GetValueAsText(buyerInfoToken, 'buyerEmail');
                        end;

                        recSalesHeader.ShipServiceLevel := NYTJSONMgt.GetValueAsText(varjsonToken, 'shipServiceLevel');
                        recSalesHeader.OrderBatch := 'Prime';

                        //Need To add function for adding amazon in list Payment Method (289)
                        recSalesHeader."Payment Method Code" := 'AMAZON';
                        recSalesHeader.IsPrime := NYTJSONMgt.GetValueAsBoolean(varjsonToken, 'isPrime');
                        recSalesHeader."Shipping Agent Code" := 'AMAZON';
                        recSalesHeader."Shipping Agent Service Code" := 'AMAZON';
                        recSalesHeader.Source := "Order Source"::Amazon;
                        recSalesHeader.Insert(true);
                        Commit();

                        SalesHeaderNo := recSalesHeader."No.";

                        varjsonToken.SelectToken('orderItemList', orderItemListToken);

                        if orderItemListToken.IsArray then begin
                            responseArray := orderItemListToken.AsArray();

                            for j := 0 to responseArray.Count - 1 do begin
                                lineNo := 10000 + (j * 10000);
                                responseArray.Get(j, orderItemListToken);
                                orderItemId := NYTJSONMgt.GetValueAsText(orderItemListToken, 'orderItemId');

                                if not InsertSalesLine(orderItemListToken, recSalesHeader."No.", lineNo, false, postalCode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'In Order ' + amazonOrderId + ' entry for Orderline ' + orderItemId + 'is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
                                    LineNotInserted := true;
                                end;
                            end;

                            if LineNotInserted = false then begin

                                lineNo := lineNo + 10000;

                                if not InsertSalesLine(orderItemListToken, recSalesHeader."No.", lineNo, true, postalCode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'Entry for item Carriage charge is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
                                end;

                                // recSalesHeader."Shortcut Dimension 1 Code" := 'AMAZON';
                                // ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                // recSalesHeader.Modify(true);

                                recSalesHeader.Reset();
                                recSalesHeader.SetRange("No.", SalesHeaderNo);

                                if recSalesHeader.FindFirst() then begin
                                    recSalesHeader."Shortcut Dimension 1 Code" := 'AMAZON';
                                    recSalesHeader.Modify(true);

                                    ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                    Commit();
                                end;

                                recLegacyOrders.Init();
                                recLegacyOrders.MarketplaceName := 'Amazon';
                                recLegacyOrders.OrderId := recSalesHeader."External Document No.";
                                recLegacyOrders.Insert(true);
                            end
                        end;
                    end;
                end;
            end;
        end;
    end;

    // Insert Sales Line
    [TryFunction]
    local procedure InsertSalesLine(var orderItemListToken: JsonToken; var documnetNo: Code[20]; var lineNo: Integer; carriageflag: Boolean; postalCode: Text)
    var
        recSalesLine: Record "Sales Line";
        recItem: Record Item;
        itemPriceToken, shippingPriceToken : JsonToken;
        ItemNo: Code[30];
        UnitPriceIncludingVat, UnitPriceExcludingVat, VatPercentage, UnitPriceFromApi : Decimal;
        quantity: Integer;
        cuHOSTryReserve: Codeunit HOSTryReserve;
    begin
        recSalesLine.Init();
        recSalesLine."Line No." := lineNo;
        recSalesLine."Document No." := documnetNo;
        recSalesLine."Document Type" := "Sales Document Type"::Order;
        recSalesLine.Type := "Sales Line Type"::Item;

        if not carriageflag then begin
            recSalesLine."No." := NYTJSONMgt.GetValueAsText(orderItemListToken, 'sellerSKU');
            recSalesLine.Validate("No.");
            ItemNo := NYTJSONMgt.GetValueAsText(orderItemListToken, 'sellerSKU');
            quantity := NYTJSONMgt.GetValueAsDecimal(orderItemListToken, 'quantityOrdered');
            recSalesLine.Quantity := quantity;
            recSalesLine.Validate(Quantity);

            orderItemListToken.SelectToken('itemPrice', itemPriceToken);
            if itemPriceToken.IsObject then begin
                UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(itemPriceToken, 'amount') / quantity;
                UnitPriceFromApi := NYTJSONMgt.GetValueAsDecimal(itemPriceToken, 'amount');
                recSalesLine."Unit Price" := UnitPriceIncludingVat;
                recSalesLine.Validate("Unit Price");
            end;

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
            recSalesLine."3rd Party System PK" := NYTJSONMgt.GetValueAsText(orderItemListToken, 'orderItemId');

        end
        else begin
            orderItemListToken.SelectToken('shippingPrice', shippingPriceToken);
            if shippingPriceToken.IsObject then begin
                UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(shippingPriceToken, 'amount');
            end;
            recSalesLine."No." := 'CARRIAGE';
            recSalesLine.Validate("No.");

            recSalesLine.Quantity := 1;
            recSalesLine.Validate(Quantity);

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

        recSalesLine."Shortcut Dimension 1 Code" := 'AMAZON';
        recSalesLine.Insert(true);

        if recSalesLine."No." <> 'CARRIAGE' then begin
            cuHOSTryReserve.TryReserve(recSalesLine."Document No.");
            cu_CommonHelper.InsertMagentoGrossValue(documnetNo, UnitPriceFromApi);
        end;

        //If the item is assembly item
        if recSalesLine.IsAsmToOrderRequired() then begin
            recSalesLine.AutoAsmToOrder();
        end;
    end;
}