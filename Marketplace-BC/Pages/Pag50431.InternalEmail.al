page 50431 "Internal Email"
{
    Caption = 'Internal Email';
    PageType = XmlPort;
    SourceTable = EmailAlert;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Email Address"; Rec."Email Address")
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}
