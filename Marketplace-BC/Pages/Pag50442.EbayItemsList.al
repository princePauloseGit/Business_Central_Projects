page 50442 "Ebay Items List"
{
    ApplicationArea = All;
    Caption = 'Ebay Items List';
    PageType = List;
    SourceTable = EbayItemsList;
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
                field(LAST_INVENTORY; Rec.LAST_INVENTORY)
                {
                    ApplicationArea = All;
                }
                field(LAST_PRICE; Rec.LAST_PRICE)
                {
                    ApplicationArea = All;
                }
                field(Listing_ID; Rec.Listing_ID)
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Offer_ID; Rec.Offer_ID)
                {
                    ApplicationArea = All;
                }
                field(ForceUpdate; Rec.ForceUpdate)
                {
                    ApplicationArea = All;
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}
