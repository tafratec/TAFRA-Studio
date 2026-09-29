unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  ExtCtrls, StdCtrls;

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
    procedure OpenProjectMenuItemClick(Sender: TObject);
    procedure OutputMenuItemClick(Sender: TObject);
    procedure ProjectExplorerMenuItemClick(Sender: TObject);
  private
    FCurrentProjectPath: string;
    procedure AddOutput(const AMessage: string);
    procedure UpdateProjectState;
  public
    property CurrentProjectPath: string read FCurrentProjectPath;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  UpdateProjectState;
  AddOutput('TAFRA Studio is ready.');
end;

procedure TMainForm.OpenProjectMenuItemClick(Sender: TObject);
begin
  if not SelectDirectoryDialog.Execute then
    Exit;

  FCurrentProjectPath := SelectDirectoryDialog.FileName;
  ProjectTreeView.Items.Clear;
  ProjectTreeView.Items.Add(nil, FCurrentProjectPath);
  UpdateProjectState;
  AddOutput('Project opened: ' + FCurrentProjectPath);
end;

procedure TMainForm.CloseProjectMenuItemClick(Sender: TObject);
begin
  if FCurrentProjectPath = '' then
    Exit;

  AddOutput('Project closed: ' + FCurrentProjectPath);
  FCurrentProjectPath := '';
  ProjectTreeView.Items.Clear;
  UpdateProjectState;
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

procedure TMainForm.OutputMenuItemClick(Sender: TObject);
begin
  OutputPanel.Visible := OutputMenuItem.Checked;
  OutputSplitter.Visible := OutputMenuItem.Checked;
end;

procedure TMainForm.AboutMenuItemClick(Sender: TObject);
begin
  MessageDlg('TAFRA Studio' + LineEnding +
    'TAFRA Framework Development Studio', mtInformation, [mbOK], 0);
end;

procedure TMainForm.AddOutput(const AMessage: string);
begin
  OutputMemo.Lines.Add(AMessage);
end;

procedure TMainForm.UpdateProjectState;
begin
  CloseProjectMenuItem.Enabled := FCurrentProjectPath <> '';

  if FCurrentProjectPath = '' then
    StatusBar.SimpleText := 'No project open'
  else
    StatusBar.SimpleText := 'Project: ' + FCurrentProjectPath;
end;

end.
