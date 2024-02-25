codeunit 50400 InitialDataInsertion
{
    Subtype = Install;
    trigger OnInstallAppPerCompany();
    var
        myAppInfo: ModuleInfo;
    begin
        // Get info about the currently executing module
        NavApp.GetCurrentModuleInfo(myAppInfo);

        // A 'DataVersion' of 0.0.0.0 indicates a 'fresh/new' install
        if myAppInfo.DataVersion = Version.Create(0, 0, 0, 0) then begin
            InsertMarketPlaceDimensionValue('Amazon');
            InsertMarketPlaceDimensionValue('PayPal');
            InsertMarketPlaceDimensionValue('ebay');
            InsertMarketPlaceDimensionValue('OnBuy');
            InsertMarketPlaceDimensionValue('Website');
            InsertMarketPlaceDimensionValue('B&Q');
            InsertEntryDays();
        end
        else begin
            InsertMarketPlaceDimensionValue('Amazon');
            InsertMarketPlaceDimensionValue('PayPal');
            InsertMarketPlaceDimensionValue('ebay');
            InsertMarketPlaceDimensionValue('OnBuy');
            InsertMarketPlaceDimensionValue('Website');
            InsertMarketPlaceDimensionValue('B&Q');
            InsertEntryDays();
        end;
    end;

    procedure InsertMarketPlaceDimensionValue(DimensionCode: Code[20]): Boolean
    var
        recDimensionValue: Record "Dimension Value";
    begin
        recDimensionValue.SetRange("Dimension Code", 'DEPARTMENT');
        recDimensionValue.SetRange(Code, DimensionCode);

        if recDimensionValue.FindFirst() then begin
            exit(true);
        end
        else begin
            recDimensionValue.Init();
            recDimensionValue."Dimension Code" := 'DEPARTMENT';
            recDimensionValue.Code := DimensionCode;
            recDimensionValue.Validate(Code);
            recDimensionValue.Name := DimensionCode;
            recDimensionValue.Insert(true);
            exit(true);
        end;
    end;

    procedure InsertEntryDays()
    var
        rec_ReturnDays: Record ReturnDays;
    begin
        if rec_ReturnDays.Count = 0 then begin
            rec_ReturnDays.Init();
            rec_ReturnDays.Days := 1;
            rec_ReturnDays.Insert(true);
        end;

    end;
}
