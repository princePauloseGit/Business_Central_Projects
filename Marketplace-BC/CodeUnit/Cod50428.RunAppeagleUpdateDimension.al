codeunit 50428 RunAppeagleUpdateDimension
{
    trigger OnRun()
    var
        cu_AppeagleCSVGeneration: Codeunit AppeagleCSVGeneration;
    begin
        cu_AppeagleCSVGeneration.APIGetCatalogItems();
    end;
}
