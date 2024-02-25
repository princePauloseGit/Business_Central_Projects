codeunit 50426 AmazonPaymentForCredits
{
    var
        rec_AmazonSetting: Record "Amazon Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        result, URI : text;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure ConnectAmazonPaymentApi()
    var
        sendBody: Text;
    begin
        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                //Header
                Clear(RESTAPIHelper);
                URI := RESTAPIHelper.GetBaseURl() + 'Amazon/DownloadPaymentForCredits';
                RESTAPIHelper.Initialize('POST', URI);

                RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());

                sendBody := '{"reportDocumentIds": [],"days":15}';
                RESTAPIHelper.AddBody(sendBody);
                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadCreditsApiResponse(result);
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    local procedure ReadCreditsApiResponse(var response: Text)
    var
        Jtoken, documentNoToken : JsonToken;
        JObject: JsonObject;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j : Integer;
        externalDocumentNumber: Code[35];
        Amount: Decimal;
    begin
        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');
        JObject.Get('credits', Jtoken);
        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');
        for i := 0 to Jarray.Count() - 1 do begin
            Jarray.Get(i, Jtoken);
            Jtoken.AsObject.Get('externalDocumentNumber', documentNoToken);
            externalDocumentNumber := documentNoToken.AsValue().AsCode();
            Jtoken.AsObject.Get('amount', documentNoToken);
            Amount := documentNoToken.AsValue().AsDecimal();
            InsertAmazonPaymentCreditData(externalDocumentNumber, Amount);
        end;
    end;

    procedure InsertAmazonPaymentCreditData(externalDocNo: Code[35]; amount: Decimal)
    var
        recAmazonPaymentCreditData: Record AmazonPaymentCreditData;
    begin
        recAmazonPaymentCreditData.SetRange("External Document No", externalDocNo);
        if not recAmazonPaymentCreditData.FindFirst() then begin
            recAmazonPaymentCreditData.Init();
            recAmazonPaymentCreditData."External Document No" := externalDocNo;
            recAmazonPaymentCreditData.Amount := amount;
            recAmazonPaymentCreditData.Insert(true);
        end;

    end;
}
