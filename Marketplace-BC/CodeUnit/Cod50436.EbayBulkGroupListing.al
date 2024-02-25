codeunit 50436 EbayBulkCreateGroupListing
{
    trigger OnRun()
    begin
        SendToAPIGroupListing();
    end;

    var
        cu_CommonHelper: Codeunit CommonHelper;
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        rec_EbaySettings: Record "ebay Setting";
        listingBodyList, offerBodyList, groupBodyList : List of [Text];

    procedure SendToAPIGroupListing()
    var
        recEbayListing: Record EbayListing;
        itemBatch, sendItemBatch : Dictionary of [Integer, Text];
        recItem: Record Item;
        indexMain, outerIndex, innerIndex, batchOf5, parentIndex, recordPerBatch, newBatchSize : Integer;
        batchListingJsonBody, URI, result : Text;
        parentSKUs, childItems : list of [Text];
        parentChildren: Dictionary of [Text, List of [Text]];
        parentChildrenBatch, innerParentChildrenBatch, sendFinalBatch : Dictionary of [Integer, Dictionary of [Text, List of [Text]]];
        recItemSubstitution: Record "Item Substitution";
        parentItemNo: Code[20];
        calculatedBatch: Decimal;
        finalParentChildrenBatch: Dictionary of [Integer, Dictionary of [Integer, Dictionary of [Text, List of [Text]]]];
    begin
        Clear(URI);
        rec_EbaySettings.Reset();

        if rec_EbaySettings.FindSet() then begin
            repeat

                if (rec_EbaySettings.refresh_token.Trim() <> '') and (rec_EbaySettings.oauth_credentials.Trim() <> '') then begin

                    parentIndex := 0;
                    Clear(itemBatch);
                    Clear(parentChildren);

                    // TO DO - LastAttempt procedure 
                    recEbayListing.SetCurrentKey(LastAttempt);
                    recEbayListing.SetAscending(LastAttempt, true);

                    recEbayListing.SetRange(EbayAction, 'CREATE_GROUP');
                    recEbayListing.SetRange(isCompleted, false);

                    if recEbayListing.FindSet() then begin
                        repeat
                            recItemSubstitution.Reset();
                            recItemSubstitution.SetRange("Substitute No.", recEbayListing.sku);
                            parentItemNo := '';

                            if recItemSubstitution.FindFirst() then begin
                                parentItemNo := recItemSubstitution."No.";
                            end;

                            if parentItemNo <> '' then begin
                                if not parentSKUs.Contains(parentItemNo) then begin
                                    parentSKUs.Add(parentItemNo);
                                    recItemSubstitution.Reset();
                                    recItemSubstitution.SetRange("No.", parentItemNo);
                                    Clear(childItems);

                                    if recItemSubstitution.FindSet() then
                                        repeat
                                            if recItem.Get(recItemSubstitution."Substitute No.") then begin
                                                if recItem.Enabled_ebay then begin
                                                    childItems.Add(recItemSubstitution."Substitute No.");
                                                end;
                                            end;
                                        until recItemSubstitution.Next() = 0;

                                    if childItems.Count > 0 then begin
                                        parentIndex := parentIndex + 1;
                                        parentChildren.Add(parentItemNo, childItems);
                                        parentChildrenBatch.Add(parentIndex, parentChildren);
                                        Clear(parentChildren);
                                    end;
                                end;
                            end;
                        until recEbayListing.Next() = 0;
                    end;

                    innerIndex := 0;
                    batchOf5 := 0;
                    outerIndex := 0;
                    recordPerBatch := 0;

                    if rec_EbaySettings.RecordsPerRun > parentChildrenBatch.Count then begin
                        recordPerBatch := parentChildrenBatch.Count;
                    end
                    else begin
                        recordPerBatch := rec_EbaySettings.RecordsPerRun;
                    end;

                    calculatedBatch := round(parentChildrenBatch.Count / recordPerBatch, 1, '<');

                    if rec_EbaySettings.BatchSize > calculatedBatch then begin
                        newBatchSize := calculatedBatch;
                    end else begin
                        newBatchSize := rec_EbaySettings.BatchSize;
                    end;

                    for indexMain := 1 to parentChildrenBatch.Count do begin

                        batchOf5 := batchOf5 + 1;

                        if batchOf5 <= recordPerBatch then begin
                            innerIndex := innerIndex + 1;
                            innerParentChildrenBatch.Add(innerIndex, parentChildrenBatch.Get(indexMain))
                        end else begin
                            batchOf5 := 0;
                            innerIndex := 0;
                            outerIndex := outerIndex + 1;
                            finalParentChildrenBatch.Add(outerIndex, innerParentChildrenBatch);
                            Clear(innerParentChildrenBatch);

                            if finalParentChildrenBatch.Count = newBatchSize then begin
                                indexMain := parentChildrenBatch.Count;
                            end else begin
                                indexMain := indexMain - 1;
                            end;
                        end;
                    end;

                    if innerParentChildrenBatch.Count <> 0 then begin
                        outerIndex := outerIndex + 1;
                        finalParentChildrenBatch.Add(outerIndex, innerParentChildrenBatch);
                    end;

                    // Pass batch of 15 one by one to api
                    for indexMain := 1 to finalParentChildrenBatch.Count do begin
                        Clear(listingBodyList);
                        Clear(offerBodyList);
                        Clear(groupBodyList);
                        sendFinalBatch := finalParentChildrenBatch.Get(indexMain);

                        batchListingJsonBody := '';
                        //Create JSON body of 15 items
                        batchListingJsonBody := BulkCreateGroupBatch(sendFinalBatch, rec_EbaySettings);
                        Message(batchListingJsonBody);
                        if batchListingJsonBody <> '' then begin
                            Clear(RESTAPIHelper);

                            URI := RESTAPIHelper.GetBaseURl() + 'Ebay/CreateGroupListing';
                            RESTAPIHelper.Initialize('POST', URI);
                            RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                            RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());
                            RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                            RESTAPIHelper.AddBody(batchListingJsonBody);
                            RESTAPIHelper.SetContentType('application/json');

                            //API Call per Batch
                            // if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                            //     result := RESTAPIHelper.GetResponseContentAsText();
                            //     cu_eBayCommonHelper.ReadBulkApiResponse(result, rec_EbaySettings);
                            // end
                            // else begin
                            //     Message('An error occured while create listing, please check integration log');
                            // end;
                            Sleep(2000);
                        end;
                    end;
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    procedure BulkCreateGroupBatch(groupListing: Dictionary of [Integer, Dictionary of [Text, List of [Text]]]; rec_eBaySetting: Record "ebay Setting"): Text
    var
        groupIndex, childElement, childIndex, i, j, k : Integer;
        parentChildren: Dictionary of [Text, List of [Text]];
        childSKUs: List of [Text];
        parentSKU: Code[20];
        itemBatch: Dictionary of [Integer, Text];
        childSKU, groupBatchJson, listingBody, offerBody, groupBody : Text;
    begin
        childElement := 0;
        groupBatchJson := '';
        listingBody := '';
        offerBody := '';
        groupBody := '';

        for groupIndex := 1 to groupListing.Count do begin
            parentChildren := groupListing.Get(groupIndex);

            // Group loop of 15 iteration
            foreach parentSKU in parentChildren.Keys do begin

                // Create GROUP JSON
                GenerateGroupJson(parentSKU);

                childSKUs := parentChildren.Get(parentSKU);

                foreach childSKU in childSKUs do begin
                    childElement := childElement + 1;
                    itemBatch.Add(childElement, childSKU);
                end;
            end;
        end;

        CreateGroupListingJson(itemBatch, rec_eBaySetting);

        if listingBodyList.Count > 0 then begin
            listingBody := '"listing":[';
            for i := 1 to listingBodyList.Count do begin
                if i <> listingBodyList.Count then
                    listingBody := listingBody + '' + listingBodyList.Get(i) + ','
                else
                    listingBody := listingBody + '' + listingBodyList.Get(i) + '';
            end;
            listingBody := listingBody + ']';
        end;

        if offerBodyList.Count > 0 then begin
            offerBody := '"offers":[';
            for j := 1 to offerBodyList.Count do begin
                if j <> offerBodyList.Count then
                    offerBody := offerBody + '' + offerBodyList.Get(j) + ','
                else
                    offerBody := offerBody + '' + offerBodyList.Get(j) + '';
            end;
            offerBody := offerBody + ']';
        end;

        if groupBodyList.Count > 0 then begin
            groupBody := '"groups":[';
            for k := 1 to groupBodyList.Count do begin
                if k <> groupBodyList.Count then
                    groupBody := groupBody + '' + groupBodyList.Get(k) + ','
                else
                    groupBody := groupBody + '' + groupBodyList.Get(k) + '';
            end;
            groupBody := groupBody + ']';
        end;

        if (listingBody <> '') and (offerBody <> '') and (groupBody <> '') then begin
            groupBatchJson := '{' + listingBody + ',' + offerBody + ',' + groupBody + '}';
        end;

        exit(groupBatchJson);
    end;

    procedure CreateGroupListingJson(itemBatch: Dictionary of [Integer, Text]; rec_eBaySetting: Record "ebay Setting")
    var
        quantity, index, element : Integer;
        rec_Item_No, parentSKU : Code[20];
        rec_Item, parentItem : Record Item;
        recItemSubstitution: Record "Item Substitution";
        createChild: Boolean;
        title, brand, description, ind, descText, descBase64Data, imageUrls, attributeValue, quantityLimitPerBuyer, fulfillmentPolicyId, listingDesc, base64Data, categoryId : Text;
        LF, CR : char;
        descList: List of [Text];
        cdu_Base64: Codeunit "Base64 Convert";
        isListingCreated, isOfferCreated : Boolean;
        salesPrice: Decimal;
        webCategoryId: BigInteger;
        genProdPostingGroup: Record "Gen. Product Posting Group";
        cuStockLevel: Codeunit StockLevel;

    begin
        LF := 10;
        CR := 13;
        rec_Item.Reset();

        for index := 1 to itemBatch.Count do begin
            descBase64Data := '';
            quantityLimitPerBuyer := '';
            imageUrls := '';
            title := '';
            descText := '';
            description := '';
            categoryId := '';
            webCategoryId := 0;
            isListingCreated := false;
            isOfferCreated := false;

            rec_Item_No := itemBatch.Get(index);
            rec_Item.SetRange("No.", rec_Item_No);

            if rec_Item.FindFirst() then begin

                title := cdu_Base64.ToBase64(rec_Item.Description);

                if rec_Item.ALT_TITLE <> '' then begin
                    title := cdu_Base64.ToBase64(rec_Item.ALT_TITLE);
                end;

                // quantity := (cu_eBayCommonHelper.CalculateAvailbleStock(rec_Item) + cu_eBayCommonHelper.GetQtyCanBeAssembled(rec_Item_No)) - rec_Item.Reserve_Stock_ebay;

                quantity := cuStockLevel.GetQuantity(rec_Item."No.", true);

                if (quantity < 0) then begin
                    quantity := 0;
                end;

                if quantity > 20 then begin
                    quantity := 20;
                end;

                recItemSubstitution.SetRange("Substitute No.", rec_Item_No);

                if recItemSubstitution.FindFirst() then begin
                    createChild := false;
                    parentItem.SetRange("No.", recItemSubstitution."No.");
                    parentItem.SetRange(Enabled_ebay, true);

                    if parentItem.FindFirst() then begin
                        createChild := true;
                    end;
                end;
                #region " Listing "
                if genProdPostingGroup.Get(rec_Item."Gen. Prod. Posting Group") then begin
                    brand := genProdPostingGroup.Description;
                end;

                if (rec_Item.FULL_DESCRIPITION <> '') or (rec_Item.FULL_DESCRIPITION_CONTINUED <> '') then begin
                    description := rec_Item.FULL_DESCRIPITION + ' ' + rec_Item.FULL_DESCRIPITION_CONTINUED;
                    descList := description.Split(LF, CR);

                    foreach ind in descList do begin
                        descText := descText + ind;
                    end;

                    descBase64Data := cdu_Base64.ToBase64(descText);
                end;

                if rec_Item.IMAGE_FILE_NAME <> '' then begin
                    imageUrls := '"' + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.IMAGE_FILE_NAME)) + '"';
                end;

                if rec_Item.LARGE_IMAGE_2 <> '' then begin
                    if imageUrls <> '' then begin
                        imageUrls := imageUrls + ',"';
                    end
                    else begin
                        imageUrls := '"';
                    end;
                    imageUrls := imageUrls + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.LARGE_IMAGE_2)) + '"';
                end;

                if rec_Item.LARGE_IMAGE_3 <> '' then begin
                    if imageUrls <> '' then begin
                        imageUrls := imageUrls + ',"';
                    end else begin
                        imageUrls := '"';
                    end;
                    imageUrls := imageUrls + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.LARGE_IMAGE_3)) + '"';
                end;

                if rec_Item.LARGE_IMAGE_4 <> '' then begin
                    if imageUrls <> '' then begin
                        imageUrls := imageUrls + ',"';
                    end else begin
                        imageUrls := '"';
                    end;
                    imageUrls := imageUrls + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.LARGE_IMAGE_4)) + '"';
                end;

                if rec_Item.LARGE_IMAGE_5 <> '' then begin
                    if imageUrls <> '' then begin
                        imageUrls := imageUrls + ',"';
                    end else begin
                        imageUrls := '"';
                    end;
                    imageUrls := imageUrls + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.LARGE_IMAGE_5)) + '"';
                end;

                if rec_Item.LARGE_IMAGE_6 <> '' then begin
                    if imageUrls <> '' then begin
                        imageUrls := imageUrls + ',"';
                    end else begin
                        imageUrls := '"';
                    end;
                    imageUrls := imageUrls + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.LARGE_IMAGE_6)) + '"';
                end;

                if imageUrls.Trim() <> '' then begin
                    imageUrls := '"imageUrls":[' + imageUrls + '],';
                end;

                attributeValue := cu_eBayCommonHelper.GetItemAttributeValue(rec_Item);

                if (descBase64Data <> '') and (rec_Item."Primary Barcode" <> '') and (imageUrls <> '') and (rec_Item.ParentAttribute <> '') then begin
                    isListingCreated := true;
                end
                else begin
                    cu_CommonHelper.InsertBusinessCentralErrorLog('Missing at least one image url, item description, attributes or barcode value', rec_Item_No, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                end;
                #endregion

                #region " Offer "
                salesPrice := cu_eBayCommonHelper.CalculateSalesPrice(rec_Item);
                fulfillmentPolicyId := cu_eBayCommonHelper.GetFulfillmentId(rec_Item);
                listingDesc := cu_eBayCommonHelper.GetItemHTMLContent(rec_Item, salesPrice);
                base64Data := cdu_Base64.ToBase64(listingDesc);
                fulfillmentPolicyId := cu_eBayCommonHelper.GetFulfillmentId(rec_Item);

                // eBay Brwose Node Field Id = 4
                webCategoryId := cu_eBayCommonHelper.GetWebCategoryId(rec_Item_No, 4);

                if webCategoryId > 0 then begin
                    categoryId := Format(webCategoryId);
                end else begin
                    categoryId := rec_eBaySetting.categoryId;
                end;

                if rec_Item."Maximum Order Quantity" <> 0 then begin
                    quantityLimitPerBuyer := '"quantityLimitPerBuyer": "' + format(rec_Item."Maximum Order Quantity") + '",';
                end;

                if salesPrice <> 0 then begin
                    isOfferCreated := true;
                end
                else begin
                    cu_CommonHelper.InsertBusinessCentralErrorLog('Price should be greater than 0', rec_Item_No, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                end;
                #endregion

                if (createChild) and (isListingCreated) and (isOfferCreated) then begin
                    listingBodyList.Add('{ "availability": { "shipToLocationAvailability":{"quantity":"' + Format(quantity, 0, 1) + '"}},"condition":"NEW","locale": "en_GB","packageType": "PARCEL_OR_PADDED_ENVELOPE","product":{"aspects": { "' + rec_Item.ParentAttribute + '": [ "' + attributeValue + '" ] },"brand":"' + brand + '","description":"' + descBase64Data + '", "ean" : ["' + rec_Item."Primary Barcode" + '"],"upc" : ["' + rec_Item."Primary Barcode" + '"],' + imageUrls + '"mpn":"' + rec_Item."No." + '","title":"' + title + '"},"sku":"' + rec_Item."No." + '" }');

                    offerBodyList.Add('{ "availableQuantity": "' + Format(quantity) + '","categoryId":"' + categoryId + '","format":"FIXED_PRICE","hideBuyerDetails":"True","includeCatalogProductDetails":"False","listingDescription":"' + base64Data + '","listingDuration":"GTC","listingPolicies":{"bestOfferTerms":{"bestOfferEnabled":"False"},"fulfillmentPolicyId":"' + fulfillmentPolicyId + '","paymentPolicyId":"' + rec_EbaySettings.paymentPolicyId + '","returnPolicyId":"' + rec_EbaySettings.returnPolicyId + '"},"marketplaceId":"EBAY_GB","merchantLocationKey":"' + rec_EbaySettings.MerchantLocationKey + '","pricingSummary":{"price":{"currency":"GBP","value":"' + format(salesPrice, 0, 1) + '"},' + quantityLimitPerBuyer + '"pricingVisibility":"NONE"},"sku":"' + rec_Item."No." + '"}');
                end;
            end;
        end;
    end;

    procedure GenerateGroupJson(parentItemNo: Code[20])
    var
        recItemSubstitution: Record "Item Substitution";
        parentItem, rec_Item : Record Item;
        childItemsSKUs, variantSKUs : List of [Code[20]];
        element: Integer;
        variantSKUsBody, valueBody, attributeValue, listingDescription, base64Data, childSKU : Text;
        attributeValuesList: List of [Text];
        cdu_Base64: Codeunit "Base64 Convert";
        recEbayListing: Record EbayListing;
    begin
        variantSKUsBody := '';
        valueBody := '';
        recItemSubstitution.Reset();
        parentItem.Reset();
        Clear(childItemsSKUs);
        Clear(variantSKUs);

        if parentItemNo <> '' then begin
            recItemSubstitution.Reset();
            recItemSubstitution.SetRange("No.", parentItemNo);

            if recItemSubstitution.FindSet() then
                repeat
                    childItemsSKUs.Add(recItemSubstitution."Substitute No.");
                until recItemSubstitution.Next() = 0;
        end;

        //To find values of child items
        for element := 1 to childItemsSKUs.Count do begin
            rec_Item.Reset();
            rec_Item.SetRange(Enabled_ebay, true);
            rec_Item.SetRange("No.", childItemsSKUs.Get(element));

            if rec_Item.FindFirst() then begin
                attributeValue := cu_eBayCommonHelper.GetItemAttributeValue(rec_Item);

                if attributeValue <> '' then begin
                    attributeValuesList.Add(attributeValue);
                    variantSKUs.Add(childItemsSKUs.Get(element));
                end;
            end;
        end;

        if variantSKUs.Count <> 0 then begin
            variantSKUsBody := '"variantSKUs":[';
            for element := 1 to variantSKUs.Count do begin

                childSKU := variantSKUs.Get(element);

                if element <> variantSKUs.Count then begin
                    variantSKUsBody := variantSKUsBody + '"' + childSKU + '",'
                end
                else begin
                    variantSKUsBody := variantSKUsBody + '"' + childSKU + '"';
                end;

                recEbayListing.SetRange(sku, childSKU);
                if recEbayListing.FindFirst() then begin
                    //if recEbayListing.Get(childSKU) then begin
                    cu_eBayCommonHelper.UpdateLastAttempt(recEbayListing.Id);
                end;
            end;
            variantSKUsBody := variantSKUsBody + ']';

            valueBody := '"values":[';
            for element := 1 to attributeValuesList.Count do begin
                if element <> attributeValuesList.Count then
                    valueBody := valueBody + '"' + cdu_Base64.FromBase64(attributeValuesList.Get(element)) + '",'
                else
                    valueBody := valueBody + '"' + cdu_Base64.FromBase64(attributeValuesList.Get(element)) + '"';
            end;
            valueBody := valueBody + ']';

            rec_Item.Reset();
            rec_Item.SetRange("No.", parentItemNo);

            if rec_Item.FindFirst() then begin
                attributeValue := cu_eBayCommonHelper.GetItemAllAttributeValue(rec_Item, '');

                listingDescription := cu_eBayCommonHelper.GetGroupItemHTMLList(rec_Item);
                base64Data := cdu_Base64.ToBase64(listingDescription);
            end;
        end;

        if (rec_Item.ParentAttribute <> '') and (rec_Item.Description <> '') and (variantSKUs.Count <> 0) then begin
            groupBodyList.Add('{' + attributeValue + ',"description":"' + base64Data + '","imageUrls":["' + cu_eBayCommonHelper.GenerateImageUrl(format(rec_Item.IMAGE_FILE_NAME)) + '"],"inventoryItemGroupKey":"' + rec_Item."No." + '","title":"' + cdu_Base64.ToBase64(rec_Item.Description) + '",' + variantSKUsBody + ',"variesBy":{"aspectsImageVariesBy":["' + rec_Item.ParentAttribute + '"],"specifications":[{"name":"' + rec_Item.ParentAttribute + '",' + valueBody + '}]} }');
        end
        else begin
            cu_CommonHelper.InsertBusinessCentralErrorLog('Group item and child items must have variation value/description/attributes', rec_Item."No.", EnhIntegrationLogTypes::Ebay, true, 'SKU');
        end;
    end;
}
