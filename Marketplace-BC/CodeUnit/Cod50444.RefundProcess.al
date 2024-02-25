codeunit 50444 RefundProcess
{
    var
        cu_CommonHelper: Codeunit CommonHelper;

    // connect B&Q refund api
    procedure ConnectBQRefundPaymentApi(SalesHeader: Record "Sales Header"; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        result, URI, JsonBody : Text;
        rec_BQSetting: Record "B&Q Settings";
        RESTAPIHelper: Codeunit "REST API Helper";
        taxes: Decimal;
    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        Clear(JsonBody);
        Clear(taxes);

        rec_BQSetting.Reset();

        if rec_BQSetting.FindSet() then begin
            URI := RESTAPIHelper.GetBaseURl() + 'BQ/RefundPayment?orderId=' + SalesHeader."External Document No.";
            RESTAPIHelper.Initialize('POST', URI);
            RESTAPIHelper.AddRequestHeader('Authorization', rec_BQSetting.APIKey.Trim());

            //Body
            JsonBody := GenerateBQRefundBody(SalesHeader);

            if JsonBody <> '' then begin
                RESTAPIHelper.AddBody(JsonBody);

                // ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(enumPaymentMethod) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentApiResponse(result, enumPaymentMethod);
                end;
            end
            else begin
                cu_CommonHelper.InsertInformationLogs('The 3rd Party System PK is blank', '', 'BQ Refund', EnhIntegrationLogTypes::"B&Q");
            end;
        end;
    end;

    procedure ConnectOnBuyRefundPaymentApi(SalesHeader: Record "Sales Header"; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        result, URI, JsonBody : Text;
        recOnBuySetting: Record "Onbuy Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        Clear(JsonBody);

        recOnBuySetting.Reset();

        if recOnBuySetting.FindSet() then begin
            URI := RESTAPIHelper.GetBaseURl() + 'onBuy/RefundOnBuyPayment';
            RESTAPIHelper.Initialize('POST', URI);
            RESTAPIHelper.AddRequestHeader('authorization', GetOnBuyAuthorziationToken(EnhIntegrationLogTypes::OnBuy));

            //Body
            JsonBody := GenerateOnBuyRefundBody(SalesHeader, recOnBuySetting);

            if JsonBody <> '' then begin
                RESTAPIHelper.AddBody(JsonBody);

                // ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(enumPaymentMethod) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentOnBuyApiResponse(result, enumPaymentMethod);
                end;
            end
            else begin
                cu_CommonHelper.InsertInformationLogs('No line IDs for OnBuy were found, please process refund manually via OnBuy web portal', '', 'OnBuy Refund', EnhIntegrationLogTypes::OnBuy);
            end;
        end;
    end;

    // generate json body for B&Q refund
    procedure GenerateBQRefundBody(SalesHeader: Record "Sales Header"): Text
    var
        rec_salesCrLines: Record "Sales Cr.Memo Line";
        rec_salesCrLinesA: Record "Sales Cr.Memo Line";
        rec_salesCrLinesB: Record "Sales Cr.Memo Line";
        refundCharge, refundAmountFromTable, maximumUnitPrice, refundAmount : Decimal;
        LineNo: Integer;
        sendBody, refundItems : Text;
    begin

        rec_salesCrLinesA.Reset();
        rec_salesCrLinesA.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesA.SetFilter("3rd Party System PK", '=%1', '');

        if rec_salesCrLinesA.FindSet() then begin

            if (rec_salesCrLinesA."No." = 'RETURNCHARGE') or (rec_salesCrLinesA."No." = 'RETURNCOLLECT') then
                refundCharge := rec_salesCrLinesA."Amount Including VAT";
        end;

        rec_salesCrLines.Reset();
        rec_salesCrLines.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLines.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLines.FindSet() then begin
            repeat

                if maximumUnitPrice < rec_salesCrLines."Amount Including VAT" then begin
                    maximumUnitPrice := rec_salesCrLines."Amount Including VAT";
                    LineNo := rec_salesCrLines."Line No.";
                end;

            until rec_salesCrLines.Next() = 0;
        end;

        rec_salesCrLinesB.Reset();
        rec_salesCrLinesB.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesB.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLinesB.FindSet() then begin
            repeat

                if rec_salesCrLinesB."Line No." = LineNo then begin

                    refundAmountFromTable := maximumUnitPrice;
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"amount":' + Format(refundAmount + refundCharge) + ',"currency_iso_code": "GBP","excluded_from_shipment": false,"order_line_id": "' + rec_salesCrLines."3rd Party System PK" + '","quantity":' + format(rec_salesCrLines.Quantity) + ',"reason_code": "REFUND_65","shipping_amount": ' + Format(0) + '},';
                end
                else begin

                    refundAmountFromTable := rec_salesCrLinesB."Amount Including VAT";
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"amount":' + Format(refundAmount) + ',"currency_iso_code": "GBP","excluded_from_shipment": false,"order_line_id": "' + rec_salesCrLines."3rd Party System PK" + '","quantity":' + format(rec_salesCrLines.Quantity) + ',"reason_code": "REFUND_65","shipping_amount": ' + Format(0) + '},';
                end;

            until rec_salesCrLinesB.Next() = 0;
        end;

        refundItems := DELCHR(refundItems, '>', ',');

        if refundItems <> '' then begin

            sendBody := '{"order_tax_mode": "TAX_INCLUDED","refunds": [' + refundItems + ' ]}';
            exit(sendBody);
        end;
    end;

    //Connect Ebay refund API
    procedure ConnecteBayRefundPaymentApi(SalesHeader: Record "Sales Header"; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        result, URI, jsonBody : Text;
        rec_eBaySetting: Record "ebay Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        Clear(jsonBody);

        rec_eBaySetting.Reset();

        if rec_eBaySetting.FindSet() then begin

            URI := RESTAPIHelper.GetBaseURl() + 'Ebay/RefundPayment?orderId=' + SalesHeader."External Document No.";

            RESTAPIHelper.Initialize('POST', URI);
            RESTAPIHelper.AddRequestHeader('refresh_token', rec_eBaySetting.refresh_token);
            RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_eBaySetting.oauth_credentials);
            RESTAPIHelper.AddRequestHeader('Environment', rec_eBaySetting.Environment);

            //Body
            jsonBody := GenerateEbayRefundBody(SalesHeader, rec_eBaySetting);

            if JsonBody <> '' then begin
                RESTAPIHelper.AddBody(jsonBody);

                // ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(enumPaymentMethod) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentApiResponse(result, enumPaymentMethod);
                end;
            end
            else begin
                cu_CommonHelper.InsertInformationLogs('The 3rd Party System PK is blank', '', 'eBay Refund', EnhIntegrationLogTypes::Ebay);
            end;

        end;
    end;

    // generate json body for ebay refund
    procedure GenerateEbayRefundBody(SalesHeader: Record "Sales Header"; rec_eBaySetting: Record "ebay Setting"): Text
    var
        rec_salesCrLines: Record "Sales Cr.Memo Line";
        rec_salesCrLinesA: Record "Sales Cr.Memo Line";
        rec_salesCrLinesB: Record "Sales Cr.Memo Line";
        refundCharge, refundAmount, refundAmountFromTable, maximumUnitPrice : Decimal;
        LineNo: Integer;
        sendBody, refundItems : Text;
    begin

        rec_salesCrLinesA.Reset();
        rec_salesCrLinesA.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesA.SetFilter("3rd Party System PK", '=%1', '');

        if rec_salesCrLinesA.FindSet() then begin

            if (rec_salesCrLinesA."No." = 'RETURNCHARGE') or (rec_salesCrLinesA."No." = 'RETURNCOLLECT') then
                refundCharge := rec_salesCrLinesA."Amount Including VAT";
        end;

        rec_salesCrLines.Reset();
        rec_salesCrLines.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLines.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLines.FindSet() then begin
            repeat

                if maximumUnitPrice < rec_salesCrLines."Amount Including VAT" then begin
                    maximumUnitPrice := rec_salesCrLines."Amount Including VAT";
                    LineNo := rec_salesCrLines."Line No.";
                end;

            until rec_salesCrLines.Next() = 0;
        end;

        rec_salesCrLinesB.Reset();
        rec_salesCrLinesB.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesB.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLinesB.FindSet() then begin
            repeat

                if rec_salesCrLinesB."Line No." = LineNo then begin

                    refundAmountFromTable := maximumUnitPrice;
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"refundAmount": {"value":' + format(refundAmount + refundCharge) + ',"currency": "GBP"},"lineItemId": "' + rec_salesCrLinesB."3rd Party System PK" + '"},';
                end
                else begin

                    refundAmountFromTable := rec_salesCrLinesB."Amount Including VAT";
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"refundAmount": {"value":' + format(refundAmount) + ',"currency": "GBP"},"lineItemId": "' + rec_salesCrLinesB."3rd Party System PK" + '"},';
                end;

            until rec_salesCrLinesB.Next() = 0;
        end;

        refundItems := DELCHR(refundItems, '>', ',');

        if refundItems <> '' then begin

            sendBody := '{"JWE":"' + rec_eBaySetting.DigitalSignatureJWE + '","PrivateKey":"' + rec_eBaySetting.DigitalSignaturePrivateKey + '","reasonForRefund": "BUYER_RETURN","refundItems": [' + refundItems + ']}';
            exit(sendBody);
        end;
    end;

    // connect braintree api for website orders (payment method code = Braintree / Paypal)
    procedure ConnectPaymentApi(SalesHeader: Record "Sales Header"; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        result, URI, sendBody : Text;
        rec_BraintreeSetting: Record "Braintree Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        refundAmt, returnValue : Decimal;
        rec_salesLines: Record "Sales Cr.Memo Line";
        "Document Type": Enum "Sales Document Type";
        cu_email: Codeunit EmailItemExceededReturnRate;
        jObject: JsonObject;
        varjsonToken: JsonToken;
    begin

        Clear(RESTAPIHelper);
        Clear(URI);
        URI := RESTAPIHelper.GetBaseURl() + 'Braintree/RefundPayment';
        RESTAPIHelper.Initialize('POST', URI);
        rec_BraintreeSetting.Reset();

        if rec_BraintreeSetting.FindSet() then begin
            repeat
                RESTAPIHelper.AddRequestHeader('merchantId', rec_BraintreeSetting.MerchantID.Trim());
                RESTAPIHelper.AddRequestHeader('privateKey', rec_BraintreeSetting.PrivateKey.Trim());
                RESTAPIHelper.AddRequestHeader('publicKey', rec_BraintreeSetting.PublicKey.Trim());

                //Body
                if SalesHeader.PaymentReference <> '' then begin
                    refundAmt := 0;

                    rec_salesLines.Reset();
                    rec_salesLines.SetRange("Order No.", SalesHeader."No.");

                    if rec_salesLines.FindSet() then begin
                        repeat
                            refundAmt := refundAmt + rec_salesLines."Amount Including VAT";
                        until rec_salesLines.Next() = 0;
                    end;

                    returnValue := CheckMagentoGrossValue(SalesHeader, refundAmt);
                    sendBody := '{"transactionId": "' + SalesHeader.PaymentReference + '","amount": ' + Format(returnValue, 0, 1) + '}';
                    RESTAPIHelper.AddBody(sendBody);

                    // ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(enumPaymentMethod) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadSettelmentApiResponse(result, enumPaymentMethod);
                    end;

                    jObject.ReadFrom(result);
                    JObject.Get('isRefunded', varjsonToken);

                    if Format(varjsonToken) = 'true' then begin
                        if SalesHeader."Sell-to Customer No." = 'HART08' then begin
                            cu_email.SendRefundEmail(SalesHeader, returnValue);
                        end;
                    end;
                end
                else begin
                    Message('Payment reference not found, please refund manually via payment gateway.');
                end;

            until rec_BraintreeSetting.Next() = 0;
        end;
    end;

    procedure ReadSettelmentOnBuyApiResponse(result: Text; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        jObject: JsonObject;
        jToken, varjsonToken : JsonToken;
        rec_refundPayment: Record RefundPayments;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;
    begin
        jObject.ReadFrom(result);
        JObject.Get('orders', jToken);

        if jToken.IsObject then begin
            rec_refundPayment.Init();
            rec_refundPayment.id := CreateGuid();
            rec_refundPayment.isRefunded := NYTJSONMgt.GetValueAsText(jToken, 'isRefunded');
            rec_refundPayment.MarketPlace := 'OnBuy';
            rec_refundPayment.RefundAmount := CopyStr(NYTJSONMgt.GetValueAsText(jToken, 'errorMessage'), 1, 2048);
            rec_refundPayment.TranscationId := NYTJSONMgt.GetValueAsText(jToken, 'orderId');
            rec_refundPayment.Insert(true);
        end;

        JObject.Get('errorLog', jToken);

        if jToken.IsObject then begin
            cu_CommonHelper.InsertEnhancedIntegrationLog(jToken, enumPaymentMethod);
        end;
    end;

    // read the api response for all the refund
    procedure ReadSettelmentApiResponse(result: Text; enumPaymentMethod: Enum EnhIntegrationLogTypes)
    var
        jObject: JsonObject;
        jToken, varjsonToken : JsonToken;
        rec_refundPayment: Record RefundPayments;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;
    begin
        jObject.ReadFrom(result);
        JObject.Get('isRefunded', varjsonToken);



        JObject.Get('errorLog', jToken);

        if jToken.IsObject then begin

            if (Format(varjsonToken) = 'false') and (Format(enumPaymentMethod) = 'Ebay') then begin
                Message(Format(enumPaymentMethod) + ' Refund has been failed for Record ID ' + NYTJSONMgt.GetValueAsText(jToken, 'recordID'));
            end;

            rec_refundPayment.Init();
            rec_refundPayment.id := CreateGuid();
            rec_refundPayment.isRefunded := Format(varjsonToken);
            rec_refundPayment.MarketPlace := NYTJSONMgt.GetValueAsText(jToken, 'source');
            rec_refundPayment.RefundAmount := CopyStr(NYTJSONMgt.GetValueAsText(jToken, 'stackTrace'), 1, 2048);
            rec_refundPayment.TranscationId := NYTJSONMgt.GetValueAsText(jToken, 'recordID');
            rec_refundPayment.Insert(true);
        end;

        cu_CommonHelper.InsertEnhancedIntegrationLog(jToken, enumPaymentMethod);
    end;

    //Procedure to compare the refund value and MagentoGrossValue
    procedure CheckMagentoGrossValue(SalesHeader: Record "Sales Header"; refundAmt: Decimal): Decimal
    var
        MagentoGrossValue: Decimal;
        recSalesCrMemo: Record "Sales Cr.Memo Header";
    begin
        recSalesCrMemo.SetRange("Return Order No.", SalesHeader."No.");
        if recSalesCrMemo.FindFirst() then begin

            MagentoGrossValue := recSalesCrMemo.MagentoGrossValue;

            if (MagentoGrossValue <> 0) and (MagentoGrossValue < refundAmt) then begin
                exit(MagentoGrossValue);
            end;

            exit(refundAmt);
        end;
    end;

    procedure CheckPriceToRefund(SalesHeader: Record "Sales Header"; refundAmt: Decimal; SystemPK: Code[50]): Decimal
    var
        PriceToRefund: Decimal;
        recSalesCrMemo: Record "Sales Cr.Memo Line";
        refundQuantity, actualQuantity : Integer;
        recSalesHeaderArc: Record "Sales Header Archive";
        recSalesLineArc: Record "Sales Line Archive";
    begin

        recSalesHeaderArc.SetRange("No.", SalesHeader.InitialSalesOrderNumber);
        if recSalesHeaderArc.FindFirst() then begin

            recSalesLineArc.SetRange("Document No.", recSalesHeaderArc."No.");
            recSalesLineArc.SetRange("3rd Party System PK", SystemPK);
            if recSalesLineArc.FindFirst() then begin
                actualQuantity := recSalesLineArc.Quantity;
            end;
        end;

        recSalesCrMemo.SetRange("Order No.", SalesHeader."No.");
        if recSalesCrMemo.FindFirst() then begin

            refundQuantity := recSalesCrMemo.Quantity;

            if refundQuantity = actualQuantity then begin
                PriceToRefund := recSalesCrMemo.TotalApiPrice;
            end
            else begin
                PriceToRefund := Round(recSalesCrMemo.ActualApiPrice * refundQuantity, 0.01, '<');
            end;

            if (PriceToRefund <> 0) and (PriceToRefund < refundAmt) then begin
                exit(PriceToRefund);
            end;

            exit(refundAmt);
        end;
    end;

    procedure GenerateOnBuyRefundBody(SalesHeader: Record "Sales Header"; recOnBuySetting: Record "Onbuy Setting"): Text
    var
        rec_salesCrLines: Record "Sales Cr.Memo Line";
        rec_salesCrLinesA: Record "Sales Cr.Memo Line";
        rec_salesCrLinesB: Record "Sales Cr.Memo Line";
        refundCharge, refundAmount, refundAmountFromTable, maximumUnitPrice : Decimal;
        LineNo: Integer;
        sendBody, refundItems : Text;
    begin

        rec_salesCrLinesA.Reset();
        rec_salesCrLinesA.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesA.SetFilter("3rd Party System PK", '=%1', '');

        if rec_salesCrLinesA.FindSet() then begin

            if (rec_salesCrLinesA."No." = 'RETURNCHARGE') or (rec_salesCrLinesA."No." = 'RETURNCOLLECT') then
                refundCharge := rec_salesCrLinesA."Amount Including VAT";
        end;

        rec_salesCrLines.Reset();
        rec_salesCrLines.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLines.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLines.FindSet() then begin
            repeat

                if maximumUnitPrice < rec_salesCrLines."Amount Including VAT" then begin
                    maximumUnitPrice := rec_salesCrLines."Amount Including VAT";
                    LineNo := rec_salesCrLines."Line No.";
                end;

            until rec_salesCrLines.Next() = 0;
        end;

        rec_salesCrLinesB.Reset();
        rec_salesCrLinesB.SetRange("Order No.", SalesHeader."No.");
        rec_salesCrLinesB.SetFilter("3rd Party System PK", '<>%1', '');

        if rec_salesCrLinesB.FindSet() then begin
            repeat

                if rec_salesCrLinesB."Line No." = LineNo then begin

                    refundAmountFromTable := maximumUnitPrice;
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"onbuy_internal_reference":"' + rec_salesCrLinesB."3rd Party System PK" + '","amount":' + Format(refundAmount + refundCharge) + '},';
                end
                else begin

                    refundAmountFromTable := rec_salesCrLinesB."Amount Including VAT";
                    refundAmount := CheckPriceToRefund(SalesHeader, refundAmountFromTable, rec_salesCrLinesB."3rd Party System PK");
                    refundItems := refundItems + '{"onbuy_internal_reference":"' + rec_salesCrLinesB."3rd Party System PK" + '","amount":' + Format(refundAmount) + '},';
                end;

            until rec_salesCrLinesB.Next() = 0;
        end;

        refundItems := DELCHR(refundItems, '>', ',');

        if refundItems <> '' then begin
            sendBody := '{"site_id":"' + recOnBuySetting.SID + '", "orders":[{"order_id":"' + SalesHeader."External Document No." + '","order_refund_reason_id":1,"items":[' + refundItems + ']}]}';

            exit(sendBody);
        end;
    end;

    procedure GetOnBuyAuthorziationToken(enumPaymentMethod: Enum EnhIntegrationLogTypes): Text
    var
        AuthKey, sendBody : Text;
        result, URI, jsonBody : Text;
        recOnBuySetting: Record "Onbuy Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        JObject: JsonObject;
        Jtoken, varjsonToken : JsonToken;

    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        RESTAPIHelper.Initialize('POST', 'https://api.onbuy.com/v2/auth/request-token');
        recOnBuySetting.Reset();

        if recOnBuySetting.FindFirst() then begin
            //Body

            sendBody := '{"secret_key": "' + recOnBuySetting.SecretKey + '","consumer_key": "' + recOnBuySetting.ClientKey + '"}';
            RESTAPIHelper.AddBody(sendBody);

            // ContentType
            RESTAPIHelper.SetContentType('application/json');

            if RESTAPIHelper.Send(enumPaymentMethod) then begin
                result := RESTAPIHelper.GetResponseContentAsText();
            end;

            jObject.ReadFrom(result);
            JObject.Get('access_token', varjsonToken);
            AuthKey := Format(varjsonToken);
            AuthKey := DelChr(AuthKey, '=', '"');
        end;
        exit(AuthKey);
    end;
}