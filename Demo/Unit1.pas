unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Math,

  GerenciaNet, GerenciaPix, GerenciaPago, GerenciaSeguro,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Objects, FMX.Layouts, FMXDelphiZXingQRCode, FMX.ListBox,
  FMX.Edit;

type
  TForm1 = class(TForm)
    GerenciaPix1: TGerenciaPix;
    Button1: TButton;
    Layout1: TLayout;
    Layout3: TLayout;
    QRCodeBitmap: TImage;
    Layout4: TLayout;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Edit5: TEdit;
    Edit6: TEdit;
    Label7: TLabel;
    Layout5: TLayout;
    Memo1: TMemo;
    GerenciaNet1: TGerenciaNet;
    GerenciaSeguro1: TGerenciaSeguro;
    GerenciaPago1: TGerenciaPago;
    procedure Button1Click(Sender: TObject);
    procedure GerenciaPix1Status(AQrCodeTexto: string);
  private
    { Private declarations }
    procedure QrCodeMobile(imgQRCode: TImage; texto: string);
    procedure QRCodeWin(imgQRCode: TImage; texto: string);

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  with GerenciaPix1 do
  begin
    Empresa   := TEmpresa.Nenhum;

    case ComboBox1.ItemIndex of
      0: Tipo := sAleatorio;
      1: Tipo := sEmail;
      2: Tipo := sCelular;
      3: Tipo := sCPF;
      4: Tipo := sCNPJ;
    end;

    Chave     := Edit1.Text;
    Descricao := Edit2.Text;
    Titular   := Edit3.Text;
    Cidade    := Edit4.Text;
    TXID      := Edit5.Text;
    Valor     := Edit6.Text;
  end;

  GerenciaPix1.GerarQrCode;
end;

procedure TForm1.GerenciaPix1Status(AQrCodeTexto: string);
begin
  Memo1.Lines.Text  := AQrCodeTexto;

  {$IFDEF MSWINDOWS}
    QRCodeWin(QRCodeBitmap, AQrCodeTexto);
  {$ELSE}
    QRCodeMobile(QRCodeBitmap, AQrCodeTexto);
  {$ENDIF}

end;

procedure TForm1.QrCodeMobile(imgQRCode: TImage; texto: string);
const
    downsizeQuality: Integer = 2; // bigger value, better quality, slower rendering
var
    QRCode: TDelphiZXingQRCode;
    Row, Column: Integer;
    pixelColor : TAlphaColor;
    vBitMapData : TBitmapData;
    pixelCount, y, x: Integer;
    columnPixel, rowPixel: Integer;

    function GetPixelCount(AWidth, AHeight: Single): Integer;
    begin
        if QRCode.Rows > 0 then
          Result := Trunc(Min(AWidth, AHeight)) div QRCode.Rows
        else
          Result := 0;
    end;
begin
    // Not a good idea to stretch the QR Code...
    if imgQRCode.WrapMode = TImageWrapMode.iwStretch then
        imgQRCode.WrapMode := TImageWrapMode.Fit;


    QRCode := TDelphiZXingQRCode.Create;

    try
        QRCode.Data := '  ' + texto;
        QRCode.Encoding := TQRCodeEncoding.qrAuto;
        QRCode.QuietZone := 4;
        pixelCount := GetPixelCount(imgQRCode.Width, imgQRCode.Height);

        case imgQRCode.WrapMode of
            TImageWrapMode.iwOriginal,
            TImageWrapMode.iwTile,
            TImageWrapMode.iwCenter:
            begin
                if pixelCount > 0 then
                    imgQRCode.Bitmap.SetSize(QRCode.Columns * pixelCount,
                    QRCode.Rows * pixelCount);
            end;

            TImageWrapMode.iwFit:
            begin
                if pixelCount > 0 then
                begin
                    imgQRCode.Bitmap.SetSize(QRCode.Columns * pixelCount * downsizeQuality,
                        QRCode.Rows * pixelCount * downsizeQuality);
                    pixelCount := pixelCount * downsizeQuality;
                end;
            end;

            //TImageWrapMode.iwStretch:
            //    raise Exception.Create('Not a good idea to stretch the QR Code');
        end;
        if imgQRCode.Bitmap.Canvas.BeginScene then
        begin
            try
                imgQRCode.Bitmap.Canvas.Clear(TAlphaColors.White);
                if pixelCount > 0 then
                begin
                      if imgQRCode.Bitmap.Map(TMapAccess.maWrite, vBitMapData)  then
                      begin
                            try
                                 For Row := 0 to QRCode.Rows - 1 do
                                 begin
                                    for Column := 0 to QRCode.Columns - 1 do
                                    begin
                                        if (QRCode.IsBlack[Row, Column]) then
                                            pixelColor := TAlphaColors.Black
                                        else
                                            pixelColor := TAlphaColors.White;

                                        columnPixel := Column * pixelCount;
                                        rowPixel := Row * pixelCount;

                                        for x := 0 to pixelCount - 1 do
                                            for y := 0 to pixelCount - 1 do
                                                vBitMapData.SetPixel(columnPixel + x,
                                                    rowPixel + y, pixelColor);
                                    end;
                                 end;
                            finally
                              imgQRCode.Bitmap.Unmap(vBitMapData);
                            end;
                      end;
                end;
            finally
                imgQRCode.Bitmap.Canvas.EndScene;
          end;
        end;
    finally
        QRCode.Free;
    end;
end;

procedure TForm1.QRCodeWin(imgQRCode: TImage; texto: string);
var
  QRCode: TDelphiZXingQRCode;
  Row, Column: Integer;
  pixelColor : TAlphaColor;
  vBitMapData : TBitmapData;
begin
    imgQRCode.DisableInterpolation := true;
    imgQRCode.WrapMode := TImageWrapMode.iwStretch;

    QRCode := TDelphiZXingQRCode.Create;
    try
        QRCode.Data := texto;
        QRCode.Encoding := TQRCodeEncoding.qrAuto;
        QRCode.QuietZone := 4;
        imgQRCode.Bitmap.SetSize(QRCode.Rows, QRCode.Columns);

        for Row := 0 to QRCode.Rows - 1 do
        begin
            for Column := 0 to QRCode.Columns - 1 do
            begin
                if (QRCode.IsBlack[Row, Column]) then
                    pixelColor := TAlphaColors.Black
                else
                    pixelColor := TAlphaColors.White;

                if imgQRCode.Bitmap.Map(TMapAccess.maWrite, vBitMapData)  then
                try
                    vBitMapData.SetPixel(Column, Row, pixelColor);
                finally
                    imgQRCode.Bitmap.Unmap(vBitMapData);
                end;
            end;
        end;

    finally
        QRCode.Free;
    end;
end;

end.
