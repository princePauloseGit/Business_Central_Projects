page 50428 Enquiries
{
    Caption = 'Enquiries';

    CardPageId = EnquiriesCard;
    PageType = List;
    SourceTable = Enquiries;
    SourceTableView = sorting(No)
    order(descending);
    UsageCategory = Administration;
    RefreshOnActivate = true;
    ApplicationArea = All;

    layout
    {
        area(content)
        {

            repeater(General)
            {
                field(No; Rec.No) { ApplicationArea = All; }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                { ApplicationArea = All; Caption = 'Customer No'; }
                field("Sell-to Customer Name"; rec."Sell-to Customer Name")
                { ApplicationArea = All; Caption = 'Customer Name'; }
                field(Email; Rec.Email) { ApplicationArea = all; }
                field(Phone; Rec.Phone) { ApplicationArea = all; }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = all;
                    Caption = 'Ship-to City';
                }
                field("Ship-to Post Code"; rec."Ship-to Post Code") { ApplicationArea = all; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Postcode; rec.Postcode) { ApplicationArea = all; }
                field("Location"; Rec."Location Code") { ApplicationArea = All; }
                field(Status; rec.Status) { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(3),
                              "No." = FIELD(No);
            }
            systempart(PyamentTermsLinks; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(PyamentTermsNotes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DeleteAllUserSessions)
            {
                Caption = 'Delete All User Sessions';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    rec_enquiries: Record Enquiries;
                    varFilterPageBuilder: FilterPageBuilder;
                    recEnquiresLine: Record "Enquiries Line";
                    rec_EnquiryFilter: Record EnquiryFilter;
                begin
                    rec_EnquiryFilter.DeleteAll(true);
                    rec_enquiries.DeleteAll();
                    recEnquiresLine.DeleteAll();
                    Commit();
                end;
            }
            action("Open Enquiries Filter Page")
            {
                Caption = 'Open Enquiries Filter Page';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    sessionId, index : Integer;
                    orderId, messages, soMsg, saMsg : Text;
                    pge_EnquiryFilter: Page EnquiryFilter;
                    rec_EnquiryFilter: Record EnquiryFilter;
                    cdu_Enquiry: Codeunit EnquiriesAndReturns;
                    so_Messages, sa_Messages : Dictionary of [Integer, Text];
                begin
                    orderId := '';
                    messages := '';
                    soMsg := '';
                    saMsg := '';
                    index := 0;
                    pge_EnquiryFilter.SetSessionId(pageSessionId);

                    IF pge_EnquiryFilter.RunModal() = Action::OK then begin

                        rec_EnquiryFilter.Reset();
                        rec_EnquiryFilter.SetRange(sessionId, pageSessionId);

                        if rec_EnquiryFilter.FindSet() then begin

                            so_Messages := cdu_Enquiry.InsertEnquiriesHeader(rec_EnquiryFilter, pageSessionId);
                            sa_Messages := cdu_Enquiry.InsertArchiveOrder(rec_EnquiryFilter, pageSessionId);

                            if not so_Messages.Keys.Contains(pageSessionId) then begin
                                foreach sessionId in so_Messages.Keys do begin
                                    orderId := so_Messages.Get(sessionId);
                                    index := index + 1;

                                    if index <> so_Messages.Count then
                                        soMsg := soMsg + orderId + ', '
                                    else
                                        soMsg := soMsg + orderId;
                                end;
                            end;

                            index := 0;

                            if not sa_Messages.Keys.Contains(pageSessionId) then begin
                                foreach sessionId in sa_Messages.Keys do begin
                                    orderId := sa_Messages.Get(sessionId);
                                    index := index + 1;

                                    if sessionId <> sa_Messages.Count then
                                        saMsg := saMsg + orderId + ', '
                                    else
                                        saMsg := saMsg + orderId;
                                end;
                            end;

                            if soMsg <> '' then begin
                                messages := messages + soMsg
                            end;

                            if saMsg <> '' then begin
                                if messages <> '' then begin
                                    messages := messages + ', ' + saMsg;
                                end
                                else begin
                                    messages := messages + saMsg;
                                end;
                            end;

                            if messages <> '' then begin
                                Message('Sorry, ' + messages + ' records are being used by another user');
                            end;

                            Commit();
                            Rec.SetRange(SessionId, pageSessionId);
                        end;
                    end;
                    rec_EnquiryFilter.SetRange(sessionId, pageSessionId);
                    rec_EnquiryFilter.DeleteAll(true);
                end;
            }
            action(DeleteNotes)
            {
                Caption = 'Delete Notes From Enquiries And SalesOrder';
                Image = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    recSalesHeader: record "Sales Header";
                    recRecoredLink: record "Record Link";
                    recEnquiries: Record Enquiries;
                begin
                    recSalesHeader.SetRange("No.", 'SO000044662');
                    if recSalesHeader.FindFirst() then begin

                        recRecoredLink.SetRange("Record ID", recSalesHeader.RecordId);
                        if recRecoredLink.FindSet() then begin
                            recRecoredLink.DeleteAll();
                        end;

                        recRecoredLink.SetRange("Record ID", recSalesHeader."Enq-Sales RecordId");
                        if recRecoredLink.FindSet() then begin
                            recRecoredLink.DeleteAll();
                        end;
                    end;
                end;
            }
        }
    }

    var
        pageSessionId: Integer;

    trigger OnOpenPage()
    var
        rec_EnquiryFilter: Record EnquiryFilter;
        recEnquiries: Record Enquiries;
        recEnquiresLine: Record "Enquiries Line";
        MaxTime: Duration;
        checkTime: Decimal;
    begin
        //StopSession(pageSessionId);
        Clear(pageSessionId);
        //Rec.Reset();
        pageSessionId := SessionId();
        Rec.SetRange(Rec.SessionId, pageSessionId);

        if recEnquiries.FindSet() then begin
            checkTime := 0;
            repeat
                MaxTime := CurrentDateTime - recEnquiries.SystemCreatedAt;
                checkTime := MaxTime / 60000;
                if checkTime > 10 then begin
                    recEnquiries.Delete();
                end;
            until recEnquiries.Next() = 0;
        end;

        if recEnquiresLine.FindSet() then begin
            checkTime := 0;
            repeat
                MaxTime := CurrentDateTime - recEnquiresLine.SystemCreatedAt;
                checkTime := MaxTime / 60000;
                if checkTime > 10 then begin
                    recEnquiresLine.Delete();
                end;
            until recEnquiresLine.Next() = 0;
        end;
    end;

    trigger OnClosePage()
    var
        rec_EnquiryFilter: Record EnquiryFilter;
        recEnquiries: Record Enquiries;
        recEnquiresLine: Record "Enquiries Line";
    begin
        rec_EnquiryFilter.SetRange(sessionId, pageSessionId);
        rec_EnquiryFilter.DeleteAll();

        recEnquiries.SetRange(sessionId, pageSessionId);
        recEnquiries.DeleteAll();

        recEnquiresLine.SetRange(SessionId, pageSessionId);
        recEnquiresLine.DeleteAll();

        Commit();
    end;
}
