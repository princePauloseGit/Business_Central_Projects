codeunit 50443 ManoManoJobQueue
{
    trigger OnRun()
    var
        cuManoOrderDownloads: Codeunit ManoOrderDownloads;
        cuManoAcceptOrders: Codeunit ManoAcceptOrders;
        cuManoShippingUpdate: Codeunit ManoShippingUpdate;
    begin
        cuManoOrderDownloads.ConnectManoAPIForSalesOrders();
        cuManoAcceptOrders.ConnectManoAcceptOrdersApi();
        cuManoShippingUpdate.ConnectManoShipmentApi();
    end;
}
