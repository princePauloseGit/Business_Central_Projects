codeunit 50414 "AmazonProductFeeds"
{
    trigger OnRun()
    begin
        SendToApiProductFileData();
    end;

    Var
        isProductDataInserted, isStockDataInserted : Boolean;
        cu_CommonHelper: Codeunit CommonHelper;
        cu_eBayCommonHelper: Codeunit EbayCommonHelper;
        i: Integer;

    procedure SendToApiProductFileData()
    var
        RESTAPIHelper: Codeunit "REST API Helper";
        URI, Base64Data_Product, result, errorMessage : Text;
        varJsonArray, Jarray : JsonArray;
        Jtoken, varjsonToken : JsonToken;
        JObject: JsonObject;
        rec_AmazonSetting: Record "Amazon Setting";
        isGUIAllowed: Boolean;
        Question: Text;
        Answer: Boolean;
        CustomerNo: Integer;
        Text000: Label 'Exit without saving changes to customer %1?';
        Text001: Label 'You selected %1.';
        cdu_Base64: Codeunit "Base64 Convert";
        ZipInStream: InStream;
        TempInStream: InStream;
        ZipArchive: Codeunit "Data Compression";
        OutStream: OutStream;
        tmpBlob: Codeunit "Temp Blob";
        FileName: Text;
        environment: Integer;

    begin
        isGUIAllowed := true;
        if GuiAllowed then begin
            isGUIAllowed := Dialog.Confirm('Yes: Send To API\No: Download To Browser');
        end;

        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat

                if rec_AmazonSetting.Environment = rec_AmazonSetting.Environment::Sandbox then begin
                    environment := 0;
                end
                else begin
                    environment := 1;
                end;

                if rec_AmazonSetting."Product / Stock File" then begin
                    Clear(RESTAPIHelper);
                    URI := RESTAPIHelper.GetBaseURl() + 'Amazon/SubmitFeed/Product';
                    RESTAPIHelper.Initialize('POST', URI);
                    RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                    RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                    RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
                    RESTAPIHelper.AddRequestHeader('environment', format(environment));

                    //Body
                    isProductDataInserted := false;
                    Base64Data_Product := CreateProductTxtFile(isGUIAllowed);
                    RESTAPIHelper.AddBody('{"base64EncodedData":"' + Base64Data_Product + '"}');
                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');
                    if isGUIAllowed then
                        if isProductDataInserted then begin
                            if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                                result := RESTAPIHelper.GetResponseContentAsText();
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
                                Message('Successfully Uploaded Product File');
                            end;
                        end
                        else begin
                            Message('No Data Generated');
                        end;
                end
                else begin
                    errorMessage := 'The Upload Product / Stock is disabled for the customer; please grant access to proceed.';
                    cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    local procedure CreateProductTxtFile(isGUIAllowed: Boolean): Text
    var
        InStr: InStream;
        OutStr: OutStream;
        tmpBlob: Codeunit "Temp Blob";
        country_of_origin_Name, other_image_url1, other_image_url2, other_image_url3, other_image_url4, other_image_url5, country_of_origin, extendedInfoText, i, bullet1, bullet2, bullet3, bullet4, bullet5, varTextTab, FileName, ProductFileData, ProductName, fullDescription : Text;
        rec_Item: Record Item;
        cdu_Base64: Codeunit "Base64 Convert";
        Quantity, RecommendedBrowseNode1, BrowseNode : Decimal;
        Brand, Barcode, fabric, size_name : Code[50];
        CR: char;
        LF: char;
        varTab: Char;
        bulletPoints, bulletPointValue : List of [Text];
        count: Integer;
        MainImgUrl, salesPrice : Text;
        recCountryRegion: Record "Country/Region";
        recGenProdPostingGrp: Record "Gen. Product Posting Group";
        ZipArchive: Codeunit "Data Compression";
        ZipInStream: InStream;
        TempInStream: InStream;
        cuStockLevel: Codeunit StockLevel;
    begin
        varTab := 9;
        varTextTab := Format(varTab);
        CR := 13;
        LF := 10;
        FileName := 'Product';
        tmpBlob.CreateOutStream(OutStr, TextEncoding::Windows);

        OutStr.WriteText('TemplateType=fptcustomcustom' + varTextTab + 'Version=2018.0622' + varTextTab + 'TemplateSignature=S0lUQ0hFTixIT01FX0ZVUk5JVFVSRV9BTkRfREVDT1IsSE9NRQ==' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Images' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Variation' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Basic' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Discovery' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Product Enrichment' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Dimensions' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Fulfillment' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Compliance' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'Offer' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + 'b2b' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + varTextTab + '' + CR + LF);

        OutStr.WriteText('Product Type' + varTextTab + 'Seller SKU' + varTextTab + 'Brand Name' + varTextTab + 'Product Name' + varTextTab + 'Manufacturer' + varTextTab + 'Recommended Browse Nodes' + varTextTab + 'Standard Price' + varTextTab + 'Quantity' + varTextTab + 'Merchant Shipping Group' + varTextTab + 'Main Image URL' + varTextTab + 'Swatch Image URL' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Other Image Url' + varTextTab + 'Parentage' + varTextTab + 'Parent SKU' + varTextTab + 'Relationship Type' + varTextTab + 'Variation Theme' + varTextTab + 'Update Delete' + varTextTab + 'GTIN Exemption Reason' + varTextTab + 'Product ID' + varTextTab + 'Product ID Type' + varTextTab + 'Manufacturer Part Number' + varTextTab + 'Product Description' + varTextTab + 'Inner Material Type' + varTextTab + 'Inner Material Type' + varTextTab + 'Inner Material Type' + varTextTab + 'Inner Material Type' + varTextTab + 'Inner Material Type' + varTextTab + 'Merchant Catalogue Number' + varTextTab + 'Key Product Features' + varTextTab + 'Key Product Features' + varTextTab + 'Key Product Features' + varTextTab + 'Key Product Features' + varTextTab + 'Key Product Features' + varTextTab + 'Search Terms' + varTextTab + 'Search Terms' + varTextTab + 'Search Terms' + varTextTab + 'Search Terms' + varTextTab + 'Search Terms' + varTextTab + 'Platinum Keyword' + varTextTab + 'Platinum Keyword' + varTextTab + 'Platinum Keyword' + varTextTab + 'Platinum Keyword' + varTextTab + 'Platinum Keyword' + varTextTab + 'Home & Furniture Target Audience' + varTextTab + 'Wattage Unit Of Measure' + varTextTab + 'blade_length' + varTextTab + 'runtime_unit_of_measure' + varTextTab + 'size_map' + varTextTab + 'length_range' + varTextTab + 'width_range' + varTextTab + 'awards_won1' + varTextTab + 'awards_won2' + varTextTab + 'awards_won3' + varTextTab + 'awards_won4' + varTextTab +
'awards_won5' + varTextTab + 'awards_won6' + varTextTab + 'awards_won7' + varTextTab + 'awards_won8' + varTextTab + 'awards_won9' + varTextTab + 'awards_won10' + varTextTab + 'battery_description' + varTextTab + 'shaft_style_type' + varTextTab + 'Output Capacity Unit Of Measure' + varTextTab + 'Blade Length Unit Of Measure' + varTextTab + 'Age restriction bladed products' + varTextTab + 'Paper Size Unit of Measure' + varTextTab + 'lithium_battery_voltage_unit_of_measure' + varTextTab + 'lithium_battery_voltage' + varTextTab + 'Scent' + varTextTab + 'Thread Count' + varTextTab + 'Number Of Sets' + varTextTab + 'Is Stain Resistant' + varTextTab + 'Wattage' + varTextTab + 'Colour' + varTextTab + 'Color Map' + varTextTab + 'Size' + varTextTab + 'Manufacturer Warranty Description' + varTextTab + 'Number Of Pieces' + varTextTab + 'Material Type' + varTextTab + 'Hard floor cleaning performance class' + varTextTab + 'Dust re-emission class' + varTextTab + 'Carpet cleaning performance class' + varTextTab + 'Theme' + varTextTab + 'Unit of Measure (Per Unit Pricing)' + varTextTab + 'Style Name' + varTextTab + 'Unit Count (Per Unit Pricing)' + varTextTab + 'Special Features' + varTextTab + 'Special Features' + varTextTab + 'Special Features' + varTextTab + 'Special Features' + varTextTab + 'Special Features' + varTextTab + 'Special Features' + varTextTab + 'Runtime' + varTextTab + 'Seating Capacity' + varTextTab + 'Operating Type' + varTextTab + 'Design' + varTextTab + 'Iron & Steamer Steam Output' + varTextTab + 'Paper size' + varTextTab + 'Iron & Steamer Pressure' + varTextTab + 'Paint Type' + varTextTab + 'Iron & Steamer Pressure Unit of Measure' + varTextTab + 'Occasion Type' + varTextTab + 'Number of Speeds' + varTextTab + 'Number of doors' + varTextTab + 'Sound Level' + varTextTab + 'Material Composition' + varTextTab + 'Noise Level Unit Of Measure' + varTextTab + 'Yarn Weight Category' + varTextTab + 'Kitchen Scale Capacity' + varTextTab + 'Item Type' + varTextTab + 'Maximum Weight Capacity Unit Of Measure' + varTextTab + 'Ornament Type' + varTextTab + 'Shape' + varTextTab + 'Mattress Firmness' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Mixer Feature' + varTextTab + 'Auto Shutoff' + varTextTab + 'Indoor Fountain Installation Type' + varTextTab + 'Compatible Devices' + varTextTab + 'Capacity Unit Of Measure' + varTextTab + 'Bed Frame Type' + varTextTab + 'Energy efficiency class' + varTextTab + 'Capacity' + varTextTab + 'Knitting Needle Type' + varTextTab + 'Knitting Needle Type' + varTextTab + 'Knitting Needle Type' + varTextTab + 'Knitting Needle Type' + varTextTab + 'Knitting Needle Type' + varTextTab + 'Energy Efficiency Class Range' + varTextTab + 'Blade Material Type' + varTextTab + 'Finish' + varTextTab + 'Finish' + varTextTab + 'Finish' + varTextTab + 'Finish' + varTextTab + 'Finish' + varTextTab + 'Blade Edge' + varTextTab + 'Slatted Frame Adjustment Type' + varTextTab + 'Annual Energy Consumption' + varTextTab + 'Annual Energy Consumption Unit Of Measure' + varTextTab + 'Handheld Vacuum Battery Type' + varTextTab + 'Power Plug Type' + varTextTab + 'Item Width Unit Of Measure' + varTextTab + 'item_width' + varTextTab + 'item_height' + varTextTab + 'Item Height Unit Of Measure' + varTextTab + 'Item Dimensions Unit Of Measure' + varTextTab + 'Item Length Unit Of Measure' + varTextTab + 'item_length' + varTextTab + 'Display Depth' + varTextTab + 'Item Display Depth Unit Of Measure' + varTextTab + 'Shipping Weight' + varTextTab + 'Website Shipping Weight Unit Of Measure' + varTextTab + 'Vacuum Sealer Bag Length' + varTextTab + 'Item Display Length Unit Of Measure' + varTextTab + 'Display Width' + varTextTab + 'Item Display Width Unit Of Measure' + varTextTab + 'Display Height' + varTextTab + 'Item Display Height Unit Of Measure' + varTextTab + 'Display Diameter' + varTextTab + 'Item Display Diameter Unit Of Measure' + varTextTab + 'Vacuum & Floor Care Item Weight' + varTextTab + 'Item Display Weight Unit Of Measure' + varTextTab + 'Volume' + varTextTab + 'Volume Capacity Name Unit Of Measure' + varTextTab + 'Volume Capacity of the appliance' + varTextTab + 'Item Display Volume Unit Of Measure' + varTextTab + 'Cookware Diameter' + varTextTab + 'Item Diameter Unit Of Measure' + varTextTab + 'Item Thickness Unit Of Measure' + varTextTab + 'item_thickness_derived' + varTextTab + 'Package Weight Unit Of Measure' + varTextTab + 'Package Dimensions Unit Of Measure' + varTextTab + 'package_weight' + varTextTab + 'Package Length' + varTextTab + 'Package Width' + varTextTab + 'Package Height' + varTextTab + 'Fulfillment Centre ID' + varTextTab + 'specific_uses_for_product1' + varTextTab + 'specific_uses_for_product2' + varTextTab + 'specific_uses_for_product3' + varTextTab + 'specific_uses_for_product4' + varTextTab + 'specific_uses_for_product5' + varTextTab + 'Product fiche' + varTextTab + 'Energy efficiency label' + varTextTab + 'legal_disclaimer_description' + varTextTab + 'safety_warning' + varTextTab + 'fedas_id' + varTextTab + 'EU Toys Safety Directive Age-Specific Warning' + varTextTab + 'EU Toys Safety Directive Non-Age-Specific Warning' + varTextTab + 'EU Toys Safety Directive Language Warning' + varTextTab + 'Country/Region of declaration' + varTextTab + 'Batteries are Included' + varTextTab + 'Is this product a battery or does it utilise batteries?' + varTextTab + 'Battery type/size' + varTextTab + 'Battery type/size' + varTextTab + 'Battery type/size' + varTextTab + 'Number of batteries' + varTextTab + 'Number of batteries' + varTextTab + 'Number of batteries' + varTextTab + 'Battery composition' + varTextTab + 'Battery weight (grams)' + varTextTab + 'battery_weight_unit_of_measure' + varTextTab + 'Number of Lithium Metal Cells' + varTextTab + 'Number of Lithium-ion Cells' + varTextTab + 'Lithium Battery Packaging' + varTextTab + 'Watt hours per battery' + varTextTab + 'lithium_battery_energy_content_unit_of_measure' + varTextTab + 'Lithium content (grams)' + varTextTab + 'lithium_battery_weight_unit_of_measure' + varTextTab + 'Applicable Dangerous Goods Regulations' + varTextTab + 'Applicable Dangerous Goods Regulations' + varTextTab + 'Applicable Dangerous Goods Regulations' + varTextTab + 'Applicable Dangerous Goods Regulations' + varTextTab + 'Applicable Dangerous Goods Regulations' + varTextTab + 'UN number' + varTextTab + 'Safety Data Sheet (SDS) URL' + varTextTab + 'Item Weight' + varTextTab + 'item_weight_unit_of_measure' + varTextTab + 'Volume' + varTextTab + 'item_volume_unit_of_measure' + varTextTab + 'Flash point (Â°C)?' + varTextTab + 'Categorization/GHS pictograms (select all that apply)' + varTextTab + 'Categorization/GHS pictograms (select all that apply)' + varTextTab + 'Categorization/GHS pictograms (select all that apply)' + varTextTab + 'Recommended Retail Price' + varTextTab + 'weee_tax_value' + varTextTab + 'Number of Items' + varTextTab + 'weee_tax_value_unit_of_measure' + varTextTab + 'Stop Selling Date' + varTextTab + 'Max Order Quantity' + varTextTab + 'Offering Release Date' + varTextTab + 'Scheduled Delivery SKU List' + varTextTab + 'Launch Date' + varTextTab + 'Currency' + varTextTab + 'Package Quantity' + varTextTab + 'Product Tax Code' + varTextTab + 'Release Date' + varTextTab + 'Sale Price' + varTextTab + 'Sale From Date' + varTextTab + 'Sale End Date' + varTextTab + 'Item Condition' + varTextTab + 'Offer Handling Time' + varTextTab + 'Restock Date' + varTextTab + 'Maximum Aggregate Ship Quantity' + varTextTab + 'Can Be Gift Messaged' + varTextTab + 'Is Gift Wrap Available?' + varTextTab + 'Is Discontinued by Manufacturer' + varTextTab + 'Registered Parameter' + varTextTab + 'Business Price' + varTextTab + 'Quantity Price Type' + varTextTab + 'Quantity Lower Bound 1' + varTextTab + 'Quantity Price 1' + varTextTab + 'Quantity Lower Bound 2' + varTextTab + 'Quantity Price 2' + varTextTab + 'Quantity Lower Bound 3' + varTextTab + 'Quantity Price 3' + varTextTab + 'Quantity Lower Bound 4' + varTextTab + 'Quantity Price 4' + varTextTab + 'Quantity Lower Bound 5' + varTextTab + 'Quantity Price 5' + varTextTab + 'National Stock Number' + varTextTab + 'United Nations Standard Products and Services Code' + varTextTab + 'Pricing Action' + varTextTab + 'Country/Region Of Origin' + varTextTab + 'Fabric Type' + CR + LF);

        OutStr.WriteText('feed_product_type' + varTextTab + 'item_sku' + varTextTab + 'brand_name' + varTextTab + 'item_name' + varTextTab + 'manufacturer' + varTextTab + 'recommended_browse_nodes' + varTextTab + 'standard_price' + varTextTab + 'quantity' + varTextTab + 'merchant_shipping_group_name' + varTextTab + 'main_image_url' + varTextTab + 'swatch_image_url' + varTextTab + 'other_image_url1' + varTextTab + 'other_image_url2' + varTextTab + 'other_image_url3' + varTextTab + 'other_image_url4' + varTextTab + 'other_image_url5' + varTextTab + 'other_image_url6' + varTextTab + 'other_image_url7' + varTextTab + 'other_image_url8' + varTextTab + 'parent_child' + varTextTab + 'parent_sku' + varTextTab + 'relationship_type' + varTextTab + 'variation_theme' + varTextTab + 'update_delete' + varTextTab + 'gtin_exemption_reason' + varTextTab + 'external_product_id' + varTextTab + 'external_product_id_type' + varTextTab + 'part_number' + varTextTab + 'product_description' + varTextTab + 'inner_material_type1' + varTextTab + 'inner_material_type2' + varTextTab + 'inner_material_type3' + varTextTab + 'inner_material_type4' + varTextTab + 'inner_material_type5' + varTextTab + 'catalog_number' + varTextTab + 'bullet_point1' + varTextTab + 'bullet_point2' + varTextTab + 'bullet_point3' + varTextTab + 'bullet_point4' + varTextTab + 'bullet_point5' + varTextTab + 'generic_keywords1' + varTextTab + 'generic_keywords2' + varTextTab + 'generic_keywords3' + varTextTab + 'generic_keywords4' + varTextTab + 'generic_keywords5' + varTextTab + 'platinum_keywords1' + varTextTab + 'platinum_keywords2' + varTextTab + 'platinum_keywords3' + varTextTab + 'platinum_keywords4' + varTextTab + 'platinum_keywords5' + varTextTab + 'target_audience_keywords' + varTextTab + 'wattage_unit_of_measure' + varTextTab + 'blade_length' + varTextTab + 'runtime_unit_of_measure' + varTextTab + 'size_map' + varTextTab + 'length_range' + varTextTab + 'width_range' + varTextTab + 'awards_won1' + varTextTab + 'awards_won2' + varTextTab + 'awards_won3' + varTextTab + 'awards_won4' + varTextTab + 'awards_won5' + varTextTab + 'awards_won6' + varTextTab + 'awards_won7' + varTextTab + 'awards_won8' + varTextTab + 'awards_won9' + varTextTab + 'awards_won10' + varTextTab + 'battery_description' + varTextTab + 'shaft_style_type' + varTextTab + 'output_capacity_unit_of_measure' + varTextTab + 'blade_length_unit_of_measure' + varTextTab + 'customer_restriction_type' + varTextTab + 'paper_size_unit_of_measure' + varTextTab + 'lithium_battery_voltage_unit_of_measure' + varTextTab + 'lithium_battery_voltage' + varTextTab + 'scent_name' + varTextTab + 'thread_count' + varTextTab + 'number_of_sets' + varTextTab + 'is_stain_resistant' + varTextTab + 'wattage' + varTextTab + 'color_name' + varTextTab + 'color_map' + varTextTab + 'size_name' + varTextTab + 'warranty_description' + varTextTab + 'number_of_pieces' + varTextTab + 'material_type' + varTextTab + 'vacuum_cleaner_hardfloor_cleaning_class' + varTextTab + 'vacuum_cleaner_dust_reemission_class' + varTextTab + 'vacuum_cleaner_carpet_cleaning_class' + varTextTab + 'theme' + varTextTab + 'unit_count_type' + varTextTab + 'style_name' + varTextTab + 'unit_count' + varTextTab + 'special_features1' + varTextTab + 'special_features2' + varTextTab + 'special_features3' + varTextTab + 'special_features4' + varTextTab + 'special_features5' + varTextTab + 'special_features6' + varTextTab + 'runtime' + varTextTab + 'seating_capacity' + varTextTab + 'power_source_type' + varTextTab + 'pattern_name' + varTextTab + 'output_capacity' + varTextTab + 'paper_size' + varTextTab + 'operating_pressure' + varTextTab + 'paint_type' + varTextTab + 'operating_pressure_unit_of_measure' + varTextTab + 'occasion_type' + varTextTab + 'number_of_speeds' + varTextTab + 'number_of_doors' + varTextTab + 'noise_level' + varTextTab + 'material_composition' + varTextTab + 'noise_level_unit_of_measure' + varTextTab + 'line_weight' + varTextTab + 'maximum_weight_capacity' + varTextTab + 'item_type_name' + varTextTab + 'maximum_weight_capacity_unit_of_measure' + varTextTab + 'item_styling' + varTextTab + 'item_shape' + varTextTab + 'item_hardness' + varTextTab + 'included_components1' + varTextTab + 'included_components2' + varTextTab + 'included_components3' + varTextTab + 'included_components4' + varTextTab + 'included_components5' + varTextTab + 'included_components6' + varTextTab + 'included_components7' + varTextTab + 'included_components8' + varTextTab + 'included_components9' + varTextTab + 'included_components10' + varTextTab + 'has_automatic_shutoff' + varTextTab + 'installation_type' + varTextTab + 'compatible_devices' + varTextTab + 'capacity_unit_of_measure' + varTextTab + 'frame_type' + varTextTab + 'efficiency' + varTextTab + 'capacity' + varTextTab + 'form_factor1' + varTextTab + 'form_factor2' + varTextTab + 'form_factor3' + varTextTab + 'form_factor4' + varTextTab + 'form_factor5' + varTextTab + 'eu_energy_label_efficiency_class' + varTextTab + 'blade_material_type' + varTextTab + 'finish_type1' + varTextTab + 'finish_type2' + varTextTab + 'finish_type3' + varTextTab + 'finish_type4' + varTextTab + 'finish_type5' + varTextTab + 'blade_edge_type' + varTextTab + 'adjustment_type' + varTextTab + 'annual_energy_consumption' + varTextTab + 'annual_energy_consumption_unit_of_measure' + varTextTab + 'battery_form_factor' + varTextTab + 'power_plug_type' + varTextTab + 'item_width_unit_of_measure' + varTextTab + 'item_width' + varTextTab + 'item_height' + varTextTab + 'item_height_unit_of_measure' + varTextTab + 'item_dimensions_unit_of_measure' + varTextTab + 'item_length_unit_of_measure' + varTextTab + 'item_length' + varTextTab + 'item_display_depth' + varTextTab + 'item_display_depth_unit_of_measure' + varTextTab + 'website_shipping_weight' + varTextTab + 'website_shipping_weight_unit_of_measure' + varTextTab + 'item_display_length' + varTextTab + 'item_display_length_unit_of_measure' + varTextTab + 'item_display_width' + varTextTab + 'item_display_width_unit_of_measure' + varTextTab + 'item_display_height' + varTextTab + 'item_display_height_unit_of_measure' + varTextTab + 'item_display_diameter' + varTextTab + 'item_display_diameter_unit_of_measure' + varTextTab + 'item_display_weight' + varTextTab + 'item_display_weight_unit_of_measure' + varTextTab + 'volume_capacity_name' + varTextTab + 'volume_capacity_name_unit_of_measure' + varTextTab + 'item_display_volume' + varTextTab + 'item_display_volume_unit_of_measure' + varTextTab + 'item_diameter_derived' + varTextTab + 'item_diameter_unit_of_measure' + varTextTab + 'item_thickness_unit_of_measure' + varTextTab + 'item_thickness_derived' + varTextTab + 'package_weight_unit_of_measure' + varTextTab + 'package_dimensions_unit_of_measure' + varTextTab + 'package_weight' + varTextTab + 'package_length' + varTextTab + 'package_width' + varTextTab + 'package_height' + varTextTab + 'fulfillment_center_id' + varTextTab + 'specific_uses_for_product1' + varTextTab + 'specific_uses_for_product2' + varTextTab + 'specific_uses_for_product3' + varTextTab + 'specific_uses_for_product4' + varTextTab + 'specific_uses_for_product5' + varTextTab + 'product_efficiency_image_url' + varTextTab + 'energy_efficiency_image_url' + varTextTab + 'legal_disclaimer_description' + varTextTab + 'safety_warning' + varTextTab + 'fedas_id' + varTextTab + 'eu_toys_safety_directive_age_warning' + varTextTab + 'eu_toys_safety_directive_warning' + varTextTab + 'eu_toys_safety_directive_language' + varTextTab + 'country_string' + varTextTab + 'are_batteries_included' + varTextTab + 'batteries_required' + varTextTab + 'battery_type1' + varTextTab + 'battery_type2' + varTextTab + 'battery_type3' + varTextTab + 'number_of_batteries1' + varTextTab + 'number_of_batteries2' + varTextTab + 'number_of_batteries3' + varTextTab + 'battery_cell_composition' + varTextTab + 'battery_weight' + varTextTab + 'battery_weight_unit_of_measure' + varTextTab + 'number_of_lithium_metal_cells' + varTextTab + 'number_of_lithium_ion_cells' + varTextTab + 'lithium_battery_packaging' + varTextTab + 'lithium_battery_energy_content' + varTextTab + 'lithium_battery_energy_content_unit_of_measure' + varTextTab + 'lithium_battery_weight' + varTextTab + 'lithium_battery_weight_unit_of_measure' + varTextTab + 'supplier_declared_dg_hz_regulation1' + varTextTab + 'supplier_declared_dg_hz_regulation2' + varTextTab + 'supplier_declared_dg_hz_regulation3' + varTextTab + 'supplier_declared_dg_hz_regulation4' + varTextTab + 'supplier_declared_dg_hz_regulation5' + varTextTab + 'hazmat_united_nations_regulatory_id' + varTextTab + 'safety_data_sheet_url' + varTextTab + 'item_weight' + varTextTab + 'item_weight_unit_of_measure' + varTextTab + 'item_volume' + varTextTab + 'item_volume_unit_of_measure' + varTextTab + 'flash_point' + varTextTab + 'ghs_classification_class1' + varTextTab + 'ghs_classification_class2' + varTextTab + 'ghs_classification_class3' + varTextTab + 'list_price' + varTextTab + 'weee_tax_value' + varTextTab + 'number_of_items' + varTextTab + 'weee_tax_value_unit_of_measure' + varTextTab + 'offering_end_date' + varTextTab + 'max_order_quantity' + varTextTab + 'offering_start_date' + varTextTab + 'delivery_schedule_group_id' + varTextTab + 'product_site_launch_date' + varTextTab + 'currency' + varTextTab + 'item_package_quantity' + varTextTab + 'product_tax_code' + varTextTab + 'merchant_release_date' + varTextTab + 'sale_price' + varTextTab + 'sale_from_date' + varTextTab + 'sale_end_date' + varTextTab + 'condition_type' + varTextTab + 'fulfillment_latency' + varTextTab + 'restock_date' + varTextTab + 'max_aggregate_ship_quantity' + varTextTab + 'offering_can_be_gift_messaged' + varTextTab + 'offering_can_be_giftwrapped' + varTextTab + 'is_discontinued_by_manufacturer' + varTextTab + 'missing_keyset_reason' + varTextTab + 'business_price' + varTextTab + 'quantity_price_type' + varTextTab + 'quantity_lower_bound1' + varTextTab + 'quantity_price1' + varTextTab + 'quantity_lower_bound2' + varTextTab + 'quantity_price2' + varTextTab + 'quantity_lower_bound3' + varTextTab + 'quantity_price3' + varTextTab + 'quantity_lower_bound4' + varTextTab + 'quantity_price4' + varTextTab + 'quantity_lower_bound5' + varTextTab + 'quantity_price5' + varTextTab + 'national_stock_number' + varTextTab + 'unspsc_code' + varTextTab + 'pricing_action' + varTextTab + 'country_of_origin' + varTextTab + 'fabric_type' + CR + LF);
        rec_Item.Reset();
        rec_Item.SetRange(SHOW_ON_AMAZON, true);
        rec_Item.SetRange(EXCLUDED_MAIN_FEED, false);
        rec_Item.SetRange(RESTRICTED_18, false);
        rec_Item.SetRange(Blocked, false);
        if rec_Item.FindSet() then
            repeat
                clear(bulletPoints);
                Clear(bulletPointValue);
                clear(bullet1);
                clear(bullet2);
                clear(bullet3);
                clear(bullet4);
                clear(bullet5);
                Clear(fullDescription);
                Clear(MainImgUrl);
                Clear(country_of_origin_Name);
                Clear(country_of_origin);

                fullDescription := RemoveMarkupTags(rec_Item.FULL_DESCRIPITION);

                MainImgUrl := GenerateImageUrl(rec_Item.IMAGE_FILE_NAME);
                other_image_url1 := GenerateImageUrl(rec_Item.LARGE_IMAGE_2);
                other_image_url2 := GenerateImageUrl(rec_Item.LARGE_IMAGE_3);
                other_image_url3 := GenerateImageUrl(rec_Item.LARGE_IMAGE_4);
                other_image_url4 := GenerateImageUrl(rec_Item.LARGE_IMAGE_5);
                other_image_url5 := GenerateImageUrl(rec_Item.LARGE_IMAGE_6);

                extendedInfoText := rec_Item.Extended_Info_Text;
                bulletPoints := extendedInfoText.Split('<br>', LF, CR);

                //inserting into bulletPointValue without newline
                foreach i in bulletPoints do begin
                    if (i <> Format(CR)) then begin
                        bulletPointValue.Add(i);
                    end;
                end;
                count := 0;
                foreach i in bulletPointValue do begin
                    count := count + 1;
                    if (count = 1) then begin
                        bullet1 := RemoveMarkupTags(i);
                    end;
                    if (count = 2) then begin
                        bullet2 := RemoveMarkupTags(i);
                    end;
                    if (count = 3) then begin
                        bullet3 := RemoveMarkupTags(i);
                    end;
                    if (count = 4) then begin
                        bullet4 := RemoveMarkupTags(i);
                    end;
                    if (count = 5) then begin
                        bullet5 := RemoveMarkupTags(i);
                    end;
                end;

                //Product Name
                if rec_Item.AMAZON_DESCRIPTION <> '' then
                    ProductName := rec_Item.AMAZON_DESCRIPTION
                else
                    ProductName := rec_Item.SHORT_DESCRIPTION;

                // Amazon Brwose Node Field Id = 3
                BrowseNode := cu_eBayCommonHelper.GetWebCategoryId(rec_Item."No.", 3);

                if rec_Item.AMAZON_BROWSE_NODE <> 0 then
                    RecommendedBrowseNode1 := rec_Item.AMAZON_BROWSE_NODE
                else
                    if BrowseNode <> 0 then
                        RecommendedBrowseNode1 := BrowseNode
                    else
                        RecommendedBrowseNode1 := 3147471;

                salesPrice := CalculateSalesPrice(rec_Item);

                //   Quantity := (CalculateAmazonAvailbleStock(rec_Item) + getQtyCanBeAssembled(rec_Item."No.")) - rec_Item.NON_LIST_STOCK;
                Quantity := cuStockLevel.GetQuantity(rec_Item."No.", false);

                if Quantity < 0 then
                    Quantity := 0;

                if rec_Item."Gen. Prod. Posting Group" <> '' then begin
                    recGenProdPostingGrp.SetRange(Code, rec_Item."Gen. Prod. Posting Group");
                    if recGenProdPostingGrp.FindFirst() then
                        Brand := recGenProdPostingGrp.Description;
                end;

                fabric := getItemFabricType(rec_Item);
                Barcode := rec_Item."Primary Barcode"; // as per 24 feb mail by Andrew Oborn
                size_name := getItemClothingSize(rec_Item);

                if rec_Item."Country/Region of Origin Code" <> '' then begin
                    country_of_origin := rec_Item."Country/Region of Origin Code";
                    recCountryRegion.SetRange(Code, country_of_origin);
                    if recCountryRegion.FindFirst() then
                        country_of_origin_Name := recCountryRegion.Name;
                end
                else
                    country_of_origin_Name := 'China';

                OutStr.WriteText(
                'Kitchen' + varTextTab +    //1-feed_product_type
                Format(rec_Item."No.").Trim() + varTextTab +   //2-item_sku
                Format(Brand).Trim() + varTextTab +    //3-brand_name
                Format(rec_Item.Description.Trim()) + varTextTab +  //4-item_name
                Format(rec_Item.MANUFACTURER.Trim()) + varTextTab +    //5-manufacturer
                Format(Format(RecommendedBrowseNode1, 0, 1)) + varTextTab +   //6-recommended_browse_nodes
                salesPrice + varTextTab +   //7-standard_price
                Format(Quantity, 0, 1) + varTextTab +     //8-quantity
                'Nationwide Prime' + varTextTab +   //9-merchant_shipping_group_name
                Format(MainImgUrl.Trim()) + varTextTab +     //10-main_image_url
                '' + varTextTab +   //11-swatch_image_url
                Format(other_image_url1.Trim()) + varTextTab +   //12-other_image_url1
                Format(other_image_url2.Trim()) + varTextTab +   //13-other_image_url2
                Format(other_image_url3.Trim()) + varTextTab +   //14-other_image_url3
                Format(other_image_url4.Trim()) + varTextTab +   //15-other_image_url4
                Format(other_image_url5.Trim()) + varTextTab +   //16-other_image_url5
                '' + varTextTab +   //17-other_image_url6
                '' + varTextTab +   //18-other_image_url7
                '' + varTextTab +   //19-other_image_url8
                '' + varTextTab +   //20-parent_child
                '' + varTextTab +   //21-parent_sku
                '' + varTextTab +   //22-relationship_type
                '' + varTextTab +   //23-variation_theme
                '' + varTextTab +   //24-update_delete
                '' + varTextTab +   //25-gtin_exemption_reason
                Format(Barcode).Trim() + varTextTab +    //26-external_product_id
                'EAN' + varTextTab +    //27-external_product_id_type
                '' + varTextTab +   //28-part_number
                Format(fullDescription.Trim()) + varTextTab +   //29-product_description
                '' + varTextTab +   //30-inner_material_type1
                '' + varTextTab +   //31-inner_material_type2
                '' + varTextTab +   //32-inner_material_type3
                '' + varTextTab +   //33-inner_material_type4
                '' + varTextTab +   //34-inner_material_type5
                '' + varTextTab +   //35-catalog_number
                Format(bullet1.Trim()) + varTextTab +   //36-bullet_point1
                Format(bullet2.Trim()) + varTextTab +   //37-bullet_point2
                Format(bullet3.Trim()) + varTextTab +   //38-bullet_point3
                Format(bullet4.Trim()) + varTextTab +   //39-bullet_point4
                Format(bullet5.Trim()) + varTextTab +   //40-bullet_point5
                '' + varTextTab +   //41-generic_keywords1
                '' + varTextTab +   //42-generic_keywords2
                '' + varTextTab +   //43-generic_keywords3
                '' + varTextTab +   //44-generic_keywords4
                '' + varTextTab +   //45-generic_keywords5
                '' + varTextTab +   //46-platinum_keywords1
                '' + varTextTab +   //47-platinum_keywords2
                '' + varTextTab +   //48-platinum_keywords3
                '' + varTextTab +   //49-platinum_keywords4
                '' + varTextTab +   //50-platinum_keywords5
                '' + varTextTab +   //51-target_audience_keywords
                '' + varTextTab +   //52-wattage_unit_of_measure
                '' + varTextTab +   //53-blade_length
                '' + varTextTab +   //54-runtime_unit_of_measure
                '' + varTextTab +   //55-size_map
                '' + varTextTab +   //56-length_range
                '' + varTextTab +   //57-width_range
                '' + varTextTab +   //58-awards_won1
                '' + varTextTab +   //59-awards_won2
                '' + varTextTab +   //60-awards_won3
                '' + varTextTab +   //61-awards_won4
                '' + varTextTab +   //62-awards_won5
                '' + varTextTab +   //63-awards_won6
                '' + varTextTab +   //64-awards_won7
                '' + varTextTab +   //65-awards_won8
                '' + varTextTab +   //66-awards_won9
                '' + varTextTab +   //67-awards_won10
                '' + varTextTab +   //68-battery_description
                '' + varTextTab +   //69-shaft_style_type
                '' + varTextTab +   //70-output_capacity_unit_of_measure
                '' + varTextTab +   //71-blade_length_unit_of_measure
                '' + varTextTab +   //72-customer_restriction_type
                '' + varTextTab +   //73-paper_size_unit_of_measure
                '' + varTextTab +   //74-lithium_battery_voltage_unit_of_measure
                '' + varTextTab +   //75-lithium_battery_voltage
                '' + varTextTab +   //76-scent_name
                '' + varTextTab +   //77-thread_count
                '' + varTextTab +   //78-number_of_sets
                '' + varTextTab +   //79-is_stain_resistant
                '' + varTextTab +   //80-wattage
                '' + varTextTab +   //81-color_name
                '' + varTextTab +   //82-color_map
                Format(size_name).Trim() + varTextTab +    //83-size_name
                '' + varTextTab +   //84-warranty_description
                '' + varTextTab +   //85-number_of_pieces
                '' + varTextTab +   //86-material_type
                '' + varTextTab +   //87-vacuum_cleaner_hardfloor_cleaning_class
                '' + varTextTab +   //88-vacuum_cleaner_dust_reemission_class
                '' + varTextTab +   //89-vacuum_cleaner_carpet_cleaning_class
                '' + varTextTab +   //90-theme
                '' + varTextTab +   //91-unit_count_type
                '' + varTextTab +   //92-style_name
                '' + varTextTab +   //93-unit_count
                '' + varTextTab +   //94-special_features1
                '' + varTextTab +   //95-special_features2
                '' + varTextTab +   //96-special_features3
                '' + varTextTab +   //97-special_features4
                '' + varTextTab +   //98-special_features5
                '' + varTextTab +   //99-special_features6
                '' + varTextTab +   //100-runtime
                '' + varTextTab +   //101-seating_capacity
                '' + varTextTab +   //102-power_source_type
                '' + varTextTab +   //103-pattern_name
                '' + varTextTab +   //104-output_capacity
                '' + varTextTab +   //105-paper_size
                '' + varTextTab +   //106-operating_pressure
                '' + varTextTab +   //107-paint_type
                '' + varTextTab +   //108-operating_pressure_unit_of_measure
                '' + varTextTab +   //109-occasion_type
                '' + varTextTab +   //110-number_of_speeds
                '' + varTextTab +   //111-number_of_doors
                '' + varTextTab +   //112-noise_level
                '' + varTextTab +   //113-material_composition
                '' + varTextTab +   //114-noise_level_unit_of_measure
                '' + varTextTab +   //115-line_weight
                '' + varTextTab +   //116-maximum_weight_capacity
                '' + varTextTab +   //117-item_type_name
                '' + varTextTab +   //118-maximum_weight_capacity_unit_of_measure
                '' + varTextTab +   //119-item_styling	
                '' + varTextTab +   //120-item_shape
                '' + varTextTab +   //121-item_hardness
                '' + varTextTab +   //122-included_components1
                '' + varTextTab +   //123-included_components2
                '' + varTextTab +   //124-included_components3
                '' + varTextTab +   //125-included_components4
                '' + varTextTab +   //126-included_components5
                '' + varTextTab +   //127-included_components6
                '' + varTextTab +   //128-included_components7
                '' + varTextTab +   //129-included_components8
                '' + varTextTab +   //130-included_components9
                '' + varTextTab +   //131-included_components10
                '' + varTextTab +   //132-has_automatic_shutoff
                '' + varTextTab +   //133-installation_type
                '' + varTextTab +   //134-compatible_devices
                '' + varTextTab +   //135-capacity_unit_of_measure
                '' + varTextTab +   //136-frame_type
                '' + varTextTab +   //137-efficiency
                '' + varTextTab +   //138-capacity
                '' + varTextTab +   //139-form_factor1
                '' + varTextTab +   //140-form_factor2
                '' + varTextTab +   //141-form_factor3
                '' + varTextTab +   //142-form_factor4
                '' + varTextTab +   //143-form_factor5
                '' + varTextTab +   //144-eu_energy_label_efficiency_class
                '' + varTextTab +   //145-blade_material_type
                '' + varTextTab +   //146-finish_type1
                '' + varTextTab +   //147-finish_type2
                '' + varTextTab +   //148-finish_type3
                '' + varTextTab +   //149-finish_type4
                '' + varTextTab +   //150-finish_type5
                '' + varTextTab +   //151-blade_edge_type
                '' + varTextTab +   //152-adjustment_type
                '' + varTextTab +   //153-annual_energy_consumption	
                '' + varTextTab +   //154-annual_energy_consumption_unit_of_measure
                '' + varTextTab +   //155-battery_form_factor
                '' + varTextTab +   //156-power_plug_type
                '' + varTextTab +   //157-item_width_unit_of_measure
                '' + varTextTab +   //158-item_width
                '' + varTextTab +   //159-item_height
                '' + varTextTab +   //160-item_height_unit_of_measure
                '' + varTextTab +   //161-item_dimensions_unit_of_measure
                '' + varTextTab +   //162-item_length_unit_of_measure
                '' + varTextTab +   //163-item_length
                '' + varTextTab +   //164-item_display_depth
                '' + varTextTab +   //165-item_display_depth_unit_of_measure
                '' + varTextTab +   //166-website_shipping_weight
                '' + varTextTab +   //167-website_shipping_weight_unit_of_measure
                '' + varTextTab +   //168-item_display_length
                '' + varTextTab +   //169-item_display_length_unit_of_measure
                '' + varTextTab +   //170-item_display_width
                '' + varTextTab +   //171-item_display_width_unit_of_measure
                '' + varTextTab +   //172-item_display_height
                '' + varTextTab +   //173-item_display_height_unit_of_measure
                '' + varTextTab +   //174-item_display_diameter
                '' + varTextTab +   //175-item_display_diameter_unit_of_measure
                '' + varTextTab +   //176-item_display_weight
                '' + varTextTab +   //177-item_display_weight_unit_of_measure
                '' + varTextTab +   //178-volume_capacity_name
                '' + varTextTab +   //179-volume_capacity_name_unit_of_measure
                '' + varTextTab +   //180-item_display_volume
                '' + varTextTab +   //181-item_display_volume_unit_of_measure
                '' + varTextTab +   //182-item_diameter_derived
                '' + varTextTab +   //183-item_diameter_unit_of_measure
                '' + varTextTab +   //184-item_thickness_unit_of_measure
                '' + varTextTab +   //185-item_thickness_derived
                '' + varTextTab +   //186-package_weight_unit_of_measure
                '' + varTextTab +   //187-package_dimensions_unit_of_measure
                '' + varTextTab +   //188-package_weight
                '' + varTextTab +   //189-package_length
                '' + varTextTab +   //190-package_width
                '' + varTextTab +   //191-package_height
                '' + varTextTab +   //192-fulfillment_center_id
                '' + varTextTab +   //193-specific_uses_for_product1
                '' + varTextTab +   //194-specific_uses_for_product2
                '' + varTextTab +   //195-specific_uses_for_product3
                '' + varTextTab +   //196-specific_uses_for_product4
                '' + varTextTab +   //197-specific_uses_for_product5
                '' + varTextTab +   //198-product_efficiency_image_url
                '' + varTextTab +   //199-energy_efficiency_image_url
                '' + varTextTab +   //200-legal_disclaimer_description	
                '' + varTextTab +   //201-safety_warning
                '' + varTextTab +   //202-fedas_id
                '' + varTextTab +   //203-eu_toys_safety_directive_age_warning
                '' + varTextTab +   //204-eu_toys_safety_directive_warning
                '' + varTextTab +   //205-eu_toys_safety_directive_language
                '' + varTextTab +   //206-country_string
                '' + varTextTab +   //207-are_batteries_included
                '' + varTextTab +   //208-batteries_required
                '' + varTextTab +   //209-battery_type1
                '' + varTextTab +   //210-battery_type2
                '' + varTextTab +   //211-battery_type3
                '' + varTextTab +   //212-number_of_batteries1
                '' + varTextTab +   //213-number_of_batteries2
                '' + varTextTab +   //214-number_of_batteries3
                '' + varTextTab +   //215-battery_cell_composition
                '' + varTextTab +   //216-battery_weight
                '' + varTextTab +   //217-battery_weight_unit_of_measure
                '' + varTextTab +   //218-number_of_lithium_metal_cells
                '' + varTextTab +   //219-number_of_lithium_ion_cells
                '' + varTextTab +   //220-lithium_battery_packaging
                '' + varTextTab +   //221-lithium_battery_energy_content
                '' + varTextTab +   //222-lithium_battery_energy_content_unit_of_measure
                '' + varTextTab +   //223-lithium_battery_weight
                '' + varTextTab +   //224-lithium_battery_weight_unit_of_measure
                '' + varTextTab +   //225-supplier_declared_dg_hz_regulation1
                '' + varTextTab +   //226-supplier_declared_dg_hz_regulation2
                '' + varTextTab +   //227-supplier_declared_dg_hz_regulation3
                '' + varTextTab +   //228-supplier_declared_dg_hz_regulation4
                '' + varTextTab +   //229-supplier_declared_dg_hz_regulation5
                '' + varTextTab +   //230-hazmat_united_nations_regulatory_id
                '' + varTextTab +   //231-safety_data_sheet_url
                '' + varTextTab +   //232-item_weight
                '' + varTextTab +   //233-item_weight_unit_of_measure
                '' + varTextTab +   //234-item_volume
                '' + varTextTab +   //235-item_volume_unit_of_measure
                '' + varTextTab +   //236-flash_point
                '' + varTextTab +   //237-ghs_classification_class1
                '' + varTextTab +   //238-ghs_classification_class2
                '' + varTextTab +   //239-ghs_classification_class3
                '' + varTextTab +   //240-list_price
                '' + varTextTab +   //241-weee_tax_value
                '' + varTextTab +   //242-number_of_items
                '' + varTextTab +   //243-weee_tax_value_unit_of_measure
                '' + varTextTab +   //244-offering_end_date
                '' + varTextTab +   //245-max_order_quantity
                '' + varTextTab +   //246-offering_start_date
                '' + varTextTab +   //247-delivery_schedule_group_id
                '' + varTextTab +   //248-product_site_launch_date
                '' + varTextTab +   //249-currency
                '' + varTextTab +   //250-item_package_quantity
                '' + varTextTab +   //251-product_tax_code
                '' + varTextTab +   //252-merchant_release_date
                '' + varTextTab +   //253-sale_price
                '' + varTextTab +   //254-sale_from_date
                '' + varTextTab +   //255-sale_end_date
                'NEW' + varTextTab +    //256-condition_type
                '' + varTextTab +   //257-fulfillment_latency
                '' + varTextTab +   //258-restock_date
                '' + varTextTab +   //259-max_aggregate_ship_quantity
                '' + varTextTab +   //260-offering_can_be_gift_messaged
                '' + varTextTab +   //261-offering_can_be_giftwrapped
                '' + varTextTab +   //262-is_discontinued_by_manufacturer
                '' + varTextTab +   //263-missing_keyset_reason
                '' + varTextTab +   //264-business_price
                '' + varTextTab +   //265-quantity_price_type
                '' + varTextTab +   //266-quantity_lower_bound1
                '' + varTextTab +   //267-quantity_price1
                '' + varTextTab +   //268-quantity_lower_bound2
                '' + varTextTab +   //269-quantity_price2	
                '' + varTextTab +   //270-quantity_lower_bound3
                '' + varTextTab +   //271-quantity_price3
                '' + varTextTab +   //272-quantity_lower_bound4
                '' + varTextTab +   //273-quantity_price4
                '' + varTextTab +   //274-quantity_lower_bound5
                '' + varTextTab +   //275-quantity_price5
                '' + varTextTab +   //276-national_stock_number
                '' + varTextTab +   //277-unspsc_code
                '' + varTextTab +   //278-pricing_action
                Format(country_of_origin_Name.Trim()) + varTextTab +    //279-country_of_origin
                Format(fabric).Trim() +    //280-fabric_type
                CR + LF);

                isProductDataInserted := true;
            until rec_Item.Next() = 0;

        ZipArchive.CreateZipArchive();
        TempInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
        ZipArchive.AddEntry(TempInStream, 'Product.txt');
        ZipArchive.SaveZipArchive(tmpBlob);
        ZipInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
        ProductFileData := cdu_Base64.ToBase64(ZipInStream);
        if isGUIAllowed = false then begin
            FileName := FileName + '.zip';
            DownloadFromStream(ZipInStream, '', '', '', FileName);
        end;
        exit(ProductFileData);
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

    local procedure CalculateSalesPrice(recItem: Record Item): Text;
    var
        // rec_Item: Record Item;
        rec_GenProductPostingGroup: Record "Gen. Product Posting Group";
        rec_VatProductPostingGroup: Record "VAT Product Posting Group";
        rec_VatPostingSetup: Record "VAT Posting Setup";
        rec_AmazonSetting: Record "Amazon Setting";
        rec_AppeagleRates: Record AppeagleRates;
        rec_ItemLegderEntry: Record "Item Ledger Entry";
        Price1, Rate, MarginProtection, Price2, SalesPrice, standardsellPricewithVat, FIFOCost : Decimal;
        cdu_ItemVatCalculation: Codeunit ItemVatCalculation;
        standardPrice: Text;
    begin
        //Price1
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
            rec_ItemLegderEntry.SetAscending("Posting Date", true);
            if rec_ItemLegderEntry.FindFirst() then begin
                rec_ItemLegderEntry.CalcFields("Cost Amount (Actual)");
                fifoCost := (rec_ItemLegderEntry."Cost Amount (Actual)" / rec_ItemLegderEntry.Quantity);
            end
            else
                fifoCost := recItem."Last Direct Cost";
        end
        else begin
            fifoCost := recItem."Last Direct Cost";
        end;

        //Determine Packaging type rate
        if recItem.PARCEL_SIZE = '' then begin

            recItem.CalcFields(AMAZON_API_WEIGHT);

            if (recItem.AMAZON_API_WEIGHT > 1500) or ((recItem.AMAZON_API_WEIGHT = 0) and (recItem."Unit Price" > 50))
            then begin
                rec_AppeagleRates.SetFilter(Code, 'Carrier Box');
                if rec_AppeagleRates.FindSet() then begin
                    Rate := rec_AppeagleRates.Rate;
                end;
            end
            else begin
                rec_AppeagleRates.SetFilter(Code, 'Packet Post');
                if rec_AppeagleRates.FindSet() then begin
                    Rate := rec_AppeagleRates.Rate;
                end;
            end;
        end
        else begin
            if (recItem.PARCEL_SIZE = 'Box Post') or (recItem.PARCEL_SIZE = 'UPS18') then begin
                rec_AppeagleRates.SetFilter(Code, 'Carrier Box');
                if rec_AppeagleRates.FindSet() then begin
                    Rate := rec_AppeagleRates.Rate;
                end;
            end
            else begin
                rec_AppeagleRates.SetRange(Code, recItem.PARCEL_SIZE);
                if rec_AppeagleRates.FindSet() then begin
                    Rate := rec_AppeagleRates.Rate;
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

        standardPrice := FORMAT(Round(SalesPrice, 0.01), 0, '<Precision,2:2><Standard Format,0>');
        standardPrice := standardPrice.Replace(',', '');

        exit(standardPrice);
    end;

    local procedure CalculateAmazonAvailbleStock(recItem: Record Item): Decimal
    var
        AmazonAvailableStock: Decimal;
    begin
        recItem.CalcFields(Inventory);
        recItem.CalcFields("Qty. on Sales Order");
        recItem.CalcFields("Qty. on Asm. Component");
        recItem.CalcFields(QtyAtReceive);

        AmazonAvailableStock := recItem.Inventory - recItem."Qty. on Sales Order" - recItem.QtyAtReceive - recItem."Qty. on Asm. Component";
        if AmazonAvailableStock < 0 then
            AmazonAvailableStock := 0;
        exit(AmazonAvailableStock);
    end;

    procedure getQtyCanBeAssembled(sku: code[20]): integer
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

    local procedure getReferenceofBarcode(recItem: Record Item): Code[50]
    var
        rec_ItemReference: Record "Item Reference";
        barcode: Code[50];
    begin
        rec_ItemReference.Reset();
        rec_ItemReference.SetRange("Item No.", recItem."No.");
        rec_ItemReference.SetRange("Reference Type", "Item Reference Type"::"Bar Code");
        if rec_ItemReference.FindFirst() then begin
            barcode := rec_ItemReference."Reference No.";
        end;
        exit(barcode);
    end;

    local procedure getItemBrand(recItem: Record Item): Code[50]
    var
        ItemAttributeId, ItemAttributeValueId : Integer;
        Brand: Code[50];
        recItemAttribute: Record "Item Attribute";
        recItemAttributeValue: Record "Item Attribute Value";
        recItemAttributeValueMap: Record "Item Attribute Value Mapping";

    begin
        recItemAttribute.Reset();
        recItemAttribute.SetRange("Name", 'brand');
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
            Brand := recItemAttributeValue.Value;
        end;
        exit(Brand);
    end;

    local procedure getItemClothingSize(recItem: Record Item): Code[50]
    var
        ItemAttributeId, ItemAttributeValueId : Integer;
        clothingSize: Code[50];
        recItemAttribute: Record "Item Attribute";
        recItemAttributeValue: Record "Item Attribute Value";
        recItemAttributeValueMap: Record "Item Attribute Value Mapping";

    begin
        recItemAttribute.Reset();
        recItemAttribute.SetRange("Name", 'clothing_size');
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
            clothingSize := recItemAttributeValue.Value;
        end;
        exit(clothingSize);
    end;

    local procedure getItemFabricType(recItem: Record Item): Code[50]
    var
        ItemAttributeId, ItemAttributeValueId : Integer;
        fabricType: Code[50];
        recItemAttribute: Record "Item Attribute";
        recItemAttributeValue: Record "Item Attribute Value";
        recItemAttributeValueMap: Record "Item Attribute Value Mapping";

    begin
        recItemAttribute.Reset();
        recItemAttribute.SetRange("Name", 'fabric');
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
            fabricType := recItemAttributeValue.Value;
        end;

        exit(fabricType);
    end;

    procedure generateAuthenticationKey(): Text
    var
        DateForWeek: Record Date;
        Authenticate: Text;
        cdu_Base64: Codeunit "Base64 Convert";
        Base64Data: text;
    begin
        DateForWeek.Get(DateForWeek."Period Type"::Date, Today);
        Authenticate := Format(CurrentDateTime, 0, 9) + '-' + DateForWeek."Period Name";
        Authenticate := DelStr(Authenticate, 11, 14);
        Base64Data := cdu_Base64.ToBase64(Authenticate);
        exit(Base64Data);
    end;

    procedure SendToApiStockLevelFeedData()
    var
        RESTAPIHelper: Codeunit "REST API Helper";
        URI, body, result, errorMessage : Text;
        varJsonArray, Jarray : JsonArray;
        varjsonToken, Jtoken : JsonToken;
        i: Integer;
        JObject: JsonObject;
        rec_AmazonSetting: Record "Amazon Setting";
        isGUIAllowed: Boolean;
        environment: Integer;
        ZipArchive: Codeunit "Data Compression";

    begin
        isGUIAllowed := true;
        if GuiAllowed then begin
            isGUIAllowed := Dialog.Confirm('Yes: Send To API\No: Download To Browser');
        end;

        rec_AmazonSetting.Reset();
        if rec_AmazonSetting.FindSet() then begin
            Clear(RESTAPIHelper);
            repeat

                if rec_AmazonSetting.Environment = rec_AmazonSetting.Environment::Sandbox then begin
                    environment := 0;
                end
                else begin
                    environment := 1;
                end;

                if rec_AmazonSetting."Product / Stock File" then begin
                    Clear(RESTAPIHelper);
                    URI := RESTAPIHelper.GetBaseURl() + 'Amazon/SubmitFeed/StockLevel';
                    RESTAPIHelper.Initialize('POST', URI);
                    RESTAPIHelper.AddRequestHeader('AccessKey', rec_AmazonSetting.APIKey.Trim());
                    RESTAPIHelper.AddRequestHeader('SecretKey', rec_AmazonSetting.APISecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RoleArn', rec_AmazonSetting.RoleArn.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientId', rec_AmazonSetting.ClientId.Trim());
                    RESTAPIHelper.AddRequestHeader('ClientSecret', rec_AmazonSetting.ClientSecret.Trim());
                    RESTAPIHelper.AddRequestHeader('RefreshToken', rec_AmazonSetting.RefreshToken.Trim());
                    RESTAPIHelper.AddRequestHeader('MarketPlaceId', rec_AmazonSetting.MarketplaceID.Trim());
                    RESTAPIHelper.AddRequestHeader('environment', format(environment));

                    //Body
                    isStockDataInserted := false;
                    body := CreateStockLevelFeedTxtFile(isGUIAllowed);
                    RESTAPIHelper.AddBody('{"base64EncodedData":"' + body + '"}');
                    //ContentType
                    RESTAPIHelper.SetContentType('application/json');

                    if isGUIAllowed then
                        if isStockDataInserted then begin
                            if RESTAPIHelper.Send(EnhIntegrationLogTypes::Amazon) then begin
                                result := RESTAPIHelper.GetResponseContentAsText();
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
                                Message('Successfully Uploaded Stock File');
                            end;
                        end
                        else
                            Message('No Stock Data Found');
                end
                else begin
                    errorMessage := 'The Upload Product / Stock is disabled for the customer; please grant access to proceed.';
                    cu_CommonHelper.InsertWarningForAmazon(errorMessage, rec_AmazonSetting.CustomerCode, 'Customer Id', EnhIntegrationLogTypes::Amazon)
                end;
            until rec_AmazonSetting.Next() = 0;
        end;
    end;

    // local procedure CreateStockLevelFeedTxtFile(isGUIAllowed: Boolean): Text
    // var
    //     InStr: InStream;
    //     OutStr: OutStream;
    //     tmpBlob: Codeunit "Temp Blob";
    //     FileName: Text;
    //     rec_Item: Record Item;
    //     cdu_Base64: Codeunit "Base64 Convert";
    //     StockLevelFeedTxt: Text;
    //     Quantity: Decimal;
    //     varTab: Char;
    //     varTextTab: Text;
    //     ItemSKU: Code[20];
    //     ZipArchive: Codeunit "Data Compression";
    //     ZipInStream: InStream;
    //     TempInStream: InStream;
    //     recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    //     cuStockLevel: Codeunit StockLevel;

    // begin
    //     varTab := 9;
    //     varTextTab := Format(varTab);
    //     FileName := 'StockLevel';
    //     tmpBlob.CreateOutStream(OutStr, TextEncoding::Windows);
    //     OutStr.WriteText('SKU' + varTextTab + 'Quantity' + varTextTab + 'FullfilmentLatency');
    //     OutStr.WriteText();

    //     rec_Item.Reset();
    //     rec_Item.SetRange(SHOW_ON_AMAZON, true);
    //     rec_Item.SetRange(RESTRICTED_18, false);
    //     rec_Item.SetRange(Blocked, false);

    //     if rec_Item.FindSet() then begin

    //         repeat

    //             ItemSKU := rec_Item."No.";

    //             // Quantity := (CalculateAmazonAvailbleStock(rec_Item) + getQtyCanBeAssembled(ItemSKU)) - rec_Item.NON_LIST_STOCK;
    //             Quantity := cuStockLevel.GetQuantity(ItemSKU, false);

    //             if Quantity < 0 then
    //                 Quantity := 0;

    //             OutStr.WriteText(Format(rec_Item."No.") + varTextTab + Format(Quantity, 0, 1) + varTextTab + '0');
    //             OutStr.WriteText();
    //             isStockDataInserted := true;

    //         until rec_Item.Next() = 0;
    //     end;

    //     recAmazonItemsStockLevel.Reset();
    //     recAmazonItemsStockLevel.SetRange(isSentToAmazonStockLevel, true);
    //     recAmazonItemsStockLevel.SetRange(isSent, false);
    //     if recAmazonItemsStockLevel.FindSet() then begin
    //         Quantity := 0;
    //         repeat
    //             rec_Item.Reset();
    //             rec_Item.SetRange("No.", recAmazonItemsStockLevel.ItemNo);
    //             rec_Item.SetRange(RESTRICTED_18, false);
    //             if rec_Item.FindFirst() then begin

    //                 OutStr.WriteText(Format(recAmazonItemsStockLevel.ItemNo) + varTextTab + Format(Quantity, 0, 1) + varTextTab + '0');
    //                 OutStr.WriteText();

    //                 isStockDataInserted := true;

    //                 recAmazonItemsStockLevel.isSentToAmazonStockLevel := false;
    //                 recAmazonItemsStockLevel.isSent := true;
    //                 recAmazonItemsStockLevel.Modify(true);
    //             end;
    //         until recAmazonItemsStockLevel.Next() = 0;
    //     end;

    //     ZipArchive.CreateZipArchive();
    //     TempInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
    //     ZipArchive.AddEntry(TempInStream, 'StockLevel.txt');
    //     ZipArchive.SaveZipArchive(tmpBlob);
    //     ZipInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
    //     StockLevelFeedTxt := cdu_Base64.ToBase64(ZipInStream);

    //     if isGUIAllowed = false then begin
    //         FileName := FileName + '.zip';
    //         DownloadFromStream(ZipInStream, '', '', '', FileName);
    //     end;
    //     exit(StockLevelFeedTxt);
    // end;

    local procedure CreateStockLevelFeedTxtFile(isGUIAllowed: Boolean): Text
    var
        InStr: InStream;
        OutStr: OutStream;
        tmpBlob: Codeunit "Temp Blob";
        FileName: Text;
        rec_Item: Record Item;
        cdu_Base64: Codeunit "Base64 Convert";
        StockLevelFeedTxt: Text;
        Quantity: Decimal;
        varTab: Char;
        varTextTab: Text;
        ItemSKU: Code[20];
        ZipArchive: Codeunit "Data Compression";
        ZipInStream: InStream;
        TempInStream: InStream;
        cuStockLevel: Codeunit StockLevel;
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin
        // isSent Flag is set to True on Triggers codeunit EventSubscribers
        varTab := 9;
        varTextTab := Format(varTab);
        FileName := 'StockLevel';
        tmpBlob.CreateOutStream(OutStr, TextEncoding::Windows);
        OutStr.WriteText('SKU' + varTextTab + 'Quantity' + varTextTab + 'FullfilmentLatency');
        OutStr.WriteText();

        rec_Item.Reset();
        rec_Item.SetRange(SHOW_ON_AMAZON, true);
        rec_Item.SetRange(RESTRICTED_18, false);
        rec_Item.SetRange(Blocked, false);

        if rec_Item.FindSet() then begin
            repeat

                ItemSKU := rec_Item."No.";
                Quantity := cuStockLevel.GetQuantity(ItemSKU, false);

                if Quantity < 0 then begin
                    Quantity := 0;
                end;

                recAmazonItemsStockLevel.Reset();
                recAmazonItemsStockLevel.SetRange(ItemNo, ItemSKU);
                recAmazonItemsStockLevel.SetRange(isBlocked, false);
                recAmazonItemsStockLevel.SetRange(isSent, false);

                if recAmazonItemsStockLevel.FindFirst() then begin
                    if (recAmazonItemsStockLevel.Quantity <> Quantity) then begin

                        OutStr.WriteText(Format(rec_Item."No.") + varTextTab + Format(Quantity, 0, 1) + varTextTab + '0');
                        OutStr.WriteText();
                        isStockDataInserted := true;
                        StoreQtyAmazon(rec_Item."No.", Quantity, true);
                    end;
                end;
            until rec_Item.Next() = 0;
        end;

        // send to Amazon Zero if blocked or ShowonAmazon is false
        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(isBlocked, true);
        recAmazonItemsStockLevel.SetRange(isSent, false);

        if recAmazonItemsStockLevel.FindSet() then begin
            repeat
                OutStr.WriteText(Format(recAmazonItemsStockLevel.ItemNo) + varTextTab + '0' + varTextTab + '0');
                OutStr.WriteText();
                StoreQtyAmazon(recAmazonItemsStockLevel.ItemNo, 0, true);
            until recAmazonItemsStockLevel.Next() = 0;
        end;

        ZipArchive.CreateZipArchive();
        TempInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
        ZipArchive.AddEntry(TempInStream, 'StockLevel.txt');
        ZipArchive.SaveZipArchive(tmpBlob);
        ZipInStream := tmpBlob.CreateInStream(TextEncoding::Windows);
        StockLevelFeedTxt := cdu_Base64.ToBase64(ZipInStream);

        if isGUIAllowed = false then begin
            FileName := FileName + '.zip';
            DownloadFromStream(ZipInStream, '', '', '', FileName);
        end;
        exit(StockLevelFeedTxt);
    end;

    procedure StoreQtyAmazon(ItemNo: Code[50]; quantity: Decimal; isUpdate: Boolean)
    var
        recAmazonItemsStockLevel: Record AmazonItemsStockLevel;
    begin

        recAmazonItemsStockLevel.Reset();
        recAmazonItemsStockLevel.SetRange(ItemNo, ItemNo);

        if recAmazonItemsStockLevel.FindFirst() then begin
            recAmazonItemsStockLevel.Quantity := quantity;
            recAmazonItemsStockLevel.isSent := true;
            recAmazonItemsStockLevel.Modify(true);
        end else begin
            recAmazonItemsStockLevel.Init();
            recAmazonItemsStockLevel.Id := CreateGuid();
            recAmazonItemsStockLevel.ItemNo := ItemNo;
            recAmazonItemsStockLevel.Quantity := quantity;
            recAmazonItemsStockLevel.isSent := true;
            recAmazonItemsStockLevel.Insert(true);
        end;
        Commit();
    end;

    procedure RemoveMarkupTags(sampleText: Text): Text
    var
        FullDescription: Text;
        CR, LF : char;
    begin
        CR := 13;
        LF := 10;
        Clear(FullDescription);
        WHILE STRPOS(sampleText, '<') > 0 DO begin
            IF STRPOS(sampleText, '>') > STRPOS(sampleText, '<') THEN BEGIN
                sampleText := DELSTR(sampleText, STRPOS(sampleText, '<'), STRPOS(sampleText, '>') - STRPOS(sampleText, '<') + 1);
            END
            ELSE BEGIN
                sampleText := DELSTR(sampleText, STRPOS(sampleText, '<'), STRLEN(sampleText) - STRPOS(sampleText, '<') + 1);
            END;
        END;
        FullDescription := DelChr(sampleText, '=', LF);
        FullDescription := DelChr(FullDescription, '=', CR);
        exit(FullDescription);
    end;
}

