codeunit 50420 "B&QPaymentDownload"
{
    trigger OnRun()
    begin
        CreateBQCashReceiptBatchEntry();
    end;

    var
        RESTAPIHelper: Codeunit "REST API Helper";
        result, URI : text;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        rec_BQSetting: Record "B&Q Settings";
        cu_CommonHelper: Codeunit CommonHelper;


    local procedure GetNewLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        rec_GenJournaLine: Record "Gen. Journal Line";
    begin
        rec_GenJournaLine.Validate("Journal Template Name", TemplateName);
        rec_GenJournaLine.Validate("Journal Batch Name", BatchName);
        rec_GenJournaLine.SetRange("Journal Template Name", TemplateName);
        rec_GenJournaLine.SetRange("Journal Batch Name", BatchName);
        if rec_GenJournaLine.FindLast() then
            exit(rec_GenJournaLine."Line No." + 10000);
        exit(10000);
    end;

    procedure CreateBQCashReceiptBatchEntry()
    var
        sendBody: Text;
        pastDate: Date;
    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        pastDate := cu_CommonHelper.CalculateDate(15);
        URI := RESTAPIHelper.GetBaseURl() + 'BQ/DownloadBQPayment';
        RESTAPIHelper.Initialize('POST', URI);
        rec_BQSetting.Reset();

        if rec_BQSetting.FindSet() then begin
            repeat
                RESTAPIHelper.AddRequestHeader('Authorization', rec_BQSetting.APIKey.Trim());

                //Body
                sendBody := GenerateBodyforSettlementReports();
                RESTAPIHelper.AddBody('{"payment_state":"PAID","last_updated_from":"' + Format(pastDate, 0, 9) + '",' + sendBody + '}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');
                if RESTAPIHelper.Send(EnhIntegrationLogTypes::"B&Q") then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentApiResponse(result, rec_BQSetting);
                end;
            until rec_BQSetting.Next() = 0;
        end;
    end;

    procedure GenerateBodyforSettlementReports(): Text
    var
        element: Integer;
        reportIdList: list of [Text];
        reportIdBody: Text;
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
    begin
        rec_SettelmentPaymentIds.Reset();
        rec_SettelmentPaymentIds.SetRange(canArchived, false);
        rec_SettelmentPaymentIds.SetRange(MarketPlace, 'B&Q');
        if rec_SettelmentPaymentIds.FindSet() then begin
            repeat
                reportIdList.Add(rec_SettelmentPaymentIds."Report ID");
            until rec_SettelmentPaymentIds.Next() = 0;
        end;
        reportIdBody := '"reportDocumentIds": [';
        for element := 1 to reportIdList.Count do begin
            if element <> reportIdList.Count then
                reportIdBody := reportIdBody + '"' + reportIdList.Get(element) + '",'
            else
                reportIdBody := reportIdBody + '"' + reportIdList.Get(element) + '"';
        end;
        reportIdBody := reportIdBody + '] ';
        exit(reportIdBody);
    end;

    procedure ReadSettelmentApiResponse(var response: Text; rec_BQSetting: Record "B&Q Settings")
    var
        Jtoken, documentNoToken, ResultToken : JsonToken;
        JObject: JsonObject;
        Jarray: JsonArray;
        i, j : Integer;
        description, accountType, externalDocumentNumber : Text;
        varJsonArray, responseArray : JsonArray;
        varjsonToken, resultListToken : JsonToken;
        settlementId, accountNo, balAccountNo : Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        enumGenJournalBalAccountType: Enum "Payment Balance Account Type";
        BQVendorCode, BQBankAccount, BQCustomerCode : Code[35];
    begin
        if JObject.ReadFrom(response) then
            JObject.Get('payments', Jtoken);

        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                Jtoken.AsObject.Get('accountingDocumentNumber', documentNoToken);
                settlementId := documentNoToken.AsValue().AsCode();
                // Creating batch according to settlement ID
                InsertBQSettlement_CashReceiptJournalBatch(settlementId);
                JObject := Jtoken.AsObject();

                JObject.Get('bqPayments', Jtoken);
                for j := 0 to Jtoken.AsArray().Count() - 1 do begin
                    if Jtoken.AsArray().Get(j, ResultToken) then begin
                        ResultToken.AsObject.Get('accountType', resultListToken);
                        accountType := resultListToken.AsValue().AsText();

                        ResultToken.AsObject.Get('externalDocumentNumber', resultListToken);
                        externalDocumentNumber := resultListToken.AsValue().AsText();

                        //Customer Payment line
                        if (accountType = 'Customer') then begin
                            if not InsertBQSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Customer, rec_BQSetting.CustomerCode) then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::"B&Q", false, 'Settlement Id')
                            end;
                        end;

                        //vendor payment line
                        if accountType = 'Vendor' then begin
                            if not InsertBQSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, rec_BQSetting.VendorCode) then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::"B&Q", false, 'Settlement Id')
                            end;
                        end;

                        //Bank payment line:
                        if accountType = 'Bank' then begin
                            if not InsertBQSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::"Bank Account", '12000') then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::"B&Q", false, 'Settlement Id')
                            end;
                        end;
                    end;
                end;
            end;

        //reportDocumentDetails Entry
        if JObject.ReadFrom(result) then
            JObject.Get('reportDocumentDetails', Jtoken);
        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                JObject := Jtoken.AsObject();
                InsertProcessedReportIds(Jtoken);
            end;

        if JObject.ReadFrom(result) then
            JObject.Get('errorLogs', Jtoken);
        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                JObject := Jtoken.AsObject();
                cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::"B&Q");
            end;
    end;


    local procedure InsertBQSettlement_CashReceiptJournalBatch(settlementId: Code[20])
    var
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec_GenJournalBatch: Record "Gen. Journal Batch";
    begin
        rec_GenJournalBatch.Init();
        rec_GenJournalBatch."Journal Template Name" := 'CASHRCPT';
        rec_GenJournalBatch.Name := settlementId;
        rec_GenJournalBatch.Description := 'BQ-' + settlementId;
        rec_GenJournalBatch."Template Type" := enumTemplateType::"Cash Receipts";
        rec_GenJournalBatch."Allow VAT Difference" := true;
        rec_GenJournalBatch.Insert(true);
    end;


    [TryFunction]
    local procedure InsertBQSettlement_CashReceiptGenJournalLine(var resultToken: JsonToken; var settlementId: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; accountNo: Code[20])
    var
        valueToken: JsonToken;
        rec_GenJournaLine: Record "Gen. Journal Line";
        balAccNo: Code[20];
        BalGenPostingType: enum "General Posting Type";

    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', settlementId);
        ResultToken.AsObject.Get('balAccountNo', valueToken);
        balAccNo := valueToken.AsValue().AsText();

        if (balAccNo = '79076') or (balAccNo = '82010') then begin
            rec_GenJournaLine."Document No." := settlementId + 'F';
            rec_GenJournaLine."Bal. Account No." := balAccNo;
            rec_GenJournaLine.Validate("Bal. Account No.");
            rec_GenJournaLine."Bal. Gen. Posting Type" := BalGenPostingType::Purchase;
            rec_GenJournaLine.Validate("Bal. Gen. Posting Type");
            rec_GenJournaLine."Bal. VAT Bus. Posting Group" := 'DOMESTIC';
            rec_GenJournaLine.Validate("Bal. VAT Bus. Posting Group");
            rec_GenJournaLine."Bal. VAT Prod. Posting Group" := 'STANDARD_20%';
            rec_GenJournaLine.Validate("Bal. VAT Prod. Posting Group");

        end
        else
            rec_GenJournaLine."Document No." := settlementId;

        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := settlementId;
        rec_GenJournaLine."Document Type" := "Gen. Journal Document Type"::" ";
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType;
        ResultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));
        rec_GenJournaLine."Account No." := accountNo;
        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('externalDocumentNumber', valueToken);
        rec_GenJournaLine."External Document No." := valueToken.AsValue().AsText();
        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := (valueToken.AsValue().AsDecimal());
        rec_GenJournaLine.Validate(Amount);
        rec_GenJournaLine."Bal. VAT %" := 1;
        ResultToken.AsObject.Get('balVATAmount', valueToken);
        rec_GenJournaLine."Bal. VAT Amount" := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate("Bal. VAT Amount");
        rec_GenJournaLine."Payment Method Code" := 'B&Q';
        rec_GenJournaLine.Insert(true);
    end;

    local procedure InsertProcessedReportIds(resultToken: JsonToken)
    var
        valueToken: JsonToken;
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
    begin
        resultToken.AsObject.Get('canArchived', valueToken);
        if not valueToken.AsValue().AsBoolean() then begin
            rec_SettelmentPaymentIds.Init();
            rec_SettelmentPaymentIds.canArchived := valueToken.AsValue().AsBoolean();
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds."Report ID" := valueToken.AsValue().AsText();
            rec_SettelmentPaymentIds.MarketPlace := 'B&Q';
            rec_SettelmentPaymentIds.Insert(true);
        end

        //Modify the EXisting ReportId with true
        else begin
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds.SetRange("Report ID", valueToken.AsValue().AsText());
            if rec_SettelmentPaymentIds.FindFirst() then begin
                rec_SettelmentPaymentIds.canArchived := true;
                rec_SettelmentPaymentIds.MarketPlace := 'B&Q';
                rec_SettelmentPaymentIds.Modify(true);
            end
        end;
    end;
}
