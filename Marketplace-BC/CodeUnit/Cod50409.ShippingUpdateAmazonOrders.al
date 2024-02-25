codeunit 50409 "ShippingUpdate-AmazonOrders"
{
    trigger OnRun()
    begin
        ConnectAmazonShipmentConfirmation();
    end;

    var
        amazonURI: Text;
        rec_AmazonSetting: Record "Amazon Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreateResponseBody(customerCode: Code[50]): Text
    var
        rec_SalesInvoiceHeader: Record "Sales Invoice Header";
        rec_SalesInvoiceLine: Record "Sales Invoice Line";
        rec_AmazonConfirmShipment: Record AmazonConfirmShipment;
        LineElement, HeaderElement : Integer;
        orderId: Code[35];
        orderItemId: Code[50];
        orderItemsList, responseBody : Text;
    begin
        responseBody := '';
        HeaderElement := 1;
        rec_AmazonConfirmShipment.SetRange(ConfirmShipment, false);
        rec_AmazonConfirmShipment.SetRange(AmazonSettingsLookup, customerCode);
        if rec_AmazonConfirmShipment.FindSet() then
            repeat
                rec_SalesInvoiceHeader.SetRange("External Document No.", rec_AmazonConfirmShipment.OrderId);
                if rec_SalesInvoiceHeader.FindSet() then
                    repeat
                        orderId := rec_SalesInvoiceHeader."External Document No.";
                        orderItemsList := '';
                        LineElement := 1;
                        rec_SalesInvoiceLine.SetRange("Order No.", rec_SalesInvoiceHeader."Order No.");
                        rec_SalesInvoiceLine.SetFilter("3rd Party System PK", '<>%1', '');
                        if rec_SalesInvoiceLine.FindSet() then begin
                            repeat
                                orderItemsList := orderItemsList + '{ "orderItemId":"' + rec_SalesInvoiceLine."3rd Party System PK" + '","quantity":' + format(rec_SalesInvoiceLine.Quantity) + '}';
                                if rec_SalesInvoiceLine.Count <> LineElement then begin
                                    orderItemsList := orderItemsList + ',';
                                end;
                                LineElement := LineElement + 1;
                            until rec_SalesInvoiceLine.Next() = 0;
                        end;

                        responseBody := responseBody + '{"orderId": "' + orderId + '","confirmShipmentRequest": {"marketplaceId": "' + rec_AmazonSetting.MarketplaceID.Trim() + '","packageDetail": { "packageReferenceId": "1", "carrierCode": "' + rec_SalesInvoiceHeader."Shipping Agent Code" + '", "trackingNumber":"' + rec_SalesInvoiceHeader."Package Tracking No." + '","shipDate": "' + Format(rec_SalesInvoiceHeader."Shipment Date", 0, 9) + '","orderItemsList":[' + orderItemsList + ']}}}';

                        if rec_AmazonConfirmShipment.Count <> HeaderElement then begin
                            responseBody := responseBody + ',';
                        end;
                        HeaderElement := HeaderElement + 1;
                    until rec_SalesInvoiceHeader.Next() = 0;
            until rec_AmazonConfirmShipment.Next() = 0;
        responseBody := '[' + responseBody + ']';
        exit(responseBody);
    end;

    procedure ConnectAmazonShipmentConfirmation()
    var
        sendBody, result : Text;
    begin
        Clear(RESTAPIHelper);
        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            repeat
                Clear(RESTAPIHelper);
                amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/ShipmentConfirmation';
                RESTAPIHelper.Initialize('POST', amazonURI);
                RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());

                sendBody := CreateResponseBody(rec_AmazonSetting.CustomerCode);

                RESTAPIHelper.AddBody(sendBody);
                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result);
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    procedure ReadApiResponse(apiResponse: Text)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        JObject: JsonObject;
        i: Integer;
        AmzOrderId: Code[50];
        recAmazonConfirmShipment: Record AmazonConfirmShipment;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('shipments', varjsonToken);
        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(AmzOrderId);
                AmzOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderId');
                recAmazonConfirmShipment.SetRange(OrderId, AmzOrderId);
                if recAmazonConfirmShipment.FindFirst() then begin
                    recAmazonConfirmShipment.ConfirmShipment := NYTJSONMgt.GetValueAsBoolean(varjsonToken, 'isConfirmedShipment');
                    recAmazonConfirmShipment.Modify(true);
                end;
            end;
        end;
    end;
}
