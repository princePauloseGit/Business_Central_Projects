codeunit 50401 "REST API Helper"
{
    Access = Public;
    //TODO: Build in RequestCatcher.com functionality so that it's easy to analyze requests that come from Business Central

    var
        WebClient: HttpClient;
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebRequestHeaders: HttpHeaders;
        WebContentHeaders: HttpHeaders;
        WebContent: HttpContent;
        CurrentContentType: Text;
        RestHeaders: TextBuilder;
        ContentTypeSet: Boolean;
        cu_CommonHelper: Codeunit CommonHelper;

    procedure GetBaseURl(): Text
    var
        ApiUrl, baseAPIUrl, i : Text;
        baseurlList: List of [Text];
        recMarketplaceHostAPI: Record MarketplaceHostAPI;
    begin

        if recMarketplaceHostAPI.FindLast() then
            ApiUrl := recMarketplaceHostAPI.MarketPlaceAPI;

        if ApiUrl.EndsWith('/') then
            baseAPIUrl := ApiUrl + 'api/'
        else
            baseAPIUrl := ApiUrl + '/api/';
        exit(baseAPIUrl);
    end;

    procedure Initialize(Method: Text; URI: Text);
    begin
        WebRequest.Method := Method;
        WebRequest.SetRequestUri(URI);

        WebRequest.GetHeaders(WebRequestHeaders);
    end;

    procedure AddRequestHeader(HeaderKey: Text; HeaderValue: Text)
    begin
        RestHeaders.AppendLine(HeaderKey + ': ' + HeaderValue);
        WebRequestHeaders.Add(HeaderKey, HeaderValue);
    end;

    procedure AddBody(Body: Text)
    begin
        WebContent.WriteFrom(Body);
        ContentTypeSet := true;
    end;

    procedure SetContentType(ContentType: Text)
    begin
        CurrentContentType := ContentType;
        webcontent.GetHeaders(WebContentHeaders);
        if WebContentHeaders.Contains('Content-Type') then
            WebContentHeaders.Remove('Content-Type');
        WebContentHeaders.Add('Content-Type', ContentType);
    end;

    procedure Send(EnhIntegrationLogTypes: Enum EnhIntegrationLogTypes) SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
        RequestUrl, description, ebayError, outputString : Text;
        Outstr: OutStream;
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        WebClient.Timeout := 300000;
        SendSuccess := WebClient.Send(WebRequest, WebResponse);
        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);

        if SendSuccess then begin
            if not WebResponse.IsSuccessStatusCode() then begin
                SendSuccess := false;
                WebResponse.Content().ReadAs(outputString);
                cu_CommonHelper.InsertBusinessCentralErrorLog(outputString, 'Status code: ' + format(WebResponse.HttpStatusCode), EnhIntegrationLogTypes, true, '');
            end;
        end;
        //Log(StartDateTime, TotalDuration);
    end;

    procedure SendtoEbay(EnhIntegrationLogTypes: Enum EnhIntegrationLogTypes) SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
        RequestUrl, description, ebayError, outputString : Text;
        Outstr: OutStream;
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        WebClient.Timeout := 300000;
        SendSuccess := WebClient.Send(WebRequest, WebResponse);
        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);

        if SendSuccess then begin
            if not WebResponse.IsSuccessStatusCode() then begin
                SendSuccess := false;
                WebResponse.Content().ReadAs(outputString);
                cu_CommonHelper.InsertBusinessCentralErrorLog(outputString, 'Failed to send from Business central to API' + format(WebResponse.HttpStatusCode), EnhIntegrationLogTypes, true, '');
            end;
        end;
        //Log(StartDateTime, TotalDuration);
    end;

    procedure GetResponseContentAsText() ResponseContentText: Text
    var
        RestBlob: Codeunit "Temp Blob";
        Instr: Instream;
    begin

        RestBlob.CreateInStream(Instr);
        WebResponse.Content().ReadAs(ResponseContentText);
    end;

    procedure GetResponseReasonPhrase(): Text
    begin
        exit(WebResponse.ReasonPhrase());
    end;

    procedure GetHttpStatusCode(): Integer
    begin
        exit(WebResponse.HttpStatusCode());
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;
}