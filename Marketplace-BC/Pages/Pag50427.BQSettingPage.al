page 50427 "B&QSettingPage"
{
    PageType = XmlPort;
    Caption = 'B&&Q Setting';
    SourceTable = "B&Q Settings";
    DataCaptionExpression = 'B&&Q Setting';
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(CustomerCode; Rec.CustomerCode)
                {
                    ApplicationArea = All;
                    TableRelation = Customer."No.";
                    ShowMandatory = true;
                }
                field(VendorCode; Rec.VendorCode)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    TableRelation = Vendor."No.";
                }
                field(APIKey; Rec.APIKey)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field(Limit; Rec.Limit)
                {
                    Editable = isVisible;
                    ApplicationArea = All;
                }
                field(manualTest; Rec.manualTest)
                {

                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                    begin
                        if Rec.manualTest then begin
                            isVisible := true;

                        end else begin
                            isVisible := false;
                            rec.Limit := 0;
                            rec.offset := '0';
                            rec.Modify(true);
                        end;
                    end;
                }
            }

        }
    }

    var
        isVisible: Boolean;


    trigger OnOpenPage()
    var
    begin
        if Rec.manualTest then begin
            isVisible := true;
        end else begin
            isVisible := false;
        end
    end;

}
