tableextension 50407 "Item Table Extension" extends Item
{
    fields
    {
        field(50400; RRP; Decimal)
        {
            Caption = 'RRP';
            DataClassification = ToBeClassified;
        }
        field(50401; Enabled_Appeagle; Boolean)
        {
            Caption = 'Enabled Appeagle';
            DataClassification = ToBeClassified;
        }
        field(50402; AMAZON_API_WEIGHT; Decimal)
        {
            Caption = 'Amazon API Weight';
            CalcFormula = lookup(ItemDimensions.API_Weight where(FBA_SKU = field(FBA_SKU)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(50403; ASIN; Text[100])
        {
            Caption = ' Amazon’s code for the item';
            CalcFormula = lookup(ItemDimensions.ASIN where(FBA_SKU = field(FBA_SKU)));
            Editable = false;
            FieldClass = FlowField;
            // DataClassification = ToBeClassified;
        }

        field(50404; AMAZON_API_LENGTH; Decimal)
        {
            Caption = 'Amazon API Length';
            CalcFormula = lookup(ItemDimensions.API_Length where(FBA_SKU = field(FBA_SKU)));
            Editable = false;
            FieldClass = FlowField;
            //DataClassification = ToBeClassified;

        }
        field(50405; AMAZON_API_WIDTH; Decimal)
        {
            Caption = 'Amazon API Width';
            CalcFormula = lookup(ItemDimensions.API_Width where(FBA_SKU = field(FBA_SKU)));
            Editable = false;
            FieldClass = FlowField;
            //DataClassification = ToBeClassified;

        }
        field(50406; AMAZON_API_HEIGHT; Decimal)
        {
            Caption = 'Amazon API Height';
            CalcFormula = lookup(ItemDimensions.API_Height where(FBA_SKU = field(FBA_SKU)));
            Editable = false;
            FieldClass = FlowField;
            //DataClassification = ToBeClassified;
        }
        field(50407; FBA_MIN_PRICE_OVERRIDE; Decimal)
        {
            Caption = 'FBA Min Price Override';
            DataClassification = ToBeClassified;
        }
        field(50408; FBA_MAX_PRICE_OVERRIDE; Decimal)
        {
            Caption = 'FBA Max Price Override';
            DataClassification = ToBeClassified;
        }
        field(50409; EFN_PRICE_OVERRIDE; Decimal)
        {
            Caption = 'EFN Price Override';
            DataClassification = ToBeClassified;
        }
        field(50410; LAST_CHECKED_DATE; Date)
        {
            Caption = 'Last Checked Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50411; CodeItem; Text[100])
        {
            Caption = 'Code';
            DataClassification = ToBeClassified;
        }
        field(50412; ValueItem; Text[100])
        {
            Caption = 'Value';
            DataClassification = ToBeClassified;
        }
        field(50413; ACTIVE_ON_ONBUY; Boolean)
        {
            Caption = 'Active on Onbuy';
            DataClassification = ToBeClassified;
        }
        field(50414; LAST_ONBUY_STOCK_LEVELS; Integer)
        {
            Caption = ' Last Onbuy Stock Levels';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50415; LAST_REFRESH_DATE; Date)
        {
            Caption = 'Last Refresh Date';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50416; PREVIOUS_PRICE; Decimal)
        {
            Caption = 'Previous Price';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50417; RESERVE_STOCK; Integer)
        {
            Caption = 'Reserve Stock';
            DataClassification = ToBeClassified;
        }
        field(50418; AMAZON_BROWSE_NODE; BigInteger)
        {
            Caption = 'Amazon Browse Node';
            DataClassification = ToBeClassified;
        }
        field(50419; FBA_SKU; Text[100])
        {
            Caption = 'FBA SKU ';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                recItemDimensions: Record ItemDimensions;
            begin
                recItemDimensions.Reset();
                recItemDimensions.SetRange(No, Rec."No.");

                if not recItemDimensions.FindFirst() then begin

                    recItemDimensions.Init();
                    recItemDimensions.Id := GetLastLineNo();
                    recItemDimensions.No := Rec."No.";
                    recItemDimensions.FBA_SKU := Rec.FBA_SKU;
                    recItemDimensions.Insert(true);
                end
                else begin

                    if Rec.FBA_SKU = '' then begin
                        recItemDimensions.Delete(true);
                    end
                    else begin
                        recItemDimensions.FBA_SKU := Rec.FBA_SKU;
                        recItemDimensions.Modify(true);
                    end;
                end;
            end;
        }
        field(50420; EFN_APPEAGLE; Boolean)
        {
            Caption = 'EFN Appeagle  ';
            DataClassification = ToBeClassified;
        }
        field(50421; FBA_APPEAGLE; Boolean)
        {
            Caption = 'FBA Appeagle ';
            DataClassification = ToBeClassified;
        }
        field(50422; SHOW_ON_AMAZON; Boolean)
        {
            Caption = 'Show on Amazon';
            DataClassification = ToBeClassified;
        }
        field(50423; NON_LIST_STOCK; Integer)
        {
            Caption = 'Non List Stock';
            DataClassification = ToBeClassified;
        }
        field(50424; AMAZON_DESCRIPTION; Text[2048])
        {
            Caption = 'Amazon Description';
            DataClassification = ToBeClassified;
        }
        field(50425; DO_NOT_APPLY_LINKED_ITEM; Boolean)
        {
            Caption = 'Do Not Apply Linked Items';
            DataClassification = ToBeClassified;
        }
        field(50426; EXCLUDED_MAIN_FEED; Boolean)
        {
            Caption = 'Excluded Main Feed';
            DataClassification = ToBeClassified;
        }
        field(50427; ALT_TITLE; Text[80])
        {
            Caption = 'ALT Title ';
            DataClassification = ToBeClassified;
        }
        field(50428; OVERRIDE_PRICE; Decimal)
        {
            Caption = 'Override Price';
            DataClassification = ToBeClassified;
        }
        field(50429; Enabled_ebay; Boolean)
        {
            Caption = 'Enabled on eBay';
            DataClassification = ToBeClassified;
        }
        field(50430; Reserve_Stock_ebay; Integer)
        {
            Caption = 'ReserveStock on ebay';
            DataClassification = ToBeClassified;
        }
        field(50431; EBAY_SHIPPING_POLICY; Text[100])
        {
            Caption = 'EBAY Shipping Policy';
            DataClassification = ToBeClassified;
        }
        field(50433; LAST_UPDATE; Date)
        {
            Caption = 'Last Update';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50434; LARGE_IMAGE_5; Text[500])
        {
            Caption = 'Large Image 5';
            DataClassification = ToBeClassified;
        }
        field(50435; LARGE_IMAGE_6; Text[500])
        {
            Caption = 'Large Image 6';
            DataClassification = ToBeClassified;
        }
        field(50436; LARGE_IMAGE_2; Text[500])
        {
            Caption = 'Large Image 2';
            DataClassification = ToBeClassified;
        }
        field(50437; LARGE_IMAGE_3; Text[500])
        {
            Caption = 'Large Image 3';
            DataClassification = ToBeClassified;
        }
        field(50438; LARGE_IMAGE_4; Text[500])
        {
            Caption = 'Large Image 4';
            DataClassification = ToBeClassified;
        }
        field(50439; PDF_NAME; Text[200])
        {
            Caption = 'PDF Name';
            DataClassification = ToBeClassified;
        }
        field(50440; YOU_TUBE_1; Text[500])
        {
            Caption = 'You Tube 1 ';
            DataClassification = ToBeClassified;
        }
        field(50441; YOU_TUBE_2; Text[500])
        {
            Caption = 'You Tube 2 ';
            DataClassification = ToBeClassified;
        }
        field(50442; YOU_TUBE_3; Text[500])
        {
            Caption = 'You Tube 3 ';
            DataClassification = ToBeClassified;
        }
        field(50443; YOU_TUBE_4; Text[500])
        {
            Caption = 'You Tube 4';
            DataClassification = ToBeClassified;
        }
        field(50444; GUARANTEE; Text[2048])
        {
            Caption = 'Guarantee';
            DataClassification = ToBeClassified;
        }
        field(50445; MAGENTO_ID; Integer)
        {
            Caption = 'Magento ID';
            DataClassification = ToBeClassified;
        }
        field(50446; HIDE_FROM_WEBSITE; Boolean)
        {
            Caption = 'Hide From Website';
            DataClassification = ToBeClassified;
        }
        field(50448; SHIPPING_GROUP; Text[40])
        {
            Caption = 'Shipping Group';
            DataClassification = ToBeClassified;
        }
        field(50449; LAST_MAGENTO_STOCK_LEVEL; Integer)
        {
            Caption = 'LastMagentoStockLevel';
            DataClassification = ToBeClassified;

        }
        field(50450; LAST_UPLOADED_YOU_TUBE_1; Text[2048])
        {
            Caption = 'Last Uploaded You Tube 1';
            DataClassification = ToBeClassified;

        }
        field(50451; LAST_UPLOADED_YOU_TUBE_2; Text[2048])
        {
            Caption = 'Last Uploaded You Tube 2';
            DataClassification = ToBeClassified;

        }
        field(50452; LAST_UPLOADED_YOU_TUBE_3; Text[2048])
        {
            Caption = 'Last Uploaded You Tube 3';
            DataClassification = ToBeClassified;

        }
        field(50453; LAST_UPLOADED_YOU_TUBE_4; Text[2048])
        {
            Caption = 'Last Uploaded You Tube 4';
            DataClassification = ToBeClassified;

        }
        field(50454; YOU_TUBE_MAGENTO_ID_1; Integer)
        {
            Caption = 'You Tube Magento ID 1';
            DataClassification = ToBeClassified;

        }
        field(50455; YOU_TUBE_MAGENTO_ID_2; Integer)
        {
            Caption = 'You Tube Magento ID 2';
            DataClassification = ToBeClassified;

        }
        field(50456; YOU_TUBE_MAGENTO_ID_3; Integer)
        {
            Caption = 'You Tube Magento ID 3';
            DataClassification = ToBeClassified;

        }
        field(50457; YOU_TUBE_MAGENTO_ID_4; Integer)
        {
            Caption = 'You Tube Magento ID 4';
            DataClassification = ToBeClassified;

        }
        field(50458; FULL_DESCRIPITION; Text[2048])
        {
            Caption = 'Full Description';
            DataClassification = ToBeClassified;
        }
        field(50459; SHORT_DESCRIPTION; Text[255])
        {
            Caption = 'Short Description';
            DataClassification = ToBeClassified;
        }
        field(50460; IMAGE_FILE_NAME; Text[255])
        {
            Caption = 'Image File Name';
            DataClassification = ToBeClassified;
        }
        field(50461; THUMB_NAIL_IMAGE; Text[255])
        {
            Caption = 'Thumb Nail Image';
            DataClassification = ToBeClassified;
        }
        field(50462; SINGLE_PRODUCT_PAGE_NAME; Text[2048])
        {
            Caption = 'Single Product Page Name';
            DataClassification = ToBeClassified;
        }
        field(50463; MANUFACTURER; Text[200])
        {
            Caption = 'Manufacturer';
            DataClassification = ToBeClassified;
        }
        field(50464; RESTRICTED_18; Boolean)
        {
            Caption = 'Restricted 18';
            DataClassification = ToBeClassified;

        }
        field(50465; Extended_Info_Text; Text[2048])
        {
            Caption = 'Extended Info Text';
            DataClassification = ToBeClassified;
        }
        field(50466; SHOP_LIST; Text[100])
        {
            Caption = 'Shop List ';
            DataClassification = ToBeClassified;
            TableRelation = "Shop Lists";
        }
        field(50467; LAST_FULL_REFRESH; Date)
        {
            Caption = 'Last Full Refresh';
            DataClassification = ToBeClassified;
        }
        field(50468; LAST_LEVEL_REFRESH; Date)
        {
            Caption = 'Last Level Refresh';
            DataClassification = ToBeClassified;
        }
        field(50469; MARGIN_PROTECTION; Decimal)
        {
            Caption = 'Margin Protection';
            DataClassification = ToBeClassified;
        }
        field(50470; BUBBLE_WRAP; Boolean)
        {
            Caption = 'Bubble Wrap ';
            DataClassification = ToBeClassified;
        }
        field(50471; AMAZON_LABEL; Boolean)
        {
            Caption = 'Amazon Label';
            DataClassification = ToBeClassified;
        }
        field(50472; ROUNDEL; Text[20])
        {
            Caption = 'Roundel';
            DataClassification = ToBeClassified;
        }
        field(50473; RELATED_RANGE; Text[10])
        {
            Caption = 'Related Range';
            DataClassification = ToBeClassified;
        }
        field(50474; NOT_VISIBLE_INDIVIDUALLY; Boolean)
        {
            Caption = 'Not Visible Individually';
            DataClassification = ToBeClassified;
        }
        field(50475; TAB_NAME; Text[50])
        {
            Caption = 'Tab Name';
            DataClassification = ToBeClassified;
        }
        field(50476; TAB_CONTENT; Text[2048])
        {
            Caption = 'Tab Content';
            DataClassification = ToBeClassified;
        }
        field(50477; SORT; Integer)
        {
            Caption = 'Sort';
            DataClassification = ToBeClassified;
        }
        field(50478; HTML; Text[2048])
        {
            Caption = 'HTML';
            DataClassification = ToBeClassified;
        }
        field(50479; TAGLINE; Text[200])
        {
            Caption = 'Tagline';
            DataClassification = ToBeClassified;
        }
        field(50480; PARENT_CODE; Text[200])
        {
            Caption = 'Parent-Code';
            DataClassification = ToBeClassified;
        }
        field(50481; CHILD_CODE; Text[200])
        {
            Caption = 'Child-Code';
            DataClassification = ToBeClassified;
        }
        field(50482; CAPTION_2; Text[200])
        {
            Caption = 'Caption 2';
            DataClassification = ToBeClassified;
        }
        field(50483; VALUE_2; Text[200])
        {
            Caption = 'Value 2';
            DataClassification = ToBeClassified;
        }
        field(50484; CAPTION; Text[200])
        {
            Caption = 'Caption';
            DataClassification = ToBeClassified;
        }
        field(50485; VALUE_1; Text[200])
        {
            Caption = 'Value 1';
            DataClassification = ToBeClassified;
        }
        field(50486; PRICE_OVERRIDE; Decimal)
        {
            Caption = 'Price Override';
            DataClassification = ToBeClassified;
        }
        field(50487; PARCEL_SIZE; Text[20])
        {
            Caption = 'Parcel Size';
            DataClassification = ToBeClassified;
        }

        field(50488; APPEAGLE_PRICE; Decimal)
        {
            Caption = 'AppEagle Price';
            DataClassification = ToBeClassified;
        }
        field(50489; TotalReturn; Decimal)
        {
            Caption = 'Total Returned';
            DataClassification = ToBeClassified;
        }
        field(50490; FULL_DESCRIPITION_CONTINUED; Text[2048])
        {
            Caption = 'Full descrition continued';
            DataClassification = ToBeClassified;
        }
        field(50491; LAST_PRICE; Decimal)
        {
            Caption = 'Last Price';
            DataClassification = ToBeClassified;
        }
        field(50492; LAST_INVENTORY; Decimal)
        {
            Caption = 'Last Inventory';
            DataClassification = ToBeClassified;
        }
        field(50493; Listing_ID; Text[100])
        {
            Caption = 'Listing ID';
            CalcFormula = lookup(EbayItemsList.Listing_ID where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(50494; Offer_ID; Text[100])
        {
            Caption = 'Offer ID';
            CalcFormula = lookup(EbayItemsList.Offer_ID where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50495; eBay_PRICE; Decimal)
        {
            Caption = 'eBay Price';
            CalcFormula = lookup(EbayItemsList.LAST_PRICE where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        field(50496; eBay_INVENTORY; Decimal)
        {
            Caption = 'eBay Inventory';
            CalcFormula = lookup(EbayItemsList.LAST_INVENTORY where("No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }

        modify(SHOW_ON_AMAZON)
        {
            trigger OnAfterValidate()
            var
                recAmazonItemStock: Record AmazonItemsStockLevel;
            begin


                if (Rec.Blocked = true) or (Rec.SHOW_ON_AMAZON = false) then begin
                    recAmazonItemStock.Reset();
                    recAmazonItemStock.SetRange(ItemNo, Rec."No.");

                    if recAmazonItemStock.FindFirst() then begin
                        recAmazonItemStock.isBlocked := true;
                        recAmazonItemStock.isSent := false;
                        recAmazonItemStock.Modify(true);
                    end;
                end;

                if (Rec.Blocked = false) and (Rec.SHOW_ON_AMAZON = true) then begin

                    recAmazonItemStock.Reset();
                    recAmazonItemStock.SetRange(ItemNo, Rec."No.");

                    if recAmazonItemStock.FindFirst() then begin
                        recAmazonItemStock.isBlocked := false;
                        recAmazonItemStock.isSent := false;
                        recAmazonItemStock.Modify(true);
                    end;
                end;
            end;
        }

        modify(Blocked)
        {
            trigger OnAfterValidate()
            var
                cuEbayListing: Codeunit EbayDeleteItem;
                recEbayItems: Record EbayItemsList;
                cuEbayCommonHelper: Codeunit EbayCommonHelper;
                recAmazonItemStock: Record AmazonItemsStockLevel;
            begin
                Rec.CalcFields(Offer_ID);
                Rec.CalcFields(Listing_ID);

                if (Rec.Enabled_ebay = true) and (Rec.Blocked = true) and ((Rec.Offer_ID <> '') or (Rec.Listing_ID <> '')) then begin
                    cuEbayListing.sendToDeleteInventoryItems(Rec."No.");
                end;

                if (rec.Enabled_ebay = false) or (Rec.Blocked = true) then begin

                    recEbayItems.Reset();
                    recEbayItems.SetRange("No.", rec."No.");

                    if recEbayItems.FindFirst() then begin
                        recEbayItems.DeleteAll();
                    end;
                end;

                if (rec.Enabled_ebay = true) and (Rec.Blocked = false) then begin
                    recEbayItems.SetRange("No.", Rec."No.");
                    if not recEbayItems.FindFirst() then begin
                        recEbayItems.Init();
                        recEbayItems.Id := cuEbayCommonHelper.GetLastLineNo();
                        recEbayItems."No." := Rec."No.";
                        recEbayItems.Insert(true);
                    end;
                end;

                if (Rec.Blocked = true) or (Rec.SHOW_ON_AMAZON = false) then begin
                    recAmazonItemStock.Reset();
                    recAmazonItemStock.SetRange(ItemNo, Rec."No.");

                    if recAmazonItemStock.FindFirst() then begin
                        recAmazonItemStock.isBlocked := true;
                        recAmazonItemStock.isSent := false;
                        recAmazonItemStock.Modify(true);
                    end;
                end;

                if (Rec.Blocked = false) and (Rec.SHOW_ON_AMAZON = true) then begin

                    recAmazonItemStock.Reset();
                    recAmazonItemStock.SetRange(ItemNo, Rec."No.");

                    if recAmazonItemStock.FindFirst() then begin
                        recAmazonItemStock.isBlocked := false;
                        recAmazonItemStock.isSent := false;
                        recAmazonItemStock.Modify(true);
                    end;
                end;
            end;
        }
        modify(Enabled_ebay)
        {
            trigger OnAfterValidate()
            var
                cuEbayListing: Codeunit EbayDeleteItem;
                recEbayItems: Record EbayItemsList;
                cuEbayCommonHelper: Codeunit EbayCommonHelper;

            begin
                Rec.CalcFields(Offer_ID);
                Rec.CalcFields(Listing_ID);

                if (Rec.Enabled_ebay = false) and ((Rec.Offer_ID <> '') or (Rec.Listing_ID <> '')) then begin
                    cuEbayListing.sendToDeleteInventoryItems(Rec."No.");
                end;

                if (rec.Enabled_ebay = true) and (Rec.Blocked = false) then begin

                    recEbayItems.SetRange("No.", Rec."No.");
                    if not recEbayItems.FindFirst() then begin

                        recEbayItems.Init();
                        recEbayItems.Id := cuEbayCommonHelper.GetLastLineNo();
                        recEbayItems."No." := Rec."No.";
                        recEbayItems.Insert(true);
                    end;
                end;

                if (rec.Enabled_ebay = false) or (Rec.Blocked = true) then begin

                    recEbayItems.Reset();
                    recEbayItems.SetRange("No.", rec."No.");

                    if recEbayItems.FindFirst() then begin
                        recEbayItems.DeleteAll();
                    end;
                end;
            end;


        }


    }

    keys
    {
        key(FBA_SKU; FBA_SKU)
        {

        }
        key("No."; "No.")
        {
        }
    }

    trigger OnAfterDelete()
    var
        cuEbayListing: Codeunit EbayDeleteItem;
        recItemDimensions: Record ItemDimensions;
    begin
        Rec.CalcFields(Offer_ID);
        Rec.CalcFields(Listing_ID);

        if (Rec.Enabled_ebay = false) and ((Rec.Offer_ID <> '') or (Rec.Listing_ID <> '')) then begin
            cuEbayListing.sendToDeleteInventoryItems(Rec."No.");
        end;

        recItemDimensions.Reset();
        recItemDimensions.SetRange(FBA_SKU, Rec.FBA_SKU);
        if recItemDimensions.FindFirst() then begin
            recItemDimensions.Delete(true);
        end;
    end;

    procedure GetLastLineNo(): Integer
    var
        Id: Integer;
        recItemDimensions: Record ItemDimensions;
    begin

        if recItemDimensions.FindLast() then
            Id := recItemDimensions.Id + 1
        else
            id := 1;
        exit(Id)
    end;


}
