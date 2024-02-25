codeunit 50430 "EbayShippingUpdate"
{
    trigger OnRun()
    begin
        ConnectEBayShipmentConfirmation();
    end;

    var
        eBayURI: Text;
        rec_eBaySetting: Record "ebay Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreateResponseBody(customerCode: Code[50]): Text
    var
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesInvoiceLine: Record "Sales Invoice Line";
        rec_eBayConfirmShipment: Record eBayConfirmShipment;
        LineElement, HeaderElement : Integer;
        orderId: Code[35];
        orderItemId: Code[50];
        lineItemsList, responseBody : Text;
        toDateTime, tommorowDateTime : DateTime;
        isExists: Boolean;
    begin
        responseBody := '';
        Clear(responseBody);
        HeaderElement := 1;
        toDateTime := CREATEDATETIME(CalcDate('<-3D>', Today), 0T);
        tommorowDateTime := CREATEDATETIME(CalcDate('<+1D>', Today), 0T);

        rec_SalesInvoiceHeader.SetRange("Shortcut Dimension 1 Code", 'EBAY');
        rec_SalesInvoiceHeader.SetFilter(SystemCreatedAt, '%1..%2', toDateTime, tommorowDateTime);

        if rec_SalesInvoiceHeader.FindSet() then begin
            repeat
                orderId := rec_SalesInvoiceHeader."External Document No.";
                rec_eBayConfirmShipment.SetRange(OrderId, orderId);

                if not rec_eBayConfirmShipment.FindFirst() then begin
                    lineItemsList := '';
                    rec_SalesInvoiceLine.SetRange("Order No.", rec_SalesInvoiceHeader."Order No.");
                    rec_SalesInvoiceLine.SetFilter("3rd Party System PK", '<>%1', '');

                    if rec_SalesInvoiceLine.FindSet() then begin
                        repeat
                            isExists := lineItemsList.Contains(rec_SalesInvoiceLine."No.");

                            if (rec_SalesInvoiceLine."No." <> 'CARRIAGE') and (rec_SalesInvoiceLine.Quantity <> 0) and (not isExists) then begin

                                if lineItemsList <> '' then begin
                                    lineItemsList := lineItemsList + ',';
                                end;

                                lineItemsList := lineItemsList + '{ "lineItemId":"' + rec_SalesInvoiceLine."3rd Party System PK" + '","quantity":"' + format(rec_SalesInvoiceLine.Quantity) + '"}';
                            end;
                        until rec_SalesInvoiceLine.Next() = 0;

                        lineItemsList := DELCHR(lineItemsList, '>', ',');

                        responseBody := responseBody + '{"orderId": "' + orderId + '","shipmentData":{"lineItems": [' + lineItemsList + '],' + '"shippedDate":"' + format(rec_SalesInvoiceHeader."Shipment Date", 0, 9) + 'T00:00:00.000Z' + '","shippingCarrierCode":"' + rec_SalesInvoiceHeader."Shipping Agent Code" + '","trackingNumber":"' + rec_SalesInvoiceHeader."Package Tracking No." + '"}}';

                        if rec_SalesInvoiceHeader.Count <> HeaderElement then begin
                            responseBody := responseBody + ',';
                        end;

                        HeaderElement := HeaderElement + 1;
                        // end else begin
                        //     cu_CommonHelper.InsertBusinessCentralErrorLog('No Sales Line Found', rec_SalesInvoiceHeader."Order No.", EnhIntegrationLogTypes::Ebay, true, 'Order Id');
                    end;
                end;
            until rec_SalesInvoiceHeader.Next() = 0;
        end;
        responseBody := DELCHR(responseBody, '>', ',');
        responseBody := '{"createShipments":[' + responseBody + ']}';

        exit(responseBody);
    end;

    procedure ConnectEBayShipmentConfirmation()
    var
        sendBody, result : Text;
    begin
        Clear(RESTAPIHelper);
        rec_eBaySetting.Reset();
        if rec_eBaySetting.FindSet() then begin
            repeat
                Clear(RESTAPIHelper);
                eBayURI := RESTAPIHelper.GetBaseURl() + 'ebay/CreateShippingFulfilment';
                RESTAPIHelper.Initialize('POST', eBayURI);
                RESTAPIHelper.AddRequestHeader('refresh_token', rec_eBaySetting.refresh_token);
                RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_eBaySetting.oauth_credentials);
                RESTAPIHelper.AddRequestHeader('Environment', rec_eBaySetting.Environment);

                sendBody := CreateResponseBody(rec_eBaySetting.CustomerCode);
                RESTAPIHelper.AddBody(sendBody);
                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result);
                end;
            until rec_eBaySetting.Next() = 0;
        end;
    end;

    procedure ReadApiResponse(apiResponse: Text)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
        eBayOrderId: Code[50];
        recEbayConfirmShipment: Record eBayConfirmShipment;
        isCheck: Boolean;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('shipments', varjsonToken);
        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(eBayOrderId);
                eBayOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');
                isCheck := NYTJSONMgt.GetValueAsBoolean(varjsonToken, 'isConfirmedShipment');

                recEbayConfirmShipment.Init();
                recEbayConfirmShipment.Id := CreateGuid();
                recEbayConfirmShipment.OrderId := eBayOrderId;
                recEbayConfirmShipment.ConfirmShipment := isCheck;
                recEbayConfirmShipment.Insert(true);

            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Ebay);
        end;
    end;
}

