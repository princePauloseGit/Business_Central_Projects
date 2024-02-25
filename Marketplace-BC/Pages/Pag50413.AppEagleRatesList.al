page 50413 "AppEagle Rates List"
{
    ApplicationArea = All;
    Caption = 'Appeagle Rates List';
    PageType = List;
    SourceTable = AppeagleRates;
    UsageCategory = Lists;
    CardPageId = AppEagleRates;
    layout
    {
        area(content)
        {
            repeater(General)
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
                    Caption = 'Amazon Carrier Mapping';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the AmazonCarrierMapping field.';
                }
                field(EbayRate; Rec.EbayRate)
                {
                    Caption = 'Ebay Rate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the EbayRate field.';
                }
                field(MarkupRate; Rec.MarkupRate)
                {
                    Caption = 'Markup Rate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MarkupRate field.';
                }
            }
        }
    }
}
