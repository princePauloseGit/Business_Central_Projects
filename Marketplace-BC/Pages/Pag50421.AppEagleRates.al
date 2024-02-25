page 50421 "AppEagleRates"
{
    Caption = 'AppEagle Rates';
    PageType = Card;
    SourceTable = AppeagleRates;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Rate; Rec.Rate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Rate field.';
                }
                field(AmazonCarrierMapping; Rec.AmazonCarrierMapping)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the AmazonCarrierMapping field.';
                    TableRelation = AmazonBoxSizes.Name where(isFBA = const(true));
                }
                field(EbayRate; Rec.EbayRate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the EbayRate field.';
                }
                field(MarkupRate; Rec.MarkupRate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MarkupRate field.';
                }
            }
        }
    }
}
