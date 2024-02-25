codeunit 50438 EbayCommonHelper
{
    var
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        cu_CommonHelper: Codeunit CommonHelper;
        cdu_Base64: Codeunit "Base64 Convert";

    procedure UpdateLastAttempt(id: Integer)
    var
        recEbayListing: record EbayListing;
    begin
        if recEbayListing.Get(id) then begin
            recEbayListing.LastAttempt := recEbayListing.LastAttempt + 1;
            recEbayListing.Modify(true);
        end;
    end;

    procedure GetWebCategoryId(ItemNo: code[20]; browseNodeField: Integer): BigInteger
    var
        ItemNoRef, WebCatRef, BrowseNodeRef, IdRef, level, sequence, magentoId : fieldref;
        webCatAssignRef, webCategoriesRef : RecordRef;
        BrowseNode, webCategoryBrowseNode, maxLevel, minSequence, magentoResponseId, webCategoryLevel, webCategorySequence, webCatogoryMagentoId : BigInteger;
    begin
        webCatAssignRef.Open(90101);
        webCategoriesRef.Open(90100);
        ItemNoRef := webCatAssignRef.Field(1);
        ItemNoRef.SetRange(ItemNo);
        WebCatRef := webCatAssignRef.Field(2);
        maxLevel := 0;
        minSequence := 0;
        magentoResponseId := 0;
        webCategoryBrowseNode := 0;

        if webCatAssignRef.FindSet() then begin
            repeat
                IdRef := webCategoriesRef.Field(1);
                IdRef.SetRange(WebCatRef);

                // Amazon Browse Node Field Id 3 and eBay Browse Node Field Id 4
                BrowseNodeRef := webCategoriesRef.Field(browseNodeField);

                level := webCategoriesRef.Field(5);
                sequence := webCategoriesRef.Field(6);
                magentoId := webCategoriesRef.Field(1);

                if webCategoriesRef.FindFirst() then begin
                    BrowseNode := BrowseNodeRef.Value;
                    webCategoryLevel := level.Value;
                    webCategorySequence := sequence.Value;
                    webCatogoryMagentoId := magentoId.Value;

                    if minSequence = 0 then begin
                        minSequence := webCategorySequence;
                    end;

                    if BrowseNode <> 0 then begin
                        if webCategoryLevel > maxLevel then begin
                            maxLevel := webCategoryLevel;
                            magentoResponseId := webCatogoryMagentoId;
                            minSequence := webCategorySequence;
                        end else
                            if webCategoryLevel = maxLevel then begin
                                if webCategorySequence < minSequence then begin
                                    minSequence := webCategorySequence;
                                    magentoResponseId := webCatogoryMagentoId;
                                end;
                            end;
                    end;
                end;
            until webCatAssignRef.Next() = 0;

            IdRef.SetRange(magentoResponseId);

            if webCategoriesRef.FindFirst() then begin
                webCategoryBrowseNode := BrowseNodeRef.Value;
                exit(webCategoryBrowseNode);
            end;
        end;
    end;

    procedure ReadBulkApiResponse(var apiResponse: Text; var recEbaySetting: Record "ebay Setting")
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        i: Integer;
        eBayAction, sku : Code[40];
        description, listingID : Text;
        JObject: JsonObject;
        recEbayListing: Record EbayListing;
        recItem: Record Item;
        recEbayItems: Record EbayItemsList;
        cuStockLevel: Codeunit StockLevel;
    begin
        if not JObject.ReadFrom(apiResponse) then begin
            Error('Invalid response, expected a JSON object');
        end;

        JObject.Get('listing', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            Error('Array not Reading Properly');
        end;

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                Clear(eBayAction);
                sku := NYTJSONMgt.GetValueAsText(varjsonToken, 'sku');

                //Ebay Listing update
                listingID := NYTJSONMgt.GetValueAsText(varjsonToken, 'listingId');
                if listingID <> '' then begin
                    recEbayListing.SetRange(sku, sku);

                    if recEbayListing.FindFirst() then begin
                        recEbayListing.isCompleted := true;
                        recEbayListing.Modify(true);
                    end;
                end;

                recItem.Reset();
                recItem.SetRange("No.", sku);

                if recItem.FindFirst() then begin

                    recEbayItems.Reset();
                    recEbayItems.SetRange("No.", sku);

                    if recEbayItems.FindFirst() then begin
                        recEbayItems.Listing_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'listingId');
                        recEbayItems.Offer_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'offerId');
                        //recEbayItems.LAST_INVENTORY := (CalculateAvailbleStock(recItem) + GetQtyCanBeAssembled(recItem."No.")) - recItem.Reserve_Stock_ebay;
                        recEbayItems.LAST_INVENTORY := cuStockLevel.GetQuantity(recItem."No.", true);
                        recEbayItems.LAST_PRICE := CalculateSalesPrice(recItem);
                        recEbayItems.ForceUpdate := false;
                        recEbayItems.Modify(true);
                    end;
                end;
            end;
        end;

        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            Error('Array not Reading Properly');
        end;

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Ebay);
        end;
    end;

    procedure IsParentItem(ItemNo: Text): Boolean
    var
        recSubstitution: Record "Item Substitution";
        recItem: Record Item;
        variation: Boolean;
    begin
        variation := false;
        recSubstitution.SetRange("No.", ItemNo);

        if recSubstitution.FindFirst() then begin
            variation := true;
        end;

        exit(variation);
    end;

    procedure GetItemAttributeValue(recItem: Record Item): Text
    var
        ItemAttributeId, ItemAttributeValueId : Integer;
        itemValue: Text;
        recItemAttribute: Record "Item Attribute";
        recItemAttributeValue: Record "Item Attribute Value";
        recItemAttributeValueMap: Record "Item Attribute Value Mapping";
    begin
        itemValue := '';
        recItemAttribute.Reset();
        recItemAttribute.SetRange("Name", recItem.ParentAttribute);

        if recItemAttribute.FindFirst() then begin
            ItemAttributeId := recItemAttribute.ID;
            recItemAttributeValueMap.Reset();
            recItemAttributeValueMap.SetRange("No.", recItem."No.");
            recItemAttributeValueMap.SetRange("Item Attribute ID", ItemAttributeId);

            if recItemAttributeValueMap.FindFirst() then begin
                ItemAttributeValueId := recItemAttributeValueMap."Item Attribute Value ID";
            end
        end;

        recItemAttributeValue.Reset();
        recItemAttributeValue.SetRange(ID, ItemAttributeValueId);

        if recItemAttributeValue.FindFirst() then begin
            itemValue := cdu_Base64.ToBase64(recItemAttributeValue.Value);
        end;

        exit(itemValue);
    end;

    procedure GetGroupItemHTMLList(recItem: Record Item): Text;
    var
        rec: Record Item;
        HtmlContent, title, description, HtmlTemplate, updatedHtml : Text;
        salesPrice: Decimal;
        recEbaySetting: Record "ebay Setting";
    begin

        title := recItem.Description;
        if recItem.ALT_TITLE <> '' then begin
            title := recItem.ALT_TITLE
        end;

        description := '';
        if (recItem.FULL_DESCRIPITION <> '') or (recItem.FULL_DESCRIPITION_CONTINUED <> '') then begin
            description := recItem.FULL_DESCRIPITION + ' ' + recItem.FULL_DESCRIPITION_CONTINUED;
        end;

        if recItem.OVERRIDE_PRICE > 0 then begin
            salesPrice := recItem.OVERRIDE_PRICE;
        end else begin
            salesPrice := CalculateSalesPrice(recItem);
        end;

        if recEbaySetting.FindSet() then begin
            HtmlTemplate := recEbaySetting.GetWorkDescription();
        end;

        updatedHtml := HtmlTemplate.Replace('{SKU}', recItem."No.");
        updatedHtml := updatedHtml.Replace('{IMAGE_1}', GenerateImageUrl(recItem.IMAGE_FILE_NAME));
        updatedHtml := updatedHtml.Replace('{EXTENDED_INFO}', recItem.Extended_Info_Text);
        updatedHtml := updatedHtml.Replace('£{PRICE}', '');
        updatedHtml := updatedHtml.Replace('{ITEM_TITLE}', title);
        updatedHtml := updatedHtml.Replace('{DESCRIPTION}', description);

        exit(updatedHtml);
    end;

    procedure GetFulfillmentId(recItem: Record Item): Text
    var
        Policy, PolicyId : Text;
        UnitPrice: Decimal;
        cuItemVatCalculation: Codeunit ItemVatCalculation;
        recFulfilmentPolicy: Record FulfilmentPolicy;
    begin
        UnitPrice := cuItemVatCalculation.CalculateVat(recItem);

        if recItem.EBAY_SHIPPING_POLICY <> '' then begin
            Policy := recItem.EBAY_SHIPPING_POLICY;
        end
        else
            if recItem.PARCEL_SIZE <> '' then begin
                case recItem.PARCEL_SIZE of
                    'Small Letter':
                        Policy := 'EBAY POST';
                    'Large Letter':
                        Policy := 'EBAY POST';
                    'Packet Post':
                        Policy := 'EBAY POST';
                    'Carrier Box':
                        Policy := 'DPD';
                    'Box Post':
                        Policy := 'DPD';
                    'UPS18':
                        Policy := 'DPD';
                end;
            end
            else
                if UnitPrice < 25 then begin
                    Policy := 'EBAY POST';
                end
                else begin
                    Policy := 'DPD';
                end;

        recFulfilmentPolicy.SetRange("Policy Name", Policy);

        if recFulfilmentPolicy.FindFirst() then begin
            PolicyId := recFulfilmentPolicy."Policy Id";
        end;

        exit(PolicyId);
    end;

    procedure CalculateAvailbleStock(recItem: Record Item): Decimal
    var
        availableStock: Decimal;
    begin
        recItem.CalcFields(Inventory);
        recItem.CalcFields("Qty. on Sales Order");
        recItem.CalcFields(QtyAtReceive);
        availableStock := recItem.Inventory - recItem."Qty. on Sales Order" - recItem.QtyAtReceive - recItem."Qty. on Asm. Component";

        if availableStock < 0 then begin
            availableStock := 0;
        end;

        exit(availableStock);
    end;

    procedure GetQtyCanBeAssembled(sku: code[20]): Integer
    var
        bom: record "BOM Component";
        recitem2: record Item;
        canbuild: integer;
    begin
        canbuild := 999999;
        bom.Reset();
        bom.SetFilter("Parent Item No.", sku);
        if bom.FindSet() then
            repeat
                if recitem2.Get(bom."No.") then begin
                    recitem2.CalcFields(Inventory);
                    recitem2.CalcFields("Qty. on Sales Order");
                    if ((recitem2.Inventory - recitem2."Qty. on Sales Order") / bom."Quantity per") < canbuild then
                        canbuild := system.round((recitem2.Inventory - recitem2."Qty. on Sales Order") / bom."Quantity per", 1, '<');
                end;
            until bom.Next() = 0;
        if (canbuild = 999999) or (canbuild < 1) then
            canbuild := 0; // reset it if no assembly found or less than zero available
        exit(canbuild);
    end;

    procedure GetItemAllAttributeValue(recItem: Record Item; brand: Text): Text
    var
        element, i, index : Integer;
        recItemAttribute: Record "Item Attribute";
        recItemAttributeValue: Record "Item Attribute Value";
        recItemAttributeValueMap: Record "Item Attribute Value Mapping";
        reportIdBody, attrValue : Text;
        eBayNames, aspects : Dictionary of [Text, Text];
        attributeKeyValues: Dictionary of [Integer, Text];
    begin
        recItemAttribute.Reset();
        recItemAttributeValueMap.Reset();

        recItemAttribute.SetFilter("Ebay Name", '<>%1', '');

        if recItemAttribute.FindSet() then begin
            repeat
                recItemAttributeValueMap.SetRange("No.", recItem."No.");
                recItemAttributeValueMap.SetRange("Item Attribute ID", recItemAttribute.ID);

                if recItemAttributeValueMap.Findset() then begin
                    repeat
                        index := index + 1;
                        eBayNames.Add(format(recItemAttributeValueMap."Item Attribute Value ID"), recItemAttribute."Ebay Name");
                        attributeKeyValues.Add(index, format(recItemAttributeValueMap."Item Attribute Value ID"));
                    until recItemAttributeValueMap.Next() = 0;
                end;

            until recItemAttribute.Next() = 0;
        end;

        for element := 1 to attributeKeyValues.Count do begin
            recItemAttributeValue.Reset();
            Evaluate(i, attributeKeyValues.Get(element));
            recItemAttributeValue.SetRange(ID, i);
            recItemAttributeValue.SetFilter(Value, '<>%1', '');

            if recItemAttributeValue.FindSet() then begin
                if recItemAttributeValue.Value <> '' then begin
                    aspects.Add(eBayNames.Get(attributeKeyValues.Get(element)), recItemAttributeValue.Value);
                end;
            end;
        end;

        reportIdBody := '"aspects":{';
        element := 1;

        foreach attrValue in aspects.Keys do begin
            if element <> aspects.Count then begin
                reportIdBody := reportIdBody + '"' + attrValue + '":["' + cdu_Base64.ToBase64(aspects.Get(attrValue)) + '"],';
            end
            else begin
                reportIdBody := reportIdBody + '"' + attrValue + '":["' + cdu_Base64.ToBase64(aspects.Get(attrValue)) + '"]';
            end;
            element := element + 1;
        end;

        // Append Brand Compulsory
        if brand <> '' Then begin
            if aspects.Count = 0 then begin
                reportIdBody := reportIdBody + '"Brand" : ["' + cdu_Base64.ToBase64(brand) + '"]';
            end else begin
                reportIdBody := reportIdBody + ',"Brand" : ["' + cdu_Base64.ToBase64(brand) + '"]';
            end;
        end;

        reportIdBody := reportIdBody + '}';

        exit(reportIdBody);
    end;

    procedure GetItemHTMLContent(recItem: Record Item; salesPrice: Decimal): Text;
    var
        rec: Record Item;
        HtmlContent, title, description, HtmlTemplate, updatedHtml : Text;
        recEbaySetting: Record "ebay Setting";
    begin

        if recItem.ALT_TITLE <> '' then begin
            title := recItem.ALT_TITLE
        end
        else begin
            title := recItem.Description
        end;

        description := recItem.FULL_DESCRIPITION + ' ' + recItem.FULL_DESCRIPITION_CONTINUED;

        if recEbaySetting.FindSet() then
            HtmlTemplate := recEbaySetting.GetWorkDescription();

        updatedHtml := HtmlTemplate.Replace('{SKU}', recItem."No.");
        updatedHtml := updatedHtml.Replace('{IMAGE_1}', GenerateImageUrl(recItem.IMAGE_FILE_NAME));
        updatedHtml := updatedHtml.Replace('{EXTENDED_INFO}', recItem.Extended_Info_Text);
        updatedHtml := updatedHtml.Replace('{PRICE}', Format(Round(salesPrice, 0.01), 0, '<Precision,2:2><Standard Format,0>'));
        updatedHtml := updatedHtml.Replace('{ITEM_TITLE}', title);
        updatedHtml := updatedHtml.Replace('{DESCRIPTION}', description);

        exit(updatedHtml);
    end;

    procedure GenerateImageUrl(ImageName: Text): Text
    var
        MainImgUrl, URLPrefix, firstChar, secChar : Text;
    begin
        URLPrefix := 'https://www.hartsofstur.com/media/catalog/';
        Clear(MainImgUrl);
        Clear(firstChar);
        Clear(secChar);

        if ImageName <> '' then begin
            ImageName := DelChr(ImageName, '<', 'products\');
            firstChar := CopyStr(ImageName, 1, 1);
            secChar := CopyStr(ImageName, 2, 1);
            MainImgUrl := URLPrefix + 'product/' + firstChar + '/' + secChar + '/' + ImageName;
        end;

        exit(MainImgUrl);
    end;

    procedure CalculateSalesPrice(recItem: Record Item): Decimal;
    var
        rec_GenProductPostingGroup: Record "Gen. Product Posting Group";
        rec_VatProductPostingGroup: Record "VAT Product Posting Group";
        rec_VatPostingSetup: Record "VAT Posting Setup";
        rec_AmazonSetting: Record "Amazon Setting";
        rec_AppeagleRates: Record AppeagleRates;
        rec_ItemLegderEntry: Record "Item Ledger Entry";
        Price1, Rate, MarginProtection, Price2, SalesPrice, standardsellPricewithVat, FIFOCost : Decimal;
        cdu_ItemVatCalculation: Codeunit ItemVatCalculation;
        standardPrice: Decimal;
    begin

        recItem.CalcFields(Inventory);

        if (format(recItem.OVERRIDE_PRICE) = '') or (recItem.OVERRIDE_PRICE = 0) then begin
            standardsellPricewithVat := cdu_ItemVatCalculation.CalculateVat(recItem);

            if standardsellPricewithVat < 0.99 then
                Price1 := 0.99
            else begin
                if (standardsellPricewithVat >= 1) and (standardsellPricewithVat <= 25) then
                    Price1 := standardsellPricewithVat + 2
                else
                    if (standardsellPricewithVat >= 25.01) and (standardsellPricewithVat <= 50) then
                        Price1 := standardsellPricewithVat + 5
                    else
                        Price1 := standardsellPricewithVat;
            end;

            //Price2
            //FIFO Cost todo
            if recItem.Inventory <> 0 then begin
                rec_ItemLegderEntry.SetRange("Item No.", recItem."No.");
                rec_ItemLegderEntry.SETFILTER("Remaining Quantity", '>%1', 0);
                rec_ItemLegderEntry.SetCurrentKey("Posting Date");
                rec_ItemLegderEntry.SetAscending("Posting Date", false);
                if rec_ItemLegderEntry.FindFirst() then begin
                    rec_ItemLegderEntry.CalcFields("Cost Amount (Actual)");
                    FIFOCost := (rec_ItemLegderEntry."Cost Amount (Actual)" / rec_ItemLegderEntry.Quantity);
                    if FIFOCost = 0 then begin
                        FIFOCost := recItem."Last Direct Cost";
                    end;
                end
                else
                    FIFOCost := recItem."Last Direct Cost";
            end
            else begin
                FIFOCost := recItem."Last Direct Cost";
            end;

            //Determine Packaging type rate
            if recItem.PARCEL_SIZE = '' then begin
                if (recItem."Net Weight" > 1.5) or ((recItem."Net Weight" = 0) and (recItem."Unit Price" > 50))
                then begin
                    rec_AppeagleRates.SetFilter(Code, 'Carrier Box');
                    if rec_AppeagleRates.FindSet() then begin
                        Rate := rec_AppeagleRates.EbayRate;
                    end;
                end
                else begin
                    rec_AppeagleRates.SetFilter(Code, 'Packet Post');
                    if rec_AppeagleRates.FindSet() then begin
                        Rate := rec_AppeagleRates.EbayRate;
                    end;
                end;
            end
            else begin
                if (recItem.PARCEL_SIZE = 'Box Post') or (recItem.PARCEL_SIZE = 'UPS18') then begin
                    rec_AppeagleRates.SetFilter(Code, 'Carrier Box');
                    if rec_AppeagleRates.FindSet() then begin
                        Rate := rec_AppeagleRates.EbayRate;
                    end;
                end
                else begin
                    rec_AppeagleRates.SetRange(Code, recItem.PARCEL_SIZE);
                    if rec_AppeagleRates.FindSet() then begin
                        Rate := rec_AppeagleRates.EbayRate;
                    end;
                end;
            end;

            //Retrive margin protection multiplier
            if recItem.MARGIN_PROTECTION <> 0 then begin
                MarginProtection := recItem.MARGIN_PROTECTION;
            end
            else begin
                rec_AppeagleRates.Reset();
                rec_AppeagleRates.SetRange(Code, recItem.PARCEL_SIZE);
                if rec_AppeagleRates.FindFirst() then begin
                    MarginProtection := rec_AppeagleRates.MarkupRate;
                end
                else
                    MarginProtection := 1.6;
            end;

            Price2 := (FIFOCost + Rate) * MarginProtection;

            if Price1 > Price2 then
                SalesPrice := Price1
            else
                SalesPrice := Price2;
            standardPrice := SalesPrice;
        end
        else begin
            standardPrice := recItem.OVERRIDE_PRICE;
        end;
        exit(Round(standardPrice, 0.01));
    end;

    procedure ReadUpdateBulkApiResponse(var apiResponse: Text)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        i: Integer;
        eBayAction, sku : Code[40];
        isSuccess: Boolean;
        description: Text;
        JObject: JsonObject;
        recEbayListing: Record EbayListing;
        recItem: Record Item;
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        recEbayItems: Record EbayItemsList;
        salesPrice, quantity : Decimal;
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;
        cuStockLevel: Codeunit StockLevel;

    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('responses', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            sku := NYTJSONMgt.GetValueAsText(varjsonToken, 'sku');
            isSuccess := NYTJSONMgt.GetValueAsBoolean(varjsonToken, 'success');

            //Ebay Listing update
            if isSuccess then begin
                recEbayListing.Reset();
                recEbayListing.SetRange(sku, sku);

                if recEbayListing.FindFirst() then begin
                    recEbayListing.isCompleted := true;
                    recEbayListing.Modify(true);
                end;

                recItem.Reset();
                recItem.SetRange("No.", sku);

                if recItem.FindFirst() then begin

                    // quantity := (cu_eBayCommonHelper.CalculateAvailbleStock(recItem) + cu_eBayCommonHelper.getQtyCanBeAssembled(recItem."No.")) - recItem.Reserve_Stock_ebay;

                    quantity := cuStockLevel.GetQuantity(recItem."No.", true);

                    if (quantity < 0) then begin
                        quantity := 0;
                    end;

                    if quantity > 20 then begin
                        quantity := 20;
                    end;

                    if recItem.OVERRIDE_PRICE > 0 then begin
                        salesPrice := recItem.OVERRIDE_PRICE;
                    end else begin
                        salesPrice := cu_eBayCommonHelper.CalculateSalesPrice(recItem);
                    end;

                    recEbayItems.Reset();
                    recEbayItems.SetRange("No.", recItem."No.");

                    if recEbayItems.FindFirst() then begin
                        recEbayItems.LAST_INVENTORY := quantity;
                        recEbayItems.LAST_PRICE := salesPrice;
                        recEbayItems.ForceUpdate := false;
                        recEbayItems.Modify(true);
                    end;
                end;
            end;
        end;


        JObject.Get('errorLogs', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        for i := 0 to varJsonArray.Count() - 1 do begin
            varJsonArray.Get(i, varjsonToken);
            cu_CommonHelper.InsertEnhancedIntegrationLog(varjsonToken, EnhIntegrationLogTypes::Ebay);
        end;
    end;

    procedure GetLastLineNo(): Integer
    var
        Id: Integer;
        rec: Record EbayItemsList;
    begin

        if rec.FindLast() then
            Id := rec.Id + 1
        else
            id := 1;
        exit(Id)
    end;
}
