pageextension 50401 "Sales Order Archive Ext" extends "Sales Order Archive"
{
    layout
    {
        addafter(Status)
        {
            field("Source"; Rec.Source)
            {
                Editable = false;
                ApplicationArea = All;
                Caption = 'Source';
            }
        }
    }
}
