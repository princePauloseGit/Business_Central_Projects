page 50423 DisplayUrl
{
    Caption = 'Post Refund To Provider';
    PageType = StandardDialog;
    UsageCategory = Administration;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field(AmazonRefundLink; AmazonRefundLink)
                {
                    ApplicationArea = All;
                    Caption = 'Please click here to process the Refund';
                    ToolTip = 'Specifies the value of the Link field.';
                    Editable = false;
                    ExtendedDatatype = URL;
                }
            }
        }
    }

    var
        AmazonRefundLink, BQRefundLink, eBayRefundLink : Text;
        isAmz, isBQ, iseBay : Boolean;

    procedure CreateAmazonLink(AmazonURL: Text)
    begin
        AmazonRefundLink := AmazonURL;
    end;
}
