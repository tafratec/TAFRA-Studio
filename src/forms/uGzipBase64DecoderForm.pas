unit uGzipBase64DecoderForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, ExtCtrls,
  uGzipBase64DecoderService, uThemeService;

type
  TGzipBase64DecoderForm = class(TForm)
  private
    FDecoderService: TGzipBase64DecoderService;
    FThemeService: TThemeService;
    FThemeName: string;
    FInputMemo: TMemo;
    FOutputMemo: TMemo;
    FDecodeButton: TButton;
    FCopyButton: TButton;
    FSaveButton: TButton;
    FClearButton: TButton;
    FCloseButton: TButton;
    FSaveDialog: TSaveDialog;
    procedure ClearClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure DecodeClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; AThemeService: TThemeService;
      const AThemeName: string); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Clipbrd;

constructor TGzipBase64DecoderForm.Create(AOwner: TComponent;
  AThemeService: TThemeService; const AThemeName: string);
var
  InputLabel: TLabel;
  OutputLabel: TLabel;
begin
  inherited CreateNew(AOwner, 1);
  FThemeService := AThemeService;
  FThemeName := AThemeName;
  FDecoderService := TGzipBase64DecoderService.Create;

  Caption := 'Gzip + Base64 Decoder';
  Position := poOwnerFormCenter;
  Width := 780;
  Height := 610;
  Constraints.MinWidth := 620;
  Constraints.MinHeight := 460;

  InputLabel := TLabel.Create(Self);
  InputLabel.Parent := Self;
  InputLabel.Left := 16;
  InputLabel.Top := 16;
  InputLabel.Caption := 'Gzip + Base64 input';

  FInputMemo := TMemo.Create(Self);
  FInputMemo.Parent := Self;
  FInputMemo.Left := 16;
  FInputMemo.Top := 40;
  FInputMemo.Width := 732;
  FInputMemo.Height := 190;
  FInputMemo.Anchors := [akLeft, akTop, akRight];
  FInputMemo.ScrollBars := ssBoth;
  FInputMemo.WordWrap := False;

  FDecodeButton := TButton.Create(Self);
  FDecodeButton.Parent := Self;
  FDecodeButton.Left := 16;
  FDecodeButton.Top := 244;
  FDecodeButton.Width := 100;
  FDecodeButton.Caption := 'Decode';
  FDecodeButton.Default := True;
  FDecodeButton.OnClick := @DecodeClick;

  FClearButton := TButton.Create(Self);
  FClearButton.Parent := Self;
  FClearButton.Left := 124;
  FClearButton.Top := 244;
  FClearButton.Width := 100;
  FClearButton.Caption := 'Clear';
  FClearButton.OnClick := @ClearClick;

  FCopyButton := TButton.Create(Self);
  FCopyButton.Parent := Self;
  FCopyButton.Left := 432;
  FCopyButton.Top := 244;
  FCopyButton.Width := 100;
  FCopyButton.Anchors := [akTop, akRight];
  FCopyButton.Caption := 'Copy Output';
  FCopyButton.Enabled := False;
  FCopyButton.OnClick := @CopyClick;

  FSaveButton := TButton.Create(Self);
  FSaveButton.Parent := Self;
  FSaveButton.Left := 540;
  FSaveButton.Top := 244;
  FSaveButton.Width := 100;
  FSaveButton.Anchors := [akTop, akRight];
  FSaveButton.Caption := 'Save Output...';
  FSaveButton.OnClick := @SaveClick;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Self;
  FCloseButton.Left := 648;
  FCloseButton.Top := 244;
  FCloseButton.Width := 100;
  FCloseButton.Anchors := [akTop, akRight];
  FCloseButton.Caption := 'Close';
  FCloseButton.ModalResult := mrClose;

  OutputLabel := TLabel.Create(Self);
  OutputLabel.Parent := Self;
  OutputLabel.Left := 16;
  OutputLabel.Top := 286;
  OutputLabel.Caption := 'Decoded text';

  FOutputMemo := TMemo.Create(Self);
  FOutputMemo.Parent := Self;
  FOutputMemo.Left := 16;
  FOutputMemo.Top := 310;
  FOutputMemo.Width := 732;
  FOutputMemo.Height := 238;
  FOutputMemo.Anchors := [akLeft, akTop, akRight, akBottom];
  FOutputMemo.ReadOnly := True;
  FOutputMemo.ScrollBars := ssBoth;
  FOutputMemo.WordWrap := False;

  FSaveDialog := TSaveDialog.Create(Self);
  FSaveDialog.Filter := 'Text files (*.txt)|*.txt|JSON files (*.json)|*.json|CSV files (*.csv)|*.csv';
  FSaveDialog.DefaultExt := 'txt';
  FSaveDialog.Options := FSaveDialog.Options + [ofOverwritePrompt];

  if Assigned(FThemeService) then
    FThemeService.ApplyTheme(Self, FThemeName);
end;

destructor TGzipBase64DecoderForm.Destroy;
begin
  FDecoderService.Free;
  inherited Destroy;
end;

procedure TGzipBase64DecoderForm.ClearClick(Sender: TObject);
begin
  FInputMemo.Clear;
  FOutputMemo.Clear;
  FCopyButton.Enabled := False;
  FInputMemo.SetFocus;
end;

procedure TGzipBase64DecoderForm.CopyClick(Sender: TObject);
begin
  if FOutputMemo.Text <> '' then
    Clipboard.AsText := FOutputMemo.Lines.Text;
end;

procedure TGzipBase64DecoderForm.DecodeClick(Sender: TObject);
var
  DecodedText: string;
  ErrorMessage: string;
begin
  if FDecoderService.TryDecode(FInputMemo.Lines.Text, DecodedText, ErrorMessage) then
  begin
    FOutputMemo.Lines.Text := DecodedText;
    FCopyButton.Enabled := DecodedText <> '';
  end
  else
  begin
    FOutputMemo.Clear;
    FCopyButton.Enabled := False;
    MessageDlg('Decode failed', ErrorMessage, mtError, [mbOK], 0);
  end;
end;

procedure TGzipBase64DecoderForm.SaveClick(Sender: TObject);
var
  OutputStream: TFileStream;
  OutputText: string;
begin
  if FOutputMemo.Text = '' then
  begin
    MessageDlg('Save output', 'There is no decoded text to save.', mtInformation,
      [mbOK], 0);
    Exit;
  end;

  case FSaveDialog.FilterIndex of
    2: FSaveDialog.DefaultExt := 'json';
    3: FSaveDialog.DefaultExt := 'csv';
  else
    FSaveDialog.DefaultExt := 'txt';
  end;

  if not FSaveDialog.Execute then
    Exit;

  OutputText := FOutputMemo.Lines.Text;
  try
    OutputStream := TFileStream.Create(FSaveDialog.FileName, fmCreate);
    try
      if OutputText <> '' then
        OutputStream.WriteBuffer(OutputText[1], Length(OutputText));
    finally
      OutputStream.Free;
    end;
  except
    on E: Exception do
      MessageDlg('Save failed', 'Unable to save the output: ' + E.Message,
        mtError, [mbOK], 0);
  end;
end;

end.
