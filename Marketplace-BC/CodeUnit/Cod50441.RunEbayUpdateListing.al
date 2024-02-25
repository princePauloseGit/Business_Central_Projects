codeunit 50441 RunEbayUpdateListing
{
    trigger OnRun()
    var
        cu_EbayListing: Codeunit EbayBulkCreateSingleListing;
    begin
        cu_EbayListing.SendToAPISingleListing('UPDATE');
    end;
}
