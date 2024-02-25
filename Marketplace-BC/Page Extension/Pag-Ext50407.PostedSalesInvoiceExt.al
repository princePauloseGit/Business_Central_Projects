pageextension 50407 "Posted Sales InvoiceExt" extends "Posted Sales Invoice"
{
    actions
    {
        addfirst(processing)
        {
            action(FullItemUpdate)
            {
                Caption = 'Confirm Shipment';
                ApplicationArea = All;
                Promoted = true;
                Image = Process;
                trigger OnAction();
                var
                    recBQConfirmShipment: Record BQConfirmShipment;
                    recManoConfirmShipment: Record ManoConfirmShipment;
                begin
                    if Rec."Shortcut Dimension 1 Code" = 'B&Q' then begin

                        if Rec."External Document No." <> '' then begin
                            recBQConfirmShipment.Reset();
                            recBQConfirmShipment.SetRange(OrderId, Rec."External Document No.");

                            if not recBQConfirmShipment.FindFirst() then begin
                                recBQConfirmShipment.Init();
                                recBQConfirmShipment.Id := CreateGuid();
                                recBQConfirmShipment.OrderId := Rec."External Document No.";
                                recBQConfirmShipment.ConfirmShipment := true;
                                recBQConfirmShipment.Insert(true);

                                Message('Shipment Updated for Order ID: %1', Rec."External Document No.");
                            end else begin
                                Message('Order Id already Shipped');
                            end;
                        end else begin
                            Message('External Document No is empty');
                        end;

                    end;
                    if Rec."Shortcut Dimension 1 Code" = 'MANOMANO' then begin

                        if Rec."External Document No." <> '' then begin
                            recManoConfirmShipment.Reset();
                            recManoConfirmShipment.SetRange(OrderId, Rec."External Document No.");

                            if not recManoConfirmShipment.FindFirst() then begin
                                recManoConfirmShipment.Init();
                                recManoConfirmShipment.Id := CreateGuid();
                                recManoConfirmShipment.OrderId := Rec."External Document No.";
                                recManoConfirmShipment.ConfirmShipment := true;
                                recManoConfirmShipment.Insert(true);

                                Message('Shipment Updated for Order ID: %1', Rec."External Document No.");
                            end else begin
                                Message('Order Id already Shipped');
                            end;
                        end else begin
                            Message('External Document No is empty');
                        end;
                    end;
                end;
            }
        }
    }
}
