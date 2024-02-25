table 50427 SortedWebCategory
{
    Caption = 'SortedWebCategory';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; id; Guid)
        {
            Caption = 'id';
            DataClassification = ToBeClassified;
        }
        field(2; "Magento ID"; Integer)
        {
            Caption = 'Magento ID';
            DataClassification = ToBeClassified;
        }
        field(3; Sequence; Integer)
        {
            Caption = 'Sequence ';
            DataClassification = ToBeClassified;
        }
        field(4; Level; Integer)
        {
            Caption = 'Level ';
            DataClassification = ToBeClassified;
        }
        field(5; BrowseNode; BigInteger)
        {
            Caption = 'BrowseNode';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }
}
