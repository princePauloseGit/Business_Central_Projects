page 50430 "Enquiries Order Subform"
{
    Caption = 'Enquiries Order Subform';
    PageType = ListPart;
    SourceTable = "Enquiries Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Type field.';
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.';
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.';
                    Editable = false;
                }

                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity field.';
                    Editable = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Unit Price field.';
                    Editable = false;
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity Invoiced field.';
                    Editable = false;
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity Shipped field.';
                    Editable = false;
                }
                field("Return/Replace"; Rec."Return/Replace")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Return/Replace field.';

                    trigger OnValidate()
                    var
                        cu_ItemVatCalculation: Codeunit ItemVatCalculation;
                        rec_Item: Record Item;
                        itemVat: Decimal;
                        rec_SalesLine: Record "Sales Line";
                        enum_DocumentType: Enum "Sales Document Type";
                    begin
                        if ((Rec."Return/Replace" > Rec.Quantity) or (Rec."Return/Replace" < 0) or (Rec."Return/Replace" > Rec."Quantity Shipped")) and ((Rec."Return/Replace" > Rec.Quantity) or (Rec."Return/Replace" > Rec."Quantity Invoiced") or (Rec."Return/Replace" < 0)) then begin
                            Error('Return/Replace quantity must less than or equal to Quantity Shipped and Quantity Invoice');
                        end;

                        rec_SalesLine.SetRange("Document Type", enum_DocumentType::Order);
                        rec_SalesLine.SetRange("Document No.", rec."Document No.");
                        rec_SalesLine.SetRange("Line No.", Rec."Line No.");

                        if rec_SalesLine.FindFirst() then begin
                            if Rec."Return/Replace" + rec_SalesLine."Total Returned" > rec_SalesLine.Quantity then begin
                                Error('Total return for item %1 exceeded than the quanity', rec."No.");
                            end;
                        end;

                    end;

                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Return Reason Code field.';
                    trigger OnValidate()
                    var
                        rec_EnquiryHeader: Record Enquiries;
                    begin
                        if Rec."Return Reason Code" <> '' then begin
                            rec_EnquiryHeader.SetRange(No, Rec."Document No.");
                            if rec_EnquiryHeader.FindSet() then begin
                                Page.run(Page::"Return Comment", rec_EnquiryHeader)
                            end;

                        end;
                    end;
                }
                field(VAT; Rec.VAT)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the VAT field.';
                    Editable = false;
                }
            }
        }
    }
}