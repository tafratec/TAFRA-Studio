unit uProjectAnalyzer;

{$mode objfpc}{$H+}

interface

uses
  uProjectModel;

type
  TProjectAnalyzer = class
  private
    function CategoryForExtension(const AExtension: string): string;
    function ShouldExcludeDirectory(const ADirectoryName: string): Boolean;
    function ShouldIncludeFile(const AExtension: string): Boolean;
    function DetectProjectType(AProject: TTAFRAProject): string;
    function RelativePath(const ARootPath, AFilePath: string): string;
    procedure InferOwnership(AFile: TTAFRAProjectFile);
    procedure ScanFiles(AProject: TTAFRAProject; const ADirectory: string);
  public
    procedure Analyze(AProject: TTAFRAProject);
  end;

implementation

uses
  Classes, SysUtils;

function TProjectAnalyzer.CategoryForExtension(const AExtension: string): string;
begin
  if SameText(AExtension, '.php') then
    Result := 'PHP'
  else if SameText(AExtension, '.js') then
    Result := 'JavaScript'
  else if SameText(AExtension, '.css') then
    Result := 'CSS'
  else if SameText(AExtension, '.html') then
    Result := 'HTML'
  else if SameText(AExtension, '.json') then
    Result := 'JSON'
  else if SameText(AExtension, '.sql') then
    Result := 'SQL'
  else if SameText(AExtension, '.md') then
    Result := 'Markdown'
  else
    Result := 'Other';
end;

function TProjectAnalyzer.ShouldExcludeDirectory(const ADirectoryName: string
  ): Boolean;
begin
  Result :=
    SameText(ADirectoryName, '.git') or
    SameText(ADirectoryName, 'vendor') or
    SameText(ADirectoryName, 'node_modules') or
    SameText(ADirectoryName, 'cache') or
    SameText(ADirectoryName, 'logs');
end;

function TProjectAnalyzer.ShouldIncludeFile(const AExtension: string): Boolean;
begin
  Result :=
    SameText(AExtension, '.php') or
    SameText(AExtension, '.js') or
    SameText(AExtension, '.css') or
    SameText(AExtension, '.html') or
    SameText(AExtension, '.json') or
    SameText(AExtension, '.sql') or
    SameText(AExtension, '.md');
end;

function TProjectAnalyzer.DetectProjectType(AProject: TTAFRAProject): string;
var
  ProjectName: string;
begin
  ProjectName := LowerCase(AProject.Name);

  if Pos('erp', ProjectName) > 0 then
    Result := 'TAFRA ERP'
  else if Pos('ota', ProjectName) > 0 then
    Result := 'TAFRA OTA'
  else if DirectoryExists(AProject.RootPath + DirectorySeparator + 'app' +
    DirectorySeparator + 'modules') then
    Result := 'Standard TAFRA Framework'
  else if DirectoryExists(AProject.RootPath + DirectorySeparator + 'app') or
    DirectoryExists(AProject.RootPath + DirectorySeparator + 'public') then
    Result := 'Partial TAFRA-compatible project'
  else
    Result := 'Unknown project';
end;

function TProjectAnalyzer.RelativePath(const ARootPath, AFilePath: string
  ): string;
begin
  Result := ExtractRelativePath(IncludeTrailingPathDelimiter(ARootPath),
    AFilePath);
end;

procedure TProjectAnalyzer.InferOwnership(AFile: TTAFRAProjectFile);
var
  Prefix: string;
  Parts: TStringList;
begin
  Prefix := 'app' + DirectorySeparator + 'modules' + DirectorySeparator;
  if Pos(Prefix, AFile.RelativePath) <> 1 then
    Exit;

  Parts := TStringList.Create;
  try
    Parts.Delimiter := DirectorySeparator;
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := AFile.RelativePath;

    if Parts.Count >= 3 then
      AFile.OwnerModule := Parts[2];

    if (Parts.Count >= 5) and SameText(Parts[3], 'submodules') then
      AFile.OwnerSubmodule := Parts[4];
  finally
    Parts.Free;
  end;
end;

procedure TProjectAnalyzer.ScanFiles(AProject: TTAFRAProject;
  const ADirectory: string);
var
  Search: TSearchRec;
  FullPath: string;
  Extension: string;
  ProjectFile: TTAFRAProjectFile;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    Search) <> 0 then
    Exit;

  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;

      FullPath := IncludeTrailingPathDelimiter(ADirectory) + Search.Name;

      if (Search.Attr and faDirectory) <> 0 then
      begin
        if not ShouldExcludeDirectory(Search.Name) then
          ScanFiles(AProject, FullPath);
        Continue;
      end;

      Extension := LowerCase(ExtractFileExt(Search.Name));
      if not ShouldIncludeFile(Extension) then
        Continue;

      ProjectFile := AProject.AddFile(TTAFRAProjectFile.CreateInventoryItem(
        Search.Name,
        FullPath,
        RelativePath(AProject.RootPath, FullPath),
        Extension,
        CategoryForExtension(Extension),
        Search.Size,
        FileDateToDateTime(Search.Time)));
      InferOwnership(ProjectFile);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure TProjectAnalyzer.Analyze(AProject: TTAFRAProject);
begin
  if not Assigned(AProject) then
    Exit;

  AProject.ClearFiles;
  AProject.ProjectType := DetectProjectType(AProject);
  ScanFiles(AProject, AProject.RootPath);

  if AProject.Files.Count = 0 then
    AProject.AddIssue(TTAFRAValidationIssue.Create('Warning',
      'No relevant project files were found by the analyzer.',
      AProject.RootPath));
end;

end.
