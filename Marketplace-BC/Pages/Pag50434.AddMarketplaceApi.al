page 50434 AddMarketplaceApi
{
    Caption = 'Add Marketplace Api';
    PageType = StandardDialog;
    SourceTable = MarketplaceHostAPI;
    DataCaptionExpression = 'Marketplace API';
    UsageCategory = Administration;
    Editable = true;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(MarketPlaceAPI; Rec.MarketPlaceAPI)
                {
                    ApplicationArea = All;
                    Caption = 'Marketplace Api';
                    Editable = true;

                    trigger OnValidate()
                    var
                        recMarketplaceHostAPI: Record MarketplaceHostAPI;
                    begin
                        recMarketplaceHostAPI.Date := CurrentDateTime;
                    end;
                }
                field(ModifiedAt; Rec.Date)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    trigger OnInit()
    begin
        if Rec.IsEmpty then
            Rec.Insert()
    end;

}
