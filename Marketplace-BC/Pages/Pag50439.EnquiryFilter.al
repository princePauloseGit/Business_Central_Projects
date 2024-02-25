page 50439 EnquiryFilter
{
    Caption = 'Enquiry Filter';
    PageType = XmlPort;
    UsageCategory = Administration;
    ApplicationArea = all;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(ExternalDOCNo; ExternalDOCNo)
                {
                    ApplicationArea = All;

                    Caption = 'External Document No.';
                    Editable = true;

                    trigger OnValidate()
                    var
                        user: Text;
                    begin
                        user := UserId;
                        if (Rec.ExternalDocNo <> '') Or (Rec.shipToCode <> '') or (Rec.BillPostCode <> '') or (Rec.SalesOrderNo <> '') then begin
                            Rec.ExternalDocNo := ExternalDOCNo;
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.Modify(true);
                            Commit();
                        end
                        else begin
                            Rec.Init();
                            Rec.No := CreateGuid();
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.ExternalDocNo := ExternalDOCNo;
                            Rec.Insert(true);
                            Commit();
                        end;

                    end;
                }
                field(shipToCode; shipToCode)
                {
                    ApplicationArea = All;
                    Caption = 'Ship To Code';
                    Editable = true;
                    trigger OnValidate()
                    var
                        user: Text;
                    begin
                        user := UserId;
                        if (Rec.ExternalDocNo <> '') Or (Rec.shipToCode <> '') or (Rec.BillPostCode <> '') or (Rec.SalesOrderNo <> '') then begin
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.shipToCode := shipToCode;
                            Rec.Modify(true);
                            Commit();
                        end
                        else begin
                            Rec.Init();
                            Rec.No := CreateGuid();
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.ShiptoCode := shipToCode;
                            Rec.Insert(true);
                            Commit();
                        end;
                    end;
                }
                field(PostCode; PostCode)
                {
                    ApplicationArea = All;
                    Caption = 'Post Code';
                    Editable = true;
                    trigger OnValidate()
                    var
                        user: Text;
                    begin
                        user := UserId;
                        if (Rec.ExternalDocNo <> '') Or (Rec.shipToCode <> '') or (Rec.BillPostCode <> '') or (Rec.SalesOrderNo <> '') then begin
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.BillPostCode := PostCode;
                            Rec.Modify(true);
                            Commit();
                        end
                        else begin
                            Rec.Init();
                            Rec.No := CreateGuid();
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.BillPostCode := PostCode;
                            Rec.Insert(true);
                            Commit();
                        end;
                    end;
                }
                field(SalesNo; SalesNo)
                {
                    ApplicationArea = All;
                    TableRelation = "Sales Header"."No.";
                    Caption = 'Sales Order No.';
                    Editable = true;
                    trigger OnValidate()
                    var
                        user: Text;
                    begin

                        user := UserId;
                        if (Rec.ExternalDocNo <> '') Or (Rec.shipToCode <> '') or (Rec.BillPostCode <> '') then begin
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.SalesOrderNo := SalesNo;
                            Rec.Modify(true);
                            Commit();
                        end
                        else begin
                            Rec.Init();
                            Rec.No := CreateGuid();
                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.SalesOrderNo := SalesNo;
                            Rec.Insert(true);
                            Commit();
                        end;
                    end;
                }

                field(SalesArchiveNo; SalesArchiveNo)
                {
                    ApplicationArea = All;
                    TableRelation = "Sales Header Archive"."No.";

                    Caption = 'Sales Archive Order No.';
                    Editable = true;

                    trigger OnValidate()
                    var
                        user: Text;
                    begin
                        user := UserId;
                        if ((Rec.ExternalDocNo <> '') Or (Rec.shipToCode <> '') or (Rec.BillPostCode <> '') or (Rec.SalesOrderArchive <> '')) and (Rec.SalesOrderNo = '') then begin

                            Rec.userid := user;
                            Rec.sessionId := currentSessionID;
                            Rec.SalesOrderArchive := SalesArchiveNo;
                            Rec.Modify(true);
                            Commit();
                        end
                        else begin
                            Rec.Init();
                            Rec.No := CreateGuid();
                            Rec.userid := user;
                            rec.sessionId := currentSessionID;
                            Rec.SalesOrderArchive := SalesArchiveNo;
                            Rec.Insert(true);
                            Commit();
                        end;
                    end;
                }
            }

        }

    }
    procedure SetSessionId(newSessionId: Integer)
    var

    begin
        currentSessionID := newSessionId;
    end;

    var
        SalesNo: Code[20];
        SalesArchiveNo: Code[20];
        ExternalDOCNo: Code[35];
        PostCode: Code[50];
        shipToCode: Code[50];
        Archive: Boolean;
        Rec: Record EnquiryFilter;
        currentSessionID: Integer;

    trigger OnOpenPage()
    var
        myInt: Integer;
        rec_EnquiryFilter: Record EnquiryFilter;
        recEnquiries: Record Enquiries;
        recEnquiresLine: Record "Enquiries Line";
        recordLink: Record "Record Link";
    begin
        Clear(shipToCode);
        Clear(PostCode);
        Clear(Rec);
        Clear(Archive);
        Clear(ExternalDOCNo);
        Clear(SalesNo);

        Archive := false;

        recEnquiries.SetRange(sessionId, currentSessionID);
        recEnquiries.DeleteAll();

        recEnquiresLine.SetRange(SessionId, currentSessionID);
        recEnquiresLine.DeleteAll();
        Commit();

        // if format(Rec.sessionId) <> '' then begin
        //     rec_EnquiryFilter.SetRange(sessionId, sessionId);
        //     rec_EnquiryFilter.Delete(true);
        // end;

    end;

}

