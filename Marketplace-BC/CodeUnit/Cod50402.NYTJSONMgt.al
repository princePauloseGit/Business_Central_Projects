codeunit 50402 "NYT JSON Mgt"
{
    procedure SelectJsonToken(JObject: JsonObject; Path: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.SelectToken(Path, JToken) then
            if NOT JToken.AsValue().IsNull() then
                exit(JToken.AsValue().AsText());
    end;

    procedure SelectDecimalJsonToken(JObject: JsonObject; Path: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if JObject.SelectToken(Path, JToken) then
            if NOT JToken.AsValue().IsNull() then
                exit(JToken.AsValue().AsDecimal());
    end;

    procedure SelectBooleanJsonToken(JObject: JsonObject; Path: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if JObject.SelectToken(Path, JToken) then
            if NOT JToken.AsValue().IsNull() then
                exit(JToken.AsValue().AsBoolean());
    end;


    procedure GetValueAsText(JToken: JsonToken; ParamString: Text): Text
    var
        JObject: JsonObject;
    begin
        JObject := JToken.AsObject();
        exit(SelectJsonToken(JObject, ParamString));
    end;

    procedure GetValueAsBoolean(JToken: JsonToken; ParamString: Text): Boolean
    var
        JObject: JsonObject;
    begin
        JObject := JToken.AsObject();
        exit(SelectBooleanJsonToken(JObject, ParamString));
    end;

    procedure GetValueAsDecimal(JToken: JsonToken; ParamString: Text): Decimal
    var
        JObject: JsonObject;
    begin
        JObject := JToken.AsObject();
        exit(SelectDecimalJsonToken(JObject, ParamString));
    end;

    procedure EvaluateUTCDateTime(DataTimeText: Text) EvaluatedDateTime: DateTime;
    var
        TypeHelper: Codeunit "Type Helper";
        ValueTest: Variant;
    begin
        ValueTest := EvaluatedDateTime;
        IF TypeHelper.Evaluate(ValueTest, DataTimeText, '', TypeHelper.GetCultureName()) THEN
            EvaluatedDateTime := ValueTest;
    end;
}
