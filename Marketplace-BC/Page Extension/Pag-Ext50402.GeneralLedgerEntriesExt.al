pageextension 50402 "General Ledger Entries Ext" extends "General Ledger Entries"
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
