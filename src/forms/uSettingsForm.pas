unit uSettingsForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  uComposerRunner, uResultTypes, uSettingsService, uStudioSettings,
  uThemeService;

type
  TSettingsForm = class(TForm)
  private
    FSettingsService: TSettingsService;
    FComposerRunner: TComposerRunner;
    FThemeService: TThemeService;
    FWorkingSettings: TStudioSettings;
    FOpenDialog: TOpenDialog;
    FStudioPHPEdit: TEdit;
    FProjectPHPEdit: TEdit;
    FProjectPHPModeCombo: TComboBox;
    FComposerPathEdit: TEdit;
    FComposerRuntimeCombo: TComboBox;
    FComposerCustomPHPEdit: TEdit;
    FSourceFontNameEdit: TEdit;
    FSourceFontSizeEdit: TEdit;
    FThemeCombo: TComboBox;
    FFontDialog: TFontDialog;
    procedure AddLabel(AParent: TWinControl; const ACaption: string;
      ALeft, ATop: Integer);
    function AddEdit(AParent: TWinControl; const AText: string;
      ALeft, ATop, AWidth: Integer): TEdit;
    function AddButton(AParent: TWinControl; const ACaption: string;
      ALeft, ATop, AWidth: Integer; AOnClick: TNotifyEvent): TButton;
    function AddCombo(AParent: TWinControl; ALeft, ATop, AWidth: Integer;
      const AItems: array of string; const AValue: string): TComboBox;
    procedure BrowseStudioPHPClick(Sender: TObject);
    procedure BrowseProjectPHPClick(Sender: TObject);
    procedure BrowseComposerClick(Sender: TObject);
    procedure BrowseComposerCustomPHPClick(Sender: TObject);
    procedure ChooseSourceFontClick(Sender: TObject);
    procedure TestStudioPHPClick(Sender: TObject);
    procedure TestProjectPHPClick(Sender: TObject);
    procedure TestComposerClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure CopyControlsToSettings(ASettings: TStudioSettings);
    procedure SelectTheme(const AThemeName: string);
    procedure ShowResult(const ATitle: string; AResult: TOperationResult);
  public
    constructor Create(AOwner: TComponent; ASettingsService: TSettingsService;
      AComposerRunner: TComposerRunner; AThemeService: TThemeService); reintroduce;
    destructor Destroy; override;
  end;

implementation

constructor TSettingsForm.Create(AOwner: TComponent;
  ASettingsService: TSettingsService; AComposerRunner: TComposerRunner;
  AThemeService: TThemeService);
var
  SaveButton: TButton;
  CancelButton: TButton;
begin
  inherited CreateNew(AOwner, 1);

  FSettingsService := ASettingsService;
  FComposerRunner := AComposerRunner;
  FThemeService := AThemeService;
  FWorkingSettings := TStudioSettings.Create;
  if Assigned(FSettingsService) then
    FWorkingSettings.Assign(FSettingsService.Settings);

  Caption := 'Application Settings';
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Width := 690;
  Height := 520;

  FOpenDialog := TOpenDialog.Create(Self);
  FOpenDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
  FFontDialog := TFontDialog.Create(Self);

  AddLabel(Self, 'Theme', 16, 20);
  FThemeCombo := TComboBox.Create(Self);
  FThemeCombo.Parent := Self;
  FThemeCombo.Left := 170;
  FThemeCombo.Top := 16;
  FThemeCombo.Width := 160;
  FThemeCombo.Style := csDropDownList;
  if Assigned(FThemeService) then
    FThemeService.FillThemeNames(FThemeCombo.Items);
  SelectTheme(FWorkingSettings.ThemeName);

  AddLabel(Self, 'Studio PHP executable', 16, 64);
  FStudioPHPEdit := AddEdit(Self, FWorkingSettings.StudioPHPPath, 170, 60, 390);
  AddButton(Self, 'Browse...', 568, 60, 90, @BrowseStudioPHPClick);
  AddButton(Self, 'Test', 568, 90, 90, @TestStudioPHPClick);

  AddLabel(Self, 'Project PHP mode', 16, 126);
  FProjectPHPModeCombo := AddCombo(Self, 170, 122, 160,
    ['auto', 'custom'], FWorkingSettings.ProjectPHPMode);
  AddLabel(Self, 'Project PHP executable', 16, 160);
  FProjectPHPEdit := AddEdit(Self, FWorkingSettings.ProjectPHPPath, 170, 156, 390);
  AddButton(Self, 'Browse...', 568, 156, 90, @BrowseProjectPHPClick);
  AddButton(Self, 'Test', 568, 186, 90, @TestProjectPHPClick);

  AddLabel(Self, 'Composer path', 16, 228);
  FComposerPathEdit := AddEdit(Self, FWorkingSettings.ComposerPath, 170, 224, 390);
  AddButton(Self, 'Browse...', 568, 224, 90, @BrowseComposerClick);
  AddButton(Self, 'Test', 568, 254, 90, @TestComposerClick);

  AddLabel(Self, 'Composer PHP runtime', 16, 292);
  FComposerRuntimeCombo := AddCombo(Self, 170, 288, 160,
    ['project_php', 'studio_php', 'custom_php'],
    FWorkingSettings.ComposerRuntimeMode);
  AddLabel(Self, 'Custom Composer PHP', 16, 326);
  FComposerCustomPHPEdit := AddEdit(Self, FWorkingSettings.ComposerCustomPHPPath,
    170, 322, 390);
  AddButton(Self, 'Browse...', 568, 322, 90, @BrowseComposerCustomPHPClick);

  AddLabel(Self, 'Source viewer font', 16, 366);
  FSourceFontNameEdit := AddEdit(Self, FWorkingSettings.SourceFontName,
    170, 362, 280);
  AddLabel(Self, 'Size', 462, 366);
  FSourceFontSizeEdit := AddEdit(Self, IntToStr(FWorkingSettings.SourceFontSize),
    500, 362, 60);
  AddButton(Self, 'Choose...', 568, 362, 90, @ChooseSourceFontClick);

  SaveButton := AddButton(Self, 'Save', 468, 440, 90, @SaveClick);
  SaveButton.Default := True;

  CancelButton := AddButton(Self, 'Cancel', 568, 440, 90, nil);
  CancelButton.ModalResult := mrCancel;

  if Assigned(FThemeService) then
    FThemeService.ApplyTheme(Self, FWorkingSettings.ThemeName);
end;

destructor TSettingsForm.Destroy;
begin
  FWorkingSettings.Free;
  inherited Destroy;
end;

procedure TSettingsForm.AddLabel(AParent: TWinControl; const ACaption: string;
  ALeft, ATop: Integer);
var
  LabelControl: TLabel;
begin
  LabelControl := TLabel.Create(Self);
  LabelControl.Parent := AParent;
  LabelControl.Caption := ACaption;
  LabelControl.Left := ALeft;
  LabelControl.Top := ATop + 4;
end;

function TSettingsForm.AddEdit(AParent: TWinControl; const AText: string;
  ALeft, ATop, AWidth: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Text := AText;
end;

function TSettingsForm.AddButton(AParent: TWinControl; const ACaption: string;
  ALeft, ATop, AWidth: Integer; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.OnClick := AOnClick;
end;

function TSettingsForm.AddCombo(AParent: TWinControl; ALeft, ATop,
  AWidth: Integer; const AItems: array of string; const AValue: string
  ): TComboBox;
var
  I: Integer;
begin
  Result := TComboBox.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Style := csDropDownList;

  for I := Low(AItems) to High(AItems) do
    Result.Items.Add(AItems[I]);

  Result.ItemIndex := Result.Items.IndexOf(AValue);
  if (Result.ItemIndex < 0) and (Result.Items.Count > 0) then
    Result.ItemIndex := 0;
end;

procedure TSettingsForm.BrowseStudioPHPClick(Sender: TObject);
begin
  FOpenDialog.Filter := 'PHP executable|php.exe|All files|*.*';
  if FOpenDialog.Execute then
    FStudioPHPEdit.Text := FOpenDialog.FileName;
end;

procedure TSettingsForm.BrowseProjectPHPClick(Sender: TObject);
begin
  FOpenDialog.Filter := 'PHP executable|php.exe|All files|*.*';
  if FOpenDialog.Execute then
    FProjectPHPEdit.Text := FOpenDialog.FileName;
end;

procedure TSettingsForm.BrowseComposerClick(Sender: TObject);
begin
  FOpenDialog.Filter :=
    'Composer|composer.exe;composer.bat;composer.cmd;composer.phar|All files|*.*';
  if FOpenDialog.Execute then
    FComposerPathEdit.Text := FOpenDialog.FileName;
end;

procedure TSettingsForm.BrowseComposerCustomPHPClick(Sender: TObject);
begin
  FOpenDialog.Filter := 'PHP executable|php.exe|All files|*.*';
  if FOpenDialog.Execute then
    FComposerCustomPHPEdit.Text := FOpenDialog.FileName;
end;

procedure TSettingsForm.ChooseSourceFontClick(Sender: TObject);
begin
  FFontDialog.Font.Name := FSourceFontNameEdit.Text;
  FFontDialog.Font.Size := StrToIntDef(FSourceFontSizeEdit.Text, 10);

  if FFontDialog.Execute then
  begin
    FSourceFontNameEdit.Text := FFontDialog.Font.Name;
    FSourceFontSizeEdit.Text := IntToStr(FFontDialog.Font.Size);
  end;
end;

procedure TSettingsForm.TestStudioPHPClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  ResultInfo := FSettingsService.TestPHPExecutable(FStudioPHPEdit.Text);
  try
    ShowResult('Test Studio PHP', ResultInfo);
  finally
    ResultInfo.Free;
  end;
end;

procedure TSettingsForm.TestProjectPHPClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  ResultInfo := FSettingsService.TestPHPExecutable(FProjectPHPEdit.Text);
  try
    ShowResult('Test Project PHP', ResultInfo);
  finally
    ResultInfo.Free;
  end;
end;

procedure TSettingsForm.TestComposerClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  CopyControlsToSettings(FWorkingSettings);
  ResultInfo := FComposerRunner.TestComposer(FWorkingSettings);
  try
    ShowResult('Test Composer', ResultInfo);
  finally
    ResultInfo.Free;
  end;
end;

procedure TSettingsForm.SaveClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  CopyControlsToSettings(FWorkingSettings);
  ResultInfo := FSettingsService.Save(FWorkingSettings);
  try
    if ResultInfo.Success then
    begin
      ModalResult := mrOK;
      Close;
    end
    else
      ShowResult('Save Settings', ResultInfo);
  finally
    ResultInfo.Free;
  end;
end;

procedure TSettingsForm.CopyControlsToSettings(ASettings: TStudioSettings);
var
  Theme: TStudioTheme;
begin
  if not Assigned(ASettings) then
    Exit;

  ASettings.StudioPHPPath := Trim(FStudioPHPEdit.Text);
  ASettings.ProjectPHPPath := Trim(FProjectPHPEdit.Text);
  ASettings.ProjectPHPMode := FProjectPHPModeCombo.Text;
  ASettings.ComposerPath := Trim(FComposerPathEdit.Text);
  ASettings.ComposerRuntimeMode := FComposerRuntimeCombo.Text;
  ASettings.ComposerCustomPHPPath := Trim(FComposerCustomPHPEdit.Text);
  ASettings.SourceFontName := Trim(FSourceFontNameEdit.Text);
  ASettings.SourceFontSize := StrToIntDef(FSourceFontSizeEdit.Text, 10);

  if Assigned(FThemeCombo) and (FThemeCombo.ItemIndex >= 0) then
  begin
    Theme := TStudioTheme(FThemeCombo.Items.Objects[FThemeCombo.ItemIndex]);
    if Assigned(Theme) then
      ASettings.ThemeName := Theme.Name;
  end;
end;

procedure TSettingsForm.SelectTheme(const AThemeName: string);
var
  I: Integer;
  Theme: TStudioTheme;
begin
  if not Assigned(FThemeCombo) then
    Exit;

  FThemeCombo.ItemIndex := -1;
  for I := 0 to FThemeCombo.Items.Count - 1 do
  begin
    Theme := TStudioTheme(FThemeCombo.Items.Objects[I]);
    if Assigned(Theme) and SameText(Theme.Name, AThemeName) then
    begin
      FThemeCombo.ItemIndex := I;
      Exit;
    end;
  end;

  if (FThemeCombo.ItemIndex < 0) and (FThemeCombo.Items.Count > 0) then
    FThemeCombo.ItemIndex := 0;
end;

procedure TSettingsForm.ShowResult(const ATitle: string;
  AResult: TOperationResult);
var
  DialogType: TMsgDlgType;
begin
  if Assigned(AResult) and AResult.Success then
    DialogType := mtInformation
  else
    DialogType := mtWarning;

  if Assigned(AResult) then
    MessageDlg(ATitle, AResult.MessageText, DialogType, [mbOK], 0)
  else
    MessageDlg(ATitle, 'No result was returned.', mtWarning, [mbOK], 0);
end;

end.
