table 50403 "Appeagle Setting"
{
    Caption = 'Appeagle Setting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; SFTPHost; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(3; SFTPuser; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(4; SFTPPassword; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(5; SFTPdestinationpath; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(6; SFTPPort; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(7; RecordsPerRun; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Max records per run';
        }
    }

    keys
    {
        key(PK; settingsid)
        {
            Clustered = true;
        }
    }
}