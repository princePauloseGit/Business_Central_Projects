codeunit 50410 AmazonStockLevelFeedData
{
    trigger OnRun()
    var
        cu_AmazonProductFeeds: Codeunit AmazonProductFeeds;
    begin
        cu_AmazonProductFeeds.SendToApiStockLevelFeedData();
    end;
}
