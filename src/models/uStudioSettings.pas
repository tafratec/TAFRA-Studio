unit uStudioSettings;

{$mode objfpc}{$H+}

interface

type
  TStudioSettings = class
  private
    FStudioPHPPath: string;
    FProjectPHPPath: string;
    FProjectPHPMode: string;
    FComposerPath: string;
    FComposerRuntimeMode: string;
    FComposerCustomPHPPath: string;
    FSourceFontName: string;
    FSourceFontSize: Integer;
    FThemeName: string;
  public
    procedure Assign(ASettings: TStudioSettings);
    property StudioPHPPath: string read FStudioPHPPath write FStudioPHPPath;
    property ProjectPHPPath: string read FProjectPHPPath write FProjectPHPPath;
    property ProjectPHPMode: string read FProjectPHPMode write FProjectPHPMode;
    property ComposerPath: string read FComposerPath write FComposerPath;
    property ComposerRuntimeMode: string read FComposerRuntimeMode
      write FComposerRuntimeMode;
    property ComposerCustomPHPPath: string read FComposerCustomPHPPath
      write FComposerCustomPHPPath;
    property SourceFontName: string read FSourceFontName write FSourceFontName;
    property SourceFontSize: Integer read FSourceFontSize write FSourceFontSize;
    property ThemeName: string read FThemeName write FThemeName;
  end;

implementation

procedure TStudioSettings.Assign(ASettings: TStudioSettings);
begin
  if not Assigned(ASettings) then
    Exit;

  FStudioPHPPath := ASettings.StudioPHPPath;
  FProjectPHPPath := ASettings.ProjectPHPPath;
  FProjectPHPMode := ASettings.ProjectPHPMode;
  FComposerPath := ASettings.ComposerPath;
  FComposerRuntimeMode := ASettings.ComposerRuntimeMode;
  FComposerCustomPHPPath := ASettings.ComposerCustomPHPPath;
  FSourceFontName := ASettings.SourceFontName;
  FSourceFontSize := ASettings.SourceFontSize;
  FThemeName := ASettings.ThemeName;
end;

end.
