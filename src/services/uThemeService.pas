unit uThemeService;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, Controls, Forms, Graphics;

type
  TStudioTheme = class
  private
    FName: string;
    FDisplayName: string;
    FWindowColor: TColor;
    FPanelColor: TColor;
    FTextColor: TColor;
    FInputColor: TColor;
    FInputTextColor: TColor;
    FEditorColor: TColor;
    FEditorTextColor: TColor;
    FProjectExplorerBackgroundColor: TColor;
    FProjectExplorerTextColor: TColor;
    FProjectExplorerLineColor: TColor;
    FProjectExplorerSelectedBackgroundColor: TColor;
    FProjectExplorerSelectedTextColor: TColor;
    FAccentColor: TColor;
  public
    constructor Create(const AName, ADisplayName: string;
      AWindowColor, APanelColor, ATextColor, AInputColor, AInputTextColor,
      AEditorColor, AEditorTextColor, AProjectExplorerBackgroundColor,
      AProjectExplorerTextColor, AProjectExplorerLineColor,
      AProjectExplorerSelectedBackgroundColor, AProjectExplorerSelectedTextColor,
      AAccentColor: TColor);
    property Name: string read FName;
    property DisplayName: string read FDisplayName;
    property WindowColor: TColor read FWindowColor;
    property PanelColor: TColor read FPanelColor;
    property TextColor: TColor read FTextColor;
    property InputColor: TColor read FInputColor;
    property InputTextColor: TColor read FInputTextColor;
    property EditorColor: TColor read FEditorColor;
    property EditorTextColor: TColor read FEditorTextColor;
    property ProjectExplorerBackgroundColor: TColor
      read FProjectExplorerBackgroundColor;
    property ProjectExplorerTextColor: TColor read FProjectExplorerTextColor;
    property ProjectExplorerLineColor: TColor read FProjectExplorerLineColor;
    property ProjectExplorerSelectedBackgroundColor: TColor
      read FProjectExplorerSelectedBackgroundColor;
    property ProjectExplorerSelectedTextColor: TColor
      read FProjectExplorerSelectedTextColor;
    property AccentColor: TColor read FAccentColor;
  end;

  TThemeService = class
  private
    FThemes: TList;
    procedure AddTheme(ATheme: TStudioTheme);
    procedure ApplyControlTheme(AControl: TControl; ATheme: TStudioTheme);
    procedure ApplyTreeViewTheme(ATreeView: TCustomTreeView;
      ATheme: TStudioTheme);
  public
    constructor Create;
    destructor Destroy; override;
    function FindTheme(const AName: string): TStudioTheme;
    function DefaultTheme: TStudioTheme;
    function ResolveTheme(const AName: string): TStudioTheme;
    procedure FillThemeNames(AItems: TStrings);
    procedure ApplyTheme(AForm: TCustomForm; const AThemeName: string);
  end;

implementation

uses
  ExtCtrls, StdCtrls, SysUtils;

constructor TStudioTheme.Create(const AName, ADisplayName: string;
  AWindowColor, APanelColor, ATextColor, AInputColor, AInputTextColor,
  AEditorColor, AEditorTextColor, AProjectExplorerBackgroundColor,
  AProjectExplorerTextColor, AProjectExplorerLineColor,
  AProjectExplorerSelectedBackgroundColor, AProjectExplorerSelectedTextColor,
  AAccentColor: TColor);
begin
  inherited Create;
  FName := AName;
  FDisplayName := ADisplayName;
  FWindowColor := AWindowColor;
  FPanelColor := APanelColor;
  FTextColor := ATextColor;
  FInputColor := AInputColor;
  FInputTextColor := AInputTextColor;
  FEditorColor := AEditorColor;
  FEditorTextColor := AEditorTextColor;
  FProjectExplorerBackgroundColor := AProjectExplorerBackgroundColor;
  FProjectExplorerTextColor := AProjectExplorerTextColor;
  FProjectExplorerLineColor := AProjectExplorerLineColor;
  FProjectExplorerSelectedBackgroundColor :=
    AProjectExplorerSelectedBackgroundColor;
  FProjectExplorerSelectedTextColor := AProjectExplorerSelectedTextColor;
  FAccentColor := AAccentColor;
end;

constructor TThemeService.Create;
begin
  inherited Create;
  FThemes := TList.Create;

  AddTheme(TStudioTheme.Create('light', 'Light',
    clWhite, $00F5F5F5, clBlack, clWhite, clBlack, clWhite, clBlack,
    clWhite, clBlack, clGray, clHighlight, clHighlightText, $00D77800));

  AddTheme(TStudioTheme.Create('dark', 'Dark',
    $00401A00, $00502205, clWhite, $00301500, clWhite,
    $00201000, clWhite, $00301500, clYellow, $00C8C8C8, clWhite, clBlack,
    $00D77800));
end;

destructor TThemeService.Destroy;
var
  I: Integer;
begin
  for I := 0 to FThemes.Count - 1 do
    TObject(FThemes[I]).Free;
  FThemes.Free;
  inherited Destroy;
end;

procedure TThemeService.AddTheme(ATheme: TStudioTheme);
begin
  FThemes.Add(ATheme);
end;

function TThemeService.FindTheme(const AName: string): TStudioTheme;
var
  I: Integer;
  Theme: TStudioTheme;
begin
  Result := nil;
  for I := 0 to FThemes.Count - 1 do
  begin
    Theme := TStudioTheme(FThemes[I]);
    if SameText(Theme.Name, AName) then
      Exit(Theme);
  end;
end;

function TThemeService.DefaultTheme: TStudioTheme;
begin
  Result := FindTheme('dark');
  if (not Assigned(Result)) and (FThemes.Count > 0) then
    Result := TStudioTheme(FThemes[0]);
end;

function TThemeService.ResolveTheme(const AName: string): TStudioTheme;
begin
  Result := FindTheme(AName);
  if not Assigned(Result) then
    Result := DefaultTheme;
end;

procedure TThemeService.FillThemeNames(AItems: TStrings);
var
  I: Integer;
  Theme: TStudioTheme;
begin
  if not Assigned(AItems) then
    Exit;

  AItems.Clear;
  for I := 0 to FThemes.Count - 1 do
  begin
    Theme := TStudioTheme(FThemes[I]);
    AItems.AddObject(Theme.DisplayName, Theme);
  end;
end;

procedure TThemeService.ApplyTreeViewTheme(ATreeView: TCustomTreeView;
  ATheme: TStudioTheme);
begin
  if not Assigned(ATreeView) or not Assigned(ATheme) then
    Exit;

  ATreeView.Color := ATheme.ProjectExplorerBackgroundColor;
  ATreeView.BackgroundColor := ATheme.ProjectExplorerBackgroundColor;
  ATreeView.Font.Color := ATheme.ProjectExplorerTextColor;
  ATreeView.SelectionColor := ATheme.ProjectExplorerSelectedBackgroundColor;
  ATreeView.SelectionFontColor := ATheme.ProjectExplorerSelectedTextColor;
  ATreeView.SelectionFontColorUsed := True;
end;

procedure TThemeService.ApplyControlTheme(AControl: TControl;
  ATheme: TStudioTheme);
var
  I: Integer;
  WinControl: TWinControl;
begin
  if not Assigned(AControl) or not Assigned(ATheme) then
    Exit;

  AControl.Font.Color := ATheme.TextColor;

  if AControl is TCustomMemo then
  begin
    TCustomMemo(AControl).Color := ATheme.EditorColor;
    TCustomMemo(AControl).Font.Color := ATheme.EditorTextColor;
  end
  else if AControl is TCustomEdit then
  begin
    TCustomEdit(AControl).Color := ATheme.InputColor;
    TCustomEdit(AControl).Font.Color := ATheme.InputTextColor;
  end
  else if AControl is TCustomTreeView then
    ApplyTreeViewTheme(TCustomTreeView(AControl), ATheme)
  else if AControl is TCustomComboBox then
  begin
    TCustomComboBox(AControl).Color := ATheme.InputColor;
    TCustomComboBox(AControl).Font.Color := ATheme.InputTextColor;
  end
  else if AControl is TCustomLabel then
  begin
    TCustomLabel(AControl).Font.Color := ATheme.TextColor
  end
  else if AControl is TCustomPanel then
  begin
    TCustomPanel(AControl).Color := ATheme.PanelColor;
    TCustomPanel(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TTabSheet then
  begin
    TTabSheet(AControl).Color := ATheme.WindowColor;
    TTabSheet(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TToolBar then
  begin
    TToolBar(AControl).Color := ATheme.PanelColor;
    TToolBar(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TStatusBar then
  begin
    TStatusBar(AControl).Color := ATheme.PanelColor;
    TStatusBar(AControl).Font.Color := ATheme.TextColor;
  end;

  if AControl is TWinControl then
  begin
    WinControl := TWinControl(AControl);
    for I := 0 to WinControl.ControlCount - 1 do
      ApplyControlTheme(WinControl.Controls[I], ATheme);
  end;
end;

procedure TThemeService.ApplyTheme(AForm: TCustomForm; const AThemeName: string);
var
  Theme: TStudioTheme;
  I: Integer;
begin
  if not Assigned(AForm) then
    Exit;

  Theme := ResolveTheme(AThemeName);
  if not Assigned(Theme) then
    Exit;

  AForm.Color := Theme.WindowColor;
  AForm.Font.Color := Theme.TextColor;
  for I := 0 to AForm.ControlCount - 1 do
    ApplyControlTheme(AForm.Controls[I], Theme);
end;

end.
