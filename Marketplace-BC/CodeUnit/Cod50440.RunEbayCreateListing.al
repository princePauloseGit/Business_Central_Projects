codeunit 50440 RunEbayCreateListing
{
    trigger OnRun()
    var
        cu_EbayListing: Codeunit EbayBulkCreateSingleListing;
    begin
        cu_EbayListing.SendToAPISingleListing('CREATE');
    end;
}
