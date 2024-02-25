codeunit 50412 "AppeagleCSVGeneration"
{
    trigger OnRun()
    begin
        GetAllItems();
    end;

    var
        rec_Item: Record Item;
        rec_AmazonSetting: Record "Amazon Setting";
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        CSVText: Text;
        Char1310: Char;
        OutS: OutStream;
        InS: InStream;
        Rec_TempBlob: Codeunit "Temp Blob";
        cdu_Base64: Codeunit "Base64 Convert";
        cu_CommonHelper: Codeunit CommonHelper;

    local procedure GetAllFBAAppeagleItems(): Dictionary of [Integer, Dictionary of [Integer, Text]]
    var
        element, totalRecords, outerIndex, innerIndex, batchOf, recordPerBatch : Integer;
        asinBody: Text;
        itemBatch: Dictionary of [Integer, Text];
        itemBatchBatch: Dictionary of [Integer, Dictionary of [Integer, Text]];
        rec_AppeagleSetting: Record "Appeagle Setting";
        calculatedBatch: Decimal;
    begin
        rec_Item.Reset();
        rec_AppeagleSetting.Reset();
        rec_Item.SetRange(SHOW_ON_AMAZON, true);
        rec_Item.SetRange(FBA_APPEAGLE, true);
        rec_Item.SetFilter(FBA_SKU, '<>%1', '');

        batchOf := 0;
        innerIndex := 0;
        outerIndex := 0;
        recordPerBatch := 0;
        Clear(itemBatchBatch);
        Clear(itemBatch);

        if rec_AppeagleSetting.FindFirst() then begin
            if rec_AppeagleSetting.RecordsPerRun > rec_Item.Count then begin
                recordPerBatch := rec_Item.Count;
            end
            else begin
                recordPerBatch := rec_AppeagleSetting.RecordsPerRun;
            end;

            if recordPerBatch < 1 then begin
                recordPerBatch := 100;
            end;
        end;

        if rec_Item.FindSet() then begin
            repeat
                if rec_Item.FBA_SKU <> '' then begin

                    rec_Item.CalcFields(AMAZON_API_LENGTH);
                    rec_Item.CalcFields(AMAZON_API_WIDTH);
                    rec_Item.CalcFields(AMAZON_API_HEIGHT);
                    rec_Item.CalcFields(AMAZON_API_WEIGHT);
                    rec_Item.CalcFields(ASIN);

                    if (rec_Item.AMAZON_API_HEIGHT = 0) OR
                        (rec_Item.AMAZON_API_LENGTH = 0) OR
                        (rec_Item.AMAZON_API_WIDTH = 0) OR
                        (rec_Item.AMAZON_API_WEIGHT = 0) OR
                        (rec_Item.ASIN = '') OR
                        (rec_Item."Last Date Modified" > (Today - 7))
                        then begin

                        batchOf := batchOf + 1;

                        // Create batch of x items
                        if batchOf <= recordPerBatch then begin
                            innerIndex := innerIndex + 1;
                            itemBatch.Add(innerIndex, rec_Item.FBA_SKU);
                        end
                        else begin // Add x items batch to another list
                            batchOf := 0;
                            innerIndex := 0;
                            outerIndex := outerIndex + 1;
                            itemBatchBatch.Add(outerIndex, itemBatch);
                            Clear(itemBatch);
                        end;
                    end;
                end;
            until rec_Item.Next() = 0;

            if itemBatch.Count >= 1 then begin
                outerIndex := outerIndex + 1;
                itemBatchBatch.Add(outerIndex, itemBatch);
            end;
        end;

        exit(itemBatchBatch);
    end;

    procedure GetCatalogItemBody(itemBatch: Dictionary of [Integer, Text]): Text
    var
        element: Integer;
        fbaSkuBody: Text;
    begin
        fbaSkuBody := '{"SKUs": [';
        for element := 1 to itemBatch.Count do begin
            if element <> itemBatch.Count then
                fbaSkuBody := fbaSkuBody + '"' + itemBatch.Get(element) + '",'
            else
                fbaSkuBody := fbaSkuBody + '"' + itemBatch.Get(element) + '"'
        end;
        fbaSkuBody := fbaSkuBody + '] }';

        exit(fbaSkuBody);
    end;

    procedure APIGetCatalogItems()
    var
        result, URI, sendBody, filename : Text;
        itemBatches: Dictionary of [Integer, Dictionary of [Integer, Text]];
        indexMain: Integer;
        itemBatch: Dictionary of [Integer, Text];
        Rec_TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        rec_AmazonSetting.Reset();
        indexMain := 1;
        sendBody := '';

        rec_AmazonSetting.SetRange(Orders, true);

        if rec_AmazonSetting.FindFirst() then begin

            itemBatches := GetAllFBAAppeagleItems();

            // Pass batch of x, one by one to api
            for indexMain := 1 to itemBatches.Count do begin
                itemBatch := itemBatches.Get(indexMain);

                //Body
                sendBody := GetCatalogItemBody(itemBatch);

                //Header
                Clear(RESTAPIHelper);
                URI := RESTAPIHelper.GetBaseURl() + 'Amazon/GetCatalogItems';
                RESTAPIHelper.Initialize('POST', URI);
                RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
                RESTAPIHelper.AddRequestHeader('MerchantId', rec_AmazonSetting.MerchantID.Trim());

                RESTAPIHelper.AddBody(sendBody);

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Appeagle) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ProcessFBAItemsDimensions(result);
                end;

                Sleep(2000);
            end;
        end;
    end;

    local procedure ProcessFBAItemsDimensions(var result: Text)
    var
        i, responsecnt : Integer;
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        JObject: JsonObject;
    begin
        if not JObject.ReadFrom(result) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('catalogItems', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for responsecnt := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(responsecnt, varjsonToken);
                NYTJSONMgt.GetValueAsText(varjsonToken, 'errorMessage');
                NYTJSONMgt.GetValueAsText(varjsonToken, 'asin');

                updateFBAItemDimension(varjsonToken);
            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Appeagle);
        end;
    end;

    local procedure updateFBAItemDimension(resultJsonToken: JsonToken)
    var
        asin: Code[20];
        height, weightInKg, width, length : Decimal;
        dimensionToken: JsonToken;
        JObject2: JsonObject;
        fbaSKU: Text;
        recItemDimensions: Record ItemDimensions;
    begin
        asin := NYTJSONMgt.GetValueAsText(resultJsonToken, 'asin');
        fbaSKU := NYTJSONMgt.GetValueAsText(resultJsonToken, 'sku');

        resultJsonToken.SelectToken('height', dimensionToken);

        if resultJsonToken.IsObject then begin
            JObject2 := resultJsonToken.AsObject();
            height := NYTJSONMgt.GetValueAsDecimal(dimensionToken, 'value');
        end;

        resultJsonToken.SelectToken('length', dimensionToken);

        if resultJsonToken.IsObject then begin
            JObject2 := resultJsonToken.AsObject();
            length := NYTJSONMgt.GetValueAsDecimal(dimensionToken, 'value');
        end;

        resultJsonToken.SelectToken('weightInKg', dimensionToken);

        if resultJsonToken.IsObject then begin
            JObject2 := resultJsonToken.AsObject();
            weightInKg := NYTJSONMgt.GetValueAsDecimal(dimensionToken, 'value');
        end;

        resultJsonToken.SelectToken('width', dimensionToken);

        if resultJsonToken.IsObject then begin
            JObject2 := resultJsonToken.AsObject();
            width := NYTJSONMgt.GetValueAsDecimal(dimensionToken, 'value');
        end;

        //Updating dimensions from amazonAPI
        recItemDimensions.Reset();
        recItemDimensions.SetRange(FBA_SKU, fbaSKU);

        if recItemDimensions.FindFirst() then begin
            recItemDimensions.API_Height := height;
            recItemDimensions.API_Length := length;
            recItemDimensions.API_Width := width;
            recItemDimensions.ASIN := asin;
            recItemDimensions.API_Weight := weightInKg * 1000;

            recItemDimensions.Modify(true);
        end;
    end;

    procedure CalculateMinMaxpriceforMFNItems(recItem: Record Item)
    var
        MFNCostPrice, MFNItemMinPrice, MFNItemMaxPrice, IntermediateMaxPrice : Decimal;
    begin
        MFNCostPrice := CalculateCostPriceforMFNItem(recItem);
        MFNItemMinPrice := CalculateWeightAndMarkup(recItem, MFNCostPrice);
        IntermediateMaxPrice := calculateIntermediatemaxprice(recItem);
        if IntermediateMaxPrice > MFNItemMinPrice then
            MFNItemMaxPrice := IntermediateMaxPrice
        else
            MFNItemMaxPrice := (MFNItemMinPrice * 1.3);

        CreateCSV(recItem."No.", MFNItemMinPrice, MFNItemMaxPrice, '')
    end;

    local procedure CalculateMinMaxpriceforFBAItems(recItem: Record Item)
    var
        FBACostPrice, FBAItemMinPrice, FBAItemMaxPrice, bestboxweight : Decimal;
        rec_FBACalculationSettings: Record FBACalculationSettings;
        costperKg, markup : Decimal;
    begin
        Clear(FBACostPrice);
        Clear(FBAItemMaxPrice);
        Clear(FBAItemMinPrice);
        FBACostPrice := CalculateCostPriceForFBAItem(recItem);
        recItem.CalcFields(AMAZON_API_WEIGHT);
        //Min Price
        if recItem.FBA_MIN_PRICE_OVERRIDE <> 0 then
            FBAItemMinPrice := recItem.FBA_MIN_PRICE_OVERRIDE
        else begin
            bestboxweight := RetreiveBestSmallestPackingTypeFee(recItem);
            rec_FBACalculationSettings.Reset();
            if rec_FBACalculationSettings.FindFirst() then begin
                markup := rec_FBACalculationSettings.MarkupFactor;
                costperKg := (rec_FBACalculationSettings.CostPerKgUK) / 1000;
            end;
            FBAItemMinPrice := 1.47 * ((FBACostPrice * markup) + (recItem.AMAZON_API_WEIGHT * (costperKg) + bestboxweight));
        end;

        //Max Price
        if recItem.FBA_MAX_PRICE_OVERRIDE <> 0 then
            FBAItemMaxPrice := recItem.FBA_MAX_PRICE_OVERRIDE
        else begin
            FBAItemMaxPrice := FBAItemMinPrice * 1.3;
        end;

        if recItem.RRP > FBAItemMaxPrice then
            FBAItemMaxPrice := recItem.RRp;

        CreateCSV(recItem.FBA_SKU, FBAItemMinPrice, FBAItemMaxPrice, 'Amazon FBA')
    end;

    local procedure CalculateCostPriceforMFNItem(recItem: Record Item): Decimal
    var
        itemCost: Decimal;
        enumReplenishmentSystem: Enum "Replenishment System";
        MFNMinPrice, MFNMaxPrice : Decimal;
        IntermediateMaxPrice: Decimal;
        weightBasedCarrierRate, markuprate : Decimal; //calculation
    begin
        recItem.CalcFields(Inventory);
        if recItem.Inventory <> 0 then
            itemCost := recItem."Unit Cost"
        else
            itemCost := recItem."Last Direct Cost";

        if recItem."Replenishment System" = enumReplenishmentSystem::Assembly then begin
            itemCost := getQtyCanBeAssembled(recItem."No.");
        end;
        exit(itemCost)
    end;

    procedure getQtyCanBeAssembled(ItemNo: Code[20]): Decimal
    var
        bom: record "BOM Component";
        recitem2: record Item;
        itemCost, canbuild : Decimal;
    begin
        bom.Reset();
        bom.SetFilter("Parent Item No.", ItemNo);
        if bom.FindSet() then
            repeat
                if recitem2.Get(bom."No.") then begin
                    if recitem2.Inventory <> 0 then
                        itemCost := recitem2."Unit Cost"
                    else
                        itemCost := recitem2."Last Direct Cost";

                    canbuild := canbuild + (itemCost * bom."Quantity per");
                end;
            until bom.Next() = 0;
        exit(canbuild);
    end;

    local procedure CalculateWeightAndMarkup(recItem: Record Item; costprice: Decimal): Decimal
    var
        WeightRate, MarkupRate, MFNMinPrice, UnitPriceWithVat : Decimal;
        rec_AppeagleRate: Record AppeagleRates;
        cu_ItemVatCalculation: Codeunit ItemVatCalculation;
    begin
        UnitPriceWithVat := cu_ItemVatCalculation.CalculateVat(recItem);
        if recItem.RESTRICTED_18 then begin
            rec_AppeagleRate.SetRange(Code, 'UPS18');
            if rec_AppeagleRate.FindFirst() then begin
                WeightRate := rec_AppeagleRate.Rate;
                MarkupRate := rec_AppeagleRate.MarkupRate;
            end
        end;
        if (recItem."Gross Weight" = 0) and (UnitPriceWithVat > 50) then begin
            rec_AppeagleRate.SetRange(Code, 'Carrier Box');
            if rec_AppeagleRate.FindFirst() then begin
                WeightRate := rec_AppeagleRate.Rate;
                MarkupRate := rec_AppeagleRate.MarkupRate;
            end
        end;
        if (recItem."Gross Weight" = 0) and (UnitPriceWithVat < 50) then begin
            rec_AppeagleRate.SetRange(Code, 'RM Prime');
            if rec_AppeagleRate.FindFirst() then begin
                WeightRate := rec_AppeagleRate.Rate;
                MarkupRate := rec_AppeagleRate.MarkupRate;
            end
        end;
        if (recItem."Gross Weight" < 1.5) and (recItem."Gross Weight" <> 0) then begin
            rec_AppeagleRate.SetRange(Code, 'RM Prime');
            if rec_AppeagleRate.FindFirst() then begin
                WeightRate := rec_AppeagleRate.Rate;
                MarkupRate := rec_AppeagleRate.MarkupRate;
            end
        end;
        if (recItem."Gross Weight" > 1.5) and (recItem."Gross Weight" <> 0) then begin
            rec_AppeagleRate.SetRange(Code, 'Carrier Box');
            if rec_AppeagleRate.FindFirst() then begin
                WeightRate := rec_AppeagleRate.Rate;
                MarkupRate := rec_AppeagleRate.MarkupRate;
            end
        end;

        MFNMinPrice := (costprice + WeightRate) * MarkupRate;
        exit(MFNMinPrice);
    end;

    local procedure CalculateValueBasedCarrierRate(recItem: Record Item): Decimal
    var
        UnitPriceWithVat, carrierRate : Decimal;
        cu_ItemVatCalculation: Codeunit ItemVatCalculation;
        rec_AppeagleRate: Record AppeagleRates;
    begin
        UnitPriceWithVat := cu_ItemVatCalculation.CalculateVat(recItem);
        if UnitPriceWithVat < 25 then begin
            rec_AppeagleRate.Reset();
            rec_AppeagleRate.SetRange(Code, 'Packet Post');
            if rec_AppeagleRate.FindFirst() then begin
                carrierRate := rec_AppeagleRate.Rate;
            end;
        end
        else begin
            if (UnitPriceWithVat >= 25) and (UnitPriceWithVat < 79.99) then begin
                rec_AppeagleRate.Reset();
                rec_AppeagleRate.SetRange(Code, 'Box Post');
                if rec_AppeagleRate.FindFirst() then begin
                    carrierRate := rec_AppeagleRate.Rate;
                end;
            end
            else begin
                rec_AppeagleRate.Reset();
                rec_AppeagleRate.SetRange(Code, 'Carrier Box');
                if rec_AppeagleRate.FindFirst() then begin
                    carrierRate := rec_AppeagleRate.Rate;
                end;
            end;
        end;
        exit(carrierRate);
    end;

    local procedure CalculateBaseSellPrice(recItem: Record Item): Decimal
    var
        baseSellPrice: Decimal;
        cu_ItemVatCalculation: Codeunit ItemVatCalculation;
    begin
        if recItem.RRP <> 0 then
            baseSellPrice := recItem.RRP
        else begin
            baseSellPrice := cu_ItemVatCalculation.CalculateVat(recItem);
        end;
        exit(baseSellPrice);
    end;

    local procedure calculateIntermediatemaxprice(recItem: Record Item): Decimal
    var
        baseSellPrice, IntermediateMaxPrice, valueBasedCarrierRate, CarrierBoxRate : Decimal;
        // valueBasedCarrierRate calculated
        rec_AppeagleRates: Record AppeagleRates;
    begin
        baseSellPrice := CalculateBaseSellPrice(recItem);
        valueBasedCarrierRate := CalculateValueBasedCarrierRate(recItem);

        if (baseSellPrice + valueBasedCarrierRate) > 79.99 then begin
            rec_AppeagleRates.SetRange(Code, 'Carrier Box');
            if rec_AppeagleRates.FindFirst() then
                CarrierBoxRate := rec_AppeagleRates.Rate;
            IntermediateMaxPrice := baseSellPrice + CarrierBoxRate;
        end
        else
            IntermediateMaxPrice := baseSellPrice + valueBasedCarrierRate;
        exit(IntermediateMaxPrice);
    end;

    //FBA Cost Price
    procedure CalculateCostPriceForFBAItem(recItem: Record Item): Decimal
    var
        FBAcostPrice: Decimal;
        rec_ValueEntry: Record "Value Entry";
        recItemLedger: Record "Item Ledger Entry";
        isRecFound: Boolean;
    begin
        //to do
        //Look for the most recent inventory adjustment with a reference of reason code 'ZFBA' – use this;
        //if not found then standard item cost price i.e unit cost
        rec_ValueEntry.SetRange("Item No.", recItem."No.");
        rec_ValueEntry.SetCurrentKey("Posting Date");
        rec_ValueEntry.SetAscending("Posting Date", false);
        if rec_ValueEntry.FindSet() then begin
            repeat
                if (rec_ValueEntry."Reason Code" <> '') and (rec_ValueEntry."Reason Code" = 'ZFBA') then begin
                    recItemLedger.SetRange("Entry No.", rec_ValueEntry."Item Ledger Entry No.");
                    if recItemLedger.FindSet() then begin
                        isRecFound := true;
                        recItemLedger.CalcFields("Cost Amount (Actual)");
                        FBAcostPrice := recItemLedger."Cost Amount (Actual)" / recItemLedger.Quantity;
                        break;
                    end;
                end
            until rec_ValueEntry.Next() = 0;
        end;
        if isRecFound then
            exit(FBAcostPrice)
        else begin
            FBAcostPrice := recItem."Last Direct Cost";
            exit(FBAcostPrice);
        end;
    end;

    //Find Best suitable box from dimension
    local procedure RetreiveBestSmallestPackingTypeFee(recItem: Record Item): Decimal
    var
        rec_FBACalculationSettings: Record FBACalculationSettings;
        rec_AmazonBoxSizes: Record AmazonBoxSizes;
        bubbleWrapCost, lableCost, Fee, BestFee, BoxWeight, BestBoxWeight : Decimal;
    begin
        BestBoxWeight := 0;
        BestFee := 0;

        rec_FBACalculationSettings.Reset();

        if rec_FBACalculationSettings.FindFirst() then begin
            bubbleWrapCost := rec_FBACalculationSettings.BubbleWrapCost;
            lableCost := rec_FBACalculationSettings.LabelCost;
        end;

        rec_AmazonBoxSizes.Reset();
        rec_AmazonBoxSizes.SetCurrentKey(Volume);
        rec_AmazonBoxSizes.SetAscending(Volume, true);

        if rec_AmazonBoxSizes.FindSet() then begin
            repeat
                recItem.CalcFields(AMAZON_API_HEIGHT);
                recItem.CalcFields(AMAZON_API_LENGTH);
                recItem.CalcFields(AMAZON_API_WEIGHT);
                recItem.CalcFields(AMAZON_API_WIDTH);

                Clear(BoxWeight);
                BoxWeight := rec_AmazonBoxSizes."Packaging Weight" + recItem.AMAZON_API_WEIGHT;

                if (rec_AmazonBoxSizes.Width > recItem.AMAZON_API_WIDTH) and
                (rec_AmazonBoxSizes.Length > recItem.AMAZON_API_LENGTH) and
                (rec_AmazonBoxSizes.Height > recItem.AMAZON_API_HEIGHT) and
                (rec_AmazonBoxSizes."Max box weight" >= BoxWeight) and
                (rec_AmazonBoxSizes.isFBA) then begin

                    if BestBoxWeight = 0 then begin
                        BestBoxWeight := rec_AmazonBoxSizes."Max box weight";
                        BestFee := rec_AmazonBoxSizes.Fee;
                        Fee := rec_AmazonBoxSizes.Fee;
                    end;

                    if (BestBoxWeight >= rec_AmazonBoxSizes."Max box weight") and (BestFee >= rec_AmazonBoxSizes.Fee) then begin
                        BestBoxWeight := rec_AmazonBoxSizes."Max box weight";
                        BestFee := rec_AmazonBoxSizes.Fee;
                        Fee := rec_AmazonBoxSizes.Fee;
                    end;
                end
            until rec_AmazonBoxSizes.Next() = 0;
        end;

        if recItem.BUBBLE_WRAP then begin
            Fee := Fee + bubbleWrapCost;
        end;
        if recItem.AMAZON_LABEL then begin
            Fee := Fee + lableCost;
        end;
        exit(Fee);
    end;

    local procedure UpdateVolumeOfAmazonBoxSizes()
    var
        rec_AmazonBoxSizes: Record AmazonBoxSizes;
    begin
        rec_AmazonBoxSizes.Reset();
        if rec_AmazonBoxSizes.FindSet() then begin
            repeat
                rec_AmazonBoxSizes.Volume := (rec_AmazonBoxSizes.Length * rec_AmazonBoxSizes.Width * rec_AmazonBoxSizes.Height);
                rec_AmazonBoxSizes.Modify();
            until rec_AmazonBoxSizes.Next() = 0;
        end;
    end;

    local procedure InitializeCSVHeader()
    var
    begin
        CLEAR(Char1310);
        Char1310 := 10;

        CSVText := CSVText + 'SKU' + ',' + 'MIN_PRICE' + ',' + 'MAX_PRICE' + ',' + 'STRATEGY_ID' + ',' + 'MARKETPLACE_ID' + ',' + 'COST' + ',' + 'CURRENCY' + ',' + 'LISTING_TYPE' + FORMAT(Char1310);
    end;

    local procedure CreateCSV(SKU: Code[25]; MIN_PRICE: Decimal; MAX_PRICE: Decimal; LISTINGTYPE: Text)
    begin
        CSVText := CSVText + '"' + SKU + '","' + Format(Round(MIN_PRICE, 0.01), 0, '<Precision,2:2><Standard Format,0>') + '","' + Format(Round(MAX_PRICE, 0.01), 0, '<Precision,2:2><Standard Format,0>') + '","' + '2051' + '' + '","' + '4249' + '' + '","' + '0' + '' + '","' + 'GBP' + '' + '","' + LISTINGTYPE + '"' + FORMAT(Char1310);
    end;

    procedure GetAllItems()
    var
        recordItem: Record Item;
        description: Text;
    begin
        APIGetCatalogItems();
        InitializeCSVHeader();
        UpdateVolumeOfAmazonBoxSizes(); //for updating volume which is needed for calculating fba fee

        recordItem.reset();
        if recordItem.FindSet() then begin
            repeat
                if not recordItem.Blocked then begin
                    //FBA Item
                    if recordItem.FBA_APPEAGLE then begin
                        if recordItem.FBA_SKU <> '' then
                            CalculateMinMaxpriceforFBAItems(recordItem)
                        else begin
                            description := 'Item ' + recordItem."No." + ' is enabled for FBA Appeagle but the FBA SKU is blank';
                            cu_CommonHelper.InsertWarningForAmazon(description, recordItem."No.", 'Item No', EnhIntegrationLogTypes::Appeagle);
                        end;
                    end;
                    //MFN Item
                    if recordItem.Enabled_Appeagle then begin
                        CalculateMinMaxpriceforMFNItems(recordItem);
                    end;
                end;
            until recordItem.Next() = 0;
        end;
        // EmailtheCSV();
        UploadToSFTP();
    end;

    procedure UploadToSFTP()
    var
        UploadToSFTPURI: Text;
        Base64Data: Text;
        filename: Text;
        result: Text;
        rec_AppeagleSetting: Record "Appeagle Setting";
        JToken: JsonToken;
        Jarray: JsonArray;
        JObject: JsonObject;
        i: Integer;
        ZipArchive: Codeunit "Data Compression";
        ZipInStream: InStream;
        TempInStream: InStream;
    begin
        Clear(RESTAPIHelper);
        filename := 'appeagle';
        Rec_TempBlob.CREATEOUTSTREAM(OutS);
        OutS.WRITETEXT(CSVText);

        ZipArchive.CreateZipArchive();
        TempInStream := Rec_TempBlob.CreateInStream(TextEncoding::Windows);
        ZipArchive.AddEntry(TempInStream, 'appeagle.csv');

        ZipArchive.SaveZipArchive(Rec_TempBlob);
        ZipInStream := Rec_TempBlob.CreateInStream(TextEncoding::Windows);
        Base64Data := cdu_Base64.ToBase64(ZipInStream);

        //for downloading at local machine
        //DownloadFromStream(Base64Data, '', '', '', filename);
        UploadToSFTPURI := RESTAPIHelper.GetBaseURl() + 'Appeagle/UploadFile';
        RESTAPIHelper.Initialize('POST', UploadToSFTPURI);

        rec_AppeagleSetting.Reset();
        if rec_AppeagleSetting.FindSet() then begin
            repeat
                //Header
                RESTAPIHelper.AddRequestHeader('sftpHost', rec_AppeagleSetting.SFTPHost.Trim());
                RESTAPIHelper.AddRequestHeader('sftpPort', rec_AppeagleSetting.SFTPPort.Trim());
                RESTAPIHelper.AddRequestHeader('sftpUser', rec_AppeagleSetting.SFTPuser.Trim());
                RESTAPIHelper.AddRequestHeader('sftpPassword', rec_AppeagleSetting.SFTPPassword.Trim());
                RESTAPIHelper.AddRequestHeader('sftpDestinationPath', rec_AppeagleSetting.SFTPdestinationpath.Trim());

                //Body
                RESTAPIHelper.AddBody('{"base64EncodedData":"' + Base64Data + '"}');
                // //ContentType
                RESTAPIHelper.SetContentType('application/json');
                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Appeagle) then begin

                    result := RESTAPIHelper.GetResponseContentAsText();

                    if Jarray.ReadFrom(result) then begin
                        for i := 0 to Jarray.Count() - 1 do begin
                            Jarray.Get(i, Jtoken);
                            JObject := Jtoken.AsObject();
                            cu_CommonHelper.InsertEnhancedIntegrationLog(JToken, EnhIntegrationLogTypes::Appeagle);
                        end
                    end;
                end;
            until rec_AppeagleSetting.Next() = 0;
        end;
    end;
}
