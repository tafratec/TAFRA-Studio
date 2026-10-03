unit uProjectModel;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TTAFRAFileSystemNode = class
  private
    FName: string;
    FPath: string;
    FIsDirectory: Boolean;
    FChildren: TList;
  public
    constructor Create(const AName, APath: string; AIsDirectory: Boolean);
    destructor Destroy; override;
    function AddChild(AChild: TTAFRAFileSystemNode): TTAFRAFileSystemNode;
    property Name: string read FName;
    property Path: string read FPath;
    property IsDirectory: Boolean read FIsDirectory;
    property Children: TList read FChildren;
  end;

  TTAFRAProjectFile = class
  private
    FName: string;
    FPath: string;
    FRelativePath: string;
    FKind: string;
    FExtension: string;
    FSize: Int64;
    FModifiedTime: TDateTime;
    FCategory: string;
    FOwnerModule: string;
    FOwnerSubmodule: string;
  public
    constructor Create(const AName, APath, AKind: string);
    constructor CreateInventoryItem(const AName, APath, ARelativePath,
      AExtension, ACategory: string; ASize: Int64; AModifiedTime: TDateTime);
    property Name: string read FName;
    property Path: string read FPath;
    property RelativePath: string read FRelativePath;
    property Kind: string read FKind;
    property Extension: string read FExtension;
    property Size: Int64 read FSize;
    property ModifiedTime: TDateTime read FModifiedTime;
    property Category: string read FCategory;
    property OwnerModule: string read FOwnerModule write FOwnerModule;
    property OwnerSubmodule: string read FOwnerSubmodule write FOwnerSubmodule;
  end;

  TTAFRASubmodule = class
  private
    FName: string;
    FPath: string;
    FControllers: TStringList;
    FModels: TStringList;
    FServices: TStringList;
    FViews: TStringList;
    FRoutes: TStringList;
    FAssets: TStringList;
    FFileTree: TTAFRAFileSystemNode;
  public
    constructor Create(const AName, APath: string);
    destructor Destroy; override;
    property Name: string read FName;
    property Path: string read FPath;
    property Controllers: TStringList read FControllers;
    property Models: TStringList read FModels;
    property Services: TStringList read FServices;
    property Views: TStringList read FViews;
    property Routes: TStringList read FRoutes;
    property Assets: TStringList read FAssets;
    property FileTree: TTAFRAFileSystemNode read FFileTree;
  end;

  TTAFRAModule = class
  private
    FName: string;
    FPath: string;
    FSubmodules: TList;
    FFileTree: TTAFRAFileSystemNode;
  public
    constructor Create(const AName, APath: string);
    destructor Destroy; override;
    function AddSubmodule(ASubmodule: TTAFRASubmodule): TTAFRASubmodule;
    property Name: string read FName;
    property Path: string read FPath;
    property Submodules: TList read FSubmodules;
    property FileTree: TTAFRAFileSystemNode read FFileTree;
  end;

  TTAFRAValidationIssue = class
  private
    FSeverity: string;
    FMessage: string;
    FPath: string;
  public
    constructor Create(const ASeverity, AMessage, APath: string);
    property Severity: string read FSeverity;
    property MessageText: string read FMessage;
    property Path: string read FPath;
  end;

  TTAFRAProject = class
  private
    FName: string;
    FRootPath: string;
    FProjectType: string;
    FModules: TList;
    FIssues: TList;
    FFiles: TList;
  public
    constructor Create(const ARootPath: string);
    destructor Destroy; override;
    function AddModule(AModule: TTAFRAModule): TTAFRAModule;
    function AddIssue(AIssue: TTAFRAValidationIssue): TTAFRAValidationIssue;
    function AddFile(AFile: TTAFRAProjectFile): TTAFRAProjectFile;
    procedure ClearFiles;
    function FileCountByCategory(const ACategory: string): Integer;
    property Name: string read FName;
    property RootPath: string read FRootPath;
    property ProjectType: string read FProjectType write FProjectType;
    property Modules: TList read FModules;
    property Issues: TList read FIssues;
    property Files: TList read FFiles;
  end;

implementation

uses
  SysUtils;

constructor TTAFRAFileSystemNode.Create(const AName, APath: string;
  AIsDirectory: Boolean);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FIsDirectory := AIsDirectory;
  FChildren := TList.Create;
end;

destructor TTAFRAFileSystemNode.Destroy;
var
  I: Integer;
begin
  for I := 0 to FChildren.Count - 1 do
    TObject(FChildren[I]).Free;
  FChildren.Free;
  inherited Destroy;
end;

function TTAFRAFileSystemNode.AddChild(AChild: TTAFRAFileSystemNode
  ): TTAFRAFileSystemNode;
begin
  FChildren.Add(AChild);
  Result := AChild;
end;

constructor TTAFRAProjectFile.Create(const AName, APath, AKind: string);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FRelativePath := AName;
  FKind := AKind;
  FExtension := ExtractFileExt(AName);
  FCategory := AKind;
end;

constructor TTAFRAProjectFile.CreateInventoryItem(const AName, APath,
  ARelativePath, AExtension, ACategory: string; ASize: Int64;
  AModifiedTime: TDateTime);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FRelativePath := ARelativePath;
  FKind := 'File';
  FExtension := AExtension;
  FSize := ASize;
  FModifiedTime := AModifiedTime;
  FCategory := ACategory;
end;

constructor TTAFRASubmodule.Create(const AName, APath: string);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FControllers := TStringList.Create;
  FModels := TStringList.Create;
  FServices := TStringList.Create;
  FViews := TStringList.Create;
  FRoutes := TStringList.Create;
  FAssets := TStringList.Create;
  FFileTree := TTAFRAFileSystemNode.Create(AName, APath, True);
end;

destructor TTAFRASubmodule.Destroy;
begin
  FFileTree.Free;
  FAssets.Free;
  FRoutes.Free;
  FViews.Free;
  FServices.Free;
  FModels.Free;
  FControllers.Free;
  inherited Destroy;
end;

constructor TTAFRAModule.Create(const AName, APath: string);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
  FSubmodules := TList.Create;
  FFileTree := TTAFRAFileSystemNode.Create(AName, APath, True);
end;

destructor TTAFRAModule.Destroy;
var
  I: Integer;
begin
  for I := 0 to FSubmodules.Count - 1 do
    TObject(FSubmodules[I]).Free;
  FFileTree.Free;
  FSubmodules.Free;
  inherited Destroy;
end;

function TTAFRAModule.AddSubmodule(ASubmodule: TTAFRASubmodule
  ): TTAFRASubmodule;
begin
  FSubmodules.Add(ASubmodule);
  Result := ASubmodule;
end;

constructor TTAFRAValidationIssue.Create(const ASeverity, AMessage,
  APath: string);
begin
  inherited Create;
  FSeverity := ASeverity;
  FMessage := AMessage;
  FPath := APath;
end;

constructor TTAFRAProject.Create(const ARootPath: string);
begin
  inherited Create;
  FRootPath := ExcludeTrailingPathDelimiter(ARootPath);
  FName := ExtractFileName(FRootPath);
  FProjectType := 'Unknown';
  FModules := TList.Create;
  FIssues := TList.Create;
  FFiles := TList.Create;
end;

destructor TTAFRAProject.Destroy;
var
  I: Integer;
begin
  for I := 0 to FFiles.Count - 1 do
    TObject(FFiles[I]).Free;
  for I := 0 to FModules.Count - 1 do
    TObject(FModules[I]).Free;
  for I := 0 to FIssues.Count - 1 do
    TObject(FIssues[I]).Free;
  FFiles.Free;
  FIssues.Free;
  FModules.Free;
  inherited Destroy;
end;

function TTAFRAProject.AddModule(AModule: TTAFRAModule): TTAFRAModule;
begin
  FModules.Add(AModule);
  Result := AModule;
end;

function TTAFRAProject.AddIssue(AIssue: TTAFRAValidationIssue
  ): TTAFRAValidationIssue;
begin
  FIssues.Add(AIssue);
  Result := AIssue;
end;

function TTAFRAProject.AddFile(AFile: TTAFRAProjectFile): TTAFRAProjectFile;
begin
  FFiles.Add(AFile);
  Result := AFile;
end;

procedure TTAFRAProject.ClearFiles;
var
  I: Integer;
begin
  for I := 0 to FFiles.Count - 1 do
    TObject(FFiles[I]).Free;
  FFiles.Clear;
end;

function TTAFRAProject.FileCountByCategory(const ACategory: string): Integer;
var
  I: Integer;
  ProjectFile: TTAFRAProjectFile;
begin
  Result := 0;
  for I := 0 to FFiles.Count - 1 do
  begin
    ProjectFile := TTAFRAProjectFile(FFiles[I]);
    if SameText(ProjectFile.Category, ACategory) then
      Inc(Result);
  end;
end;

end.
