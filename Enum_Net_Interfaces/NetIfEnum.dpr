program NetIfEnum;

uses
  Forms,
  uMain in 'uMain.pas' {frmEnumNetInterfaces};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmEnumNetInterfaces, frmEnumNetInterfaces);
  Application.Run;
end.
