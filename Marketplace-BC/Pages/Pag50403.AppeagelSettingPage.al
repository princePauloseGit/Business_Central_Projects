page 50403 "AppeagelSettingPage"
{
    PageType = XmlPort;
    Caption = 'Appeagle';
    RefreshOnActivate = true;
    SourceTable = "Appeagle Setting";
    DataCaptionExpression = 'Appeagle';

    layout
    {
        area(Content)
        {
            group(General)
            {

                field(SFTPHost; Rec.SFTPHost)
                {
                    Caption = 'SFTP Host';
                    ApplicationArea = All;
                }

                field(SFTPuser; Rec.SFTPuser)
                {
                    Caption = 'SFTP User';
                    ApplicationArea = All;
                }
                field(SFTPPassword; Rec.SFTPPassword)
                {
                    Caption = 'SFTP Password';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field(SFTPdestinationpath; Rec.SFTPdestinationpath)
                {
                    Caption = 'SFTP Path';
                    ApplicationArea = All;
                }
                field(SFTPPort; Rec.SFTPPort)
                {
                    Caption = 'SFTP Port';
                    ApplicationArea = All;
                }
                field(RecordsPerRun; rec.RecordsPerRun)
                {
                    applicationarea = all;
                }
            }
        }
    }
}