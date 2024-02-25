codeunit 50418 BrainTreePaymentDownload
{
    trigger OnRun()
    begin
        CreateBraintreeCashReceiptBatchEntry();
    end;

    var
        RESTAPIHelper: Codeunit "REST API Helper";
        result, URI : text;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;


    local procedure GetNewLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Validate("Journal Template Name", TemplateName);
        GenJournalLine.Validate("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if GenJournalLine.FindLast() then
            exit(GenJournalLine."Line No." + 10000);
        exit(10000);
    end;

    procedure CreateBraintreeCashReceiptBatchEntry()
    var
        sendBody: Text;
        rec_BraintreeSetting: Record "Braintree Setting";
        startDate, endDate : Date;
    begin

        Clear(RESTAPIHelper);
        Clear(URI);
        URI := RESTAPIHelper.GetBaseURl() + 'Braintree/DownloadPayment';
        RESTAPIHelper.Initialize('POST', URI);
        rec_BraintreeSetting.Reset();

        if rec_BraintreeSetting.FindSet() then begin
            repeat
                RESTAPIHelper.AddRequestHeader('merchantId', rec_BraintreeSetting.MerchantID.Trim());
                RESTAPIHelper.AddRequestHeader('privateKey', rec_BraintreeSetting.PrivateKey.Trim());
                RESTAPIHelper.AddRequestHeader('publicKey', rec_BraintreeSetting.PublicKey.Trim());

                //Body
                startDate := rec_BraintreeSetting.StartDate;
                endDate := rec_BraintreeSetting.EndDate;

                sendBody := GenerateBodyforSettlementReports(startDate, endDate);
                RESTAPIHelper.AddBody(sendBody);

                //ContentType
                RESTAPIHelper.SetContentType('application/json');
                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Braintree) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentApiResponse(result);
                end;
            until rec_BraintreeSetting.Next() = 0;
        end;
    end;

    procedure ReadSettelmentApiResponse(var response: Text)
    var
        Jtoken, documentNoToken, ResultToken : JsonToken;
        JObject: JsonObject;
        Amount: Integer;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j, lineNo : Integer;
        description, AccountType, DocumentType, paymentLine, shortcutDimension, externalDocumentNumber : Text;
        varJsonArray, responseArray : JsonArray;
        varjsonToken, resultListToken : JsonToken;
        settlementId, accountNo : Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        enumGenJournalDocumentType: Enum "Gen. Journal Document Type";
        rec_BraintreeSetting: Record "Braintree Setting";
        brainTreeVendorCode, brainTreeBankAccount, brainTreeCustomerCode : Code[35];

    begin
        rec_BraintreeSetting.Reset();
        if rec_BraintreeSetting.FindFirst() then begin
            brainTreeCustomerCode := rec_BraintreeSetting.CustomerCode;
            brainTreeVendorCode := rec_BraintreeSetting.VendorCode;
            brainTreeBankAccount := rec_BraintreeSetting.BankGLCode;
        end;

        if JObject.ReadFrom(response) then
            JObject.Get('settlements', Jtoken);
        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                Jtoken.AsObject.Get('settlementId', documentNoToken);
                settlementId := documentNoToken.AsValue().AsCode();
                // Creating batch according to settlement ID
                InsertBrainTreeSettlement_CashReceiptJournalBatch(settlementId);
                JObject := Jtoken.AsObject();

                JObject.Get('braintreeSettlements', Jtoken);
                for j := 0 to Jtoken.AsArray().Count() - 1 do begin

                    if Jtoken.AsArray().Get(j, ResultToken) then begin
                        ResultToken.AsObject.Get('accountType', resultListToken);
                        accountType := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('shortcutDimension', resultListToken);
                        shortcutDimension := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('documentType', resultListToken);
                        DocumentType := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('externalDocumentNumber', resultListToken);
                        externalDocumentNumber := resultListToken.AsValue().AsText();
                        //Customer Payment line
                        if (accountType = 'Customer') then begin
                            accountNo := brainTreeCustomerCode;

                            if not InsertBraintreeSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Customer, rec_BraintreeSetting.CustomerCode) then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Braintree, false, 'Settlement Id')
                            end;
                        end;
                        //vendor payment line
                        if accountType = 'Vendor' then begin
                            accountNo := brainTreeVendorCode;

                            if not InsertBraintreeSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, rec_BraintreeSetting.VendorCode) then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Braintree, false, 'Settlement Id')
                            end;
                        end;

                        //Bank payment line:
                        if accountType = 'Bank' then begin
                            accountNo := brainTreeBankAccount;

                            if not InsertBraintreeSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::"Bank Account", rec_BraintreeSetting.BankGLCode) then begin
                                description := 'For Batch ' + settlementId + ', ' + accountType + ' entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Braintree, false, 'Settlement Id')
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

        if not JObject.ReadFrom(result) then
            Error('Invalid response, expected a JSON object');
        JObject.Get('errorLogs', Jtoken);

        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

        for i := 0 to Jarray.Count() - 1 do begin
            Jarray.Get(i, Jtoken);
            JObject := Jtoken.AsObject();
            cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::Braintree);
        end;
    end;

    local procedure InsertProcessedReportIds(resultToken: JsonToken)
    var
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
        valueToken: JsonToken;
    begin
        resultToken.AsObject.Get('canArchived', valueToken);
        if not valueToken.AsValue().AsBoolean() then begin
            rec_SettelmentPaymentIds.Init();
            rec_SettelmentPaymentIds.canArchived := valueToken.AsValue().AsBoolean();

            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds."Report ID" := valueToken.AsValue().AsText();
            rec_SettelmentPaymentIds.MarketPlace := 'Braintree';
            rec_SettelmentPaymentIds.Insert(true);
        end

        //Modify the EXisting ReportId with true
        else begin
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds.SetRange("Report ID", valueToken.AsValue().AsText());
            if rec_SettelmentPaymentIds.FindFirst() then begin
                rec_SettelmentPaymentIds.canArchived := true;
                rec_SettelmentPaymentIds.MarketPlace := 'Braintree';
                rec_SettelmentPaymentIds.Modify(true);
            end
        end;
    end;

    local procedure InsertBrainTreeSettlement_CashReceiptJournalBatch(settlementId: Code[20])
    var
        recGenJournalBatch: Record "Gen. Journal Batch";
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec: Record "Gen. Journal Template";
    begin
        recGenJournalBatch.Init();
        recGenJournalBatch."Journal Template Name" := 'CASHRCPT';
        recGenJournalBatch.Name := settlementId;
        recGenJournalBatch.Description := 'BT-' + DelStr(settlementId, 1, 2);

        recGenJournalBatch."Template Type" := enumTemplateType::"Cash Receipts";

        recGenJournalBatch.Insert(true);
    end;

    [TryFunction]
    local procedure InsertBraintreeSettlement_CashReceiptGenJournalLine(var resultToken: JsonToken; var settlementId: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; accountNo: Code[20])
    var
        rec_GenJournaLine: Record "Gen. Journal Line";
        valueToken: JsonToken;
    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', settlementId);
        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := settlementId;
        resultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));
        rec_GenJournaLine."Document Type" := "Gen. Journal Document Type"::" ";
        resultToken.AsObject.Get('documentNumber', valueToken);
        rec_GenJournaLine."Document No." := valueToken.AsValue().AsCode();
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType;
        rec_GenJournaLine."Account No." := accountNo;
        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('externalDocumentNumber', valueToken);
        rec_GenJournaLine."External Document No." := valueToken.AsValue().AsText();
        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate(Amount);
        resultToken.AsObject.Get('shortcutDimension', valueToken);
        rec_GenJournaLine."Shortcut Dimension 1 Code" := valueToken.AsValue().AsCode();

        rec_GenJournaLine.Insert(true);
    end;

    procedure GenerateBodyforSettlementReports(startDate: Date; endDate: Date): Text
    var
        element: Integer;
        reportIdList: list of [Text];
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
        reportIdBody: Text;
        recBraintree: Record "Braintree Setting";
    begin

        rec_SettelmentPaymentIds.Reset();
        rec_SettelmentPaymentIds.SetRange(canArchived, false);
        rec_SettelmentPaymentIds.SetRange(MarketPlace, 'Braintree');
        if rec_SettelmentPaymentIds.FindSet() then begin
            repeat
                reportIdList.Add(rec_SettelmentPaymentIds."Report ID");
            until rec_SettelmentPaymentIds.Next() = 0;
        end;
        reportIdBody := '{"reportDocumentIds": [';
        for element := 1 to reportIdList.Count do begin
            if element <> reportIdList.Count then
                reportIdBody := reportIdBody + '"' + reportIdList.Get(element) + '",'
            else
                reportIdBody := reportIdBody + '"' + reportIdList.Get(element) + '"';
        end;

        if (Format(startDate) <> '') and (Format(endDate) <> '') then begin

            reportIdBody := reportIdBody + '], "StartDate": "' + Format(startDate, 0, 9) + 'T00:00:00.000Z","EndDate":"' + Format(endDate, 0, 9) + 'T00:00:00.000Z" }';
        end
        else begin
            reportIdBody := reportIdBody + ']}'
        end;

        exit(reportIdBody);
    end;
}
