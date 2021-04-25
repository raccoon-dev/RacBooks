unit uProgress;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage;

type
  TfrmProgress = class(TForm)
    lblTop: TLabel;
    lblBottom: TLabel;
    imgProgress: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    function GetTextBottom: string;
    function GetTextTop: string;
    procedure SetTextBottom(const Value: string);
    procedure SetTextTop(const Value: string);
    { Private declarations }
  public
    { Public declarations }
    property TextTop: string read GetTextTop write SetTextTop;
    property TextBottom: string read GetTextBottom write SetTextBottom;
  end;

var
  frmProgress: TfrmProgress;

implementation

{$R *.dfm}

procedure TfrmProgress.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmProgress.FormCreate(Sender: TObject);
begin
  lblTop.Caption    := '';
  lblBottom.Caption := '';
end;

function TfrmProgress.GetTextBottom: string;
begin
  Result := lblBottom.Caption;
end;

function TfrmProgress.GetTextTop: string;
begin
  Result := lblTop.Caption;
end;

procedure TfrmProgress.SetTextBottom(const Value: string);
begin
  lblBottom.Caption := Value;
  lblBottom.Repaint;
end;

procedure TfrmProgress.SetTextTop(const Value: string);
begin
  lblTop.Caption := Value;
  lblTop.Repaint;
end;

end.
