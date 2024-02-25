codeunit 50425 EbayPayment
{
    trigger OnRun()
    begin
        CreateEbayCashReceiptBatchEntry();
    end;

    var
        RESTAPIHelper: Codeunit "REST API Helper";
        result, URI : text;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        rec_EbaySettings: Record "ebay Setting";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreateEbayCashReceiptBatchEntry()
    var
        sendBody, Body : Text;
        pastDate: Date;
    begin
        Clear(RESTAPIHelper);
        Clear(URI);

        if Date2DWY(Today, 1) = 1 then
            pastDate := cu_CommonHelper.CalculateDate(7)
        else
            pastDate := cu_CommonHelper.CalculateDate(3);

        URI := RESTAPIHelper.GetBaseURl() + 'Ebay/DownloadPayment';
        RESTAPIHelper.Initialize('POST', URI);
        rec_EbaySettings.Reset();
        if rec_EbaySettings.FindSet() then begin
            repeat
                Clear(RESTAPIHelper);
                //Headers
                RESTAPIHelper.Initialize('POST', URI);

                RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());

                RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                //Body
                sendBody := GenerateBodyforSettlementReports();

                RESTAPIHelper.AddBody('{"JWE":"' + rec_EbaySettings.DigitalSignatureJWE + '","PrivateKey":"' + rec_EbaySettings.DigitalSignaturePrivateKey + '","Days":"15",' + sendBody + ', "PayoutStatus": "SUCCEEDED"}');

                //ContentType
                RESTAPIHelper.SetContentType('application/json');
                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();

                    ReadSettelmentApiResponse(result, rec_EbaySettings);
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    procedure ReadSettelmentApiResponse(var response: Text; rec_EbaySettings: Record "ebay Setting")
    var
        Jtoken, documentNoToken, ResultToken : JsonToken;
        JObject: JsonObject;
        Jarray: JsonArray;
        i, j : Integer;
        description, accountType, externalDocumentNumber, paymentLine, shortcutDimension, DocumentType : Text;
        varJsonArray, responseArray : JsonArray;
        varjsonToken, resultListToken : JsonToken;
        settlementId, accountNo, balAccountNo : Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        enumGenJournalBalAccountType: Enum "Payment Balance Account Type";
        EbayVendorCode, EbayBankAccount, EbayCustomerCode, ItemNo : Code[35];
    begin
        ItemNo := '';

        rec_EbaySettings.Reset();
        if rec_EbaySettings.FindFirst() then begin
            EbayCustomerCode := rec_EbaySettings.CustomerCode;
            EbayVendorCode := rec_EbaySettings.VendorCode;
            EbayBankAccount := rec_EbaySettings.BankGLCode;
        end;

        rec_EbaySettings.Reset();
        if rec_EbaySettings.FindFirst() then begin
            ebayCustomerCode := rec_EbaySettings.CustomerCode;
        end;

        if JObject.ReadFrom(response) then
            JObject.Get('settlements', Jtoken);
        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                Jtoken.AsObject.Get('settlementId', documentNoToken);
                settlementId := documentNoToken.AsValue().AsCode();
                // Creating batch according to settlement ID
                InsertEbaySettlement_CashReceiptJournalBatch(settlementId);
                JObject := Jtoken.AsObject();


                JObject.Get('settlements', Jtoken);
                for j := 0 to Jtoken.AsArray().Count() - 1 do begin

                    if Jtoken.AsArray().Get(j, ResultToken) then begin
                        ResultToken.AsObject.Get('paymentLine', resultListToken);
                        paymentLine := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('shortcutDimension', resultListToken);
                        shortcutDimension := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('documentType', resultListToken);
                        DocumentType := resultListToken.AsValue().AsText();
                        if shortcutDimension = 'eBay' then begin
                            accountNo := ebayCustomerCode;
                        end;

                        if (paymentLine = 'Customer') then begin

                            if not InsertEbaySettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Customer, EbayCustomerCode, paymentLine) then begin
                                description := 'For Batch ' + settlementId + ', Customer entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Ebay, false, 'Settlement Id')
                            end;
                        end;

                        //Bank payment line:
                        if paymentLine = 'Bank' then begin

                            if not InsertEbaySettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::"Bank Account", EbayBankAccount, paymentLine) then begin
                                description := 'For Batch ' + settlementId + ', Bank entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Ebay, false, 'Settlement Id')
                            end;
                        end;
                        if paymentLine = 'Invoice' then begin

                            if not InsertEbaySettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, EbayVendorCode, paymentLine) then begin

                                description := 'For Batch ' + settlementId + ', Invoice entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Ebay, false, 'Settlement Id')
                            end;
                        end;
                        if paymentLine = 'Payment' then begin

                            if not InsertEbaySettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, EbayVendorCode, paymentLine) then begin
                                description := 'For Batch ' + settlementId + ', Payment entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Ebay, false, 'Settlement Id')
                            end;
                        end;
                    end;
                end;
            end;

        //reportDocumentDetails Entry

        if not JObject.ReadFrom(result) then
            Error('Invalid response, expected a JSON object');
        JObject.Get('reportDocumentDetails', Jtoken);
        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

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
            cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::Ebay);
        end;
    end;

    local procedure InsertEbaySettlement_CashReceiptJournalBatch(settlementId: Code[20])
    var
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec_GenJournalBatch: Record "Gen. Journal Batch";
    begin
        rec_GenJournalBatch.Init();
        rec_GenJournalBatch."Journal Template Name" := 'CASHRCPT';
        rec_GenJournalBatch.Name := settlementId;
        rec_GenJournalBatch.Description := 'EB-' + settlementId;
        rec_GenJournalBatch."Template Type" := enumTemplateType::"Cash Receipts";
        rec_GenJournalBatch.Insert(true);
    end;

    [TryFunction]
    local procedure InsertEbaySettlement_CashReceiptGenJournalLine(var resultToken: JsonToken; var settlementId: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; accountNo: Code[20]; paymentLine: Text)
    var
        valueToken: JsonToken;
        rec_GenJournaLine: Record "Gen. Journal Line";
        balAccNo: Code[20];
        BalGenPostingType: enum "General Posting Type";

    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', settlementId);
        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := settlementId;
        resultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));
        rec_GenJournaLine."Document Type" := "Gen. Journal Document Type"::" ";
        rec_GenJournaLine."Document No." := settlementId;
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType;
        rec_GenJournaLine."Account No." := accountNo;

        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('externalDocumentNumber', valueToken);
        rec_GenJournaLine."External Document No." := valueToken.AsValue().AsText();
        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate(Amount);

        if paymentLine = 'Invoice' then begin
            rec_GenJournaLine."Bal. Account Type" := "Gen. Journal Account Type"::"G/L Account";
            rec_GenJournaLine."Bal. Account No." := '79072';
            rec_GenJournaLine.Validate("Bal. Account No.");
        end;
        resultToken.AsObject.Get('shortcutDimension', valueToken);
        rec_GenJournaLine."Shortcut Dimension 1 Code" := valueToken.AsValue().AsCode();
        rec_GenJournaLine.Insert(true);
    end;

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

    procedure GenerateBodyforSettlementReports(): Text
    var
        element: Integer;
        reportIdList: list of [Text];
        reportIdBody: Text;
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
    begin
        rec_SettelmentPaymentIds.Reset();
        rec_SettelmentPaymentIds.SetRange(canArchived, false);
        rec_SettelmentPaymentIds.SetRange(MarketPlace, 'Ebay');
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
            rec_SettelmentPaymentIds.MarketPlace := 'Ebay';
            rec_SettelmentPaymentIds.Insert(true);
        end

        //Modify the EXisting ReportId with true
        else begin
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds.SetRange("Report ID", valueToken.AsValue().AsText());
            if rec_SettelmentPaymentIds.FindFirst() then begin
                rec_SettelmentPaymentIds.canArchived := true;
                rec_SettelmentPaymentIds.MarketPlace := 'Ebay';
                rec_SettelmentPaymentIds.Modify(true);
            end
        end;
    end;

}
