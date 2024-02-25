codeunit 50431 EbayGetOfferedListing
{
    trigger OnRun()
    begin
        CreateOfferedBatch();
    end;

    var
        cu_CommonHelper: Codeunit CommonHelper;
        RESTAPIHelper: Codeunit "REST API Helper";
        TypeHelper: Codeunit "Type Helper";
        NYTJSONMgt: Codeunit "NYT JSON Mgt";
        rec_EbaySettings: Record "ebay Setting";
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;

    procedure sendEbayItemList(batchJsonBody: Text)
    var
        rec_Item: Record Item;
        quantity: Integer;
        reportIdList: list of [Text];
        reportIdBody: Text;
        element, sendCount : Integer;
        sendBody: Text;
        result, URI : text;
    begin
        Clear(RESTAPIHelper);
        Clear(URI);
        URI := RESTAPIHelper.GetBaseURl() + 'Ebay/GetOfferedListing';
        RESTAPIHelper.Initialize('POST', URI);
        rec_EbaySettings.Reset();

        if rec_EbaySettings.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat
                Clear(RESTAPIHelper);
                //Headers
                RESTAPIHelper.Initialize('POST', URI);

                RESTAPIHelper.AddRequestHeader('refresh_token', rec_EbaySettings.refresh_token.Trim());
                RESTAPIHelper.AddRequestHeader('oauth_credentials', rec_EbaySettings.oauth_credentials.Trim());

                RESTAPIHelper.AddRequestHeader('Environment', rec_EbaySettings.Environment);

                //Body
                RESTAPIHelper.AddBody(batchJsonBody);

                //ContentType
                RESTAPIHelper.SetContentType('application/json');

                if RESTAPIHelper.Send(EnhIntegrationLogTypes::Ebay) then begin
                    result := RESTAPIHelper.GetResponseContentAsText();
                    ReadApiResponse(result);
                    Sleep(1500);
                end;
            until rec_EbaySettings.Next() = 0;
        end;
    end;

    local procedure ReadApiResponse(var apiResponse: Text)
    var
        varJsonArray: JsonArray;
        varjsonToken: JsonToken;
        i: Integer;
        description: Text;
        eBaySku: Code[20];
        JObject: JsonObject;
        recEbayListing: Record EbayListing;
        recItem: Record Item;
        recEbayItems: Record EbayItemsList;
    begin
        if not JObject.ReadFrom(apiResponse) then
            Error('Invalid response, expected a JSON object');

        JObject.Get('listing', varjsonToken);

        if not varJsonArray.ReadFrom(Format(varjsonToken)) then
            Error('Array not Reading Properly');

        if varJsonArray.ReadFrom(Format(varjsonToken)) then begin
            for i := 0 to varJsonArray.Count - 1 do begin
                varJsonArray.Get(i, varjsonToken);

                eBaySku := NYTJSONMgt.GetValueAsText(varjsonToken, 'sku');
                recEbayListing.Init();
                recEbayListing.Id := GetLastLineNo();
                recEbayListing.sku := eBaySku;
                recEbayListing.EbayAction := NYTJSONMgt.GetValueAsText(varjsonToken, 'action');
                recEbayListing.listingId := NYTJSONMgt.GetValueAsText(varjsonToken, 'listingId');
                recEbayListing.Insert();

                // recItem.SetRange("No.", eBaySku);

                // if recItem.FindFirst() then begin
                //     recItem.Offer_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'offerId');
                //     recItem.Listing_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'listingId');
                //     recItem.Modify(true);
                // end;

                recEbayItems.Reset();
                recEbayItems.SetRange("No.", eBaySku);

                if recEbayItems.FindFirst() then begin
                    recEbayItems.Offer_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'offerId');
                    recEbayItems.Listing_ID := NYTJSONMgt.GetValueAsText(varjsonToken, 'listingId');
                    recEbayItems.Modify(true);
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
        Commit();
    end;

    procedure CreateOfferedBatch()
    var
        rec_Item: Record Item;
        itemBatch, sendItemBatch : Dictionary of [Integer, Text];
        itemBatchBatch: Dictionary of [Integer, Dictionary of [Integer, Text]];
        index, outerIndex, innerIndex, batchOf300 : Integer;
        batchJsonBody: Text;
        recEbayListing: Record EbayListing;
    begin
        batchOf300 := 0;
        outerIndex := 0;
        innerIndex := 0;
        rec_Item.Reset();

        recEbayListing.DeleteAll(true);
        rec_Item.SetRange(Blocked, false);
        rec_Item.SetRange(Enabled_ebay, true);

        // Get all items of eBay
        if rec_Item.FindSet() then begin
            repeat
                batchOf300 := batchOf300 + 1;

                // Create batch of 300 items
                if batchOf300 <= 300 then begin
                    innerIndex := innerIndex + 1;
                    itemBatch.Add(innerIndex, rec_Item."No.");
                end
                else begin // Add 300 items batch to another list
                    batchOf300 := 0;
                    innerIndex := 0;
                    outerIndex := outerIndex + 1;
                    itemBatchBatch.Add(outerIndex, itemBatch);
                    Clear(itemBatch);
                end;
            until rec_Item.Next() = 0;

            outerIndex := outerIndex + 1;
            itemBatchBatch.Add(outerIndex, itemBatch);
        end;

        // Pass batch of 300 one by one to api
        for index := 1 to itemBatchBatch.Count do begin
            sendItemBatch := itemBatchBatch.Get(index);

            //Create JSON body of 300 items
            batchJsonBody := SendeBaySKUList(sendItemBatch, index);
            // API Call per Batch
            sendEbayItemList(batchJsonBody);
            Sleep(1500);
        end
    end;

    procedure SendeBaySKUList(itemBatch: Dictionary of [Integer, Text]; batchId: integer): Text
    var
        rec_Item: Record Item;
        rec_EbayItems: Record EbayItemsList;
        offerBody: text;
        element, index : Integer;
        offerList: list of [Text];
        isVariation: Boolean;
        recSubstitution: Record "Item Substitution";
        salesPrice, quantity : Decimal;
        rec_Item_No: Code[50];
        listingAction: Text;
        cuStockLevel: Codeunit StockLevel;
    begin
        rec_Item.Reset();
        rec_EbayItems.Reset();

        for index := 1 to itemBatch.Count do begin
            rec_Item_No := itemBatch.Get(index);

            rec_EbayItems.SetRange("No.", rec_Item_No);

            if rec_EbayItems.FindFirst() then begin
                rec_Item.SetRange("No.", rec_Item_No);

                if rec_Item.FindFirst() then begin
                    recSubstitution.SetRange("No.", rec_Item."No.");

                    if not recSubstitution.FindFirst() then begin

                        //quantity := (cu_eBayCommonHelper.CalculateAvailbleStock(rec_Item) + cu_eBayCommonHelper.getQtyCanBeAssembled(rec_Item."No.")) - rec_Item.Reserve_Stock_ebay;

                        quantity := cuStockLevel.GetQuantity(rec_Item."No.", true);

                        if (quantity < 0) then begin
                            quantity := 0;
                        end;

                        if quantity > 20 then begin
                            quantity := 20;
                        end;

                        isVariation := FindItemSubstitution(rec_Item);

                        if rec_Item.OVERRIDE_PRICE > 0 then begin
                            salesPrice := rec_Item.OVERRIDE_PRICE;
                        end else begin
                            salesPrice := cu_eBayCommonHelper.CalculateSalesPrice(rec_Item);
                        end;

                        // UPDATE Listing
                        if (rec_EbayItems.Listing_ID <> '') and ((rec_EbayItems.LAST_PRICE <> salesPrice) or (rec_EbayItems.ForceUpdate = true)) then begin
                            offerList.Add('{"sku": "' + rec_EbayItems."No." + '", "action": "UPDATE"}');
                        end else
                            // Create Listing
                            if (rec_EbayItems.Listing_ID = '') then begin
                                if isVariation then begin
                                    listingAction := 'CREATE_GROUP';
                                end else begin
                                    listingAction := 'CREATE';
                                end;

                                offerList.Add('{"sku": "' + rec_EbayItems."No." + '", "action": "' + listingAction + '"}');
                            end;
                    end;
                end;
            end;
        end;

        offerBody := '[';

        for element := 1 to offerList.Count do begin
            if element <> offerList.Count then
                offerBody := offerBody + '' + offerList.Get(element) + ','
            else
                offerBody := offerBody + '' + offerList.Get(element) + '';
        end;
        offerBody := offerBody + ']';

        exit(offerBody);

    end;

    local procedure FindItemSubstitution(Item: Record Item): Boolean
    var
        recSubstitution: Record "Item Substitution";
        recItem: Record Item;
        isVariation: Boolean;
    begin
        isVariation := false;
        recSubstitution.SetRange("Substitute No.", Item."No.");

        if recSubstitution.FindFirst() then begin
            isVariation := true;
        end;

        exit(isVariation);
    end;

    procedure GetLastLineNo(): Integer
    var
        Id: Integer;
        rec: Record EbayListing;
    begin

        if rec.FindLast() then
            Id := rec.Id + 1
        else
            id := 1;
        exit(Id)
    end;
}
