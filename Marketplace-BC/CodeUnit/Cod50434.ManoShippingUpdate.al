codeunit 50434 ManoShippingUpdate
{
    trigger OnRun()
    begin
        ConnectManoShipmentApi();
    end;

    var
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreateResponseBody(ContractId: Text): Text
    var
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesInvoiceLine: Record "Sales Invoice Line";
        rec_ManoConfirmShipment: Record ManoConfirmShipment;
        HeaderElement: Integer;
        lineItemsList, responseBody, carrierName, trackingURL : Text;
        toDateTime, tommorowDateTime : DateTime;
        isExists: Boolean;
        recShippingAgent: Record "Shipping Agent";
        shippingCode: Code[50];
    begin
        trackingURL := '';
        responseBody := '';
        Clear(responseBody);
        HeaderElement := 1;
        toDateTime := CREATEDATETIME(CalcDate('<-3D>', Today), 0T);
        tommorowDateTime := CREATEDATETIME(CalcDate('<+1D>', Today), 0T);

        rec_SalesInvoiceHeader.SetRange("Shortcut Dimension 1 Code", 'MANOMANO');
        rec_SalesInvoiceHeader.SetFilter(SystemCreatedAt, '%1..%2', toDateTime, tommorowDateTime);

        if rec_SalesInvoiceHeader.FindSet() then begin
            repeat
                rec_ManoConfirmShipment.SetRange(OrderId, rec_SalesInvoiceHeader."External Document No.");

                if not rec_ManoConfirmShipment.FindFirst() then begin
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

                                lineItemsList := lineItemsList + '{ "seller_sku":"' + rec_SalesInvoiceLine."No." + '","quantity":' + format(rec_SalesInvoiceLine.Quantity) + '}';
                            end;
                        until rec_SalesInvoiceLine.Next() = 0;

                        lineItemsList := DELCHR(lineItemsList, '>', ',');

                        recShippingAgent.Reset();
                        recShippingAgent.SetRange(Code, rec_SalesInvoiceHeader."Shipping Agent Code");

                        if recShippingAgent.FindFirst() then begin
                            carrierName := recShippingAgent.Name;
                            shippingCode := recShippingAgent.Code;
                        end;

                        if (shippingCode = 'RM') then begin
                            trackingURL := 'https://www.royalmail.com/track-your-item#/tracking-results/' + rec_SalesInvoiceHeader."Package Tracking No.";
                        end;

                        if (shippingCode = 'DPD') then begin
                            trackingURL := 'https://www.dpd.co.uk/apps/tracking/?reference=' + rec_SalesInvoiceHeader."Package Tracking No.";
                        end;

                        responseBody := responseBody + '{"carrier": "' + carrierName + '","order_reference": "' + rec_SalesInvoiceHeader."External Document No." + '","seller_contract_id": ' + ContractId + ',"tracking_number":"' + rec_SalesInvoiceHeader."Package Tracking No." + '","tracking_url": "' + trackingURL + '","products":[' + lineItemsList + ']}';

                        if rec_SalesInvoiceHeader.Count <> HeaderElement then begin
                            responseBody := responseBody + ',';
                        end;

                        HeaderElement := HeaderElement + 1;
                    end;
                end;
            until rec_SalesInvoiceHeader.Next() = 0;
        end;
        responseBody := DELCHR(responseBody, '>', ',');

        responseBody := '{"shipmentOrders":[' + responseBody + ']}';
        exit(responseBody);
    end;

    procedure ConnectManoShipmentApi()
    var
        Url, result, jsonBody : Text;
        recManoSettings: Record ManoManoSettings;
        environment: Integer;
    begin
        Clear(RESTAPIHelper);
        Clear(Url);
        recManoSettings.Reset();

        Url := RESTAPIHelper.GetBaseURl() + 'ManoMano/CreateShipment';

        if recManoSettings.FindSet() then begin
            repeat

                if recManoSettings.Environment = recManoSettings.Environment::Sandbox then begin
                    environment := 0;
                end
                else begin
                    environment := 1;
                end;

                RESTAPIHelper.Initialize('POST', Url);
                RESTAPIHelper.AddRequestHeader('apikey', recManoSettings."API Key");
                RESTAPIHelper.AddRequestHeader('environment', format(environment));

                jsonBody := CreateResponseBody(recManoSettings."Contract Id");
                RESTAPIHelper.AddBody(jsonBody);

                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::ManoMano) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result);
                end;

            until recManoSettings.Next() = 0;
        end;
    end;

    procedure ReadApiResponse(response: Text)
    var
        jObject: JsonObject;
        jArray: JsonArray;
        jToken: JsonToken;
        index, statusCode : Integer;
        recManoConfirmShipment: Record ManoConfirmShipment;
    begin
        if not jObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');

        jObject.Get('shippedOrders', jToken);

        if jArray.ReadFrom(Format(jToken)) then begin

            for index := 0 to jArray.Count - 1 do begin

                jArray.Get(index, jToken);
                statusCode := NYTJSONMgt.GetValueAsDecimal(jToken, 'httpStatusCode');

                recManoConfirmShipment.Init();
                recManoConfirmShipment.Id := CreateGuid();
                recManoConfirmShipment.OrderId := NYTJSONMgt.GetValueAsText(jToken, 'orderID');

                if (statusCode = 200) or (statusCode = 201) or (statusCode = 204) or (statusCode = 207) then begin
                    recManoConfirmShipment.ConfirmShipment := true;
                end
                else begin
                    recManoConfirmShipment.ConfirmShipment := false;
                end;

                recManoConfirmShipment.Insert(true);
            end;
        end;

        jObject.Get('errorLogs', jToken);

        if jArray.ReadFrom(Format(jToken)) then begin
            for index := 0 to jArray.Count - 1 do begin
                jArray.Get(index, jToken);
                cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::ManoMano);
            end;
        end;
    end;
}
