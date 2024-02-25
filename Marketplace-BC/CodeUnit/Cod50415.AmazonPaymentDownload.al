codeunit 50415 AmazonPaymentDownload
{
    trigger OnRun()
    begin
        CreateCashReceiptBatchEntry();
    end;

    var
        rec_AmazonSetting: Record "Amazon Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        result, URI : text;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure CreateCashReceiptBatchEntry()
    var
        sendBody, errorMessage : Text;
    begin
        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                if rec_AmazonSetting.Payments then begin
                    Clear(RESTAPIHelper);
                    //Header
                    URI := RESTAPIHelper.GetBaseURl() + 'Amazon/DownloadPayment';
                    RESTAPIHelper.Initialize('POST', URI);
                    RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                    RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                    RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());

                    //Body 
                    sendBody := GenerateBodyforSettlementReports();
                    RESTAPIHelper.AddBody(sendBody);

                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        ReadSettelmentApiResponse(result, rec_AmazonSetting.CustomerCode, rec_AmazonSetting.VendorCode, rec_AmazonSetting.BankGLCode);
                    end;
                end
                else begin
                    errorMessage := 'The Download Payments is disabled for the customer; please grant access to proceed.';
                    cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    local procedure ReadSettelmentApiResponse(var response: Text; var CustomerCode: Code[30]; var VendorCode: Code[30]; var BankGLCode: Code[30])
    var
        Jtoken, documentNoToken, VendorGLToken, SalesReceiptToken : JsonToken;
        JObject: JsonObject;
        jsonval: JsonValue;
        Jarray: JsonArray;
        i, j : Integer;
        postingDate: Date;
        rec_AmazonReportId: Record SettelmentPaymentIds;
        description: Text;
        settlementId: Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        recGenJournalBatch: Record "Gen. Journal Batch";
    begin

        if not JObject.ReadFrom(response) then
            Error('Invalid response, expected a JSON object');
        JObject.Get('settlements', Jtoken);
        if not Jarray.ReadFrom(Format(Jtoken)) then
            Error('Array not Reading Properly');

        for i := 0 to Jarray.Count() - 1 do begin
            Jarray.Get(i, Jtoken);
            Jtoken.AsObject.Get('settlementId', documentNoToken);
            if not documentNoToken.AsValue().IsNull then begin
                settlementId := documentNoToken.AsValue().AsCode();

                // Creating batch according to settlement ID
                recGenJournalBatch.SetRange("Journal Template Name", 'CASHRCPT');
                recGenJournalBatch.SetRange(Name, settlementId);

                if not recGenJournalBatch.FindFirst() then begin

                    InsertAmazonSettlement_CashReceiptJournalBatch(settlementId);

                    JObject := Jtoken.AsObject();

                    //Sales Receipt Line Entry as per orderId
                    JObject.Get('salesReceiptLines', Jtoken);
                    for j := 0 to Jtoken.AsArray().Count() - 1 do begin
                        if Jtoken.AsArray().Get(j, SalesReceiptToken) then begin
                            SalesReceiptToken.AsObject.Get('documentNumber', documentNoToken);
                            if Not documentNoToken.AsValue().IsNull then begin
                                if not InsertAmazonSettlement_CashReceiptGenJournalLine(SalesReceiptToken, settlementId, enumGenJournalAccountType::Customer, rec_AmazonSetting.CustomerCode) then begin
                                    description := 'For Batch ' + settlementId + ', salesReceiptLines entry failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Amazon, false, 'Settlement Id');
                                end;
                            end;
                        end;
                    end;

                    //4 GL InvoiceLineEntry
                    JObject.Get('vendorGLInvoiceEntries', Jtoken);
                    for j := 0 to Jtoken.AsArray().Count() - 1 do begin
                        if Jtoken.AsArray().Get(j, VendorGLToken) then begin
                            VendorGLToken.AsObject.Get('documentNumber', documentNoToken);
                            if Not documentNoToken.AsValue().IsNull then begin
                                if not InsertVendorGLInvoice_CashRecepitGenJournalLine(VendorGLToken, settlementId, rec_AmazonSetting.VendorCode) then begin
                                    description := 'For Batch ' + settlementId + ', vendorGLInvoice entry failed to download';
                                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Amazon, false, 'Settlement Id');
                                end;
                            end;
                        end;
                    end;

                    //Single Vendor Payment Entry
                    JObject.Get('vendorPaymentEntry', Jtoken);
                    Jtoken.AsObject.Get('documentNumber', documentNoToken);
                    if Not documentNoToken.AsValue().IsNull then begin
                        if not InsertVendorPayment_CashRecepitGenJournalLine(JToken, settlementId, enumGenJournalAccountType::Vendor, rec_AmazonSetting.VendorCode) then begin
                            description := 'For Batch ' + settlementId + ', vendorPayment entry failed to download';
                            cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Amazon, false, 'Settlement Id');
                        end;
                    end;

                    //Single Bank Entry
                    JObject.Get('bankEntry', Jtoken);
                    Jtoken.AsObject.Get('documentNumber', documentNoToken);
                    if Not documentNoToken.AsValue().IsNull then begin
                        if not InsertVendorPayment_CashRecepitGenJournalLine(JToken, settlementId, enumGenJournalAccountType::"Bank Account", rec_AmazonSetting.BankGLCode) then begin
                            description := 'For Batch ' + settlementId + ', bankEntry entry failed to download';
                            cu_CommonHelper.InsertBusinessCentralErrorLog(description, settlementId, EnhIntegrationLogTypes::Amazon, false, 'Settlement Id');
                        end;
                    end;

                    //reportDocumentDetails Entry
                    if not JObject.ReadFrom(response) then
                        Error('Invalid response, expected a JSON object');
                    JObject.Get('reportDocumentDetails', Jtoken);
                    if not Jarray.ReadFrom(Format(Jtoken)) then
                        Error('Array not Reading Properly');

                    for i := 0 to Jarray.Count() - 1 do begin
                        Jarray.Get(i, Jtoken);
                        JObject := Jtoken.AsObject();
                        InsertProcessedReportIds(Jtoken);
                    end;

                    if not JObject.ReadFrom(response) then
                        Error('Invalid response, expected a JSON object');
                    JObject.Get('errorLogs', Jtoken);

                    if not Jarray.ReadFrom(Format(Jtoken)) then
                        Error('Array not Reading Properly');

                    for i := 0 to Jarray.Count() - 1 do begin
                        Jarray.Get(i, Jtoken);
                        JObject := Jtoken.AsObject();
                        cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::Amazon);
                    end;
                end;
            end;
        end;
    end;

    local procedure InsertAmazonSettlement_CashReceiptJournalBatch(settlementId: Code[20])
    var
        recGenJournalBatch: Record "Gen. Journal Batch";
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec: Record "Gen. Journal Template";
        GenJnlTemplate: Record "Gen. Journal Template";

    begin
        recGenJournalBatch.Init();
        recGenJournalBatch."Journal Template Name" := 'CASHRCPT';
        recGenJournalBatch.Name := settlementId;
        recGenJournalBatch.Description := 'AM-' + settlementId;
        recGenJournalBatch."Template Type" := enumTemplateType::"Cash Receipts";
        recGenJournalBatch.Insert(true);
    end;

    [TryFunction]
    local procedure InsertAmazonSettlement_CashReceiptGenJournalLine(var resultToken: JsonToken; var documentNo: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; var accountNo: Code[30])
    var
        rec_GenJournaLine: Record "Gen. Journal Line";
        valueToken: JsonToken;
    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', documentNo);
        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := documentNo;
        resultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));
        resultToken.AsObject().Get('documentDate', valueToken);
        rec_GenJournaLine."Document Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));

        rec_GenJournaLine."Document No." := documentNo;
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType;
        rec_GenJournaLine."Account No." := accountNo;
        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('externalDocumentNumber', valueToken);
        rec_GenJournaLine."External Document No." := valueToken.AsValue().AsText();

        resultToken.AsObject.Get('description', valueToken);
        rec_GenJournaLine.Description := valueToken.AsValue().AsText();

        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate(Amount);

        rec_GenJournaLine.Insert(true);
    end;

    [TryFunction]
    local procedure InsertVendorPayment_CashRecepitGenJournalLine(var resultToken: JsonToken; var documentNo: code[20]; enumGenJournalAccountType: Enum "Gen. Journal Account Type"; var accountNo: Code[30])
    var
        rec_GenJournaLine: Record "Gen. Journal Line";
        valueToken: JsonToken;
    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', documentNo);
        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := documentNo;
        resultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));

        rec_GenJournaLine."Document No." := documentNo;
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType;
        rec_GenJournaLine."Account No." := accountNo;
        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate(Amount);

        rec_GenJournaLine.Insert(true);
    end;

    [TryFunction]
    local procedure InsertVendorGLInvoice_CashRecepitGenJournalLine(var resultToken: JsonToken; var documentNo: code[20]; var accountNo: Code[30])
    var
        rec_GenJournaLine: Record "Gen. Journal Line";
        valueToken: JsonToken;
        BalGenPostingType: enum "General Posting Type";
        balAccNo: Code[20];
        enumGenJournalAccountType: Enum "Gen. Journal Account Type";
        AccountType: Text;
    begin
        rec_GenJournaLine.Init();
        rec_GenJournaLine."Line No." := GetNewLineNo('CASHRCPT', documentNo);
        rec_GenJournaLine."Journal Template Name" := 'CASHRCPT';
        rec_GenJournaLine."Journal Batch Name" := documentNo;
        resultToken.AsObject.Get('postingDate', valueToken);
        rec_GenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(valueToken.AsValue().AsText()));

        resultToken.AsObject.Get('documentNumber', valueToken);
        rec_GenJournaLine."Document No." := valueToken.AsValue().AsCode();
        resultToken.AsObject.Get('accountType', valueToken);
        AccountType := valueToken.AsValue().AsText();
        rec_GenJournaLine."Account Type" := enumGenJournalAccountType::Vendor;
        rec_GenJournaLine."Account No." := accountNo;
        rec_GenJournaLine.Validate("Account No.");
        resultToken.AsObject.Get('amount', valueToken);
        rec_GenJournaLine.Amount := valueToken.AsValue().AsDecimal();
        rec_GenJournaLine.Validate(Amount);

        rec_GenJournaLine."Bal. Account Type" := "Gen. Journal Account Type"::"G/L Account";
        resultToken.AsObject.Get('balancingAccountNumber', valueToken);
        balAccNo := valueToken.AsValue().AsCode();

        rec_GenJournaLine."Bal. Account No." := balAccNo;
        rec_GenJournaLine.Validate("Bal. Account No.");

        if (balAccNo = '40025') or (balAccNo = '51000') then begin
            rec_GenJournaLine."Bal. Gen. Posting Type" := BalGenPostingType::Purchase;
            rec_GenJournaLine.Validate("Bal. Gen. Posting Type");
            rec_GenJournaLine."Bal. VAT Bus. Posting Group" := 'DOMESTIC';
            rec_GenJournaLine.Validate("Bal. VAT Bus. Posting Group");
            rec_GenJournaLine."Bal. VAT Prod. Posting Group" := 'STANDARD_20%';
            rec_GenJournaLine.Validate("Bal. VAT Prod. Posting Group");
        end;

        if (balAccNo = '79071') or (balAccNo = '79075') then begin
            rec_GenJournaLine."Bal. Gen. Posting Type" := BalGenPostingType::Purchase;
            rec_GenJournaLine.Validate("Bal. Gen. Posting Type");
            rec_GenJournaLine."Bal. VAT Bus. Posting Group" := 'DOMESTIC';
            rec_GenJournaLine.Validate("Bal. VAT Bus. Posting Group");
            rec_GenJournaLine."Bal. VAT Prod. Posting Group" := 'RC_20%';
            rec_GenJournaLine.Validate("Bal. VAT Prod. Posting Group");
        end;

        rec_GenJournaLine.Insert(true);
    end;

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

    local procedure InsertProcessedReportIds(resultToken: JsonToken)
    var
        rec_AmazonReportId: Record SettelmentPaymentIds;
        valueToken: JsonToken;
    begin
        resultToken.AsObject.Get('canArchived', valueToken);
        if not valueToken.AsValue().AsBoolean() then begin
            rec_AmazonReportId.Init();
            rec_AmazonReportId.canArchived := valueToken.AsValue().AsBoolean();
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_AmazonReportId."Report ID" := valueToken.AsValue().AsText();
            rec_AmazonReportId.MarketPlace := 'Amazon';
            rec_AmazonReportId.Insert(true);
        end
        //Modify the EXisting ReportId with true
        else begin
            resultToken.AsObject.Get('reportDocumentId', valueToken);
            rec_AmazonReportId.SetRange("Report ID", valueToken.AsValue().AsText());
            if rec_AmazonReportId.FindFirst() then begin
                rec_AmazonReportId.canArchived := true;
                rec_AmazonReportId.MarketPlace := 'Amazon';
                rec_AmazonReportId.Modify(true);
            end
        end;
    end;

    local procedure GenerateBodyforSettlementReports(): Text
    var
        element: Integer;
        reportIdList: list of [Text];
        rec_amazonReportId: Record SettelmentPaymentIds;
        reportIdBody: Text;
    begin
        rec_amazonReportId.Reset();
        rec_amazonReportId.SetRange(canArchived, false);
        rec_amazonReportId.SetRange(MarketPlace, 'Amazon');
        if rec_amazonReportId.FindSet() then begin
            repeat
                reportIdList.Add(rec_amazonReportId."Report ID");
            until rec_amazonReportId.Next() = 0;
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
