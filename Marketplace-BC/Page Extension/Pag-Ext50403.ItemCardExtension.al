pageextension 50406 ItemCardExtension extends "Item Card"
{

    layout
    {
        addlast(Item)
        {
            field("Restricted18"; Rec.RESTRICTED_18)
            {
                ApplicationArea = All;
                Caption = 'Restricted 18';
            }
            field("Extended_Info_Text"; Rec.Extended_Info_Text)
            {
                ApplicationArea = All;
                Caption = 'Extended Info Text';
                MultiLine = true;
            }
            field("ShopList"; Rec.SHOP_LIST)
            {
                ApplicationArea = All;
                Caption = 'Shop List';
            }
            field("MarginProtection"; Rec.MARGIN_PROTECTION)
            {
                ApplicationArea = All;
                Caption = 'Margin Protection';
            }
        }

        addafter(Warehouse)
        {

            group(Appeagle)
            {

                field("Enabled_Appeagle"; Rec.Enabled_Appeagle)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled Appeagle';

                    trigger OnValidate()
                    begin
                        if Rec.Enabled_Appeagle then
                            isVisible := true
                        else
                            isVisible := false

                    end;
                }
                field(ParcelSize; Rec.PARCEL_SIZE)
                {
                    ApplicationArea = All;
                    Caption = 'Parcel Size';
                    TableRelation = AppeagleRates;

                }

                group("Hide1")
                {
                    ShowCaption = false;
                    Visible = isVisible;

                    field("RRP"; Rec.RRP)
                    {

                        ApplicationArea = All;
                        Caption = 'RRP';

                    }

                    field("AMAZON_API_WEIGHT"; Rec.AMAZON_API_WEIGHT)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon API Weight';
                    }
                    field("ASIN"; Rec.ASIN)
                    {
                        ApplicationArea = All;
                        Caption = 'ASIN';
                    }
                    field("Amazon API Length"; Rec.AMAZON_API_LENGTH)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon API Length';
                    }
                    field("AmazonAPIWidth"; Rec.AMAZON_API_WIDTH)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon API Width';
                    }
                    field("AmazonAPIHeight"; Rec.AMAZON_API_HEIGHT)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon API Height';
                    }
                    field("AppEagle Price"; Rec.APPEAGLE_PRICE)
                    {
                        ApplicationArea = All;
                        Caption = 'Appeagle Price';
                    }
                    field("FBAMinPriceOverride"; Rec.FBA_MIN_PRICE_OVERRIDE)
                    {
                        ApplicationArea = All;
                        Caption = 'FBA Min Price Override';
                    }
                    field("FBAMaxPriceOverride"; Rec.FBA_MAX_PRICE_OVERRIDE)
                    {
                        ApplicationArea = All;
                        Caption = 'FBA Max Price Override';
                    }
                    field("EFNPriceOverride"; Rec.EFN_PRICE_OVERRIDE)
                    {
                        ApplicationArea = All;
                        Caption = 'EFN Price Override';
                    }
                    field("LastCheckedDate"; Rec.LAST_CHECKED_DATE)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Checked Date';
                    }
                }
            }

            group(OnBuy)
            {

                field("ActiveonOnbuy"; Rec.ACTIVE_ON_ONBUY)
                {
                    ApplicationArea = All;
                    Caption = 'Active on Onbuy';
                    trigger OnValidate()
                    begin
                        if Rec.ACTIVE_ON_ONBUY then
                            isVisible2 := true
                        else
                            isVisible2 := false

                    end;
                }
                group("Hide2")
                {
                    ShowCaption = false;
                    Visible = isVisible2;
                    field("PriceOverride"; Rec.PRICE_OVERRIDE)
                    {
                        ApplicationArea = All;
                        Caption = 'Price Override';
                    }
                    field("LastOnbuyStockLevels"; Rec.LAST_ONBUY_STOCK_LEVELS)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Onbuy Stock Levels';
                    }
                    field("LastRefreshDate"; Rec.LAST_REFRESH_DATE)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Refresh Date';
                    }
                    field("PreviousPrice"; Rec.PREVIOUS_PRICE)
                    {
                        ApplicationArea = All;
                        Caption = 'Previous Price';
                    }
                    field("ReserveStock"; Rec.RESERVE_STOCK)
                    {
                        ApplicationArea = All;
                        Caption = 'Reserve Stock';
                    }

                }
            }
            group(Amazon)
            {

                field("ShowonAmazon"; Rec.SHOW_ON_AMAZON)
                {
                    ApplicationArea = All;
                    Caption = 'Show on Amazon';
                    trigger OnValidate()
                    begin
                        if Rec.SHOW_ON_AMAZON then
                            isVisible3 := true
                        else
                            isVisible3 := false
                    end;
                }
                field("FBAAppeagle"; Rec.FBA_APPEAGLE)
                {
                    ApplicationArea = All;
                    Caption = 'FBA Appeagle';
                }
                group("Hide3")
                {
                    ShowCaption = false;
                    Visible = isVisible3;
                    field("AmazonBrowseNode"; Rec.AMAZON_BROWSE_NODE)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon Browse Node';
                    }
                    field("FBASKU"; Rec.FBA_SKU)
                    {
                        ApplicationArea = All;
                        Caption = 'FBA SKU';
                    }
                    field("EFNAppeagle"; Rec.EFN_APPEAGLE)
                    {
                        ApplicationArea = All;
                        Caption = 'EFN Appeagle';
                    }
                    field("NonListStock"; Rec.NON_LIST_STOCK)
                    {
                        ApplicationArea = All;
                        Caption = 'Non List Stock';
                    }
                    field("AmazonDescription"; Rec.AMAZON_DESCRIPTION)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon Description';
                    }
                    field("DoNotApplyLinkedItems"; Rec.DO_NOT_APPLY_LINKED_ITEM)
                    {
                        ApplicationArea = All;
                        Caption = 'Do Not Apply Linked Items';
                    }
                    field("ExcludedMainFeed"; Rec.EXCLUDED_MAIN_FEED)
                    {
                        ApplicationArea = All;
                        Caption = 'Excluded Main Feed';
                    }
                    field("BubbleWrap"; Rec.BUBBLE_WRAP)
                    {
                        ApplicationArea = All;
                        Caption = 'Bubble Wrap';
                    }
                    field("AmazonLabel"; Rec.AMAZON_LABEL)
                    {
                        ApplicationArea = All;
                        Caption = 'Amazon Label';
                    }

                }
            }
            group(eBay)
            {

                field("Enabled_ebay"; Rec.Enabled_ebay)
                {
                    ApplicationArea = All;
                    Caption = 'Show on eBay';
                    trigger OnValidate()
                    begin
                        if Rec.Enabled_ebay then begin
                            isVisible4 := true
                        end
                        else begin
                            isVisible4 := false;
                        end;
                    end;
                }
                group(Hide4)
                {
                    ShowCaption = false;
                    Visible = isVisible4;

                    field("ALTTitle"; Rec.ALT_TITLE)
                    {
                        ApplicationArea = All;
                        Caption = 'ALT Title';
                    }
                    field("OverridePrice"; Rec.OVERRIDE_PRICE)
                    {
                        ApplicationArea = All;
                        Caption = 'Override Price';
                    }

                    field("ReserveStockebay"; Rec.Reserve_Stock_ebay)
                    {
                        ApplicationArea = All;
                        Caption = 'Reserve Stock on eBay';
                    }
                    field("EBAYShippingPolicy"; Rec.EBAY_SHIPPING_POLICY)
                    {
                        ApplicationArea = All;
                        Caption = 'eBay Shipping Policy';
                        TableRelation = FulfilmentPolicy."Policy Name";
                    }

                    field("LastUpdate"; Rec.LAST_UPDATE)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Update';
                    }
                    field("LAST_PRICE"; Rec.LAST_PRICE)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Price';
                    }
                    field("LAST_INVENTORY"; Rec.LAST_INVENTORY)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Inventory';
                    }
                    field(eBay_PRICE; Rec.eBay_PRICE)
                    {
                        ApplicationArea = All;
                        Caption = 'eBay Price';
                    }
                    field(eBay_INVENTORY; Rec.eBay_INVENTORY)
                    {
                        ApplicationArea = All;
                        Caption = 'eBay Inventory';
                    }
                    field(Listing_ID; Rec.Listing_ID)
                    {
                        ApplicationArea = All;
                        Caption = 'eBay Listing ID';
                    }
                    field(Offer_ID; Rec.Offer_ID)
                    {
                        ApplicationArea = All;
                        Caption = 'eBay Offer ID';
                    }

                }
            }
            group(Images)
            {

                field("ImageFileName"; Rec.IMAGE_FILE_NAME)
                {
                    ApplicationArea = All;
                    Caption = 'Image File Name';
                }

                field("LargeImage2"; Rec.LARGE_IMAGE_2)
                {
                    ApplicationArea = All;
                    Caption = 'Large Image 2';
                }
                field("LargeImage3"; Rec.LARGE_IMAGE_3)
                {
                    ApplicationArea = All;
                    Caption = 'Large Image 3';
                }
                field("LargeImage4"; Rec.LARGE_IMAGE_4)
                {
                    ApplicationArea = All;
                    Caption = 'Large Image 4';
                }
                field("LargeImage5"; Rec.LARGE_IMAGE_5)
                {
                    ApplicationArea = All;
                    Caption = 'Large Image 5';
                }
                field("LargeImage6"; Rec.LARGE_IMAGE_6)
                {
                    ApplicationArea = All;
                    Caption = 'Large Image 6';
                }
                field("ThumbNailImage"; Rec.THUMB_NAIL_IMAGE)
                {
                    ApplicationArea = All;
                    Caption = 'Thumb Nail Image';
                }
            }
            group(Web)
            {
                field("HideFromWebsite"; Rec.HIDE_FROM_WEBSITE)
                {
                    ApplicationArea = All;
                    Caption = 'Hide From Website';
                    trigger OnValidate()
                    begin
                        if Rec.HIDE_FROM_WEBSITE then
                            isVisible5 := false
                        else
                            isVisible5 := true

                    end;
                }
                field("NotVisibleIndividually"; Rec.NOT_VISIBLE_INDIVIDUALLY)
                {
                    ApplicationArea = All;
                    Caption = 'Not Visible Individually';

                }
                group(Hide5)
                {
                    ShowCaption = false;
                    Visible = isVisible5;

                    field("PDFName"; Rec.PDF_NAME)
                    {
                        ApplicationArea = All;
                        Caption = 'PDF Name';
                    }
                    field("YouTube1"; Rec.YOU_TUBE_1)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube 1';
                    }
                    field("YouTube2"; Rec.YOU_TUBE_2)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube 2';
                    }
                    field("YouTube3"; Rec.YOU_TUBE_3)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube 3';
                    }
                    field("YouTube4"; Rec.YOU_TUBE_4)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube 4';
                    }
                    field("MagentoID"; Rec.MAGENTO_ID)
                    {
                        ApplicationArea = All;
                        Caption = 'Magento ID';
                    }
                    field("ShippingGroup"; Rec.SHIPPING_GROUP)
                    {
                        ApplicationArea = All;
                        Caption = 'Shipping Group';
                    }
                    field("LastMagentoStockLevel"; Rec.LAST_MAGENTO_STOCK_LEVEL)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Magento Stock Level';
                    }
                    field("LastUploadedYouTube1"; Rec.LAST_UPLOADED_YOU_TUBE_1)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Uploaded YouTube 1';
                    }
                    field("LastUploadedYouTube2"; Rec.LAST_UPLOADED_YOU_TUBE_2)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Uploaded YouTube 2';
                    }
                    field("LastUploadedYouTube3"; Rec.LAST_UPLOADED_YOU_TUBE_3)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Uploaded YouTube 3';
                    }
                    field("LastUploadedYouTube4"; Rec.LAST_UPLOADED_YOU_TUBE_4)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Uploaded YouTube 4';
                    }
                    field("YouTubeMagentoID1"; Rec.YOU_TUBE_MAGENTO_ID_1)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube Magento ID 1';
                    }
                    field("YouTubeMagentoID2"; Rec.YOU_TUBE_MAGENTO_ID_2)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube Magento ID 2';
                    }
                    field("YouTubeMagentoID3"; Rec.YOU_TUBE_MAGENTO_ID_3)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube Magento ID 3';
                    }
                    field("YouTubeMagentoID4"; Rec.YOU_TUBE_MAGENTO_ID_4)
                    {
                        ApplicationArea = All;
                        Caption = 'YouTube Magento ID 4';
                    }
                    field("FullDescription"; Rec.FULL_DESCRIPITION)
                    {
                        ApplicationArea = All;
                        Caption = 'Full Description';
                        MultiLine = true;
                    }
                    field("FullDescriptionContinued"; Rec.FULL_DESCRIPITION_CONTINUED)
                    {
                        ApplicationArea = All;
                        Caption = 'Full Description Continued';
                        MultiLine = true;
                    }
                    field("ShortDescription"; Rec.SHORT_DESCRIPTION)
                    {
                        ApplicationArea = All;
                        Caption = 'Short Description';
                    }

                    field("SingleProductPageName"; Rec.SINGLE_PRODUCT_PAGE_NAME)
                    {
                        ApplicationArea = All;
                        Caption = 'Single Product Page Name';
                    }
                    field("Manufacturer"; Rec.MANUFACTURER)
                    {
                        ApplicationArea = All;
                        Caption = 'Manufacturer';
                    }
                    field("LastFullRefresh"; Rec.LAST_FULL_REFRESH)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Full Refresh';
                    }
                    field("LastLevelRefresh"; Rec.LAST_LEVEL_REFRESH)
                    {
                        ApplicationArea = All;
                        Caption = 'Last Level Refresh';
                    }
                    field("RelatedRange"; Rec.RELATED_RANGE)
                    {
                        ApplicationArea = All;
                        Caption = 'Related Range';
                    }
                    field("Roundel"; Rec.ROUNDEL)
                    {
                        ApplicationArea = All;
                        Caption = 'Roundel';
                    }

                }
            }


        }
    }
    actions
    {
        addfirst(processing)
        {
            action(FullItemUpdate)
            {
                Caption = 'eBay Update';
                ApplicationArea = All;
                Promoted = true;
                Image = Process;
                trigger OnAction();
                var
                    cu_EbayListing: Codeunit EbayForceUpdateListing;
                begin
                    Rec.CalcFields(Offer_ID);
                    Rec.CalcFields(Listing_ID);
                    if (Rec.Enabled_ebay = true) and (Rec.Blocked = false) and ((Rec.Offer_ID <> '') or (Rec.Listing_ID <> '')) then begin
                        cu_EbayListing.SendToAPIUpdateListing(Rec."No.");
                    end else begin
                        if (Rec.Enabled_ebay = false) or (Rec.Blocked = true) then begin
                            Message('This item is either blocked or not enabled for eBay');
                        end else begin
                            Message('This item is not yet listed on eBay');
                        end;
                    end;
                end;
            }
        }
    }

    var
        isVisible: Boolean;
        isVisible2: Boolean;
        isVisible3: Boolean;
        isVisible4: Boolean;
        isVisible5: Boolean;
        isVisible6: Boolean;


    trigger OnOpenPage()
    begin

        //ebay
        if Rec.Enabled_ebay then begin
            isVisible4 := true
        end
        else begin
            isVisible4 := false;
        end;

        if Rec.HIDE_FROM_WEBSITE then
            isVisible5 := false
        else
            isVisible5 := true;

        //appeagle
        if Rec.Enabled_Appeagle then
            isVisible := true
        else
            isVisible := false;

        //onBuy
        if Rec.ACTIVE_ON_ONBUY then
            isVisible2 := true
        else
            isVisible2 := false;

        //amazon
        if Rec.SHOW_ON_AMAZON then
            isVisible3 := true
        else
            isVisible3 := false
    end;

}
