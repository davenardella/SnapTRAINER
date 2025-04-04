library module_simplemotor;

{$MODE DELPHI}

uses
  Interfaces, Windows, Forms, tachartlazaruspkg, VxExports;

Exports
  module_create       name 'module_create',
  module_destroy      name 'module_destroy',
  module_newindex     name 'module_newindex',
  module_start        name 'module_start',
  module_stop         name 'module_stop',
  module_prestart     name 'module_prestart',
  module_edit         name 'module_edit',
  module_busy         name 'module_busy',
  module_save         name 'module_save';


procedure DLLDetach(dllparam : PtrInt);
begin
  Application.Terminate;
end;


begin
  Dll_Process_Detach_Hook := @DLLDetach;
  Application.Initialize;
  Screen.HintFont.Name:='Courier New';
end.

