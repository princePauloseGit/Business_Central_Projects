pageextension 50403 "VAT Entries Ext" extends "VAT Entries"
{
    layout
    {
        addafter("External Document No.")
        {
            field("Transaction No."; Rec."Transaction No.")
            {
                ApplicationArea = All;
                Caption = 'Transaction No.';
            }
        }
    }
}
