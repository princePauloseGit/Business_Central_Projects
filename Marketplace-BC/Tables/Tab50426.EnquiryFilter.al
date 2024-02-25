table 50426 EnquiryFilter
{
    Caption = 'Enquiry Filter';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; No; Guid)
        {
            Caption = 'No';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(2; SalesOrderNo; Code[20])
        {
            Caption = 'Sales Order No';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(3; SalesOrderArchive; Code[20])
        {
            Caption = 'Sales Order Archive';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(4; ExternalDocNo; Code[35])
        {
            Caption = 'External Doc No';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(5; BillPostCode; Code[20])
        {
            Caption = 'Post Code';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(6; ShiptoCode; Code[20])
        {
            Caption = 'Ship to Code';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(7; userid; Text[2048])
        {
            Caption = 'User ID';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(8; sessionId; Integer)
        {
            Caption = 'session ID';
            DataClassification = CustomerContent;
            Editable = true;
        }
    }
    keys
    {
        key(PK; No)
        {
            Clustered = true;
        }
    }
}
