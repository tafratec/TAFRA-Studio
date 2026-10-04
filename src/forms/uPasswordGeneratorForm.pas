unit uPasswordGeneratorForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls,
  uPasswordGeneratorService, uThemeService;

type
  TPasswordGeneratorForm = class(TForm)
  private
    FGeneratorService: TPasswordGeneratorService;
    FThemeService: TThemeService;
    FThemeName: string;
    FLengthCombo: TComboBox;
    FModeGroup: TRadioGroup;
    FPasswordEdit: TEdit;
    FGenerateButton: TButton;
    FCopyButton: TButton;
    FRegenerateButton: TButton;
    FResetButton: TButton;
    FCloseButton: TButton;
    function SelectedLength: Integer;
    function SelectedMode: TPasswordCharacterMode;
    procedure CopyPasswordClick(Sender: TObject);
    procedure GenerateClick(Sender: TObject);
    procedure RegenerateClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure SetGeneratedPassword(const APassword: string);
    procedure SetInitialState;
  public
    constructor Create(AOwner: TComponent; AThemeService: TThemeService;
      const AThemeName: string); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Clipbrd;

constructor TPasswordGeneratorForm.Create(AOwner: TComponent;
  AThemeService: TThemeService; const AThemeName: string);
var
  TitleLabel: TLabel;
  LengthLabel: TLabel;
begin
  inherited CreateNew(AOwner, 1);

  FThemeService := AThemeService;
  FThemeName := AThemeName;
  FGeneratorService := TPasswordGeneratorService.Create;

  Caption := 'Password Generator';
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Width := 520;
  Height := 360;

  TitleLabel := TLabel.Create(Self);
  TitleLabel.Parent := Self;
  TitleLabel.Left := 20;
  TitleLabel.Top := 18;
  TitleLabel.Caption := 'Generate a password using selected length and character rules.';

  LengthLabel := TLabel.Create(Self);
  LengthLabel.Parent := Self;
  LengthLabel.Left := 20;
  LengthLabel.Top := 58;
  LengthLabel.Caption := 'Password length';

  FLengthCombo := TComboBox.Create(Self);
  FLengthCombo.Parent := Self;
  FLengthCombo.Left := 160;
  FLengthCombo.Top := 54;
  FLengthCombo.Width := 120;
  FLengthCombo.Style := csDropDownList;
  FLengthCombo.Items.Add('4');
  FLengthCombo.Items.Add('6');
  FLengthCombo.Items.Add('8');
  FLengthCombo.Items.Add('10');
  FLengthCombo.Items.Add('12');
  FLengthCombo.Items.Add('14');
  FLengthCombo.Items.Add('16');
  FLengthCombo.Items.Add('18');
  FLengthCombo.Items.Add('20');
  FLengthCombo.Items.Add('24');
  FLengthCombo.Items.Add('30');

  FModeGroup := TRadioGroup.Create(Self);
  FModeGroup.Parent := Self;
  FModeGroup.Left := 20;
  FModeGroup.Top := 92;
  FModeGroup.Width := 460;
  FModeGroup.Height := 112;
  FModeGroup.Caption := 'Password content';
  FModeGroup.Items.Add('Characters, symbols, and numbers');
  FModeGroup.Items.Add('Characters and numbers');
  FModeGroup.Items.Add('Characters only');
  FModeGroup.Items.Add('Numbers only');

  FPasswordEdit := TEdit.Create(Self);
  FPasswordEdit.Parent := Self;
  FPasswordEdit.Left := 20;
  FPasswordEdit.Top := 220;
  FPasswordEdit.Width := 352;
  FPasswordEdit.ReadOnly := True;

  FCopyButton := TButton.Create(Self);
  FCopyButton.Parent := Self;
  FCopyButton.Left := 384;
  FCopyButton.Top := 218;
  FCopyButton.Width := 96;
  FCopyButton.Caption := 'Copy';
  FCopyButton.OnClick := @CopyPasswordClick;

  FGenerateButton := TButton.Create(Self);
  FGenerateButton.Parent := Self;
  FGenerateButton.Left := 20;
  FGenerateButton.Top := 270;
  FGenerateButton.Width := 96;
  FGenerateButton.Caption := 'Generate';
  FGenerateButton.OnClick := @GenerateClick;
  FGenerateButton.Default := True;

  FRegenerateButton := TButton.Create(Self);
  FRegenerateButton.Parent := Self;
  FRegenerateButton.Left := 124;
  FRegenerateButton.Top := 270;
  FRegenerateButton.Width := 104;
  FRegenerateButton.Caption := 'Regenerate';
  FRegenerateButton.OnClick := @RegenerateClick;

  FResetButton := TButton.Create(Self);
  FResetButton.Parent := Self;
  FResetButton.Left := 236;
  FResetButton.Top := 270;
  FResetButton.Width := 96;
  FResetButton.Caption := 'Reset';
  FResetButton.OnClick := @ResetClick;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Self;
  FCloseButton.Left := 384;
  FCloseButton.Top := 270;
  FCloseButton.Width := 96;
  FCloseButton.Caption := 'Close';
  FCloseButton.ModalResult := mrClose;

  SetInitialState;

  if Assigned(FThemeService) then
    FThemeService.ApplyTheme(Self, FThemeName);
end;

destructor TPasswordGeneratorForm.Destroy;
begin
  FGeneratorService.Free;
  inherited Destroy;
end;

function TPasswordGeneratorForm.SelectedLength: Integer;
begin
  Result := StrToIntDef(FLengthCombo.Text, 16);
end;

function TPasswordGeneratorForm.SelectedMode: TPasswordCharacterMode;
begin
  case FModeGroup.ItemIndex of
    1:
      Result := pcmCharactersAndNumbers;
    2:
      Result := pcmCharactersOnly;
    3:
      Result := pcmNumbersOnly;
  else
    Result := pcmMixed;
  end;
end;

procedure TPasswordGeneratorForm.CopyPasswordClick(Sender: TObject);
begin
  if FPasswordEdit.Text = '' then
    Exit;

  Clipboard.AsText := FPasswordEdit.Text;
end;

procedure TPasswordGeneratorForm.GenerateClick(Sender: TObject);
begin
  SetGeneratedPassword(FGeneratorService.GeneratePassword(SelectedLength,
    SelectedMode));
end;

procedure TPasswordGeneratorForm.RegenerateClick(Sender: TObject);
begin
  GenerateClick(Sender);
end;

procedure TPasswordGeneratorForm.ResetClick(Sender: TObject);
begin
  SetInitialState;
end;

procedure TPasswordGeneratorForm.SetGeneratedPassword(const APassword: string);
begin
  FPasswordEdit.Text := APassword;
  FCopyButton.Enabled := APassword <> '';
  FRegenerateButton.Enabled := APassword <> '';
end;

procedure TPasswordGeneratorForm.SetInitialState;
begin
  FLengthCombo.ItemIndex := FLengthCombo.Items.IndexOf('16');
  if FLengthCombo.ItemIndex < 0 then
    FLengthCombo.ItemIndex := 0;

  FModeGroup.ItemIndex := 0;
  SetGeneratedPassword('');
end;

end.
