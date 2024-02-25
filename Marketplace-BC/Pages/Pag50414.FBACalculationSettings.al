page 50414 "FBACalculationSettings"
{
    Caption = 'FBA Calculation Settings';
    PageType = XmlPort;
    SourceTable = FBACalculationSettings;
    DataCaptionExpression = 'FBA Calculation Setting';

    layout
    {
        area(content)
        {
            group(General)
            {
                field(MarkupFactor; Rec.MarkupFactor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the MarkupFactor field.';
                }
                field(CostPerKgUK; Rec.CostPerKgUK)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CostPerKgUK field.';
                }
                field(CostPerKgEU; Rec.CostPerKgEU)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CostPerKgEU field.';
                }
                field(EURExchangeRate; Rec.EURExchangeRate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the EURExchangeRate field.';
                }
                field(BubbleWrapCost; Rec.BubbleWrapCost)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the BubbleWrapCost field.';
                }
                field(LabelCost; Rec.LabelCost)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the LabelCost field.';
                }
            }
        }
    }
}
