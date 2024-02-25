codeunit 50432 ManoOrderDownloads
{
    trigger OnRun()
    begin
        ConnectManoAPIForSalesOrders();
    end;

    var
        ManoURI: Text;
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    //connect mano mano order api
    procedure ConnectManoAPIForSalesOrders()
    var
        result: text;
        startDate, endDate : Date;
        recManoSettings: Record ManoManoSettings;
        environment: Integer;
    begin
        Clear(RESTAPIHelper);
        Clear(ManoURI);
        ManoURI := RESTAPIHelper.GetBaseURl() + 'ManoMano/GetOrders';

        startDate := cu_CommonHelper.CalculateDate(10);
        endDate := Today() + 1;

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
                RESTAPIHelper.AddBody('{"seller_contract_id": "' + recManoSettings."Contract Id" + '","created_at_start": "' + Format(startDate, 0, 9) + '","created_at_end": "' + Format(endDate, 0, 9) + '","status":"PENDING"}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::ManoMano) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result, recManoSettings);
                end;
            until recManoSettings.Next() = 0;
        end;
    end;

    //Read the response from api
    local procedure ReadApiResponse(var apiResponse: Text; var recManoSettings: Record ManoManoSettings)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        index: Integer;
        ManoOrderId: Code[40];
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
                varJsonArray.Get(index, varjsonToken);

                Clear(ManoOrderId);
                ManoOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderReference');

                //Insert sales header
                if not InsertSalesHeader(varjsonToken, ManoOrderId, recManoSettings) then begin
                    description := 'Entry for OrderId ' + ManoOrderId + ' is failed to download';
                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, ManoOrderId, EnhIntegrationLogTypes::ManoMano, false, 'Order Id');
                end;
            end;
        end;

        //Insert error logs from api data
        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for index := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(index, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::ManoMano);
        end;
    end;

    //Procedure to insert Sales header data
    [TryFunction]
    procedure InsertSalesHeader(varjsonToken: JsonToken; ManoOrderId: Code[20]; recManoSettings: Record ManoManoSettings)
    var
        recSalesHeader: Record "Sales Header";
        recSalesInvoiceHeader: Record "Sales Invoice Header";
        recLegacyOrders: Record LegacyOrders;
        i, j, lineNo, lineCount : Integer;
        varJsonArray, responseArray : JsonArray;
        addressesToken, billingAddressToken, shippingAddressToken, OrderLineToken, totalPriceToken : JsonToken;
        TotalAmount: Decimal;
        ItemNo: Code[40];
        shipToPostcode, description : Text;
        itemNotExist, LineNotInserted : Boolean;
        recItem: Record Item;
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        SalesHeaderNo: Code[20];
    begin
        Clear(shipToPostcode);
        Clear(OrderLineToken);
        Clear(NYTJSONMgt);
        Clear(addressesToken);
        Clear(shippingAddressToken);
        Clear(billingAddressToken);

        recSalesHeader.Reset();
        recLegacyOrders.Reset();
        recLegacyOrders.SetRange(MarketplaceName, 'ManoMano');
        recLegacyOrders.SetRange(OrderId, ManoOrderId);

        if not recLegacyOrders.FindFirst() then begin

            recSalesHeader.SetRange("External Document No.", ManoOrderId);

            if not recSalesHeader.FindFirst() then begin

                recSalesInvoiceHeader.SetRange("External Document No.", ManoOrderId);

                if not recSalesInvoiceHeader.FindFirst() then begin

                    varjsonToken.SelectToken('orderLines', OrderLineToken);

                    if OrderLineToken.IsArray then begin
                        responseArray := OrderLineToken.AsArray();

                        for j := 0 to responseArray.Count - 1 do begin
                            responseArray.Get(j, OrderLineToken);

                            ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'sellerSku');

                            recItem.SetRange("No.", ItemNo);

                            //Check if item present in item table or not
                            if recItem.FindFirst() then begin
                                if recItem.Blocked then begin
                                    description := 'This item ' + ItemNo + ' is blocked';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, ManoOrderId, EnhIntegrationLogTypes::ManoMano, true, 'Order Id');
                                end;
                            end
                            else begin
                                itemNotExist := true;
                                description := 'This Item not found ' + ItemNo + ' so failed to download the order';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, ManoOrderId, EnhIntegrationLogTypes::ManoMano, true, 'Order Id');
                                exit(true);
                            end;
                        end;
                    end;

                    if itemNotExist = false then begin
                        recSalesHeader.Init();
                        recSalesHeader.InitRecord;
                        recSalesHeader."No." := '';
                        recSalesHeader."Document Type" := "Sales Document Type"::Order;

                        recSalesHeader."Sell-to Customer No." := recManoSettings.CustomerCode;
                        recSalesHeader.Validate("Sell-to Customer No.");
                        recSalesHeader."External Document No." := NYTJSONMgt.GetValueAsText(varjsonToken, 'orderReference');
                        recSalesHeader."Customer Posting Group" := 'DOMESTIC';

                        varjsonToken.SelectToken('addresses', addressesToken);

                        if addressesToken.IsObject then begin

                            addressesToken.SelectToken('shipping', shippingAddressToken);

                            if shippingAddressToken.IsObject then begin

                                recSalesHeader."Ship-to Name" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'firstname') + ' ' + NYTJSONMgt.GetValueAsText(shippingAddressToken, 'lastname');
                                recSalesHeader."Ship-to Address" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'address_line1');
                                recSalesHeader."Ship-to Address 2" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'address_line2'), 1, 50);
                                recSalesHeader."Ship-to City" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'city'), 1, 30);
                                recSalesHeader."Ship-to Post Code" := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'zipcode');
                                shipToPostcode := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'zipcode');
                                recSalesHeader."Sell-to Phone No." := NYTJSONMgt.GetValueAsText(shippingAddressToken, 'phone');
                                recSalesHeader."Ship-to Country/Region Code" := 'GB';
                                recSalesHeader."Ship-to Contact" := CopyStr(NYTJSONMgt.GetValueAsText(shippingAddressToken, 'firstname') + ' ' + NYTJSONMgt.GetValueAsText(shippingAddressToken, 'lastname'), 1, 100);
                            end;

                            addressesToken.SelectToken('billing', billingAddressToken);

                            if billingAddressToken.IsObject then begin
                                recSalesHeader."Bill-to Address" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'address_line1');
                                recSalesHeader."Bill-to Address 2" := CopyStr(NYTJSONMgt.GetValueAsText(billingAddressToken, 'address_line2'), 1, 50);
                                recSalesHeader."Bill-to City" := CopyStr(NYTJSONMgt.GetValueAsText(billingAddressToken, 'city'), 1, 30);
                                recSalesHeader."Bill-to Post Code" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'zipcode');
                                recSalesHeader."Bill-to Name" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'firstname') + ' ' + NYTJSONMgt.GetValueAsText(billingAddressToken, 'lastname');
                                recSalesHeader."Bill-to Contact" := CopyStr(NYTJSONMgt.GetValueAsText(billingAddressToken, 'firstname') + ' ' + NYTJSONMgt.GetValueAsText(billingAddressToken, 'lastname'), 1, 100);
                                recSalesHeader."Bill-to Country/Region Code" := 'GB';

                                recSalesHeader."Sell-to E-Mail" := NYTJSONMgt.GetValueAsText(billingAddressToken, 'email');
                                recSalesHeader.Validate("Sell-to E-Mail");
                            end;
                        end;

                        varjsonToken.SelectToken('totalPrice', totalPriceToken);

                        if totalPriceToken.IsObject then begin

                            TotalAmount := NYTJSONMgt.GetValueAsDecimal(totalPriceToken, 'amount');

                            //Check order value; if over £50 then Carrier else POST:
                            if TotalAmount > 50 then begin
                                recSalesHeader.OrderBatch := 'Carrier';
                                recSalesHeader."Shipping Agent Code" := 'DPD';
                                recSalesHeader."Shipping Agent Service Code" := '12';
                            end
                            else begin
                                recSalesHeader.OrderBatch := 'POST';
                                recSalesHeader."Shipping Agent Code" := 'RM';
                                recSalesHeader."Shipping Agent Service Code" := 'RM48';
                            end;
                        end;

                        recSalesHeader."Payment Method Code" := 'ManoMano';
                        recSalesHeader.Source := "Order Source"::"ManoMano";

                        recSalesHeader.Insert(true);
                        Commit();

                        SalesHeaderNo := recSalesHeader."No.";

                        //Call sales line procedure
                        varjsonToken.SelectToken('orderLines', OrderLineToken);

                        if OrderLineToken.IsArray then begin

                            responseArray := OrderLineToken.AsArray();

                            for j := 0 to responseArray.Count - 1 do begin

                                lineNo := 10000 + (j * 10000);
                                responseArray.Get(j, OrderLineToken);

                                if not InsertSalesLine(varjsonToken, OrderLineToken, recSalesHeader."No.", lineNo, false, shipToPostcode) then begin

                                    recSalesHeader.Delete(true);
                                    ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'sellerSku');
                                    description := 'In Order ' + ManoOrderId + ' entry for Orderline ' + ItemNo + ' is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, ManoOrderId, EnhIntegrationLogTypes::ManoMano, false, 'Order Id');
                                    LineNotInserted := true;
                                end;
                            end;

                            if LineNotInserted = false then begin

                                lineNo := lineNo + 10000;

                                if not InsertSalesLine(varjsonToken, OrderLineToken, recSalesHeader."No.", lineNo, true, shipToPostcode) then begin
                                    recSalesHeader.Delete(true);
                                    description := 'Entry for item Carriage charge is failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, ManoOrderId, EnhIntegrationLogTypes::ManoMano, false, 'Order Id');
                                end;

                                // recSalesHeader."Shortcut Dimension 1 Code" := 'MANOMANO';
                                // ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                // recSalesHeader.Modify(true);

                                recSalesHeader.Reset();
                                recSalesHeader.SetRange("No.", SalesHeaderNo);

                                if recSalesHeader.FindFirst() then begin
                                    recSalesHeader."Shortcut Dimension 1 Code" := 'MANOMANO';
                                    recSalesHeader.Modify(true);

                                    ReleaseSalesDoc.PerformManualRelease(recSalesHeader);
                                    Commit();
                                end;

                                //Insert data into legacy orders table
                                recLegacyOrders.Init();
                                recLegacyOrders.MarketplaceName := 'MANOMANO';
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
    //procedure to insert records into Sales Line table
    local procedure InsertSalesLine(var varjsonToken: JsonToken; OrderLineToken: JsonToken; var documnetNo: Code[20]; var lineNo: Integer; carriageflag: Boolean; shipToPostcode: Text)
    var
        recSalesLine: Record "Sales Line";
        recItem: Record Item;
        ItemNo: Code[30];
        quantity: Integer;
        UnitPriceIncludingVat, UnitPriceExcludingVat, VatPercentage, UnitPriceFromApi : Decimal;
        cuHOSTryReserve: Codeunit HOSTryReserve;
        priceToken, shippingPricetoken : JsonToken;

    begin
        recSalesLine.Init();
        recSalesLine."Line No." := lineNo;
        recSalesLine."Document No." := documnetNo;
        recSalesLine."Document Type" := "Sales Document Type"::Order;
        recSalesLine.Type := "Sales Line Type"::Item;

        // Insert the Sales line from api data
        if not carriageflag then begin
            recSalesLine."No." := NYTJSONMgt.GetValueAsText(OrderLineToken, 'sellerSku');
            recSalesLine.Validate("No.");
            ItemNo := NYTJSONMgt.GetValueAsText(OrderLineToken, 'sellerSku');
            quantity := NYTJSONMgt.GetValueAsDecimal(OrderLineToken, 'quantity');
            recSalesLine.Quantity := quantity;
            recSalesLine.Validate(Quantity);

            OrderLineToken.SelectToken('price', priceToken);

            if priceToken.IsObject then begin

                UnitPriceFromApi := NYTJSONMgt.GetValueAsDecimal(priceToken, 'amount') * quantity;

                UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(priceToken, 'amount');
                recSalesLine."Unit Price" := UnitPriceIncludingVat;
                recSalesLine.Validate("Unit Price");

                if (shipToPostcode.StartsWith('JE')) or (shipToPostcode.StartsWith('GY')) then begin
                    recSalesLine."VAT Prod. Posting Group" := 'ZERO_0%';
                    recSalesLine.Validate("VAT Prod. Posting Group");
                end
                else begin
                    // calculated excluding vat price
                    VatPercentage := 1 + (recSalesLine."VAT %" / 100);
                    UnitPriceExcludingVat := UnitPriceIncludingVat / VatPercentage;

                    recSalesLine."Unit Price" := UnitPriceExcludingVat;
                    recSalesLine.Validate("Unit Price");
                end;
            end;

            recSalesLine."3rd Party System PK" := NYTJSONMgt.GetValueAsText(varjsonToken, 'sellerContractId');
        end

        // Insert sales line for carriage item
        else begin
            recSalesLine."No." := 'CARRIAGE';
            recSalesLine.Validate("No.");
            recSalesLine.Quantity := 1;
            recSalesLine.Validate(Quantity);

            OrderLineToken.SelectToken('shippingPrice', shippingPricetoken);

            if shippingPricetoken.IsObject then begin

                UnitPriceIncludingVat := NYTJSONMgt.GetValueAsDecimal(varjsonToken, 'amount');

                recSalesLine."Unit Price" := UnitPriceIncludingVat;
                recSalesLine.Validate("Unit Price");

                if (shipToPostcode.StartsWith('JE')) or (shipToPostcode.StartsWith('GY')) then begin
                    recSalesLine."VAT Prod. Posting Group" := 'ZERO_0%';
                    recSalesLine.Validate("VAT Prod. Posting Group");
                end
                else begin
                    // calculated excluding vat price for carriage
                    VatPercentage := 1 + (recSalesLine."VAT %" / 100);
                    UnitPriceExcludingVat := UnitPriceIncludingVat / VatPercentage;

                    recSalesLine."Unit Price" := UnitPriceExcludingVat;
                    recSalesLine.Validate("Unit Price");
                end;
            end;
        end;

        recSalesLine."Shortcut Dimension 1 Code" := 'MANOMANO';
        recSalesLine.Insert(true);
        Commit();

        // Reserve the sales line 
        if recSalesLine."No." <> 'CARRIAGE' then begin
            cuHOSTryReserve.TryReserve(recSalesLine."Document No.");
            cu_CommonHelper.InsertMagentoGrossValue(documnetNo, UnitPriceFromApi);
        end;

        // Reserve the quantity to assemble for assembly item
        if recSalesLine.IsAsmToOrderRequired() then begin
            recSalesLine.AutoAsmToOrder();
        end;
    end;
}
