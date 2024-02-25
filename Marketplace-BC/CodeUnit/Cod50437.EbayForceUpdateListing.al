codeunit 50437 EbayForceUpdateListing
{
    var
        cu_CommonHelper: Codeunit CommonHelper;
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;
        RESTAPIHelper: Codeunit "REST API Helper";

    procedure SendToAPIUpdateListing(itemNo: Code[50])
    var
        singleListingBody, URI, result : Text;
        rec_eBaySettings: Record "ebay Setting";
    begin
        Clear(URI);
        rec_eBaySettings.Reset();

        if rec_eBaySettings.FindSet() then begin
            repeat
                singleListingBody := UpdateSingleListing(itemNo);

                if singleListingBody <> '' then begin
                    Clear(RESTAPIHelper);

                    URI := RESTAPIHelper.GetBaseURl() + 'Ebay/TestUpdateListingWithOffer';

                    RESTAPIHelper.Initialize('POST', URI);
                    RESTAPIHelper.AddRequestHeader('refresh_token', rec_eBaySettings.refresh_token.Trim());
                    RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_eBaySettings.oauth_credentials.Trim());
                    RESTAPIHelper.AddRequestHeader('Environment', rec_eBaySettings.Environment);

                    RESTAPIHelper.AddBody(singleListingBody);
                    Message(singleListingBody);
                    RESTAPIHelper.SetContentType('application/json');

                    // API Call
                    if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                        result := RESTAPIHelper.GetResponseContentAsText();
                        //cu_eBayCommonHelper.ReadUpdateBulkApiResponse(result);
                    end
                    else begin
                        Message('An error occured while create listing, please check integration log');
                    end;
                end;
            until rec_eBaySettings.Next() = 0;
        end;
    end;

    procedure UpdateSingleListing(itemNo: Code[50]): Text
    var
        title, brand, description, listingBody, offerBody, attributeValue, imageUrls, ind, descText, base64Data, descBase64Data, quantityLimitPerBuyer, htmlContent, fulfillmentPolicyId, listingDesc, singleListingBody, categoryId : Text;
        rec_Item: Record Item;
        quantity, element : Integer;
        descList: list of [Text];
        LF, CR : char;
        cdu_Base64: Codeunit "Base64 Convert";
        isListingCreated, isOfferCreated : Boolean;
        salesPrice: Decimal;
        rec_eBaySetting: Record "ebay Setting";
        webCategoryId: BigInteger;
        genProdPostingGroup: Record "Gen. Product Posting Group";
        recEbayItems: Record EbayItemsList;
        cuStockLevel: Codeunit StockLevel;

    begin
        recEbayItems.Reset();
        rec_Item.Reset();

        recEbayItems.SetRange("No.", itemNo);

        if recEbayItems.FindFirst() then begin

            rec_Item.SetRange("No.", itemNo);

            if rec_Item.FindFirst() then begin
                descBase64Data := '';
                quantityLimitPerBuyer := '';
                htmlContent := '';
                imageUrls := '';
                title := '';
                categoryId := '';
                brand := '';
                webCategoryId := 0;
                isListingCreated := false;
                isOfferCreated := false;

                title := cdu_Base64.ToBase64(rec_Item.Description);

                if rec_Item.ALT_TITLE <> '' then begin
                    title := cdu_Base64.ToBase64(rec_Item.ALT_TITLE);
                end;

                //quantity := (cu_eBayCommonHelper.CalculateAvailbleStock(rec_Item) + cu_eBayCommonHelper.GetQtyCanBeAssembled(itemNo)) - rec_Item.Reserve_Stock_ebay;

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
                    cu_CommonHelper.InsertBusinessCentralErrorLog('Missing at least one image url, item description or barcode value', itemNo, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                end;
                #endregion

                #region " Offer "
                if isListingCreated then begin
                    salesPrice := cu_eBayCommonHelper.CalculateSalesPrice(rec_Item);
                    fulfillmentPolicyId := cu_eBayCommonHelper.GetFulfillmentId(rec_Item);
                    listingDesc := cu_eBayCommonHelper.GetItemHTMLContent(rec_Item, salesPrice);
                    base64Data := cdu_Base64.ToBase64(listingDesc);

                    if base64Data <> '' then begin
                        htmlContent := '"listingDescription":"' + base64Data + '",';
                    end;

                    if rec_Item."Maximum Order Quantity" <> 0 then begin
                        quantityLimitPerBuyer := '"quantityLimitPerBuyer": "' + format(rec_Item."Maximum Order Quantity") + '",';
                    end;

                    if (quantity <> 0) or (salesPrice <> 0) then begin
                        isOfferCreated := true;
                    end
                    else begin
                        cu_CommonHelper.InsertBusinessCentralErrorLog('Quantity/Price should be greater than 0', itemNo, EnhIntegrationLogTypes::Ebay, true, 'SKU');
                    end;
                    #endregion

                    if (isListingCreated) and (isOfferCreated) then begin
                        listingBody := '"listing":[{ "availability": { "shipToLocationAvailability":{"quantity":"' + Format(quantity, 0, 1) + '"}},"condition":"NEW","locale": "en_GB","packageType": "PARCEL_OR_PADDED_ENVELOPE","product":{' + attributeValue + ',"brand":"' + brand + '","description":"' + descBase64Data + '", "ean" : ["' + rec_Item."Primary Barcode" + '"],"upc" : ["' + rec_Item."Primary Barcode" + '"],' + imageUrls + ' "mpn":"' + rec_Item."No." + '","title":"' + title + '"},"sku":"' + rec_Item."No." + '" }]';

                        if rec_eBaySetting.FindFirst() then begin
                            // eBay Brwose Node Field Id = 4
                            webCategoryId := cu_eBayCommonHelper.GetWebCategoryId(itemNo, 4);

                            if webCategoryId > 0 then begin
                                categoryId := Format(webCategoryId);
                            end else begin
                                categoryId := rec_eBaySetting.categoryId;
                            end;

                            if cu_eBayCommonHelper.IsParentItem(itemNo) then begin
                                offerBody := '"offers":[{}]';
                            end else begin
                                offerBody := '"offers":[{ "offerId": "' + recEbayItems.Offer_ID + '","availableQuantity": "' + Format(quantity, 0, 1) + '","categoryId":"' + categoryId + '","format":"FIXED_PRICE","hideBuyerDetails":"True","includeCatalogProductDetails":"False",' + htmlContent + '"listingDuration":"GTC","listingPolicies":{"bestOfferTerms":{"bestOfferEnabled":"False"},"fulfillmentPolicyId":"' + fulfillmentPolicyId + '","paymentPolicyId":"' + rec_eBaySetting.paymentPolicyId + '","returnPolicyId":"' + rec_eBaySetting.returnPolicyId + '"},"marketplaceId":"EBAY_GB","merchantLocationKey":"' + rec_eBaySetting.MerchantLocationKey + '","pricingSummary":{"price":{"currency":"GBP","value":"' + format(Round(salesPrice, 0.01), 0, 1) + '"},' + quantityLimitPerBuyer + '"pricingVisibility":"NONE"},"sku":"' + rec_Item."No." + '"}]';
                            end;
                        end;

                        singleListingBody := '{' + listingBody + ',' + offerBody + '}';
                    end;
                end;
            end;
        end;
        exit(singleListingBody);
    end;
}
