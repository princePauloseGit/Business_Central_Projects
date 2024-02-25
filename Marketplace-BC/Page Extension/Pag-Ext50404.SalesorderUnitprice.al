pageextension 50404 "Sales order Unit price" extends "Sales Order Subform"
{
    layout
    {
        modify("Unit Price")
        {
            BlankZero = false;
        }
    }
}
