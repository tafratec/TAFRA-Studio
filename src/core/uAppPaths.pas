unit uAppPaths;

{$mode objfpc}{$H+}

interface

type
  TAppPaths = class
  private
    FApplicationRoot: string;
    function PathInRoot(const ARelativePath: string): string;
  public
    constructor Create;
    property ApplicationRoot: string read FApplicationRoot;
    function ConfigPath: string;
    function ResourcesPath: string;
    function RuntimePHPPath: string;
    function PHPExecutablePath: string;
    function PHPToolsPath: string;
    function PHPHealthCheckToolPath: string;
  end;

implementation

uses
  SysUtils;

constructor TAppPaths.Create;
begin
  inherited Create;
  FApplicationRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function TAppPaths.PathInRoot(const ARelativePath: string): string;
begin
  Result := IncludeTrailingPathDelimiter(FApplicationRoot) + ARelativePath;
end;

function TAppPaths.ConfigPath: string;
begin
  Result := PathInRoot('config');
end;

function TAppPaths.ResourcesPath: string;
begin
  Result := PathInRoot('resources');
end;

function TAppPaths.RuntimePHPPath: string;
begin
  Result := PathInRoot('runtime' + DirectorySeparator + 'php');
end;

function TAppPaths.PHPExecutablePath: string;
begin
  Result := RuntimePHPPath + DirectorySeparator + 'php.exe';
end;

function TAppPaths.PHPToolsPath: string;
begin
  Result := PathInRoot('tools' + DirectorySeparator + 'php');
end;

function TAppPaths.PHPHealthCheckToolPath: string;
begin
  Result := PHPToolsPath + DirectorySeparator + 'health-check.php';
end;

end.
