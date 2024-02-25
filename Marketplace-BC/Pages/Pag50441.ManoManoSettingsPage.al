page 50441 ManoManoSettingsPage
{
    Caption = 'ManoMano Setting';
    PageType = XmlPort;
    SourceTable = ManoManoSettings;
    DataCaptionExpression = 'ManoMano Setting';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Customer Code"; Rec.CustomerCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CustomerCode field.';
                }
                field("Vendor Code"; Rec.VendorCode)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the VendorCode field.';
                }

                field("API Key"; Rec."API Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the API Key field.';
                }
                field("Contract ID"; Rec."Contract Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Contract Id field.';
                }
                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Environment field.';
                }
            }
        }
    }
}
