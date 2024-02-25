page 50436 EbayListing
{
    ApplicationArea = All;
    Caption = 'eBay Listing Page';
    PageType = List;
    SourceTable = EbayListing;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                }
                field(sku; Rec.sku)
                {
                    ApplicationArea = All;
                }
                field(listingId; Rec.listingId)
                {
                    ApplicationArea = All;
                }
                field("action"; Rec.EbayAction)
                {
                    ApplicationArea = All;
                }
                field(isCompleted; Rec.isCompleted)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
