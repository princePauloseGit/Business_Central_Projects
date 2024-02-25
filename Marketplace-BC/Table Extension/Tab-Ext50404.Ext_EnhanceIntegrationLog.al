tableextension 50404 "Ext_EnhanceIntegrationLog" extends EnhancedIntegrationLog
{
    fields
    {
        field(50101; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            Editable = false;
        }
    }
}
