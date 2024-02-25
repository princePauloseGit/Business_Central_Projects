page 50422 "FBA Calculation Settings List"
{
    ApplicationArea = All;
    Caption = 'FBA Calculation Settings List';
    PageType = List;
    SourceTable = FBACalculationSettings;
    UsageCategory = Lists;
    CardPageId = FBACalculationSettings;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(MarkupFactor; Rec.MarkupFactor)
                {
                    Caption = 'Markup Factor';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MarkupFactor field.';
                }
                field(CostPerKgUK; Rec.CostPerKgUK)
                {
                    Caption = 'Cost Per Kg UK';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CostPerKgUK field.';
                }
                field(CostPerKgEU; Rec.CostPerKgEU)
                {
                    Caption = 'Cost Per Kg EU';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CostPerKgEU field.';
                }
                field(EURExchangeRate; Rec.EURExchangeRate)
                {
                    Caption = 'EUR Exchange Rate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the EURExchangeRate field.';
                }
                field(BubbleWrapCost; Rec.BubbleWrapCost)
                {
                    Caption = 'Bubble Wrap Cost';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the BubbleWrapCost field.';
                }
                field(LabelCost; Rec.LabelCost)
                {
                    Caption = 'Label Cost';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the LabelCost field.';
                }
            }
        }
    }
}
