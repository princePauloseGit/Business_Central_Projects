codeunit 50439 EbayDeleteItem
{
    procedure sendToDeleteInventoryItems(itemNo: Text)
    var
        URI, result : Text;
        jObject: JsonObject;
        varjsonToken: JsonToken;
        varJsonArray: JsonArray;
        i: Integer;
        RESTAPIHelper: Codeunit "REST API Helper";
        rec_EbaySettings: Record "ebay Setting";
        cu_CommonHelper: Codeunit CommonHelper;

    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        URI := RESTAPIHelper.GetBaseURl() + 'Ebay/DeleteInventoryItems';
        RESTAPIHelper.Initialize('POST', URI);
        rec_EbaySettings.Reset();

        if rec_EbaySettings.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                Clear(RESTAPIHelper);
                //Headers
                RESTAPIHelper.Initialize('POST', URI);

                RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());

                RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                //Body
                RESTAPIHelper.AddBody('{"skUs": [ "' + itemNo + '"]}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();

                    if not JObject.ReadFrom(result) then
                        Error('Invalid response, expected a JSON object');

                    JObject.Get('errorLogs', varjsonToken);

                    if not varJsonArray.ReadFrom(Format(varjsonToken)) then
                        Error('Array not Reading Properly');

                    for i := 0 to varJsonArray.Count() - 1 do begin
                        varJsonArray.Get(i, varjsonToken);
                        cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Ebay);
                    end;
                end
                else
                    Message('An error occured while delete listing, please check integration log');
            until rec_EbaySettings.Next() = 0;
        end;
    end;

}
