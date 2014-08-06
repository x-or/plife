program PersistentLife;

uses
  Forms,
  PersistentLife_Unit1 in 'PersistentLife_Unit1.pas' {PersistentLifeForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPersistentLifeForm, PersistentLifeForm);
  Application.Run;
end.
