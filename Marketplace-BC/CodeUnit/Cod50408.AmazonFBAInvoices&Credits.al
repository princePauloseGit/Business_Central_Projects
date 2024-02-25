codeunit 50408 "Amazon FBA Invoices & Credits"
{
    trigger OnRun()
    var
        cu_AmazonPaymentForCredits: Codeunit AmazonPaymentForCredits;
    begin
        cu_AmazonPaymentForCredits.ConnectAmazonPaymentApi();
        GetOrdersFromAmazonAPI();
    end;

    var
        amazonURI: Text;
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;

    procedure GetOrdersFromAmazonAPI()
    var
        result, nextToken, description, errorMessage, jsonBody : text;
        Past3DaysDate, createdBeforeDate : Date;
        JObject: JsonObject;
        i: Integer;
        varJsonArray, Jarray : JsonArray;
        varjsonToken, JToken, orderTotaltoken : JsonToken;
        amazonOrderId: code[50];
        amount: Decimal;
        recAmazonPaymentCreditData: Record AmazonPaymentCreditData;
        recGenJournaLine: Record "Gen. Journal Line";
        rec_AmazonSetting: Record "Amazon Setting";
        recCustLed: Record "Cust. Ledger Entry";
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        integrationRecordId: Text;
    begin
        InsertAmazonSalesJournalBatch();
        Past3DaysDate := cu_CommonHelper.CalculateDate(3);
        rec_AmazonSetting.Reset();

        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                if rec_AmazonSetting."FBA Invoices and Credits" then begin
                    Clear(RESTAPIHelper);
                    amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetOrders';
                    RESTAPIHelper.Initialize('POST', amazonURI);
                    RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                    RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                    RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());

                    if format(rec_AmazonSetting.FBADate) <> '' then begin
                        createdBeforeDate := CALCDATE('+1D', rec_AmazonSetting.FBADate);

                        jsonBody := '{"testCase": "","createdAfter": "' + DelStr(format(rec_AmazonSetting.FBADate, 0, 9), 11) + '","createdBefore": "' + Format(createdBeforeDate, 0, 9) + '","orderStatuses": [4],"marketplaceIds": ["' + rec_AmazonSetting.MarketplaceID.Trim() + '"],"maxResultsPerPage": 30,"maxNumberOfPages": 1,"isNeedRestrictedDataToken": false,"fulfillmentChannels": [0]}';
                    end
                    else begin
                        jsonBody := '{"testCase": "","createdAfter": "' + DelStr(Format(Past3DaysDate, 0, 9), 11) + '","orderStatuses": [4],"marketplaceIds": ["' + rec_AmazonSetting.MarketplaceID.Trim() + '"],"maxResultsPerPage": 30,"maxNumberOfPages": 1,"isNeedRestrictedDataToken": false,"fulfillmentChannels": [0]}';
                    end;

                    RESTAPIHelper.AddBody(jsonBody);
                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        if not JObject.ReadFrom(result) then
                            Error('Invalid response, expected a JSON object');

                        JObject.Get('orders', varjsonToken);
                        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
                            Error('Array not Reading Properly');

                        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
                            for i := 0 to varJsonArray.Count - 1 do begin
                                varJsonArray.Get(i, varjsonToken);
                                varjsonToken.SelectToken('orderTotal', orderTotaltoken);
                                if varjsonToken.IsObject then
                                    amount := NYTJSONMgt.GetValueAsDecimal(orderTotaltoken, 'amount');
                                CheckCreditOrInvoiceEntry(varjsonToken, rec_AmazonSetting, amount);
                            end;
                        end;

                        if not JObject.ReadFrom(result) then
                            Error('Invalid response, expected a JSON object');
                        JObject.Get('errorLogs', Jtoken);

                        if not Jarray.ReadFrom(Format(Jtoken)) then
                            Error('Array not Reading Properly');

                        if varJsonArray.ReadFrom(Format(Jtoken)) then begin
                            for i := 0 to varJsonArray.Count - 1 do begin
                                varJsonArray.Get(i, varjsonToken);
                                cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Amazon);
                            end
                        end;

                        if not JObject.ReadFrom(result) then
                            Error('Invalid response, expected a JSON object');
                        JObject.Get('nextToken', Jtoken);

                        if (format(Jtoken) <> '') and (format(Jtoken) <> 'null') and (format(Jtoken) <> '""') then begin
                            nextToken := jToken.AsValue().AsText();
                            ConnectAmazonAPIGetOrdersByNextToken(rec_AmazonSetting, nextToken);
                        end;
                    end;
                end
                else begin
                    errorMessage := 'The Download FBA Invoices and Credits is disabled for the customer; please grant access to proceed.';
                    cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    procedure ConnectAmazonAPIGetOrdersByNextToken(rec_AmazonSetting: Record "Amazon Setting"; nextToken: Text)
    var
        result, description, integrationRecordId : Text;
        JObject: JsonObject;
        jsonval: JsonValue;
        varJsonArray, Jarray : JsonArray;
        varjsonToken, orderTotaltoken, Jtoken : JsonToken;
        i: Integer;
        amount: Decimal;
        recAmazonPaymentCreditData: Record AmazonPaymentCreditData;
        recCustLed: Record "Cust. Ledger Entry";
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
    begin
        SLEEP(2500);
        Clear(RESTAPIHelper);
        amazonURI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetOrdersByNextToken';
        RESTAPIHelper.Initialize('POST', amazonURI);
        RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
        RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
        RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
        RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
        RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
        RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
        RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
        RESTAPIHelper.AddRequestHeader('NextToken', nextToken);

        RESTAPIHelper.AddBody('{"isNeedRestrictedDataToken": false}');
        RESTAPIHelper.SetContentType('application/json');

        if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
            result := RESTAPIHelper.GetResponseContentAsText();
            if not JObject.ReadFrom(result) then
                Error('Invalid response, expected a JSON object');

            JObject.Get('orders', varjsonToken);
            if not varJsonArray.ReadFrom(Format(varjsonToken)) then
                Error('Array not Reading Properly');

            if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
                for i := 0 to varJsonArray.Count - 1 do begin
                    varJsonArray.Get(i, varjsonToken);
                    varjsonToken.SelectToken('orderTotal', orderTotaltoken);
                    if varjsonToken.IsObject then
                        amount := NYTJSONMgt.GetValueAsDecimal(orderTotaltoken, 'amount');
                    CheckCreditOrInvoiceEntry(varjsonToken, rec_AmazonSetting, amount);
                end;
            end;

            if not JObject.ReadFrom(result) then
                Error('Invalid response, expected a JSON object');
            JObject.Get('errorLogs', Jtoken);

            if not Jarray.ReadFrom(Format(Jtoken)) then
                Error('Array not Reading Properly');

            if varJsonArray.ReadFrom(Format(Jtoken)) then begin
                for i := 0 to varJsonArray.Count - 1 do begin
                    varJsonArray.Get(i, varjsonToken);
                    cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Amazon);
                end
            end;

            if not JObject.ReadFrom(result) then
                Error('Invalid response, expected a JSON object');

            JObject.Get('nextToken', Jtoken);

            if (format(Jtoken) <> '') and (format(Jtoken) <> 'null') and (format(Jtoken) <> '""') then begin
                nextToken := jToken.AsValue().AsText();
                ConnectAmazonAPIGetOrdersByNextToken(rec_AmazonSetting, nextToken);
            end
            else
                exit;
        end;
    end;

    procedure CheckCreditOrInvoiceEntry(var varjsonToken: JsonToken; var rec_AmazonSetting: Record "Amazon Setting"; amount: decimal)
    var
        recCustLedgerEntry: Record "Cust. Ledger Entry";
        recGenJournaLine: Record "Gen. Journal Line";
        recAmazonPaymentCreditData: Record AmazonPaymentCreditData;
        description: Text;
        amazonOrderId: code[50];
    begin
        Clear(amazonOrderId);
        amazonOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');
        recCustLedgerEntry.SetRange("Customer No.", rec_AmazonSetting.CustomerCode);
        recCustLedgerEntry.SetRange("Journal Templ. Name", 'SALES');
        recCustLedgerEntry.SetRange("Journal Batch Name", 'Amazon');
        recCustLedgerEntry.SetRange("External Document No.", amazonOrderId);
        recCustLedgerEntry.SetFilter("Document Type", '%1', "Gen. Journal Document Type"::Invoice);
        if not recCustLedgerEntry.FindFirst() then begin

            recGenJournaLine.SetRange("Account No.", rec_AmazonSetting.CustomerCode);
            recGenJournaLine.SetRange("Journal Template Name", 'SALES');
            recGenJournaLine.SetRange("Journal Batch Name", 'Amazon');
            recGenJournaLine.SetRange("External Document No.", amazonOrderId);
            recGenJournaLine.SetFilter("Document Type", '%1', "Gen. Journal Document Type"::Invoice);
            if not recGenJournaLine.FindFirst() then begin

                if not InsertSalesJournalLineEntry(varjsonToken, rec_AmazonSetting, "Gen. Journal Document Type"::Invoice, amount) then begin
                    description := 'For Batch AMAZON sales journal entry for invoice failed to download';
                    cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
                end;
            end;
        end;

        recAmazonPaymentCreditData.SetRange("External Document No", amazonOrderId);
        if recAmazonPaymentCreditData.FindSet() then begin
            recCustLedgerEntry.SetRange("Customer No.", rec_AmazonSetting.CustomerCode);
            recCustLedgerEntry.SetRange("Journal Templ. Name", 'SALES');
            recCustLedgerEntry.SetRange("Journal Batch Name", 'Amazon');
            recCustLedgerEntry.SetRange("External Document No.", amazonOrderId);
            recCustLedgerEntry.SetFilter("Document Type", '%1', "Gen. Journal Document Type"::"Credit Memo");
            if not recCustLedgerEntry.FindFirst() then begin

                recGenJournaLine.SetRange("Account No.", rec_AmazonSetting.CustomerCode);
                recGenJournaLine.SetRange("Journal Template Name", 'SALES');
                recGenJournaLine.SetRange("Journal Batch Name", 'Amazon');
                recGenJournaLine.SetRange("External Document No.", amazonOrderId);
                recGenJournaLine.SetFilter("Document Type", '%1', "Gen. Journal Document Type"::"Credit Memo");
                if not recGenJournaLine.FindFirst() then begin

                    amount := -amount;
                    if not InsertSalesJournalLineEntry(varjsonToken, rec_AmazonSetting, "Gen. Journal Document Type"::"Credit Memo", amount) then begin
                        description := 'For Batch AMAZON sales journal entry for credit failed to download';
                        cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
                    end;
                end;
            end;
        end;
    end;

    local procedure InsertAmazonSalesJournalBatch(): Boolean
    var
        recGenJournalBatch: Record "Gen. Journal Batch";
        enumTemplateType: Enum "Gen. Journal Template Type";
        rec: Record "Gen. Journal Template";
    begin
        recGenJournalBatch.SetRange("Journal Template Name", 'SALES');
        recGenJournalBatch.SetRange(Name, 'Amazon');

        if recGenJournalBatch.FindFirst() then begin
            exit(true);
        end
        else begin
            recGenJournalBatch.Init();
            recGenJournalBatch."Journal Template Name" := 'SALES';
            recGenJournalBatch.Name := 'Amazon';
            recGenJournalBatch.Description := 'Amazon Journal Batch';
            recGenJournalBatch."Template Type" := enumTemplateType::Sales;
            recGenJournalBatch."Allow VAT Difference" := true;
            recGenJournalBatch.Insert(true);
            exit(true);
        end;

    end;

    local procedure InsertAmazonDimensionValue(): Boolean
    var
        recDimensionValue: Record "Dimension Value";
    begin
        recDimensionValue.SetRange("Dimension Code", 'DEPARTMENT');
        recDimensionValue.SetRange(Code, 'AMAZON');

        if recDimensionValue.FindFirst() then begin
            exit(true);
        end
        else begin
            recDimensionValue.Init();
            recDimensionValue."Dimension Code" := 'DEPARTMENT';
            recDimensionValue.Code := 'AMAZON';
            recDimensionValue.Name := 'Amazon';
            recDimensionValue.Insert(true);
            exit(true);
        end;
    end;

    [TryFunction]
    local procedure InsertSalesJournalLineEntry(var varjsonToken: JsonToken; var recAmazonSetting: Record "Amazon Setting"; enumJournalDocumentType: Enum "Gen. Journal Document Type"; amount: Decimal)
    var
        responseArray: JsonArray;
        orderItemListToken, itemTaxToken, orderTotaltoken : JsonToken;
        sellerSKU, title, description : text;
        genProdPostingGroup, vatProdPostingGroup, amazonOrderId, DocumnetNo, Noseries : code[35];
        vatAmount: Decimal;

        enumJournalDocumentTypeA: Enum "Gen. Journal Document Type";
        enumJournalAccountType: Enum "Gen. Journal Account Type";
        enumGeneralPostingType: Enum "General Posting Type";

        recItem: Record Item;
        recGenJournaLine: Record "Gen. Journal Line";
        recGenJournaLine1: Record "Gen. Journal Line";
        recPostGenJournaLine: Record "Gen. Journal Line";
        recGeneralPostingSetup: Record "General Posting Setup";
        recCustLedgerEntry: Record "Cust. Ledger Entry";

        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        clear(recGenJournaLine);
        varjsonToken.SelectToken('orderItemList', orderItemListToken);
        if orderItemListToken.IsArray then begin
            responseArray := orderItemListToken.AsArray();
            responseArray.Get(0, orderItemListToken);
            sellerSKU := NYTJSONMgt.GetValueAsText(orderItemListToken, 'sellerSKU');
            title := NYTJSONMgt.GetValueAsText(orderItemListToken, 'title');
            description := sellerSKU + '-' + title;
            Clear(genProdPostingGroup);
            Clear(vatProdPostingGroup);
            recItem.SetRange(FBA_SKU, sellerSKU);
            if recItem.FindFirst() then begin
                genProdPostingGroup := recItem."Gen. Prod. Posting Group";
                vatProdPostingGroup := recItem."VAT Prod. Posting Group";
            end;
            orderItemListToken.SelectToken('itemTax', itemTaxToken);
            if itemTaxToken.IsObject then begin
                vatAmount := NYTJSONMgt.GetValueAsDecimal(itemTaxToken, 'amount') * -1;
            end;
        end;

        amazonOrderId := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');

        recGenJournaLine.Init();
        recGenJournaLine."Journal Template Name" := 'SALES';
        recGenJournaLine."Journal Batch Name" := 'Amazon';
        recGenJournaLine."Line No." := GetNewLineNo('SALES', 'Amazon');
        recGenJournaLine."Posting Date" := DT2Date(NYTJSONMgt.EvaluateUTCDateTime(NYTJSONMgt.GetValueAsText(varjsonToken, 'purchaseDate')));

        recGenJournaLine.SetRange("Journal Template Name", 'SALES');
        recGenJournaLine.SetRange("Journal Batch Name", 'Amazon');
        //Get No Series from No Series Table
        Noseries := getNoSeriesCode();
        recGenJournaLine."Document No." := NoSeriesMgt.GetNextNo(Noseries, WorkDate(), true);
        recGenJournaLine."Document Type" := "Gen. Journal Document Type"::Invoice;
        recGenJournaLine.Validate("Document Type");
        DocumnetNo := recGenJournaLine."Document No.";
        recGenJournaLine."Account Type" := enumJournalAccountType::Customer;
        recGenJournaLine."Account No." := recAmazonSetting.CustomerCode;
        recGenJournaLine.Validate("Account No.");
        recGenJournaLine."External Document No." := NYTJSONMgt.GetValueAsText(varjsonToken, 'amazonOrderId');
        recGenJournaLine.Description := Text.CopyStr(description, 1, 100);

        varjsonToken.SelectToken('orderTotal', orderTotaltoken);
        if varjsonToken.IsObject then begin
            recGenJournaLine.Amount := NYTJSONMgt.GetValueAsDecimal(orderTotaltoken, 'amount');
            recGenJournaLine.Validate(Amount);
        end;

        recGenJournaLine."Bal. Account Type" := enumJournalAccountType::"G/L Account";

        if (recAmazonSetting.PostingGroupFBA <> '') and (genProdPostingGroup <> '') then begin
            recGeneralPostingSetup.SetRange("Gen. Bus. Posting Group", '24');
            recGeneralPostingSetup.SetRange("Gen. Prod. Posting Group", genProdPostingGroup);
            if recGeneralPostingSetup.FindFirst() then begin
                recGenJournaLine."Bal. Account No." := recGeneralPostingSetup."Sales Account";
                recGenJournaLine.Validate("Bal. Account No.");
            end;
        end
        else begin
            recGenJournaLine."Bal. Account No." := '40024'; //change as per trello board suggestion
            recGenJournaLine.Validate("Bal. Account No.");
        end;

        recGenJournaLine."Bal. Gen. Bus. Posting Group" := recAmazonSetting.PostingGroupFBA;
        recGenJournaLine.Validate("Bal. Gen. Bus. Posting Group");
        recGenJournaLine."Bal. VAT Bus. Posting Group" := 'DOMESTIC';
        recGenJournaLine.Validate("Bal. VAT Bus. Posting Group");

        if vatProdPostingGroup <> '' then begin
            recGenJournaLine."Bal. VAT Prod. Posting Group" := vatProdPostingGroup;
            recGenJournaLine.Validate("Bal. VAT Prod. Posting Group");
        end
        else begin
            recGenJournaLine."Bal. VAT Prod. Posting Group" := 'STANDARD_20%';
            recGenJournaLine.Validate("Bal. VAT Prod. Posting Group");
        end;

        recGenJournaLine."Bal. VAT %" := 1;
        recGenJournaLine."Bal. VAT Amount" := vatAmount;
        recGenJournaLine.Validate("Bal. VAT Amount");
        recGenJournaLine."Bal. Gen. Posting Type" := enumGeneralPostingType::Sale;
        recGenJournaLine.Validate("Bal. Gen. Posting Type");
        recGenJournaLine."Shortcut Dimension 1 Code" := 'AMAZON';

        if genProdPostingGroup <> '' then begin
            recGenJournaLine."Bal. Gen. Prod. Posting Group" := genProdPostingGroup;
            recGenJournaLine.Validate("Bal. Gen. Prod. Posting Group");
        end
        else begin
            recGenJournaLine."Bal. Gen. Prod. Posting Group" := '';
        end;

        recGenJournaLine.Insert(true);

        if enumJournalDocumentType = enumJournalDocumentTypeA::"Credit Memo" then begin
            recGenJournaLine."Document Type" := enumJournalDocumentTypeA::"Credit Memo";
            recGenJournaLine.Validate("Document Type");
            recGenJournaLine.Validate(recGenJournaLine.Amount, -1 * recGenJournaLine.Amount);
            recGenJournaLine.Modify(true);
        end;

        recPostGenJournaLine.SetRange("External Document No.", amazonOrderId);
        recPostGenJournaLine.SetRange("Journal Template Name", 'SALES');
        recPostGenJournaLine.SetRange("Journal Batch Name", 'Amazon');
        recPostGenJournaLine.SetRange("Document No.", DocumnetNo);
        if recPostGenJournaLine.FindFirst() then begin

            if not AmazonBatchProcessGenJournalLine(recPostGenJournaLine, 50403) then begin
                description := 'For Batch AMAZON sales journal entry failed to post';
                cu_CommonHelper.InsertBusinessCentralErrorLog(description, amazonOrderId, EnhIntegrationLogTypes::Amazon, false, 'Order Id');
            end;
        end;
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

    [TryFunction]
    local procedure AmazonBatchProcessGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingCodeunitId: Integer)
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        custom_ErrorMessageHandler: Codeunit "Custom_Error Message Handler";
        BatchProcessingMgtHandler: Codeunit "Batch Processing Mgt. Handler";
        ICOutboxExport: Codeunit "IC Outbox Export";
        PostingResult: Boolean;
        DeveloperError, description : Text;
    begin
        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        BindSubscription(BatchProcessingMgtHandler);
        PostingResult := Codeunit.Run(PostingCodeunitId, GenJournalLine);
        if PostingResult then begin
            ICOutboxExport.DownloadBatchFiles(GetICBatchFileName());
        end;

        UnbindSubscription(BatchProcessingMgtHandler);

        if not PostingResult then begin
            description := 'For Batch AMAZON sales journal entry failed to post';
            cu_CommonHelper.InsertBusinessCentralErrorLog(description, GenJournalLine."External Document No.", EnhIntegrationLogTypes::Amazon, false, 'Order Id');
        end;
    end;

    local procedure GetICBatchFileName() Result: Text
    var
        InterCompanyZipFileNamePatternTok: Label 'General Journal IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
    end;

    local procedure LogFailurePostTelemetry(var GenJournalLine: Record "Gen. Journal Line"; var DeveloperError: Text)
    var
        ErrorMessage: Record "Error Message";
        Dimensions: Dictionary of [Text, Text];
        ErrorMessageTxt: Text;
        TelemetryCategoryTxt: Label 'GenJournal', Locked = true;
        GenJournalPostFailedTxt: Label 'General journal posting failed. Journal Template: %1, Journal Batch: %2', Locked = true;
    begin
        ErrorMessage.SetRange("Context Table Number", 0);
        if ErrorMessage.FindLast() then begin
            ErrorMessageTxt := ErrorMessage.Message;
            InsertEnhancedIntegrationLog(ErrorMessage, GenJournalLine, DeveloperError);
        end;
        Dimensions.Add('Category', TelemetryCategoryTxt);
        Dimensions.Add('Error', ErrorMessageTxt);
        Session.LogMessage('0000F9J', StrSubstNo(GenJournalPostFailedTxt, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure InsertEnhancedIntegrationLog(var ErrorMessage: Record "Error Message"; var GenJournalLine: Record "Gen. Journal Line"; var DeveloperError: Text)
    var
        rec_EnhanceIntegrationLog: Record EnhancedIntegrationLog;
        enum_OrderSource: Enum "Order Source";
        optionSource: Option Amazon,eBay,OnBuy,Website,Office;
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        rec_EnhanceIntegrationLog.Init();
        rec_EnhanceIntegrationLog.id := CreateGuid();
        rec_EnhanceIntegrationLog.source := EnhIntegrationLogTypes::Amazon;
        rec_EnhanceIntegrationLog.Severity := EnhIntegrationLogSeverity::Error;
        rec_EnhanceIntegrationLog.RecordType := Format(GenJournalLine."Document Type");
        rec_EnhanceIntegrationLog.RecordID := GenJournalLine."External Document No.";
        rec_EnhanceIntegrationLog.Message := ErrorMessage.Message;
        rec_EnhanceIntegrationLog.ExtendedText := DeveloperError;
        rec_EnhanceIntegrationLog.DateTimeOccurred := System.CurrentDateTime;
        rec_EnhanceIntegrationLog.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;

    procedure getNoSeriesCode(): Code[20];
    var
        recNoSeries: Record "No. Series";
        NoSeries: code[20];
    begin
        recNoSeries.SetRange(Description, 'General Journal');
        if recNoSeries.FindFirst() then begin
            NoSeries := recNoSeries.Code;
        end;
        exit(NoSeries);
    end;
}
