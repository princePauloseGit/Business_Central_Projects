codeunit 50421 "B&QShippingUpdate"
{
    trigger OnRun()
    begin
        CreatePostedSalesInvoiceShipment();
    end;

    var
        BQURI: Text;
        rec_BQSetting: Record "B&Q Settings";
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreatePostedSalesInvoiceShipment()
    var
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesInvoiceLine: Record "Sales Invoice Line";
        todayDateTime, tommorrowDateTime : DateTime;
        element, i : Integer;
        orderId: Code[35];
        orderItemId: Code[50];
        shipmentOrderItems, sendBody, result : Text;
        Jarray: JsonArray;
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        rec_BQSetting.Reset();

        if rec_BQSetting.FindSet() then begin
            repeat
                Clear(RESTAPIHelper);
                BQURI := RESTAPIHelper.GetBaseURl() + 'BQ/CreateShipment';
                RESTAPIHelper.Initialize('POST', BQURI);
                RESTAPIHelper.AddRequestHeader('Authorization', rec_BQSetting.APIKey.Trim());

                sendBody := CreateResponseBody();
                RESTAPIHelper.AddBody(sendBody);

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::"B&Q") then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result);
                end;
            until rec_BQSetting.Next() = 0;
        end;
    end;

    procedure CreateResponseBody(): Text
    var
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesInvoiceLine: Record "Sales Invoice Line";
        LineElement, HeaderElement : Integer;
        orderId: Code[35];
        orderItemId: Code[50];
        lineItemsList, responseBody : Text;
        toDateTime, tommorowDateTime : DateTime;
        isExists: Boolean;
        agent: Text;
        recBQConfirmShipment: Record BQConfirmShipment;
    begin
        responseBody := '';
        Clear(responseBody);
        HeaderElement := 1;

        toDateTime := CREATEDATETIME(CalcDate('<-3D>', Today), 0T);
        tommorowDateTime := CREATEDATETIME(CalcDate('<+1D>', Today), 0T);

        rec_SalesInvoiceHeader.SetRange("Shortcut Dimension 1 Code", 'B&Q');
        rec_SalesInvoiceHeader.SetFilter(SystemCreatedAt, '%1..%2', toDateTime, tommorowDateTime);

        if rec_SalesInvoiceHeader.FindSet() then begin
            repeat
                orderId := rec_SalesInvoiceHeader."External Document No.";
                recBQConfirmShipment.SetRange(OrderId, orderId);

                if not recBQConfirmShipment.FindFirst() then begin
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

                                lineItemsList := lineItemsList + '{ "offer_sku":"' + rec_SalesInvoiceLine."No." + '","order_line_id":"' + rec_SalesInvoiceLine."3rd Party System PK" + '","quantity":' + format(rec_SalesInvoiceLine.Quantity) + '}';
                            end;
                        until rec_SalesInvoiceLine.Next() = 0;

                        lineItemsList := DELCHR(lineItemsList, '>', ',');

                        agent := GetShippingAgentName(rec_SalesInvoiceHeader."Shipping Agent Code");

                        responseBody := responseBody + '{"invoice_reference":"' + rec_SalesInvoiceHeader."No." + '","order_id": "' + orderId + '","shipped": true,"tracking":{"carrier_code":"' + rec_SalesInvoiceHeader."Shipping Agent Code" + '","carrier_name":"' + agent + '","tracking_number":"' + rec_SalesInvoiceHeader."Package Tracking No." + '","tracking_url":""},"shipment_lines":[' + lineItemsList + ']}';

                        if rec_SalesInvoiceHeader.Count <> HeaderElement then begin
                            responseBody := responseBody + ',';
                        end;
                        HeaderElement := HeaderElement + 1;
                    end;
                end;
            until rec_SalesInvoiceHeader.Next() = 0;
        end;
        responseBody := DELCHR(responseBody, '>', ',');
        responseBody := '{"shipments":[' + responseBody + ']}';
        exit(responseBody);
    end;

    procedure ReadApiResponse(apiResponse: Text)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
        BQOrderId: Code[50];
        recBQConfirmShipment: Record BQConfirmShipment;
        isCheck: Boolean;
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('shipments', varjsonToken);
        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(BQOrderId);
                BQOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');
                isCheck := NYTJSONMgt.GetValueAsBoolean(varjsonToken, 'isConfirmedShipment');

                recBQConfirmShipment.Init();
                recBQConfirmShipment.Id := CreateGuid();
                recBQConfirmShipment.OrderId := BQOrderId;
                recBQConfirmShipment.ConfirmShipment := isCheck;
                recBQConfirmShipment.Insert(true);
            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::"B&Q");
        end;
    end;

    procedure GetShippingAgentName(agentCode: Code[20]): Text
    var
        rec: Record "Shipping Agent";
        AgentName: text;
    begin
        AgentName := '';
        rec.SetRange(Code, agentCode);
        if rec.FindFirst() then begin
            AgentName := rec.Name;
        end;
        exit(AgentName);
    end;
}

