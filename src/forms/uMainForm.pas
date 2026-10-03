unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, uAppPaths, uLogger, uProcessRunner, uPHPToolRunner,
  uSettingsService, uComposerRunner, uProjectSession, uProjectScanner,
  uProjectAnalyzer, uTAFRAFrameworkRules, uProjectExplorerPresenter,
  uModuleManagementService, uSettingsForm, uSourceFileService, uResultTypes,
  uProjectModel, SynEdit, SynHighlighterPHP, SynHighlighterJScript,
  SynHighlighterCss, SynHighlighterHtml, SynHighlighterSQL;

type

  { TMainForm }

  TMainForm = class(TForm)
    CloseProjectMenuItem: TMenuItem;
    ContentPanel: TPanel;
    ExplorerSplitter: TSplitter;
    ExitMenuItem: TMenuItem;
    FileMenuItem: TMenuItem;
    HelpMenuItem: TMenuItem;
    MainMenu: TMainMenu;
    OpenProjectMenuItem: TMenuItem;
    OutputMemo: TMemo;
    OutputMenuItem: TMenuItem;
    OutputPanel: TPanel;
    OutputSplitter: TSplitter;
    ProjectMenuItem: TMenuItem;
    ProjectExplorerMenuItem: TMenuItem;
    ProjectExplorerPanel: TPanel;
    ProjectTreeView: TTreeView;
    RecentProjectsMenuItem: TMenuItem;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    SeparatorMenuItem: TMenuItem;
    SettingsMenuItem: TMenuItem;
    ApplicationSettingsMenuItem: TMenuItem;
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    ViewMenuItem: TMenuItem;
    WorkspacePanel: TPanel;
    AboutMenuItem: TMenuItem;
    procedure AboutMenuItemClick(Sender: TObject);
    procedure CloseProjectMenuItemClick(Sender: TObject);
    procedure ExitMenuItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationSettingsMenuItemClick(Sender: TObject);
    procedure OpenProjectMenuItemClick(Sender: TObject);
    procedure OutputMenuItemClick(Sender: TObject);
    procedure ProjectExplorerMenuItemClick(Sender: TObject);
    procedure ProjectTreePopupMenuPopup(Sender: TObject);
    procedure ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure ProjectTreeViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FAppPaths: TAppPaths;
    FLogger: TLogger;
    FProcessRunner: TProcessRunner;
    FSettingsService: TSettingsService;
    FComposerRunner: TComposerRunner;
    FPHPToolRunner: TPHPToolRunner;
    FFrameworkRules: TTAFRAFrameworkRules;
    FProjectScanner: TProjectScanner;
    FProjectAnalyzer: TProjectAnalyzer;
    FModuleManagementService: TModuleManagementService;
    FSourceFileService: TSourceFileService;
    FProjectSession: TProjectSession;
    FProjectExplorerPresenter: TProjectExplorerPresenter;
    FScanProjectMenuItem: TMenuItem;
    FModulesManagementMenuItem: TMenuItem;
    FProjectTreePopupMenu: TPopupMenu;
    FCreateModuleMenuItem: TMenuItem;
    FCreateSubmoduleMenuItem: TMenuItem;
    FEditModulePropertiesMenuItem: TMenuItem;
    FEditSubmodulePropertiesMenuItem: TMenuItem;
    FReorderSubmodulesMenuItem: TMenuItem;
    FDeleteSubmoduleMenuItem: TMenuItem;
    FDeleteModuleMenuItem: TMenuItem;
    FCheckModuleNamingMenuItem: TMenuItem;
    FCheckSubmoduleNamingMenuItem: TMenuItem;
    FPopupCreateModuleMenuItem: TMenuItem;
    FPopupCreateSubmoduleMenuItem: TMenuItem;
    FPopupEditModulePropertiesMenuItem: TMenuItem;
    FPopupEditSubmodulePropertiesMenuItem: TMenuItem;
    FPopupReorderSubmodulesMenuItem: TMenuItem;
    FPopupDeleteSubmoduleMenuItem: TMenuItem;
    FPopupDeleteModuleMenuItem: TMenuItem;
    FPopupCheckModuleNamingMenuItem: TMenuItem;
    FPopupCheckSubmoduleNamingMenuItem: TMenuItem;
    FAnalyzerPages: TPageControl;
    FSummaryMemo: TMemo;
    FFilesMemo: TMemo;
    FDiagnosticsMemo: TMemo;
    FSourceTab: TTabSheet;
    FSourcePathLabel: TLabel;
    FSourceEditor: TSynEdit;
    FPHPHighlighter: TSynPHPSyn;
    FJScriptHighlighter: TSynJScriptSyn;
    FCssHighlighter: TSynCssSyn;
    FHtmlHighlighter: TSynHTMLSyn;
    FSQLHighlighter: TSynSQLSyn;
    function AddModuleManagementMenuItem(AOwnerMenu: TMenuItem;
      AAction: TModuleManagementAction): TMenuItem;
    function AddModuleManagementPopupItem(AAction: TModuleManagementAction
      ): TMenuItem;
    procedure AnalyzeCurrentProject;
    procedure CreateAnalyzerMenu;
    procedure CreateAnalyzerView;
    procedure CreateModuleManagementMenus;
    function CurrentModuleManagementContext: TModuleManagementContext;
    function CurrentProjectExplorerNodeInfo: TProjectExplorerNodeInfo;
    procedure FilesMemoDblClick(Sender: TObject);
    procedure HandleLog(Sender: TObject; ALevel: TLogLevel;
      const AMessage: string);
    procedure ModuleManagementMenuItemClick(Sender: TObject);
    procedure LogProjectIssues(AProject: TTAFRAProject);
    procedure LoadApplicationIcon;
    function LogoIconPath: string;
    function LogoPngPath: string;
    procedure ApplySourceViewerSettings;
    function IsDestructiveModuleManagementAction(
      AAction: TModuleManagementAction): Boolean;
    function FileBelongsToSelectedNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function FilePathMatchesSelectedNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function FilePathBelongsToNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function NormalizeAnalyzerPath(const APath: string): string;
    procedure OpenSourceFile(const AFilePath: string);
    function PrepareModuleManagementContext(AAction: TModuleManagementAction;
      var AContext: TModuleManagementContext): Boolean;
    procedure ReloadCurrentProject;
    procedure RefreshProjectExplorer;
    procedure RefreshAnalyzerView;
    procedure RefreshAnalyzerFiles;
    procedure RunPHPHealthCheck;
    procedure ScanProjectMenuItemClick(Sender: TObject);
    procedure SetModuleManagementActionEnabled(AAction: TModuleManagementAction;
      AEnabled: Boolean);
    procedure UpdateProjectState;
    procedure UpdateModuleManagementActions;
  public
    function CurrentProjectPath: string;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  FAppPaths := TAppPaths.Create;
  FLogger := TLogger.Create;
  FLogger.OnLog := @HandleLog;
  LoadApplicationIcon;
  FProcessRunner := TProcessRunner.Create;
  FSettingsService := TSettingsService.Create(FAppPaths, FProcessRunner);
  ResultInfo := FSettingsService.Load;
  try
    if not ResultInfo.Success then
      FLogger.Warning('Settings unavailable: ' + ResultInfo.MessageText);
  finally
    ResultInfo.Free;
  end;
  FComposerRunner := TComposerRunner.Create(FProcessRunner, FSettingsService);
  FPHPToolRunner := TPHPToolRunner.Create(FAppPaths, FProcessRunner,
    FSettingsService);
  FFrameworkRules := TTAFRAFrameworkRules.Create;
  FProjectScanner := TProjectScanner.Create(FFrameworkRules);
  FProjectAnalyzer := TProjectAnalyzer.Create;
  FModuleManagementService := TModuleManagementService.Create(FAppPaths,
    FPHPToolRunner);
  FSourceFileService := TSourceFileService.Create;
  FProjectSession := TProjectSession.Create(FProjectScanner);
  FProjectExplorerPresenter := TProjectExplorerPresenter.Create;
  CreateAnalyzerMenu;
  CreateModuleManagementMenus;
  CreateAnalyzerView;
  ApplySourceViewerSettings;

  UpdateProjectState;
  RefreshAnalyzerView;
  FLogger.Info('TAFRA Studio is ready.');
  RunPHPHealthCheck;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FProjectExplorerPresenter.Render(ProjectTreeView, nil);
  FProjectExplorerPresenter.Free;
  FProjectSession.Free;
  FModuleManagementService.Free;
  FSourceFileService.Free;
  FProjectAnalyzer.Free;
  FProjectScanner.Free;
  FFrameworkRules.Free;
  FPHPToolRunner.Free;
  FComposerRunner.Free;
  FSettingsService.Free;
  FProcessRunner.Free;
  FLogger.Free;
  FAppPaths.Free;
end;

procedure TMainForm.ApplicationSettingsMenuItemClick(Sender: TObject);
var
  SettingsForm: TSettingsForm;
begin
  SettingsForm := TSettingsForm.Create(Self, FSettingsService, FComposerRunner);
  try
    if SettingsForm.ShowModal = mrOK then
    begin
      FLogger.Info('Application settings saved.');
      ApplySourceViewerSettings;
      RunPHPHealthCheck;
    end;
  finally
    SettingsForm.Free;
  end;
end;

procedure TMainForm.OpenProjectMenuItemClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  if not SelectDirectoryDialog.Execute then
    Exit;

  ResultInfo := FProjectSession.OpenProject(SelectDirectoryDialog.FileName);
  try
    if ResultInfo.Success then
    begin
      FLogger.Info(ResultInfo.MessageText);
      AnalyzeCurrentProject;
      RefreshProjectExplorer;
      RefreshAnalyzerView;
      LogProjectIssues(FProjectSession.CurrentProject);
    end
    else
      FLogger.Error(ResultInfo.MessageText);
    UpdateProjectState;
  finally
    ResultInfo.Free;
  end;
end;

procedure TMainForm.CloseProjectMenuItemClick(Sender: TObject);
var
  ResultInfo: TOperationResult;
begin
  ResultInfo := FProjectSession.CloseProject;
  try
    FLogger.Info(ResultInfo.MessageText);
    RefreshProjectExplorer;
    RefreshAnalyzerView;
    UpdateProjectState;
  finally
    ResultInfo.Free;
  end;
end;

procedure TMainForm.ExitMenuItemClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.ProjectExplorerMenuItemClick(Sender: TObject);
begin
  ProjectExplorerPanel.Visible := ProjectExplorerMenuItem.Checked;
  ExplorerSplitter.Visible := ProjectExplorerMenuItem.Checked;
end;

procedure TMainForm.ProjectTreePopupMenuPopup(Sender: TObject);
begin
  UpdateModuleManagementActions;
end;

procedure TMainForm.ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
var
  NodeInfo: TProjectExplorerNodeInfo;
begin
  RefreshAnalyzerFiles;
  UpdateModuleManagementActions;

  NodeInfo := CurrentProjectExplorerNodeInfo;
  if Assigned(NodeInfo) and (NodeInfo.Kind = penFile) then
    OpenSourceFile(NodeInfo.Path);
end;

procedure TMainForm.ProjectTreeViewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Node: TTreeNode;
begin
  if Button <> mbRight then
    Exit;

  Node := ProjectTreeView.GetNodeAt(X, Y);
  if Assigned(Node) then
    ProjectTreeView.Selected := Node;
end;

procedure TMainForm.OutputMenuItemClick(Sender: TObject);
begin
  OutputPanel.Visible := OutputMenuItem.Checked;
  OutputSplitter.Visible := OutputMenuItem.Checked;
end;

procedure TMainForm.AboutMenuItemClick(Sender: TObject);
var
  AboutForm: TForm;
  LogoImage: TImage;
  TitleLabel: TLabel;
  DescriptionLabel: TLabel;
  RuntimeLabel: TLabel;
  OkButton: TButton;
begin
  AboutForm := TForm.Create(Self);
  try
    AboutForm.Caption := 'About TAFRA Studio';
    AboutForm.BorderStyle := bsDialog;
    AboutForm.Position := poOwnerFormCenter;
    AboutForm.ClientWidth := 420;
    AboutForm.ClientHeight := 220;

    if FileExists(LogoIconPath) then
      AboutForm.Icon.LoadFromFile(LogoIconPath);

    LogoImage := TImage.Create(AboutForm);
    LogoImage.Parent := AboutForm;
    LogoImage.SetBounds(20, 24, 96, 96);
    LogoImage.Stretch := True;
    LogoImage.Proportional := True;
    LogoImage.Center := True;
    if FileExists(LogoPngPath) then
      LogoImage.Picture.LoadFromFile(LogoPngPath);

    TitleLabel := TLabel.Create(AboutForm);
    TitleLabel.Parent := AboutForm;
    TitleLabel.SetBounds(140, 28, 250, 26);
    TitleLabel.Caption := 'TAFRA Studio';
    TitleLabel.Font.Style := [fsBold];
    TitleLabel.Font.Size := 14;

    DescriptionLabel := TLabel.Create(AboutForm);
    DescriptionLabel.Parent := AboutForm;
    DescriptionLabel.SetBounds(140, 66, 250, 42);
    DescriptionLabel.Caption := 'TAFRA Framework Development Studio';
    DescriptionLabel.WordWrap := True;

    RuntimeLabel := TLabel.Create(AboutForm);
    RuntimeLabel.Parent := AboutForm;
    RuntimeLabel.SetBounds(140, 112, 250, 42);
    RuntimeLabel.Caption := 'Native Lazarus 4.8 desktop tooling for TAFRA projects.';
    RuntimeLabel.WordWrap := True;

    OkButton := TButton.Create(AboutForm);
    OkButton.Parent := AboutForm;
    OkButton.Caption := 'OK';
    OkButton.ModalResult := mrOK;
    OkButton.SetBounds(320, 176, 80, 28);
    AboutForm.DefaultControl := OkButton;

    AboutForm.ShowModal;
  finally
    AboutForm.Free;
  end;
end;

procedure TMainForm.AnalyzeCurrentProject;
var
  Project: TTAFRAProject;
begin
  Project := FProjectSession.CurrentProject;
  if not Assigned(Project) then
    Exit;

  FProjectAnalyzer.Analyze(Project);
  FLogger.Info('Analyzer completed: ' + IntToStr(Project.Files.Count) +
    ' relevant files, ' + IntToStr(Project.Modules.Count) + ' modules.');
end;

function TMainForm.AddModuleManagementMenuItem(AOwnerMenu: TMenuItem;
  AAction: TModuleManagementAction): TMenuItem;
begin
  Result := TMenuItem.Create(MainMenu);
  Result.Caption := FModuleManagementService.ActionCaption(AAction);
  Result.Tag := Ord(AAction);
  Result.OnClick := @ModuleManagementMenuItemClick;
  AOwnerMenu.Add(Result);
end;

function TMainForm.AddModuleManagementPopupItem(AAction: TModuleManagementAction
  ): TMenuItem;
begin
  Result := TMenuItem.Create(FProjectTreePopupMenu);
  Result.Caption := FModuleManagementService.ActionCaption(AAction);
  Result.Tag := Ord(AAction);
  Result.OnClick := @ModuleManagementMenuItemClick;
  FProjectTreePopupMenu.Items.Add(Result);
end;

procedure TMainForm.CreateAnalyzerMenu;
begin
  FScanProjectMenuItem := TMenuItem.Create(MainMenu);
  FScanProjectMenuItem.Caption := '&Scan Project';
  FScanProjectMenuItem.Enabled := False;
  FScanProjectMenuItem.OnClick := @ScanProjectMenuItemClick;
  FileMenuItem.Insert(2, FScanProjectMenuItem);
end;

procedure TMainForm.CreateModuleManagementMenus;
begin
  FModulesManagementMenuItem := TMenuItem.Create(MainMenu);
  FModulesManagementMenuItem.Caption := '&Modules Management';
  FModulesManagementMenuItem.Enabled := False;
  ProjectMenuItem.Add(FModulesManagementMenuItem);

  FCreateModuleMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaCreateModule);
  FCreateSubmoduleMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaCreateSubmodule);
  FEditModulePropertiesMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaEditModuleProperties);
  FEditSubmodulePropertiesMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaEditSubmoduleProperties);
  FReorderSubmodulesMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaReorderSubmodules);
  FDeleteSubmoduleMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaDeleteSubmodule);
  FDeleteModuleMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaDeleteModule);
  FCheckModuleNamingMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaCheckModuleNaming);
  FCheckSubmoduleNamingMenuItem := AddModuleManagementMenuItem(FModulesManagementMenuItem,
    mmaCheckSubmoduleNaming);

  FProjectTreePopupMenu := TPopupMenu.Create(Self);
  FProjectTreePopupMenu.OnPopup := @ProjectTreePopupMenuPopup;
  ProjectTreeView.PopupMenu := FProjectTreePopupMenu;

  FPopupCreateModuleMenuItem := AddModuleManagementPopupItem(mmaCreateModule);
  FPopupCreateSubmoduleMenuItem := AddModuleManagementPopupItem(mmaCreateSubmodule);
  FPopupEditModulePropertiesMenuItem :=
    AddModuleManagementPopupItem(mmaEditModuleProperties);
  FPopupEditSubmodulePropertiesMenuItem :=
    AddModuleManagementPopupItem(mmaEditSubmoduleProperties);
  FPopupReorderSubmodulesMenuItem :=
    AddModuleManagementPopupItem(mmaReorderSubmodules);
  FPopupDeleteSubmoduleMenuItem := AddModuleManagementPopupItem(mmaDeleteSubmodule);
  FPopupDeleteModuleMenuItem := AddModuleManagementPopupItem(mmaDeleteModule);
  FPopupCheckModuleNamingMenuItem := AddModuleManagementPopupItem(mmaCheckModuleNaming);
  FPopupCheckSubmoduleNamingMenuItem :=
    AddModuleManagementPopupItem(mmaCheckSubmoduleNaming);

  UpdateModuleManagementActions;
end;

function TMainForm.CurrentModuleManagementContext: TModuleManagementContext;
var
  NodeInfo: TProjectExplorerNodeInfo;
begin
  Result.Project := nil;
  Result.ModuleName := '';
  Result.SubmoduleName := '';
  Result.NodePath := '';
  Result.Project := FProjectSession.CurrentProject;

  NodeInfo := CurrentProjectExplorerNodeInfo;
  if Assigned(NodeInfo) then
  begin
    Result.ModuleName := NodeInfo.ModuleName;
    Result.SubmoduleName := NodeInfo.SubmoduleName;
    Result.NodePath := NodeInfo.Path;
  end;
end;

function TMainForm.CurrentProjectExplorerNodeInfo: TProjectExplorerNodeInfo;
begin
  Result := nil;
  if Assigned(ProjectTreeView.Selected) then
    Result := TProjectExplorerNodeInfo(ProjectTreeView.Selected.Data);
end;

procedure TMainForm.FilesMemoDblClick(Sender: TObject);
var
  LineIndex: Integer;
  LineText: string;
  SeparatorPos: Integer;
  RelativePath: string;
  FullPath: string;
begin
  if (not Assigned(FFilesMemo)) or (CurrentProjectPath = '') then
    Exit;

  LineIndex := FFilesMemo.CaretPos.Y;
  if (LineIndex < 0) or (LineIndex >= FFilesMemo.Lines.Count) then
    Exit;

  LineText := FFilesMemo.Lines[LineIndex];
  SeparatorPos := Pos('  ', LineText);
  if SeparatorPos <= 0 then
    Exit;

  RelativePath := Trim(Copy(LineText, SeparatorPos + 2, MaxInt));
  if RelativePath = '' then
    Exit;

  FullPath := IncludeTrailingPathDelimiter(CurrentProjectPath) + RelativePath;
  OpenSourceFile(FullPath);
end;

procedure TMainForm.CreateAnalyzerView;
var
  SummaryTab: TTabSheet;
  FilesTab: TTabSheet;
  DiagnosticsTab: TTabSheet;
  SourceHeaderPanel: TPanel;
begin
  WorkspacePanel.Caption := '';

  FAnalyzerPages := TPageControl.Create(Self);
  FAnalyzerPages.Parent := WorkspacePanel;
  FAnalyzerPages.Align := alClient;

  SummaryTab := TTabSheet.Create(Self);
  SummaryTab.PageControl := FAnalyzerPages;
  SummaryTab.Caption := 'Analyzer';

  FSummaryMemo := TMemo.Create(Self);
  FSummaryMemo.Parent := SummaryTab;
  FSummaryMemo.Align := alClient;
  FSummaryMemo.ReadOnly := True;
  FSummaryMemo.ScrollBars := ssAutoBoth;
  FSummaryMemo.WordWrap := False;

  FilesTab := TTabSheet.Create(Self);
  FilesTab.PageControl := FAnalyzerPages;
  FilesTab.Caption := 'Files';

  FFilesMemo := TMemo.Create(Self);
  FFilesMemo.Parent := FilesTab;
  FFilesMemo.Align := alClient;
  FFilesMemo.ReadOnly := True;
  FFilesMemo.ScrollBars := ssAutoBoth;
  FFilesMemo.WordWrap := False;
  FFilesMemo.OnDblClick := @FilesMemoDblClick;

  DiagnosticsTab := TTabSheet.Create(Self);
  DiagnosticsTab.PageControl := FAnalyzerPages;
  DiagnosticsTab.Caption := 'Diagnostics';

  FDiagnosticsMemo := TMemo.Create(Self);
  FDiagnosticsMemo.Parent := DiagnosticsTab;
  FDiagnosticsMemo.Align := alClient;
  FDiagnosticsMemo.ReadOnly := True;
  FDiagnosticsMemo.ScrollBars := ssAutoBoth;
  FDiagnosticsMemo.WordWrap := False;

  FSourceTab := TTabSheet.Create(Self);
  FSourceTab.PageControl := FAnalyzerPages;
  FSourceTab.Caption := 'Source';

  SourceHeaderPanel := TPanel.Create(Self);
  SourceHeaderPanel.Parent := FSourceTab;
  SourceHeaderPanel.Align := alTop;
  SourceHeaderPanel.Height := 28;
  SourceHeaderPanel.Caption := '';
  SourceHeaderPanel.BevelOuter := bvNone;

  FSourcePathLabel := TLabel.Create(Self);
  FSourcePathLabel.Parent := SourceHeaderPanel;
  FSourcePathLabel.Align := alClient;
  FSourcePathLabel.Layout := tlCenter;
  FSourcePathLabel.Caption := 'Select a file from the Project Tree to preview it.';

  FPHPHighlighter := TSynPHPSyn.Create(Self);
  FJScriptHighlighter := TSynJScriptSyn.Create(Self);
  FCssHighlighter := TSynCssSyn.Create(Self);
  FHtmlHighlighter := TSynHTMLSyn.Create(Self);
  FSQLHighlighter := TSynSQLSyn.Create(Self);

  FSourceEditor := TSynEdit.Create(Self);
  FSourceEditor.Parent := FSourceTab;
  FSourceEditor.Align := alClient;
  FSourceEditor.ReadOnly := True;
  FSourceEditor.Gutter.Width := 57;
  FSourceEditor.RightGutter.Width := 0;
  FSourceEditor.Lines.Text :=
    'Select a PHP/source file from the Project Tree to preview it here.';
end;

procedure TMainForm.HandleLog(Sender: TObject; ALevel: TLogLevel;
  const AMessage: string);
begin
  OutputMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' [' +
    LogLevelToText(ALevel) + '] ' + AMessage);
end;

procedure TMainForm.ModuleManagementMenuItemClick(Sender: TObject);
var
  MgmtAction: TModuleManagementAction;
  Context: TModuleManagementContext;
  Preview: string;
  ResultInfo: TOperationResult;
begin
  if not (Sender is TMenuItem) then
    Exit;

  MgmtAction := TModuleManagementAction(TMenuItem(Sender).Tag);
  Context := CurrentModuleManagementContext;

  if not PrepareModuleManagementContext(MgmtAction, Context) then
    Exit;

  Preview := FModuleManagementService.BuildPreview(MgmtAction, Context);

  if IsDestructiveModuleManagementAction(MgmtAction) then
  begin
    if MessageDlg('Modules Management', Preview, mtWarning, [mbYes, mbNo],
      0) <> mrYes then
      Exit;
  end
  else if MessageDlg('Modules Management', Preview, mtInformation,
    [mbOK, mbCancel], 0) <> mrOK then
    Exit;

  ResultInfo := FModuleManagementService.Execute(MgmtAction, Context);
  try
    if ResultInfo.Success then
    begin
      FLogger.Info(ResultInfo.MessageText);
      ReloadCurrentProject;
    end
    else
      FLogger.Warning(ResultInfo.MessageText);
  finally
    ResultInfo.Free;
  end;
end;

procedure TMainForm.LogProjectIssues(AProject: TTAFRAProject);
var
  I: Integer;
  Issue: TTAFRAValidationIssue;
begin
  if not Assigned(AProject) then
    Exit;

  for I := 0 to AProject.Issues.Count - 1 do
  begin
    Issue := TTAFRAValidationIssue(AProject.Issues[I]);
    if SameText(Issue.Severity, 'Error') then
      FLogger.Error(Issue.MessageText)
    else
      FLogger.Warning(Issue.MessageText);
  end;
end;

procedure TMainForm.LoadApplicationIcon;
begin
  if not FileExists(LogoIconPath) then
    Exit;

  Application.Icon.LoadFromFile(LogoIconPath);
  Icon.Assign(Application.Icon);
end;

function TMainForm.LogoIconPath: string;
begin
  Result := FAppPaths.ApplicationRoot + 'tafraLogo.ico';
end;

function TMainForm.LogoPngPath: string;
begin
  Result := FAppPaths.ApplicationRoot + 'tafraLogo.png';
end;

procedure TMainForm.ApplySourceViewerSettings;
begin
  if not Assigned(FSourceEditor) or not Assigned(FSettingsService) or
    not Assigned(FSettingsService.Settings) then
    Exit;

  FSourceEditor.Font.Name := FSettingsService.Settings.SourceFontName;
  FSourceEditor.Font.Size := FSettingsService.Settings.SourceFontSize;
end;

function TMainForm.IsDestructiveModuleManagementAction(
  AAction: TModuleManagementAction): Boolean;
begin
  Result := AAction in [mmaDeleteSubmodule, mmaDeleteModule];
end;

function TMainForm.FileBelongsToSelectedNode(AProjectFile: TTAFRAProjectFile;
  ANodeInfo: TProjectExplorerNodeInfo): Boolean;
var
  FolderSegment: string;
begin
  Result := False;

  if not Assigned(ANodeInfo) then
    Exit;

  Result := FilePathMatchesSelectedNode(AProjectFile, ANodeInfo);
  if Result then
    Exit;

  case ANodeInfo.Kind of
    penProject:
      Result := True;
    penModule:
      Result := SameText(AProjectFile.OwnerModule, ANodeInfo.ModuleName);
    penSubmodules:
      Result := SameText(AProjectFile.OwnerModule, ANodeInfo.ModuleName) and
        (AProjectFile.OwnerSubmodule <> '');
    penSubmodule:
      Result := SameText(AProjectFile.OwnerModule, ANodeInfo.ModuleName) and
        SameText(AProjectFile.OwnerSubmodule, ANodeInfo.SubmoduleName);
    penFolder:
      begin
        FolderSegment := DirectorySeparator + ANodeInfo.FolderName +
          DirectorySeparator;
        Result := SameText(AProjectFile.OwnerModule, ANodeInfo.ModuleName) and
          SameText(AProjectFile.OwnerSubmodule, ANodeInfo.SubmoduleName) and
          (Pos(FolderSegment, AProjectFile.RelativePath) > 0);
      end;
    penFile:
      Result := SameText(AProjectFile.OwnerModule, ANodeInfo.ModuleName) and
        SameText(AProjectFile.OwnerSubmodule, ANodeInfo.SubmoduleName) and
        SameText(AProjectFile.Name, ANodeInfo.FileName);
  end;

  if not Result then
    Result := FilePathBelongsToNode(AProjectFile, ANodeInfo);
end;

function TMainForm.FilePathMatchesSelectedNode(AProjectFile: TTAFRAProjectFile;
  ANodeInfo: TProjectExplorerNodeInfo): Boolean;
var
  FilePath: string;
  NodePath: string;
begin
  Result := False;
  if (not Assigned(ANodeInfo)) or (ANodeInfo.Path = '') then
    Exit;

  FilePath := NormalizeAnalyzerPath(AProjectFile.Path);
  NodePath := NormalizeAnalyzerPath(ANodeInfo.Path);

  case ANodeInfo.Kind of
    penProject:
      Result := True;
    penModule, penSubmodules, penSubmodule, penFolder:
      Result := Pos(IncludeTrailingPathDelimiter(NodePath), FilePath) = 1;
    penFile:
      Result := FilePath = NodePath;
  end;
end;

function TMainForm.FilePathBelongsToNode(AProjectFile: TTAFRAProjectFile;
  ANodeInfo: TProjectExplorerNodeInfo): Boolean;
var
  RelativePath: string;
  BasePath: string;
  FolderPath: string;
  FilePath: string;
begin
  Result := False;
  if not Assigned(ANodeInfo) then
    Exit;

  RelativePath := NormalizeAnalyzerPath(AProjectFile.RelativePath);
  BasePath := 'app\modules\' + LowerCase(ANodeInfo.ModuleName);

  case ANodeInfo.Kind of
    penProject:
      Result := True;
    penModule:
      Result := Pos(BasePath + '\', RelativePath) = 1;
    penSubmodules:
      Result := Pos(BasePath + '\submodules\', RelativePath) = 1;
    penSubmodule:
      begin
        BasePath := BasePath + '\submodules\' +
          LowerCase(ANodeInfo.SubmoduleName);
        Result := Pos(BasePath + '\', RelativePath) = 1;
      end;
    penFolder:
      begin
        FolderPath := BasePath + '\submodules\' +
          LowerCase(ANodeInfo.SubmoduleName) + '\' +
          LowerCase(ANodeInfo.FolderName) + '\';
        Result := Pos(FolderPath, RelativePath) = 1;
      end;
    penFile:
      begin
        FilePath := BasePath + '\submodules\' +
          LowerCase(ANodeInfo.SubmoduleName) + '\' +
          LowerCase(ANodeInfo.FolderName) + '\' +
          LowerCase(ANodeInfo.FileName);
        Result := RelativePath = FilePath;
      end;
  end;
end;

function TMainForm.NormalizeAnalyzerPath(const APath: string): string;
begin
  Result := LowerCase(StringReplace(ExcludeTrailingPathDelimiter(APath), '/',
    '\', [rfReplaceAll]));
end;

procedure TMainForm.OpenSourceFile(const AFilePath: string);
var
  SourceResult: TSourceFileResult;
  Extension: string;
begin
  if not Assigned(FSourceEditor) or not Assigned(FSourceFileService) then
    Exit;

  SourceResult := FSourceFileService.LoadTextFile(AFilePath);
  try
    if not SourceResult.Success then
    begin
      FSourcePathLabel.Caption := AFilePath;
      FSourceEditor.Highlighter := nil;
      FSourceEditor.Lines.Text := SourceResult.MessageText;
      FAnalyzerPages.ActivePage := FSourceTab;
      FLogger.Warning(SourceResult.MessageText);
      Exit;
    end;

    Extension := LowerCase(ExtractFileExt(AFilePath));

    if Extension = '.php' then
      FSourceEditor.Highlighter := FPHPHighlighter
    else if Extension = '.js' then
      FSourceEditor.Highlighter := FJScriptHighlighter
    else if Extension = '.css' then
      FSourceEditor.Highlighter := FCssHighlighter
    else if (Extension = '.html') or (Extension = '.htm') then
      FSourceEditor.Highlighter := FHtmlHighlighter
    else if Extension = '.sql' then
      FSourceEditor.Highlighter := FSQLHighlighter
    else
      FSourceEditor.Highlighter := nil;

    FSourcePathLabel.Caption := SourceResult.FilePath;
    FSourceEditor.Lines.Text := SourceResult.Content;
    FSourceEditor.ReadOnly := True;
    FSourceEditor.CaretX := 1;
    FSourceEditor.CaretY := 1;
    FAnalyzerPages.ActivePage := FSourceTab;
  finally
    SourceResult.Free;
  end;
end;

function TMainForm.PrepareModuleManagementContext(
  AAction: TModuleManagementAction; var AContext: TModuleManagementContext
  ): Boolean;
var
  Value: string;
begin
  Result := False;

  if not Assigned(AContext.Project) then
  begin
    FLogger.Warning('Open a TAFRA project before using Modules Management.');
    Exit;
  end;

  case AAction of
    mmaCreateModule:
      begin
        Value := '';
        if not InputQuery('Create Module', 'Module name:', Value) then
          Exit;

        AContext.ModuleName := Trim(Value);
        if AContext.ModuleName = '' then
        begin
          FLogger.Warning('Module name is required.');
          Exit;
        end;
      end;
    mmaCreateSubmodule:
      begin
        if AContext.ModuleName = '' then
        begin
          FLogger.Warning('Select a module before creating a submodule.');
          Exit;
        end;

        Value := '';
        if not InputQuery('Create Submodule', 'Submodule name:', Value) then
          Exit;

        AContext.SubmoduleName := Trim(Value);
        if AContext.SubmoduleName = '' then
        begin
          FLogger.Warning('Submodule name is required.');
          Exit;
        end;
      end;
    mmaEditModuleProperties, mmaReorderSubmodules, mmaDeleteModule,
    mmaCheckModuleNaming:
      if AContext.ModuleName = '' then
      begin
        FLogger.Warning('Select a module for this Modules Management action.');
        Exit;
      end;
    mmaEditSubmoduleProperties, mmaDeleteSubmodule, mmaCheckSubmoduleNaming:
      if (AContext.ModuleName = '') or (AContext.SubmoduleName = '') then
      begin
        FLogger.Warning('Select a submodule for this Modules Management action.');
        Exit;
      end;
  end;

  Result := True;
end;

procedure TMainForm.ReloadCurrentProject;
var
  ProjectPath: string;
  ResultInfo: TOperationResult;
begin
  ProjectPath := CurrentProjectPath;
  if ProjectPath = '' then
    Exit;

  ResultInfo := FProjectSession.OpenProject(ProjectPath);
  try
    if ResultInfo.Success then
    begin
      AnalyzeCurrentProject;
      RefreshProjectExplorer;
      RefreshAnalyzerView;
      UpdateProjectState;
    end
    else
      FLogger.Warning(ResultInfo.MessageText);
  finally
    ResultInfo.Free;
  end;
end;

procedure TMainForm.RefreshProjectExplorer;
begin
  FProjectExplorerPresenter.Render(ProjectTreeView, FProjectSession.CurrentProject);
end;

procedure TMainForm.RefreshAnalyzerView;
var
  Project: TTAFRAProject;
  I: Integer;
  Issue: TTAFRAValidationIssue;
begin
  Project := FProjectSession.CurrentProject;

  FSummaryMemo.Clear;
  FFilesMemo.Clear;
  FDiagnosticsMemo.Clear;

  if not Assigned(Project) then
  begin
    FSummaryMemo.Lines.Add('No project open.');
    FDiagnosticsMemo.Lines.Add('Open a TAFRA project directory to analyze it.');
    Exit;
  end;

  FSummaryMemo.Lines.Add('Project: ' + Project.Name);
  FSummaryMemo.Lines.Add('Path: ' + Project.RootPath);
  FSummaryMemo.Lines.Add('Type: ' + Project.ProjectType);
  FSummaryMemo.Lines.Add('');
  FSummaryMemo.Lines.Add('Modules: ' + IntToStr(Project.Modules.Count));
  FSummaryMemo.Lines.Add('Relevant files: ' + IntToStr(Project.Files.Count));
  FSummaryMemo.Lines.Add('Validation issues: ' + IntToStr(Project.Issues.Count));
  FSummaryMemo.Lines.Add('');
  FSummaryMemo.Lines.Add('PHP: ' + IntToStr(Project.FileCountByCategory('PHP')));
  FSummaryMemo.Lines.Add('JavaScript: ' +
    IntToStr(Project.FileCountByCategory('JavaScript')));
  FSummaryMemo.Lines.Add('CSS: ' + IntToStr(Project.FileCountByCategory('CSS')));
  FSummaryMemo.Lines.Add('HTML: ' + IntToStr(Project.FileCountByCategory('HTML')));
  FSummaryMemo.Lines.Add('JSON: ' + IntToStr(Project.FileCountByCategory('JSON')));
  FSummaryMemo.Lines.Add('SQL: ' + IntToStr(Project.FileCountByCategory('SQL')));
  FSummaryMemo.Lines.Add('Markdown: ' +
    IntToStr(Project.FileCountByCategory('Markdown')));

  RefreshAnalyzerFiles;

  if Project.Issues.Count = 0 then
    FDiagnosticsMemo.Lines.Add('No diagnostics.')
  else
    for I := 0 to Project.Issues.Count - 1 do
    begin
      Issue := TTAFRAValidationIssue(Project.Issues[I]);
      FDiagnosticsMemo.Lines.Add(Issue.Severity + ': ' + Issue.MessageText);
    end;
end;

procedure TMainForm.RefreshAnalyzerFiles;
var
  Project: TTAFRAProject;
  NodeInfo: TProjectExplorerNodeInfo;
  I: Integer;
  MatchCount: Integer;
  ProjectFile: TTAFRAProjectFile;
begin
  if not Assigned(FFilesMemo) then
    Exit;

  FFilesMemo.Clear;
  Project := FProjectSession.CurrentProject;
  if not Assigned(Project) then
  begin
    FFilesMemo.Lines.Add('No project open.');
    Exit;
  end;

  if Assigned(ProjectTreeView.Selected) then
    NodeInfo := TProjectExplorerNodeInfo(ProjectTreeView.Selected.Data)
  else
    NodeInfo := nil;

  if not Assigned(NodeInfo) then
  begin
    FFilesMemo.Lines.Add('Select a project tree node to inspect its files.');
    Exit;
  end;

  MatchCount := 0;
  for I := 0 to Project.Files.Count - 1 do
  begin
    ProjectFile := TTAFRAProjectFile(Project.Files[I]);
    if not FileBelongsToSelectedNode(ProjectFile, NodeInfo) then
      Continue;

    Inc(MatchCount);
    FFilesMemo.Lines.Add(ProjectFile.Category + '  ' +
      ProjectFile.RelativePath);
  end;

  if MatchCount = 0 then
    FFilesMemo.Lines.Add('No analyzer files belong to the selected node.');
end;

procedure TMainForm.RunPHPHealthCheck;
var
  Health: TPHPToolResult;
begin
  Health := FPHPToolRunner.ExecuteHealthCheck;
  try
    if Health.Success then
      FLogger.Info(Health.MessageText + ' (PHP ' + Health.PHPVersion + ')')
    else
      FLogger.Warning('PHP health check unavailable: ' + Health.MessageText);
  finally
    Health.Free;
  end;
end;

procedure TMainForm.ScanProjectMenuItemClick(Sender: TObject);
begin
  if CurrentProjectPath = '' then
  begin
    FLogger.Warning('No project is open.');
    Exit;
  end;

  AnalyzeCurrentProject;
  RefreshAnalyzerView;
  RefreshProjectExplorer;
end;

procedure TMainForm.SetModuleManagementActionEnabled(
  AAction: TModuleManagementAction; AEnabled: Boolean);
begin
  case AAction of
    mmaCreateModule:
      begin
        FCreateModuleMenuItem.Enabled := AEnabled;
        FPopupCreateModuleMenuItem.Enabled := AEnabled;
      end;
    mmaCreateSubmodule:
      begin
        FCreateSubmoduleMenuItem.Enabled := AEnabled;
        FPopupCreateSubmoduleMenuItem.Enabled := AEnabled;
      end;
    mmaEditModuleProperties:
      begin
        FEditModulePropertiesMenuItem.Enabled := AEnabled;
        FPopupEditModulePropertiesMenuItem.Enabled := AEnabled;
      end;
    mmaEditSubmoduleProperties:
      begin
        FEditSubmodulePropertiesMenuItem.Enabled := AEnabled;
        FPopupEditSubmodulePropertiesMenuItem.Enabled := AEnabled;
      end;
    mmaReorderSubmodules:
      begin
        FReorderSubmodulesMenuItem.Enabled := AEnabled;
        FPopupReorderSubmodulesMenuItem.Enabled := AEnabled;
      end;
    mmaDeleteSubmodule:
      begin
        FDeleteSubmoduleMenuItem.Enabled := AEnabled;
        FPopupDeleteSubmoduleMenuItem.Enabled := AEnabled;
      end;
    mmaDeleteModule:
      begin
        FDeleteModuleMenuItem.Enabled := AEnabled;
        FPopupDeleteModuleMenuItem.Enabled := AEnabled;
      end;
    mmaCheckModuleNaming:
      begin
        FCheckModuleNamingMenuItem.Enabled := AEnabled;
        FPopupCheckModuleNamingMenuItem.Enabled := AEnabled;
      end;
    mmaCheckSubmoduleNaming:
      begin
        FCheckSubmoduleNamingMenuItem.Enabled := AEnabled;
        FPopupCheckSubmoduleNamingMenuItem.Enabled := AEnabled;
      end;
  end;
end;

procedure TMainForm.UpdateProjectState;
begin
  CloseProjectMenuItem.Enabled := CurrentProjectPath <> '';
  ProjectMenuItem.Enabled := CurrentProjectPath <> '';
  if Assigned(FModulesManagementMenuItem) then
    FModulesManagementMenuItem.Enabled := CurrentProjectPath <> '';
  if Assigned(FScanProjectMenuItem) then
    FScanProjectMenuItem.Enabled := CurrentProjectPath <> '';

  if CurrentProjectPath = '' then
    StatusBar.SimpleText := 'No project open'
  else
    StatusBar.SimpleText := 'Project: ' + CurrentProjectPath;

  UpdateModuleManagementActions;
end;

procedure TMainForm.UpdateModuleManagementActions;
var
  NodeInfo: TProjectExplorerNodeInfo;
  ProjectOpen: Boolean;
  IsModuleNode: Boolean;
  IsSubmoduleNode: Boolean;
begin
  if not Assigned(FCreateModuleMenuItem) then
    Exit;

  ProjectOpen := CurrentProjectPath <> '';
  NodeInfo := CurrentProjectExplorerNodeInfo;
  IsModuleNode := ProjectOpen and Assigned(NodeInfo) and
    (NodeInfo.Kind = penModule);
  IsSubmoduleNode := ProjectOpen and Assigned(NodeInfo) and
    (NodeInfo.Kind = penSubmodule);

  SetModuleManagementActionEnabled(mmaCreateModule, ProjectOpen);
  SetModuleManagementActionEnabled(mmaCreateSubmodule, IsModuleNode);
  SetModuleManagementActionEnabled(mmaEditModuleProperties, IsModuleNode);
  SetModuleManagementActionEnabled(mmaEditSubmoduleProperties, IsSubmoduleNode);
  SetModuleManagementActionEnabled(mmaReorderSubmodules, IsModuleNode);
  SetModuleManagementActionEnabled(mmaDeleteSubmodule, IsSubmoduleNode);
  SetModuleManagementActionEnabled(mmaDeleteModule, IsModuleNode);
  SetModuleManagementActionEnabled(mmaCheckModuleNaming, IsModuleNode);
  SetModuleManagementActionEnabled(mmaCheckSubmoduleNaming, IsSubmoduleNode);
end;

function TMainForm.CurrentProjectPath: string;
begin
  if Assigned(FProjectSession) then
    Result := FProjectSession.CurrentProjectPath
  else
    Result := '';
end;

end.
