codeunit 50433 ManoAcceptOrders
{
    trigger OnRun()
    begin
        ConnectManoAcceptOrdersApi();
    end;

    var
        ManoURI: Text;
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    //connect mano mano Accept order api
    procedure ConnectManoAcceptOrdersApi()
    var
        result, jsoneBody : text;
        recManoSettings: Record ManoManoSettings;
        environment: Integer;
    begin
        Clear(RESTAPIHelper);
        Clear(ManoURI);
        ManoURI := RESTAPIHelper.GetBaseURl() + 'ManoMano/AcceptOrders';

        recManoSettings.Reset();
        if recManoSettings.FindSet() then begin
            repeat

                if recManoSettings.Environment = recManoSettings.Environment::Sandbox then begin
                    environment := 0;
                end
                else begin
                    environment := 1;
                end;

                //Headers
                RESTAPIHelper.Initialize('POST', ManoURI);
                RESTAPIHelper.AddRequestHeader('apikey', recManoSettings."API Key".Trim());
                RESTAPIHelper.AddRequestHeader('environment', format(environment));

                //Body
                jsoneBody := GenerateBody(recManoSettings."Contract Id");
                if jsoneBody <> '' then begin
                    RESTAPIHelper.AddBody(jsoneBody);
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::ManoMano) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadApiResponse(result);
                    end;
                end
                else begin
                    cu_CommonHelper.InsertInformationLogs('No orders are outstanding to accept', '', 'Accept Orders', EnhIntegrationLogTypes::ManoMano);
                end;
            until recManoSettings.Next() = 0;
        end;
    end;

    procedure GenerateBody(contractId: Text): Text
    var
        recSalesHeader: record "Sales Header";
        recManoSettings: Record ManoManoSettings;
        jsonBody: Text;
    begin
        recSalesHeader.SetRange(Source, "Order Source"::ManoMano);
        recSalesHeader.SetRange(IsAcceptedOrder, false);
        recSalesHeader.SetRange("Document Type", "Sales Document Type"::Order);
        recSalesHeader.SetFilter(InitialSalesOrderNumber, '=%1', '');

        if recSalesHeader.FindSet() then begin
            repeat
                jsonBody := jsonBody + '{"order_reference": "' + recSalesHeader."External Document No." + '","seller_contract_id": ' + contractId + '},'
            until recSalesHeader.Next() = 0;
        end;

        jsonBody := DELCHR(jsonBody, '>', ',');

        if jsonBody <> '' then begin
            exit('{"acceptOrders":[' + jsonBody + ']}');
        end;
    end;

    procedure ReadApiResponse(response: Text)
    var
        JToken: JsonToken;
        JObject: JsonObject;
        JArray: JsonArray;
        index: Integer;
        orderId, statusCode : Text;
        recSalesHeader: Record "Sales Header";
    begin

        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('acceptOrders', JToken);

        if not JArray.ReadFrom(Format(JToken)) then
            Error('Array not Reading Properly');

        if JArray.ReadFrom(Format(JToken)) then begin

            for index := 0 to JArray.Count - 1 do begin
                JArray.Get(index, JToken);

                Clear(orderId);
                Clear(statusCode);

                orderId := NYTJSONMgt.GetValueAsText(JToken, 'orderID');
                statusCode := NYTJSONMgt.GetValueAsText(JToken, 'httpStatusCode');

                if (statusCode = '200') or (statusCode = '201') or (statusCode = '204') or (statusCode = '207') or (statusCode = '202') then begin

                    recSalesHeader.SetRange(Source, "Order Source"::ManoMano);
                    recSalesHeader.SetRange("External Document No.", orderId);

                    if recSalesHeader.FindFirst() then begin

                        recSalesHeader.IsAcceptedOrder := true;
                        recSalesHeader.Modify(true);
                    end;
                end;
            end;
        end;

        //Insert error logs from api data
        JObject.Get('errorLogs', JToken);

        if not JArray.ReadFrom(Format(JToken)) then
            Error('Array not Reading Properly');

        for index := 0 to JArray.Count() - 1 do begin
            JArray.Get(index, JToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::ManoMano);
        end;
    end;
}