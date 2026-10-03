unit uProjectScanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, uProjectModel, uTAFRAFrameworkRules;

type
  TProjectScanner = class
  private
    FFrameworkRules: TTAFRAFrameworkRules;
    procedure ScanModules(AProject: TTAFRAProject);
    procedure ScanSubmodules(AModule: TTAFRAModule);
    procedure ScanFileTree(ANode: TTAFRAFileSystemNode);
    procedure ScanKnownFiles(ASubmodule: TTAFRASubmodule);
    procedure AddFilesFromDir(const ADirectory: string; ATarget: TStrings);
  public
    constructor Create(AFrameworkRules: TTAFRAFrameworkRules);
    function Scan(const ARootPath: string): TTAFRAProject;
  end;

implementation

uses
  SysUtils;

constructor TProjectScanner.Create(AFrameworkRules: TTAFRAFrameworkRules);
begin
  inherited Create;
  FFrameworkRules := AFrameworkRules;
end;

procedure TProjectScanner.AddFilesFromDir(const ADirectory: string;
  ATarget: TStrings);
var
  Search: TSearchRec;
begin
  if not DirectoryExists(ADirectory) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile, Search) = 0 then
  begin
    try
      repeat
        if (Search.Name <> '.') and (Search.Name <> '..') and
          ((Search.Attr and faDirectory) = 0) then
          ATarget.Add(Search.Name);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
end;

procedure TProjectScanner.ScanFileTree(ANode: TTAFRAFileSystemNode);
var
  Search: TSearchRec;
  ChildPath: string;
  ChildNode: TTAFRAFileSystemNode;
begin
  if (not Assigned(ANode)) or (not ANode.IsDirectory) or
    (not DirectoryExists(ANode.Path)) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(ANode.Path) + '*', faAnyFile,
    Search) <> 0 then
    Exit;

  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;

      ChildPath := IncludeTrailingPathDelimiter(ANode.Path) + Search.Name;
      ChildNode := ANode.AddChild(TTAFRAFileSystemNode.Create(Search.Name,
        ChildPath, (Search.Attr and faDirectory) <> 0));

      if ChildNode.IsDirectory then
        ScanFileTree(ChildNode);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure TProjectScanner.ScanKnownFiles(ASubmodule: TTAFRASubmodule);
begin
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'controllers',
    ASubmodule.Controllers);
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'models',
    ASubmodule.Models);
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'services',
    ASubmodule.Services);
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'views',
    ASubmodule.Views);
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'routes',
    ASubmodule.Routes);
  AddFilesFromDir(ASubmodule.Path + DirectorySeparator + 'assets',
    ASubmodule.Assets);
end;

procedure TProjectScanner.ScanSubmodules(AModule: TTAFRAModule);
var
  SubmodulesPath: string;
  Search: TSearchRec;
  Submodule: TTAFRASubmodule;
begin
  SubmodulesPath := AModule.Path + DirectorySeparator + 'submodules';
  ScanFileTree(AModule.FileTree);
  if not DirectoryExists(SubmodulesPath) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(SubmodulesPath) + '*', faDirectory, Search) = 0 then
  begin
    try
      repeat
        if (Search.Name <> '.') and (Search.Name <> '..') and
          ((Search.Attr and faDirectory) <> 0) then
        begin
          Submodule := AModule.AddSubmodule(TTAFRASubmodule.Create(Search.Name,
            SubmodulesPath + DirectorySeparator + Search.Name));
          ScanFileTree(Submodule.FileTree);
          ScanKnownFiles(Submodule);
        end;
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
end;

procedure TProjectScanner.ScanModules(AProject: TTAFRAProject);
var
  ModulesPath: string;
  Search: TSearchRec;
  Module: TTAFRAModule;
begin
  ModulesPath := AProject.RootPath + DirectorySeparator + 'app' +
    DirectorySeparator + 'modules';
  if not DirectoryExists(ModulesPath) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(ModulesPath) + '*', faDirectory, Search) = 0 then
  begin
    try
      repeat
        if (Search.Name <> '.') and (Search.Name <> '..') and
          ((Search.Attr and faDirectory) <> 0) then
        begin
          Module := AProject.AddModule(TTAFRAModule.Create(Search.Name,
            ModulesPath + DirectorySeparator + Search.Name));
          ScanSubmodules(Module);
        end;
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
end;

function TProjectScanner.Scan(const ARootPath: string): TTAFRAProject;
begin
  Result := TTAFRAProject.Create(ARootPath);
  ScanModules(Result);

  if Assigned(FFrameworkRules) then
    FFrameworkRules.ValidateProject(Result);
end;

end.
