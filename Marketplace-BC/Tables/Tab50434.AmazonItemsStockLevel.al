table 50434 AmazonItemsStockLevel
{
    Caption = 'AmazonItemsStockLevel';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; ItemNo; Code[50])
        {
            Caption = 'ItemNo';
        }
        field(3; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(4; isSentToAmazonStockLevel; Boolean)
        {
            Caption = 'is Sent To Amazon Stock Level';
            DataClassification = ToBeClassified;
        }
        field(5; isSent; Boolean)
        {
            Caption = 'is Sent';
            DataClassification = ToBeClassified;
        }
        field(6; isBlocked; Boolean)
        {
            Caption = 'is Blocked';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(ItemNo; ItemNo)
        {
            Clustered = false;
        }
        key(isSentToAmazonStockLevel; isSentToAmazonStockLevel)
        {
            Clustered = false;
        }
        key(isBlocked; isBlocked)
        {
            Clustered = false;
        }
    }
}
