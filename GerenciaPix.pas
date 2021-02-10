unit GerenciaPix;

interface

uses
  System.SysUtils, System.Classes,

  FMX.Types, FMX.Controls, FMX.Graphics, FMXDelphiZXingQRCode;


type
  TEmpresa  = (Nenhum = 0, Gerencianet = 1);
  TTipo     = (sAleatorio = 0, sEmail = 1, sCelular = 2, sCPF = 3, sCNPJ = 4);
  TOnStatus = procedure(const AQrCodeTexto: string) of object;

  TGerenciaPix = class(TComponent)
  private
    { Private declarations }
    FEmpresa  : TEmpresa;
    FTipo     : TTipo;
    FChave    : String;
    FDescricao: String;
    FTitular  : String;
    FCidade   : String;
    FTXID     : String;
    FValor    : String;

    FStatus   : TOnStatus;
    procedure SetStatus(const AQrCodeTexto: string);
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure GerarQrCode;
    //property Status : TOnStatus read FStatus write FStatus;
  published
    { Published declarations }
    property Empresa  : TEmpresa    read FEmpresa   write FEmpresa;
    property Tipo     : TTipo       read FTipo      write FTipo;
    property Chave    : String      read FChave     write FChave;

    property Descricao: String      read FDescricao write FDescricao;
    property Titular  : String      read FTitular   write FTitular;
    property Cidade   : String      read FCidade    write FCidade;
    property TXID     : String      read FTXID      write FTXID;
    property Valor    : String      read FValor     write FValor;

    property OnStatus : TOnStatus   read FStatus    write FStatus;

  end;

  {IDs do Payload do Pix}
  const ID_PAYLOAD_FORMAT_INDICATOR = '00';
  const ID_MERCHANT_ACCOUNT_INFORMATION = '26';
  const ID_MERCHANT_ACCOUNT_INFORMATION_GUI = '00';
  const ID_MERCHANT_ACCOUNT_INFORMATION_KEY = '01';
  const ID_MERCHANT_ACCOUNT_INFORMATION_DESCRIPTION = '02';
  const ID_MERCHANT_CATEGORY_CODE = '52';
  const ID_TRANSACTION_CURRENCY = '53';
  const ID_TRANSACTION_AMOUNT = '54';
  const ID_COUNTRY_CODE = '58';
  const ID_MERCHANT_NAME = '59';
  const ID_MERCHANT_CITY = '60';
  const ID_ADDITIONAL_DATA_FIELD_TEMPLATE = '62';
  const ID_ADDITIONAL_DATA_FIELD_TEMPLATE_TXID = '05';
  const ID_CRC16 = '63';

procedure Register;

implementation

{$R ./SGerenciaPix.dcr}

procedure Register;
begin
  RegisterComponents('PagOnline', [TGerenciaPix]);
end;

{ TGerenciaPix }

constructor TGerenciaPix.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

end;

destructor TGerenciaPix.Destroy;
begin

  inherited Destroy;
end;

procedure TGerenciaPix.GerarQrCode;
  function ZeroLeft(vZero: string; vQtd: integer): string;
  var
  i, vTam: integer;
  vAux: string;
  begin
    vAux := vZero;
    vTam := length( vZero );
    vZero := '';
    for i := 1 to vQtd - vTam do
    vZero := '0' + vZero;
    vAux := vZero + vAux;
    result := vAux;
  end;

  function Crc16(texto: string; Polynom: WORD = $1021; Seed: WORD = $FFFF): WORD;
  var
    i, j: Integer;
  begin
    Result := Seed;
    for i := 1 to length(texto) do
    begin
      Result := Result xor (ord(texto[i]) shl 8);
      for j := 0 to 7 do
      begin
        if (Result and $8000) <> 0 then
          Result := (Result shl 1) xor Polynom
        else
          Result := Result shl 1;
      end;
    end;
    Result := Result and $FFFF;
  end;

  function getValue(id, value: String): String;
  begin
    Result := id+ZeroLeft(IntToStr(Length(value)),2)+value;
  end;

  function getAdicional(templent_id, tx_id, templent: String): String;
  var
   tx : String;
  begin
    tx      := getValue(templent_id, tx_id);
    result  := getValue(templent, tx);
  end;

  function getInformation(minfo, mgui, mkey, mdesc, key, desc: String): String;
  var
   sgui, skey, sdesc : String;
  begin
    sgui   := getValue(mgui, 'br.gov.bcb.pix');
    skey   := getValue(mkey, key);
    sdesc  := getValue(mdesc, desc);
    result := getValue(minfo,sgui+skey+sdesc);
  end;

var
 QrCode : String;
 Count  : Integer;
begin
  // Chave Pix
  var pixkey: String;
  if FTipo = TTipo.sCelular then
  pixkey := '+'+FChave else
  pixkey := FChave;
  // Descricao do Pagamento
  var description: String;
  description := FDescricao;
  // Nome do Titular da Conta
  var merchantName: String;
  merchantName := FTitular;
  // Cidade do Titular da Conta
  var merchantCyty: String;
  merchantCyty := FCidade;
  // ID da Transação pix
  var txid: String;
  txid := FTXID;
  // Valor da trasação
  var amount: String;
  amount := FValor;

  QrCode := getValue(ID_PAYLOAD_FORMAT_INDICATOR,'01');

  QrCode := QrCode + getInformation(ID_MERCHANT_ACCOUNT_INFORMATION,
                                    ID_MERCHANT_ACCOUNT_INFORMATION_GUI,
                                    ID_MERCHANT_ACCOUNT_INFORMATION_KEY,
                                    ID_MERCHANT_ACCOUNT_INFORMATION_DESCRIPTION,
                                    pixkey, description);

  QrCode := QrCode + getValue(ID_MERCHANT_CATEGORY_CODE,'0000');

  QrCode := QrCode + getValue(ID_TRANSACTION_CURRENCY,'986');

  QrCode := QrCode + getValue(ID_TRANSACTION_AMOUNT,amount);

  QrCode := QrCode + getValue(ID_COUNTRY_CODE,'BR');

  QrCode := QrCode + getValue(ID_MERCHANT_NAME,merchantName);

  QrCode := QrCode + getValue(ID_MERCHANT_CITY,merchantCyty);

  QrCode := QrCode + getAdicional(ID_ADDITIONAL_DATA_FIELD_TEMPLATE_TXID,txid,
                                  ID_ADDITIONAL_DATA_FIELD_TEMPLATE);

  QrCode := QrCode + ID_CRC16+'04';
  QrCode := QrCode + Crc16(QrCode).ToHexString;
  SetStatus(QrCode);
end;

procedure TGerenciaPix.SetStatus(const AQrCodeTexto: string);
begin
  FStatus(AQrCodeTexto);
end;

end.
