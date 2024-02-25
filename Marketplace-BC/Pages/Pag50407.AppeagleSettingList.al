page 50407 AppeagleSettingList
{
    ApplicationArea = All;
    Caption = 'Appeagle Setting';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "Appeagle Setting";
    CardPageId = AppeagelSettingPage;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(SFTPHost; Rec.SFTPHost)
                {
                    Editable = false;
                    Caption = 'SFTP Host';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SFTPHost field.';
                }
                field(SFTPuser; Rec.SFTPuser)
                {
                    Editable = false;
                    Caption = 'SFTP User';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SFTPuser field.';
                }
                field(SFTPdestinationpath; Rec.SFTPdestinationpath)
                {
                    Editable = false;
                    Caption = 'SFTP Path ';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SFTPdestinationpath field.';
                }
            }
        }

    }
    actions
    {
        area(Processing)
        {
            action(GenerateAppeagleCSV)
            {
                ApplicationArea = All;
                Caption = 'Generate Appeagle CSV';
                trigger OnAction()
                var
                    cu_AppeagleCSVGeneration: Codeunit AppeagleCSVGeneration;

                begin
                    cu_AppeagleCSVGeneration.GetAllItems();
                end;
            }
            action(UpdateDimensionFromAmazon)
            {
                ApplicationArea = All;
                Caption = 'Update Dimension From Amazon';
                trigger OnAction()
                var
                    cu_AppeagleCSVGeneration: Codeunit AppeagleCSVGeneration;
                begin
                    cu_AppeagleCSVGeneration.APIGetCatalogItems();
                end;
            }

            action(AddItems)
            {
                ApplicationArea = All;
                Caption = 'Add FBASKU to Item Dimensions Table';
                trigger OnAction()
                var
                    recItem: Record Item;
                    recItemDimensions: Record ItemDimensions;
                begin
                    recItemDimensions.DeleteAll();
                    recItemDimensions.Reset();

                    recItem.Reset();
                    recItem.SetFilter(FBA_SKU, '<>%1', '');
                    if recItem.FindSet() then begin
                        repeat
                            recItemDimensions.Init();
                            recItemDimensions.Id := GetLastLineNo();
                            recItemDimensions.No := recItem."No.";
                            recItemDimensions.FBA_SKU := recItem.FBA_SKU;
                            recItemDimensions.Insert(true);
                        until recItem.next() = 0;
                    end;
                end;
            }
        }
    }

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