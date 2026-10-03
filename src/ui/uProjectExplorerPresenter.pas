unit uProjectExplorerPresenter;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, uProjectModel;

type
  TProjectExplorerNodeKind = (
    penUnknown,
    penProject,
    penModule,
    penSubmodules,
    penSubmodule,
    penFolder,
    penFile,
    penValidation
  );

  TProjectExplorerNodeInfo = class
  private
    FKind: TProjectExplorerNodeKind;
    FModuleName: string;
    FSubmoduleName: string;
    FFolderName: string;
    FFileName: string;
    FPath: string;
  public
    constructor Create(AKind: TProjectExplorerNodeKind;
      const AModuleName: string = ''; const ASubmoduleName: string = '';
      const AFolderName: string = ''; const AFileName: string = '';
      const APath: string = '');
    property Kind: TProjectExplorerNodeKind read FKind;
    property ModuleName: string read FModuleName;
    property SubmoduleName: string read FSubmoduleName;
    property FolderName: string read FFolderName;
    property FileName: string read FFileName;
    property Path: string read FPath;
  end;

  TProjectExplorerPresenter = class
  private
    function AddNode(ATree: TTreeView; AParent: TTreeNode;
      const ACaption: string; AInfo: TProjectExplorerNodeInfo): TTreeNode;
    procedure ClearNodeData(ATree: TTreeView);
    procedure RenderFileTree(ATree: TTreeView; AParent: TTreeNode;
      ANode: TTAFRAFileSystemNode; const AModuleName: string;
      const ASubmoduleName: string);
  public
    procedure Render(ATree: TTreeView; AProject: TTAFRAProject);
  end;

implementation

uses
  SysUtils;

constructor TProjectExplorerNodeInfo.Create(AKind: TProjectExplorerNodeKind;
  const AModuleName: string; const ASubmoduleName: string;
  const AFolderName: string; const AFileName: string; const APath: string);
begin
  inherited Create;
  FKind := AKind;
  FModuleName := AModuleName;
  FSubmoduleName := ASubmoduleName;
  FFolderName := AFolderName;
  FFileName := AFileName;
  FPath := APath;
end;

function TProjectExplorerPresenter.AddNode(ATree: TTreeView;
  AParent: TTreeNode; const ACaption: string; AInfo: TProjectExplorerNodeInfo
  ): TTreeNode;
begin
  if Assigned(AParent) then
    Result := ATree.Items.AddChild(AParent, ACaption)
  else
    Result := ATree.Items.Add(nil, ACaption);
  Result.Data := AInfo;
end;

procedure TProjectExplorerPresenter.ClearNodeData(ATree: TTreeView);
var
  I: Integer;
begin
  for I := 0 to ATree.Items.Count - 1 do
  begin
    TObject(ATree.Items[I].Data).Free;
    ATree.Items[I].Data := nil;
  end;
end;

procedure TProjectExplorerPresenter.RenderFileTree(ATree: TTreeView;
  AParent: TTreeNode; ANode: TTAFRAFileSystemNode; const AModuleName: string;
  const ASubmoduleName: string);
var
  Node: TTreeNode;
  I: Integer;
  ChildNode: TTAFRAFileSystemNode;
begin
  if not Assigned(ANode) then
    Exit;

  if ANode.IsDirectory then
    Node := AddNode(ATree, AParent, ANode.Name,
      TProjectExplorerNodeInfo.Create(penFolder, AModuleName, ASubmoduleName,
      ANode.Name, '', ANode.Path))
  else
  begin
    AddNode(ATree, AParent, ANode.Name,
      TProjectExplorerNodeInfo.Create(penFile, AModuleName, ASubmoduleName,
      '', ANode.Name, ANode.Path));
    Exit;
  end;

  for I := 0 to ANode.Children.Count - 1 do
  begin
    ChildNode := TTAFRAFileSystemNode(ANode.Children[I]);
    RenderFileTree(ATree, Node, ChildNode, AModuleName, ASubmoduleName);
  end;
end;

procedure TProjectExplorerPresenter.Render(ATree: TTreeView;
  AProject: TTAFRAProject);
var
  RootNode: TTreeNode;
  ModuleNode: TTreeNode;
  IssuesNode: TTreeNode;
  I: Integer;
  K: Integer;
  Module: TTAFRAModule;
  Issue: TTAFRAValidationIssue;
begin
  ATree.Items.BeginUpdate;
  try
    ClearNodeData(ATree);
    ATree.Items.Clear;
    if not Assigned(AProject) then
      Exit;

    RootNode := AddNode(ATree, nil, AProject.Name,
      TProjectExplorerNodeInfo.Create(penProject));

    for I := 0 to AProject.Modules.Count - 1 do
    begin
      Module := TTAFRAModule(AProject.Modules[I]);
      ModuleNode := AddNode(ATree, RootNode, Module.Name,
        TProjectExplorerNodeInfo.Create(penModule, Module.Name, '', '', '',
        Module.Path));

      for K := 0 to Module.FileTree.Children.Count - 1 do
        RenderFileTree(ATree, ModuleNode,
          TTAFRAFileSystemNode(Module.FileTree.Children[K]), Module.Name, '');
    end;

    if AProject.Issues.Count > 0 then
    begin
      IssuesNode := AddNode(ATree, RootNode, 'Validation',
        TProjectExplorerNodeInfo.Create(penValidation));
      for I := 0 to AProject.Issues.Count - 1 do
      begin
        Issue := TTAFRAValidationIssue(AProject.Issues[I]);
        AddNode(ATree, IssuesNode, Issue.Severity + ': ' + Issue.MessageText,
          TProjectExplorerNodeInfo.Create(penValidation));
      end;
    end;

    RootNode.Expand(False);
    ATree.Selected := RootNode;
  finally
    ATree.Items.EndUpdate;
  end;
end;

end.
