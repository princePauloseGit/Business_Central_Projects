codeunit 50406 CommonHelper
{

    var
        NYTJSONMgt: Codeunit "NYT JSON Mgt";

    procedure CalculateDate(pastDay: Integer): Date
    var
        calculatedDate: Date;
        backDay: Text[4];
    begin
        backDay := '-' + format(pastDay) + 'D';
        exit(CalcDate(backDay, Today));

    end;

    procedure InsertEnhancedIntegrationLog(varjsonToken: JsonToken; enumEnhIntegrationLogTypes: Enum EnhIntegrationLogTypes)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        valueToken: JsonToken;
        severity: text;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enumEnhIntegrationLogTypes;
        severity := NYTJSONMgt.GetValueAsText(varjsonToken, 'sevarity');

        if (severity = 'Warning') then
            rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Warning
        else
            if (severity = 'Error') then
                rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Error
            else
                rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Information;

        rec_EnhanceIntegrationLog.RecordType := NYTJSONMgt.GetValueAsText(varjsonToken, 'recordType');
        rec_EnhanceIntegrationLog.RecordID := NYTJSONMgt.GetValueAsText(varjsonToken, 'recordID');
        rec_EnhanceIntegrationLog.Message := CopyStr(NYTJSONMgt.GetValueAsText(varjsonToken, 'message'), 1, 2048);
        rec_EnhanceIntegrationLog.ExtendedText := CopyStr(NYTJSONMgt.GetValueAsText(varjsonToken, 'stackTrace'), 1, 2048);
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure InsertBusinessCentralErrorLog(errorMessage: text; recordId: Text; enum_EnhIntegrationLogTypes: Enum EnhIntegrationLogTypes; ItemErrorFlag: Boolean; recordType: text)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enum_EnhIntegrationLogTypes;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Error;
        rec_EnhanceIntegrationLog.RecordType := recordType;
        rec_EnhanceIntegrationLog.RecordID := recordId;
        rec_EnhanceIntegrationLog.Message := CopyStr(errorMessage, 1, 2048);

        if ItemErrorFlag then begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(errorMessage, 1, 2048);
            rec_EnhanceIntegrationLog."Error Message" := CopyStr(errorMessage, 1, 2048);
        end
        else begin
            rec_EnhanceIntegrationLog.ExtendedText := CopyStr(GetLastErrorText(), 1, 2048);

            rec_EnhanceIntegrationLog."Error Message" := CopyStr(GetLastErrorCallStack(), 1, 2048);
        end;
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure InsertWarningForAmazon(errorMessage: text; recordId: Text; recordType: Text; enumEnhIntegrationLogTypes: Enum EnhIntegrationLogTypes)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enumEnhIntegrationLogTypes;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Warning;
        rec_EnhanceIntegrationLog.RecordType := recordType;
        rec_EnhanceIntegrationLog.RecordID := recordId;
        rec_EnhanceIntegrationLog.Message := CopyStr(errorMessage, 1, 2048);
        rec_EnhanceIntegrationLog.ExtendedText := CopyStr(errorMessage, 1, 2048);
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure InsertInformationLogs(errorMessage: text; recordId: Text; recordType: Text; enumEnhIntegrationLogTypes: Enum EnhIntegrationLogTypes)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := enumEnhIntegrationLogTypes;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Information;
        rec_EnhanceIntegrationLog.RecordType := recordType;
        rec_EnhanceIntegrationLog.RecordID := recordId;
        rec_EnhanceIntegrationLog.Message := CopyStr(errorMessage, 1, 2048);
        rec_EnhanceIntegrationLog.ExtendedText := CopyStr(errorMessage, 1, 2048);
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    procedure GetLastLineNo(no: Code[20]): Integer
    var
        Id: Integer;
        rec_SalesLines: Record "Sales Line";
    begin
        rec_SalesLines.SetRange("Document No.", no);
        if rec_SalesLines.FindLast() then
            Id := rec_SalesLines."Line No." + 10000
        else
            id := 10000;
        exit(Id)
    end;

    procedure MarketplaceEmailSetup(enum_Alerts: Enum MarketPlaceAlerts) ToRecipients: List of [Text];
    var
        rec_EmailAlerts: Record "MarketPlace Email Setup";
    begin
        rec_EmailAlerts.SetRange("Alert Name", enum_Alerts);
        if rec_EmailAlerts.FindSet() then
            repeat
                ToRecipients.Add(rec_EmailAlerts.Email);
            until rec_EmailAlerts.Next() = 0;
    end;

    procedure checkIntegrationLog(integrationRecordId: Text; enumEnhIntegrationLogTypes: Enum EnhIntegrationLogTypes): Boolean
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        rec_EnhanceIntegrationLog.SetFilter(DateTimeOccurred, '>%1', CreateDateTime(CalcDate('-10D', Today), 0T));
        rec_EnhanceIntegrationLog.SetRange(RecordID, integrationRecordId);
        rec_EnhanceIntegrationLog.SetRange(Severity, EnhIntegrationLogSeverity::Information);
        rec_EnhanceIntegrationLog.SetRange(source, enumEnhIntegrationLogTypes);
        rec_EnhanceIntegrationLog.SetRange(RecordType, 'Order Id');

        if rec_EnhanceIntegrationLog.FindFirst() then
            exit(true);

        exit(false);
    end;

    procedure InsertMagentoGrossValue(SalesHeaderNo: Code[20]; unitPrice: Decimal)
    var
        salesHeaderRef: RecordRef;
        MagentoGrossValueRef, OrderIdRef, ShortcutDimensionRef : FieldRef;
        MagentoGrossValue: Decimal;
    begin

        MagentoGrossValue := MagentoGrossValue + unitPrice;
        salesHeaderRef.Open(36);
        OrderIdRef := salesHeaderRef.Field(3);
        MagentoGrossValueRef := salesHeaderRef.Field(90133);

        OrderIdRef.SetRange(SalesHeaderNo);

        if salesHeaderRef.FindFirst() then begin
            MagentoGrossValue := MagentoGrossValueRef.Value;
            MagentoGrossValueRef.Value := MagentoGrossValue + unitPrice;
            salesHeaderRef.Modify(true);
        end;
    end;
}
