pageextension 50405 "Sales return unit price" extends "Sales Return Order Subform"
{
    layout
    {
        modify("Unit Price")
        {
            BlankZero = false;
        }
    }
}
