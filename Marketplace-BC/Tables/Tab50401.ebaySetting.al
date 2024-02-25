table 50401 "ebay Setting"
{
    Caption = 'eBay Setting';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; settingsid; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; CustomerCode; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(3; VendorCode; Code[30])
        {
            DataClassification = ToBeClassified;
        }
        field(4; APIURL; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(5; APIKey; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(6; PaypalPaymentsEmailAddress; Text[100])
        {
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                Pattern,
                Value : Text;
                Regex: Codeunit Regex;

            begin
                Pattern := '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$';
                if not Regex.IsMatch("PaypalPaymentsEmailAddress", Pattern, 0) then
                    Error('Please Enter valid email address');
            end;
        }
        field(7; About; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(8; Delivery; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(9; Returns; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(10; Template; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(11; refresh_token; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(12; oauth_credentials; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(13; Environment; Text[2])
        {
            DataClassification = ToBeClassified;
        }
        field(14; fulfillmentPolicyId; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Fulfillment Policy Id';
        }
        field(15; paymentPolicyId; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Payment Policy Id';
        }
        field(16; returnPolicyId; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Return Policy Id';
        }
        field(17; categoryId; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'category Id';
        }
        field(18; BankGLCode; Code[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Bank GL Code';
        }
        field(19; DigitalSignatureJWE; Text[2048])
        {
            DataClassification = ToBeClassified;
            Caption = 'Digital Signature JWE';
        }
        field(20; DigitalSignaturePrivateKey; Text[2048])
        {
            DataClassification = ToBeClassified;
            Caption = 'Digital Signature Private Key';
        }
        field(21; MerchantLocationKey; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'MerchantLocationKey';
        }
        field(22; ManualTest; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Manual Test';
        }
        field(23; limit; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Limit';
        }
        field(24; nextpage; Text[2048])
        {
            DataClassification = ToBeClassified;
            Caption = 'nextpage';
        }
        field(25; BatchSize; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Batch Size';
        }
        field(26; RecordsPerRun; Integer)
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
    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Template);
        Template.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields(Template);
        Template.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName(Template)));
    end;
}