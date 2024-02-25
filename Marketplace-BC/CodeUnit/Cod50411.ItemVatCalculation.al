codeunit 50411 ItemVatCalculation
{
    procedure CalculateVat(recItem: Record Item): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PostingGroup: Text;
        unitPrice, baseSellPrice : Decimal;
    begin

        Clear(baseSellPrice);
        PostingGroup := recItem."VAT Prod. Posting Group";
        unitPrice := recItem."Unit Price";

        VATPostingSetup.SetFilter("VAT Prod. Posting Group", PostingGroup);
        if VATPostingSetup.FindFirst() then begin
            baseSellPrice := unitPrice + (unitPrice * (VATPostingSetup."VAT %" / 100));
            exit(baseSellPrice);
        end;
    end;
}
