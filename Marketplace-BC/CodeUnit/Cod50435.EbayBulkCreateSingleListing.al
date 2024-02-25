codeunit 50435 EbayBulkCreateSingleListing
{

    var
        cu_CommonHelper: Codeunit CommonHelper;
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;
        RESTAPIHelper: Codeunit "REST API Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        rec_EbaySettings: Record "ebay Setting";

    procedure SendToAPISingleListing(listingAction: Text[50])
    var
        recEbayListing: Record EbayListing;
        itemBatch, sendItemBatch : Dictionary of [Integer, Text];
        itemBatchBatch: Dictionary of [Integer, Dictionary of [Integer, Text]];
        indexMain, outerIndex, innerIndex, batchOf, recordPerBatch, newBatchSize : Integer;
        batchListingJsonBody, URI, result : Text;
        reportIdList: list of [Text];
        calculatedBatch: Decimal;
    begin
        Clear(URI);
        rec_EbaySettings.Reset();

        if rec_EbaySettings.FindSet() then begin
            repeat

                if (rec_EbaySettings.refresh_token.Trim() <> '') and (rec_EbaySettings.oauth_credentials.Trim() <> '') then begin
                    batchOf := 0;
                    indexMain := 0;
                    innerIndex := 0;
                    outerIndex := 0;
                    recordPerBatch := 0;
                    Clear(itemBatchBatch);
                    Clear(itemBatch);

                    recEbayListing.SetCurrentKey(LastAttempt);
                    recEbayListing.SetAscending(LastAttempt, true);
                    recEbayListing.SetRange(EbayAction, listingAction);
                    recEbayListing.SetRange(isCompleted, false);

                    if rec_EbaySettings.RecordsPerRun > recEbayListing.Count then begin
                        recordPerBatch := recEbayListing.Count;
                    end
                    else begin
                        recordPerBatch := rec_EbaySettings.RecordsPerRun;
                    end;

                    calculatedBatch := Round(recEbayListing.Count / recordPerBatch, 1, '<');

                    if rec_EbaySettings.BatchSize > calculatedBatch then begin
                        newBatchSize := calculatedBatch;
                    end else begin
                        newBatchSize := rec_EbaySettings.BatchSize;
                    end;

                    if recEbayListing.FindSet() then begin
                        repeat
                            batchOf := batchOf + 1;

                            // Create batch of x items
                            if batchOf <= recordPerBatch then begin
                                innerIndex := innerIndex + 1;
                                itemBatch.Add(innerIndex, recEbayListing.sku);
                            end
                            else begin // Add x items batch to another list
                                batchOf := 0;
                                innerIndex := 0;
                                outerIndex := outerIndex + 1;
                                itemBatchBatch.Add(outerIndex, itemBatch);
                                Clear(itemBatch);
                            end;

                        until (recEbayListing.Next() = 0) or (outerIndex = newBatchSize);

                        if itemBatch.Count >= 1 then begin
                            outerIndex := outerIndex + 1;
                            itemBatchBatch.Add(outerIndex, itemBatch);
                        end;
                    end;

                    // Pass batch of x, one by one to api
                    for indexMain := 1 to itemBatchBatch.Count do begin
                        sendItemBatch := itemBatchBatch.Get(indexMain);
                        batchListingJsonBody := '';

                        // Create JSON body of x items
                        batchListingJsonBody := CreateSingleListingJson(sendItemBatch, rec_EbaySettings, listingAction);

                        if batchListingJsonBody <> '' then begin
                            Clear(RESTAPIHelper);

                            if listingAction = 'CREATE' then begin
                                URI := RESTAPIHelper.GetBaseURl() + 'Ebay/BulkCreateListing';
                            end
                            else begin
                                // URI := RESTAPIHelper.GetBaseURl() + 'Ebay/UpdateListingWithOffer';
                                URI := RESTAPIHelper.GetBaseURl() + 'Ebay/TestUpdateListingWithOffer';
                            end;

                            RESTAPIHelper.Initialize('POST', URI);
                            RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                            RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());
                            RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);
                            RESTAPIHelper.AddBody(batchListingJsonBody);
                            RESTAPIHelper.SetContentType('application/json');

                            // API Call per Batch
                            if RESTAPIHelper.SendtoEbay(EnhIntegrationLogTypes::Ebay) then begin
                                result := RESTAPIHelper.GetResponseContentAsText();

                                if listingAction = 'CREATE' then begin
                                    cu_eBayCommonHelper.ReadBulkApiResponse(result, rec_EbaySettings);
                                end else begin
                                    cu_eBayCommonHelper.ReadUpdateBulkApiResponse(result);
                                end;
                            end
                            else begin
                                Message('An error occured while create listing, please check integration log');
                            end;
                            Sleep(2000);
                        end;
                    end;
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    procedure CreateSingleListingJson(itemBatch: Dictionary of [Integer, Text]; rec_eBaySetting: Record "ebay Setting"; listingAction: Text[50]): Text
    var
        title, brand, description, listingBody, offerBody, attributeValue, imageUrls, ind, descText, base64Data, descBase64Data, quantityLimitPerBuyer, htmlContent, fulfillmentPolicyId, listingDesc, singleListingBody, categoryId : Text;
        rec_Item: Record Item;
        quantity, index, element : Integer;
        listingBodyList, offerBodyList, descList : list of [Text];
        rec_Item_No: Code[20];
        LF, CR : char;
        cdu_Base64: Codeunit "Base64 Convert";
        isListingCreated, isOfferCreated : Boolean;
        salesPrice: Decimal;
        rec_EbayListing: Record EbayListing;
        webCategoryId: BigInteger;
        genProdPostingGroup: Record "Gen. Product Posting Group";
        recEbayItems: Record EbayItemsList;
        cuStockLevel: Codeunit StockLevel;

    begin
        singleListingBody := '';
        listingBody := '';
        offerBody := '';
        LF := 10;
        CR := 13;
        rec_Item.Reset();
        recEbayItems.Reset();

        for index := 1 to itemBatch.Count do begin
            descBase64Data := '';
            quantityLimitPerBuyer := '';
            htmlContent := '';
            imageUrls := '';
            title := '';
            descText := '';
            description := '';
            categoryId := '';
            brand := '';
            webCategoryId := 0;
            salesPrice := 0;
            isListingCreated := false;
            isOfferCreated := false;

            rec_Item_No := itemBatch.Get(index);

            recEbayItems.SetRange("No.", rec_Item_No);

            if recEbayItems.FindFirst() then begin

                rec_Item.SetRange("No.", rec_Item_No);

                if rec_Item.FindFirst() then begin

                    #region " Only for Last Attempt field "
                    rec_EbayListing.SetRange(sku, rec_Item."No.");
                    if rec_EbayListing.FindFirst() then begin
                        cu_eBayCommonHelper.UpdateLastAttempt(rec_EbayListing.Id);
                    end;
                    #endRegion

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

                    attributeValue := cu_eBayCommonHelper.GetItemAllAttributeValue(rec_Item, brand);

                    if (attributeValue = '') and (rec_Item."Primary Barcode" <> '') then begin
                        attributeValue := '"ean" : ["' + rec_Item."Primary Barcode" + '"]';
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

                    if imageUrls <> '' then begin
                        imageUrls := '"imageUrls":[' + imageUrls + '],';
                    end;

                    if (descBase64Data <> '') and (rec_Item."Primary Barcode" <> '') and (imageUrls <> '') then begin
                        isListingCreated := true;
                    end
                    else begin
                        cu_CommonHelper.InsertBusinessCentralErrorLog('Missing at least one image url, item description or barcode value', rec_Item_No, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                    end;
                    #endregion

                    #region " Offer "
                    if isListingCreated then begin
                        salesPrice := cu_eBayCommonHelper.CalculateSalesPrice(rec_Item);
                        fulfillmentPolicyId := cu_eBayCommonHelper.GetFulfillmentId(rec_Item);
                        listingDesc := cu_eBayCommonHelper.GetItemHTMLContent(rec_Item, salesPrice);
                        base64Data := cdu_Base64.ToBase64(listingDesc);

                        // eBay Brwose Node Field Id = 4
                        webCategoryId := cu_eBayCommonHelper.GetWebCategoryId(rec_Item_No, 4);

                        if webCategoryId > 0 then begin
                            categoryId := Format(webCategoryId);
                        end else begin
                            categoryId := rec_eBaySetting.categoryId;
                        end;

                        if base64Data <> '' then begin
                            htmlContent := '"listingDescription":"' + base64Data + '",';
                        end;

                        if rec_Item."Maximum Order Quantity" <> 0 then begin
                            quantityLimitPerBuyer := '"quantityLimitPerBuyer": "' + format(rec_Item."Maximum Order Quantity") + '",';
                        end;

                        if salesPrice <> 0 then begin
                            isOfferCreated := true;
                        end
                        else begin
                            cu_CommonHelper.InsertBusinessCentralErrorLog('Quantity/Price should be greater than 0', rec_Item_No, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                        end;
                        #endregion

                        if (isListingCreated) and (isOfferCreated) then begin
                            listingBodyList.Add('{ "availability": { "shipToLocationAvailability":{"quantity":"' + Format(quantity, 0, 1) + '"}},"condition":"NEW","locale": "en_GB","packageType": "PARCEL_OR_PADDED_ENVELOPE","product":{' + attributeValue + ',"brand":"' + brand + '","description":"' + descBase64Data + '", "ean" : ["' + rec_Item."Primary Barcode" + '"],"upc" : ["' + rec_Item."Primary Barcode" + '"],' + imageUrls + ' "mpn":"' + rec_Item."No." + '","title":"' + title + '"},"sku":"' + rec_Item."No." + '" }');

                            offerBodyList.Add('{ "offerId": "' + recEbayItems.Offer_ID + '","availableQuantity": "' + Format(quantity, 0, 1) + '","categoryId":"' + categoryId + '","format":"FIXED_PRICE","hideBuyerDetails":"True","includeCatalogProductDetails":"False",' + htmlContent + '"listingDuration":"GTC","listingPolicies":{"bestOfferTerms":{"bestOfferEnabled":"False"},"fulfillmentPolicyId":"' + fulfillmentPolicyId + '","paymentPolicyId":"' + rec_eBaySetting.paymentPolicyId + '","returnPolicyId":"' + rec_eBaySetting.returnPolicyId + '"},"marketplaceId":"EBAY_GB","merchantLocationKey":"' + rec_eBaySetting.MerchantLocationKey + '","pricingSummary":{"price":{"currency":"GBP","value":"' + format(Round(salesPrice, 0.01), 0, 1) + '"},' + quantityLimitPerBuyer + '"pricingVisibility":"NONE"},"sku":"' + rec_Item."No." + '"}');
                        end;
                    end;
                end;
            end;
        end;

        if (listingBodyList.Count <> 0) and (offerBodyList.Count <> 0) then begin

            #region " Listing Node "
            listingBody := '"listing":[';

            for element := 1 to listingBodyList.Count do begin
                if element <> listingBodyList.Count then
                    listingBody := listingBody + '' + listingBodyList.Get(element) + ','
                else
                    listingBody := listingBody + '' + listingBodyList.Get(element) + '';
            end;

            listingBody := listingBody + ']';
            #endregion

            #region " Offer Node "
            offerBody := '"offers":[';

            for element := 1 to offerBodyList.Count do begin
                if element <> offerBodyList.Count then
                    offerBody := offerBody + '' + offerBodyList.Get(element) + ','
                else
                    offerBody := offerBody + '' + offerBodyList.Get(element) + '';
            end;

            offerBody := offerBody + ']';
            #endregion

            singleListingBody := '{' + listingBody + ',' + offerBody + '}';
        end;

        exit(singleListingBody);
    end;
}
