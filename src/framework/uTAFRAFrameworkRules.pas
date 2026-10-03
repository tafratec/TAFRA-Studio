unit uTAFRAFrameworkRules;

{$mode objfpc}{$H+}

interface

uses
  uProjectModel;

type
  TTAFRAFrameworkRules = class
  private
    procedure RequireDirectory(AProject: TTAFRAProject;
      const ARelativePath: string);
  public
    function IsRecognizableProject(const ARootPath: string): Boolean;
    procedure ValidateProject(AProject: TTAFRAProject);
  end;

implementation

uses
  SysUtils;

function CombinePath(const ABasePath, ARelativePath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ABasePath) + ARelativePath;
end;

procedure TTAFRAFrameworkRules.RequireDirectory(AProject: TTAFRAProject;
  const ARelativePath: string);
var
  FullPath: string;
begin
  FullPath := CombinePath(AProject.RootPath, ARelativePath);
  if not DirectoryExists(FullPath) then
    AProject.AddIssue(TTAFRAValidationIssue.Create('Error',
      'Missing expected directory: ' + ARelativePath, FullPath));
end;

function TTAFRAFrameworkRules.IsRecognizableProject(const ARootPath: string
  ): Boolean;
begin
  Result :=
    DirectoryExists(CombinePath(ARootPath, 'public')) or
    DirectoryExists(CombinePath(ARootPath, 'app')) or
    DirectoryExists(CombinePath(ARootPath, 'app' + DirectorySeparator + 'modules'));
end;

procedure TTAFRAFrameworkRules.ValidateProject(AProject: TTAFRAProject);
begin
  RequireDirectory(AProject, 'public');
  RequireDirectory(AProject, 'app');
  RequireDirectory(AProject, 'app' + DirectorySeparator + 'bootstrap');
  RequireDirectory(AProject, 'app' + DirectorySeparator + 'config');
  RequireDirectory(AProject, 'app' + DirectorySeparator + 'core');
  RequireDirectory(AProject, 'app' + DirectorySeparator + 'modules');

  if AProject.Modules.Count = 0 then
    AProject.AddIssue(TTAFRAValidationIssue.Create('Warning',
      'No modules were found under app/modules.',
      CombinePath(AProject.RootPath, 'app' + DirectorySeparator + 'modules')));
end;

end.
