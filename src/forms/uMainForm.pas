unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls, uAppPaths, uLogger, uProcessRunner, uPHPToolRunner,
  uProjectSession, uProjectScanner, uProjectAnalyzer, uTAFRAFrameworkRules,
  uProjectExplorerPresenter, uResultTypes, uProjectModel;

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
    ProjectExplorerMenuItem: TMenuItem;
    ProjectExplorerPanel: TPanel;
    ProjectTreeView: TTreeView;
    RecentProjectsMenuItem: TMenuItem;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    SeparatorMenuItem: TMenuItem;
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
    procedure OpenProjectMenuItemClick(Sender: TObject);
    procedure OutputMenuItemClick(Sender: TObject);
    procedure ProjectExplorerMenuItemClick(Sender: TObject);
    procedure ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
  private
    FAppPaths: TAppPaths;
    FLogger: TLogger;
    FProcessRunner: TProcessRunner;
    FPHPToolRunner: TPHPToolRunner;
    FFrameworkRules: TTAFRAFrameworkRules;
    FProjectScanner: TProjectScanner;
    FProjectAnalyzer: TProjectAnalyzer;
    FProjectSession: TProjectSession;
    FProjectExplorerPresenter: TProjectExplorerPresenter;
    FScanProjectMenuItem: TMenuItem;
    FAnalyzerPages: TPageControl;
    FSummaryMemo: TMemo;
    FFilesMemo: TMemo;
    FDiagnosticsMemo: TMemo;
    procedure AnalyzeCurrentProject;
    procedure CreateAnalyzerMenu;
    procedure CreateAnalyzerView;
    procedure HandleLog(Sender: TObject; ALevel: TLogLevel;
      const AMessage: string);
    procedure LogProjectIssues(AProject: TTAFRAProject);
    procedure LoadApplicationIcon;
    function LogoIconPath: string;
    function LogoPngPath: string;
    function FileBelongsToSelectedNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function FilePathMatchesSelectedNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function FilePathBelongsToNode(AProjectFile: TTAFRAProjectFile;
      ANodeInfo: TProjectExplorerNodeInfo): Boolean;
    function NormalizeAnalyzerPath(const APath: string): string;
    procedure RefreshProjectExplorer;
    procedure RefreshAnalyzerView;
    procedure RefreshAnalyzerFiles;
    procedure RunPHPHealthCheck;
    procedure ScanProjectMenuItemClick(Sender: TObject);
    procedure UpdateProjectState;
  public
    function CurrentProjectPath: string;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FAppPaths := TAppPaths.Create;
  FLogger := TLogger.Create;
  FLogger.OnLog := @HandleLog;
  LoadApplicationIcon;
  FProcessRunner := TProcessRunner.Create;
  FPHPToolRunner := TPHPToolRunner.Create(FAppPaths, FProcessRunner);
  FFrameworkRules := TTAFRAFrameworkRules.Create;
  FProjectScanner := TProjectScanner.Create(FFrameworkRules);
  FProjectAnalyzer := TProjectAnalyzer.Create;
  FProjectSession := TProjectSession.Create(FProjectScanner);
  FProjectExplorerPresenter := TProjectExplorerPresenter.Create;
  CreateAnalyzerMenu;
  CreateAnalyzerView;

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
  FProjectAnalyzer.Free;
  FProjectScanner.Free;
  FFrameworkRules.Free;
  FPHPToolRunner.Free;
  FProcessRunner.Free;
  FLogger.Free;
  FAppPaths.Free;
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

procedure TMainForm.ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  RefreshAnalyzerFiles;
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

procedure TMainForm.CreateAnalyzerMenu;
begin
  FScanProjectMenuItem := TMenuItem.Create(MainMenu);
  FScanProjectMenuItem.Caption := '&Scan Project';
  FScanProjectMenuItem.Enabled := False;
  FScanProjectMenuItem.OnClick := @ScanProjectMenuItemClick;
  FileMenuItem.Insert(2, FScanProjectMenuItem);
end;

procedure TMainForm.CreateAnalyzerView;
var
  SummaryTab: TTabSheet;
  FilesTab: TTabSheet;
  DiagnosticsTab: TTabSheet;
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

  DiagnosticsTab := TTabSheet.Create(Self);
  DiagnosticsTab.PageControl := FAnalyzerPages;
  DiagnosticsTab.Caption := 'Diagnostics';

  FDiagnosticsMemo := TMemo.Create(Self);
  FDiagnosticsMemo.Parent := DiagnosticsTab;
  FDiagnosticsMemo.Align := alClient;
  FDiagnosticsMemo.ReadOnly := True;
  FDiagnosticsMemo.ScrollBars := ssAutoBoth;
  FDiagnosticsMemo.WordWrap := False;
end;

procedure TMainForm.HandleLog(Sender: TObject; ALevel: TLogLevel;
  const AMessage: string);
begin
  OutputMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' [' +
    LogLevelToText(ALevel) + '] ' + AMessage);
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

procedure TMainForm.UpdateProjectState;
begin
  CloseProjectMenuItem.Enabled := CurrentProjectPath <> '';
  if Assigned(FScanProjectMenuItem) then
    FScanProjectMenuItem.Enabled := CurrentProjectPath <> '';

  if CurrentProjectPath = '' then
    StatusBar.SimpleText := 'No project open'
  else
    StatusBar.SimpleText := 'Project: ' + CurrentProjectPath;
end;

function TMainForm.CurrentProjectPath: string;
begin
  if Assigned(FProjectSession) then
    Result := FProjectSession.CurrentProjectPath
  else
    Result := '';
end;

end.
