codeunit 50416 PaypalPaymentDownload
{
    trigger OnRun()
    begin
        CreateCashReceiptBatchEntry();
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

    procedure CreateCashReceiptBatchEntry()
    var
        sendBody: Text;
        rec_PaypalSetting: Record "Paypal Setting";
    begin
        Clear(RESTAPIHelper);
        URI := RESTAPIHelper.GetBaseURl() + 'PayPal/DownloadPayment';
        RESTAPIHelper.Initialize('POST', URI);
        rec_PaypalSetting.Reset();

        if rec_PaypalSetting.FindSet() then begin
            repeat
                RESTAPIHelper.AddRequestHeader('sftpHost', rec_PaypalSetting.URL.Trim());
                RESTAPIHelper.AddRequestHeader('sftpPort', rec_PaypalSetting.sftpPort.Trim());
                RESTAPIHelper.AddRequestHeader('sftpUser', rec_PaypalSetting.APIUser.Trim());
                RESTAPIHelper.AddRequestHeader('sftpPassword', rec_PaypalSetting.APIPassword.Trim());
                RESTAPIHelper.AddRequestHeader('sftpDestinationPath', rec_PaypalSetting.SftpDestinationPath.Trim());
                RESTAPIHelper.AddRequestHeader('Signature', rec_PaypalSetting.Signature.Trim());

                //Body
                sendBody := GenerateBodyforSettlementReports();
                RESTAPIHelper.AddBody(sendBody);

                //ContentType
                RESTAPIHelper.SetContentType('application/json');
                if RESTAPIHelper.Send(EnhIntegrationLogTypes::PayPal) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadSettelmentApiResponse(result);
                end;
            until rec_PaypalSetting.Next() = 0;
        end;
    end;

    procedure ReadSettelmentApiResponse(var response: Text)
    var
        Jtoken, documentNoToken, VendorGLToken, SalesReceiptToken, PaymentLineToken, ResultToken : JsonToken;
        JObject: JsonObject;
        Amount: Integer;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j, lineNo : Integer;
        error, description, AccountType, DocumentType, paymentLine, shortcutDimension : Text;
        varJsonArray, responseArray : JsonArray;
        varjsonToken, shippingAddressToken, resultListToken, orderTotaltoken : JsonToken;
        settlementId, accountNo : Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        enumGenJournalDocumentType: Enum "Gen. Journal Document Type";
        recPaypalSetting: Record "Paypal Setting";
        recOnbuySetting: Record "Onbuy Setting";
        recebaySetting: Record "ebay Setting";
        paypalCustomerCode, ebayCustomerCode, OnbuyCustomerCode, paypalVendorCode, onbuyVendorCode, paypalBankAccount, ItemNo : Code[35];

    begin
        ItemNo := '';
        error := 'Please check the Sftp details';
        recPaypalSetting.Reset();
        if recPaypalSetting.FindFirst() then begin
            paypalCustomerCode := recPaypalSetting.CustomerCode;
            paypalVendorCode := recPaypalSetting.VendorCode;
            paypalBankAccount := recPaypalSetting.BankGLCode;
        end;
        recOnbuySetting.Reset();
        if recOnbuySetting.FindFirst() then begin
            OnbuyCustomerCode := recOnbuySetting.OnbuyCustomerCode;
            onbuyVendorCode := recOnbuySetting.OnbuyVendorCode;
        end;
        recebaySetting.Reset();
        if recebaySetting.FindFirst() then begin
            ebayCustomerCode := recebaySetting.CustomerCode;
        end;

        if JObject.ReadFrom(response) then
            JObject.Get('payPalSettlements', Jtoken);
        if Jarray.ReadFrom(Format(Jtoken)) then
            for i := 0 to Jarray.Count() - 1 do begin
                Jarray.Get(i, Jtoken);
                Jtoken.AsObject.Get('settlementId', documentNoToken);
                settlementId := documentNoToken.AsValue().AsCode();
                // Creating batch according to settlement ID
                InsertPaypalSettlement_CashReceiptJournalBatch(settlementId);
                JObject := Jtoken.AsObject();

                JObject.Get('payPalSettlements', Jtoken);
                for j := 0 to Jtoken.AsArray().Count() - 1 do begin

                    if Jtoken.AsArray().Get(j, ResultToken) then begin
                        ResultToken.AsObject.Get('paymentLine', resultListToken);
                        paymentLine := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('shortcutDimension', resultListToken);
                        shortcutDimension := resultListToken.AsValue().AsText();
                        ResultToken.AsObject.Get('documentType', resultListToken);
                        DocumentType := resultListToken.AsValue().AsText();

                        if (paymentLine = 'Customer') then begin
                            if shortcutDimension = 'Website' then begin
                                accountNo := paypalCustomerCode;
                            end;
                            if shortcutDimension = 'eBay' then begin
                                accountNo := ebayCustomerCode;
                            end;
                            if shortcutDimension = 'OnBuy' then begin
                                accountNo := OnbuyCustomerCode;
                            end;

                            if not InsertPaypalSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Customer, accountNo) then begin

                                description := 'For Batch ' + settlementId + ', Customer entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Paypal, false, 'Settlement Id')
                            end;
                        end;
                        //Paypal vendor payment line
                        if paymentLine = 'PayPal' then begin

                            if not InsertPaypalSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, paypalVendorCode) then begin

                                description := 'For Batch ' + settlementId + ', Vendor entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Paypal, false, 'Settlement Id')
                            end;
                        end;

                        //OnBuy vendor payment line
                        if paymentLine = 'OnBuy' then begin
                            if not InsertPaypalSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::Vendor, onbuyVendorCode) then begin

                                description := 'For Batch ' + settlementId + ', Vendor entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Paypal, false, 'Settlement Id')
                            end;
                        end;

                        //Bank payment line:
                        if paymentLine = 'Bank' then begin

                            if not InsertPaypalSettlement_CashReceiptGenJournalLine(ResultToken, settlementId, enumGenJournalAccountType::"Bank Account", paypalBankAccount) then begin

                                description := 'For Batch ' + settlementId + ', Bank entry failed to download';
                                cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Paypal, false, 'Settlement Id')
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
            cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::Paypal);
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
            rec_SettelmentPaymentIds.MarketPlace := 'PayPal';
            rec_SettelmentPaymentIds.Insert(true);
        end

        //Modify the Existing ReportId with true
        else begin
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_SettelmentPaymentIds.SetRange("Report ID", valueToken.AsValue().AsText());
            if rec_SettelmentPaymentIds.FindFirst() then begin
                rec_SettelmentPaymentIds.canArchived := true;
                rec_SettelmentPaymentIds.MarketPlace := 'PayPal';
                rec_SettelmentPaymentIds.Modify(true);
            end
        end;
    end;

    local procedure InsertPaypalSettlement_CashReceiptJournalBatch(settlementId: Code[20])
    var
        recGenJournalBatch: Record "Gen. Journal Batch";
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec: Record "Gen. Journal Template";
    begin

        recGenJournalBatch.Init();
        recGenJournalBatch."Journal Template Name" := 'CASHRCPT';
        recGenJournalBatch.Name := settlementId;
        recGenJournalBatch.Description := 'PP-' + settlementId;
        recGenJournalBatch."Template Type" := enumTemplateType::"Cash Receipts";
        recGenJournalBatch.Insert(true);
    end;

    [TryFunction]
    local procedure InsertPaypalSettlement_CashReceiptGenJournalLine(var resultToken: JsonToken; var settlementId: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; accountNo: Code[20])
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
        rec_GenJournaLine."Document No." := settlementId;
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

    procedure GenerateBodyforSettlementReports(): Text
    var
        element: Integer;
        reportIdList: list of [Text];
        rec_SettelmentPaymentIds: Record SettelmentPaymentIds;
        reportIdBody: Text;
    begin
        rec_SettelmentPaymentIds.Reset();
        rec_SettelmentPaymentIds.SetRange(canArchived, false);
        rec_SettelmentPaymentIds.SetRange(MarketPlace, 'PayPal');
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
        reportIdBody := reportIdBody + '] }';
        exit(reportIdBody);
    end;
}
