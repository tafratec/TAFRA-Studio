unit uTestPointLogModel;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TTestPointLogEntry = class
  private
    FTimestamp: string;
    FPointId: string;
    FArea: string;
    FModuleName: string;
    FFolderPath: string;
    FFilePath: string;
    FStatus: string;
    FDurationMS: Int64;
    FContext: string;
    FRequestId: string;
    FRawJson: string;
  public
    property Timestamp: string read FTimestamp write FTimestamp;
    property PointId: string read FPointId write FPointId;
    property Area: string read FArea write FArea;
    property ModuleName: string read FModuleName write FModuleName;
    property FolderPath: string read FFolderPath write FFolderPath;
    property FilePath: string read FFilePath write FFilePath;
    property Status: string read FStatus write FStatus;
    property DurationMS: Int64 read FDurationMS write FDurationMS;
    property Context: string read FContext write FContext;
    property RequestId: string read FRequestId write FRequestId;
    property RawJson: string read FRawJson write FRawJson;
  end;

implementation

end.
